// websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'scanqr_prize.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  WebSocketChannel? _channel;
  late StreamController<Map<String, dynamic>> _balanceController;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  factory WebSocketService() => _instance;

  WebSocketService._internal() {
    _balanceController = StreamController<Map<String, dynamic>>.broadcast();
    _initConnectivityListener();
  }

  Stream<Map<String, dynamic>> get balanceStream => _balanceController.stream;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = results.any(
        (result) => result != ConnectivityResult.none,
      );
      print('Network status changed: $results - Online: $isOnline');

      if (isOnline && !_isConnected && !_isConnecting) {
        print('Network available - attempting to connect...');
        connect();
      } else if (!isOnline) {
        print('Network unavailable - disconnecting if connected');
        _handleDisconnection();
      }
    });
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      print(
        'Connection attempt skipped - already ${_isConnected ? 'connected' : 'connecting'}',
      );
      return;
    }

    _isConnecting = true;
    _reconnectTimer?.cancel();
    print('Attempting WebSocket connection...');

    try {
      // Check connectivity first
      final List<ConnectivityResult> connectivityResults =
          await Connectivity().checkConnectivity();
      final isOnline = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!isOnline) {
        print('No internet connection available - aborting connection attempt');
        _isConnecting = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';

      if (token.isEmpty || userId.isEmpty) {
        print('WebSocket: Missing token or userId - cannot connect');
        _isConnecting = false;
        return;
      }

      // Close any existing connection
      await _channel?.sink.close();

      // Create new connection with timeout
      final wsUrl = Uri.parse(
        'wss://${Constants.wsUrl}/ws/balances?token=$token&userId=$userId',
      );
      print('Connecting to WebSocket at $wsUrl');

      // Add connection timeout
      final connectionTimeout = const Duration(seconds: 10);
      final connectionCompleter = Completer<void>();
      final timeoutTimer = Timer(connectionTimeout, () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError(
            TimeoutException('WebSocket connection timed out'),
          );
        }
      });

      _channel = WebSocketChannel.connect(wsUrl);

      // Listen for first message to confirm connection
      _channel!.stream.first
          .then((_) {
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete();
            }
          })
          .catchError((e) {
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.completeError(e);
            }
          });

      await connectionCompleter.future;
      timeoutTimer.cancel();

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      print('WebSocket connected successfully to $wsUrl');

      // Start ping/pong mechanism
      _startPingTimer();

      _channel!.stream.listen(
        (data) {
          print('Received WebSocket data: $data');
          try {
            final message = json.decode(data);
            if (message['type'] == 'balance_update') {
              print('Processing balance update');
              _balanceController.add(message['data']);
            } else if (message['type'] == 'pong') {
              print('Received pong response');
            }
          } catch (e) {
            print('WebSocket message error: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed by server');
          _handleDisconnection();
        },
      );
    } on TimeoutException catch (e) {
      print('WebSocket connection timeout: $e');
      _handleDisconnection();
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleDisconnection();
    } finally {
      _isConnecting = false;
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        try {
          final pingMessage = json.encode({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          print('Sending ping: $pingMessage');
          _channel!.sink.add(pingMessage);
        } catch (e) {
          print('Error sending ping: $e');
          _handleDisconnection();
        }
      }
    });
  }

  void _handleDisconnection() {
    if (!_isConnected && !_isConnecting) return;

    print('Handling disconnection...');
    _isConnected = false;
    _isConnecting = false;
    _pingTimer?.cancel();

    try {
      _channel?.sink.close();
    } catch (e) {
      print('Error closing WebSocket: $e');
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Exponential backoff with jitter (5s, 10s, 20s, 40s, max 60s)
    final baseDelay = min(5 * pow(2, _reconnectAttempts - 1).toInt(), 60);
    final jitter = Random().nextInt(3000); // Add up to 3s jitter
    final delay = Duration(milliseconds: baseDelay * 1000 + jitter);

    print(
      'Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isConnecting) {
        connect();
      }
    });
  }

  Future<void> disconnect() async {
    print('Manual disconnection requested');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _connectivitySubscription?.cancel();
    try {
      await _channel?.sink.close();
    } catch (e) {
      print('Error during manual disconnect: $e');
    }
    _isConnected = false;
    _isConnecting = false;
  }

  void dispose() {
    print('Disposing WebSocketService');
    disconnect();
    _balanceController.close();
  }
}
