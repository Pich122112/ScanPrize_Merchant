// websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/scanqr_prize.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  WebSocketChannel? _channel;
  late StreamController<Map<String, dynamic>> _balanceController;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  factory WebSocketService() => _instance;

  WebSocketService._internal() {
    _balanceController = StreamController<Map<String, dynamic>>.broadcast();
  }

  Stream<Map<String, dynamic>> get balanceStream => _balanceController.stream;

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    print('Attempting WebSocket connection...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';

      if (token.isEmpty || userId.isEmpty) {
        print('WebSocket: Missing token or userId');
        _isConnecting = false;
        return;
      }

      final wsUrl = Uri.parse(
        'ws://${Constants.wsUrl}/ws/balances?token=$token&userId=$userId',
      );

      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      print('WebSocket connected to $wsUrl');

      _channel!.stream.listen(
        (data) {
          print('Received WebSocket data: $data');
          try {
            final message = json.decode(data);
            if (message['type'] == 'balance_update') {
              _balanceController.add(message['data']);
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
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    _channel?.sink.close();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Exponential backoff (5s, 10s, 20s, 40s, max 60s)
    final delay = Duration(
      seconds: min(5 * pow(2, _reconnectAttempts - 1).toInt(), 60),
    );

    print('Scheduling reconnect in ${delay.inSeconds} seconds...');

    _reconnectTimer = Timer(delay, () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
  }

  void dispose() {
    disconnect();
    _balanceController.close();
  }
}
