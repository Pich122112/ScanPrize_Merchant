import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gb_merchant/main/TransactionPage.dart';
import 'package:gb_merchant/services/user_balance_service.dart';
import 'package:gb_merchant/utils/balance_refresh_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_server.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static late GlobalKey<NavigatorState> navigatorKey;
  static ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(0);
  static bool _permissionsRequested = false;

  /// Upload FCM token to backend
  static Future<void> sendFcmTokenToBackend({required String apiToken}) async {
    final fcmToken = await _messaging.getToken();
    if (fcmToken == null) {
      print('❌ FCM token is null, not sent to backend.');
      return;
    }

    try {
      final result = await ApiService.uploadFcmToken(
        apiToken: apiToken,
        fcmToken: fcmToken,
      );
      if (result['success'] == true || result['result'] == 123) {
        print('✅ FCM token sent to backend successfully!');
      } else {
        print('❌ FCM token upload failed: ${result['message'] ?? result}');
      }
    } catch (e) {
      print('❌ Exception during FCM token upload: $e');
    }
  }

  /// Badge management
  static Future<void> incrementBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('badgeCount') ?? 0;
    currentCount++;
    await prefs.setInt('badgeCount', currentCount);
    badgeCountNotifier.value = currentCount;
  }

  static Future<void> resetBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badgeCount', 0);
    badgeCountNotifier.value = 0;
  }

  /// Request permissions
  static Future<void> _requestNotificationPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      print('Notification permission status: $status');
    }
  }

  static Future<void> requestNotificationPermissions() async {
    return _requestNotificationPermissions();
  }

  /// Init FCM + Local Notifications
  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    await _requestNotificationPermissions();

    // ✅ Get token (wait for APNs on iOS)
    String? fcmToken;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _messaging.getAPNSToken();
      print("📱 APNS Token: $apnsToken");
      if (apnsToken != null) {
        fcmToken = await _messaging.getToken();
      }
    } else {
      fcmToken = await _messaging.getToken();
    }
    print("🔥 FCM Token: $fcmToken");

    // Upload token if user logged in
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('token');
    if (fcmToken != null && apiToken != null) {
      await sendFcmTokenToBackend(apiToken: apiToken);
    }

    // Token refresh listener
    _messaging.onTokenRefresh.listen((newToken) async {
      print("🔑 Refreshed FCM token: $newToken");
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString('token');
      if (apiToken != null) {
        await sendFcmTokenToBackend(apiToken: apiToken);
      }
    });

    // Init local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        print("📩 Notification tapped with payload: ${response.payload}");
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            await handleNotificationData(Map<String, dynamic>.from(data));
          } catch (e) {
            print('❌ Error parsing notification payload: $e');
          }
        }

        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
      },
    );

    // Foreground 99777454 notifications → force banner/sound on iOS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      final data = message.data;

      await incrementBadgeCount();
      await handleNotificationData(data);
      print("📩 Foreground notification received: $data");
      await _localNotifications.show(
        message.notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            icon: '@drawable/ic_notification',
            importance: Importance.max,
            priority: Priority.high,
            channelShowBadge: true,
          ),
          iOS: DarwinNotificationDetails(
            badgeNumber: badgeCountNotifier.value,
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: "default_thread",
          ),
        ),
        payload: jsonEncode(data),
      );
    });

    // Background/terminated opened
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => NotificationPage()),
      );
      BalanceRefreshNotifier().refreshBalances();
      print("📩 Notification opened from background: ${message.data}");
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print("✅ FirebaseService initialized successfully!");
  }

  /// Handle custom notification data
  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    print('📲 Handling notification data: $data');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        final userProfile = await ApiService.getUserProfile(token);
        if (userProfile['success'] == true && userProfile['data'] != null) {
          final balances = UserBalanceService.parseWalletsFromUserDetail(
            userProfile,
          );
          await UserBalanceService.setBalancesToCache(balances);
          BalanceRefreshNotifier().refreshBalances();
          print('✅ Balances updated from notification: $balances');
        }
      }
    } catch (e) {
      print('❌ Error updating balances from notification: $e');
    }
  }
}

/// Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FirebaseService.incrementBadgeCount();
  await FirebaseService.handleNotificationData(message.data);
  print('📩 Handling a background message: ${message.messageId}');
}

//Correct with 228 line code changes
