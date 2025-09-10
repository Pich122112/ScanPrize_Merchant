// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart' show defaultTargetPlatform;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
// import 'package:gb_merchant/main/TransactionPage.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:permission_handler/permission_handler.dart';

// class FirebaseService {
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   static late GlobalKey<NavigatorState> navigatorKey;
//   static ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(0);
//   // ignore: unused_field
//   static bool _permissionsRequested = false;

//   /// 📌 Add this method here
//   static Future<void> incrementBadgeCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     int currentCount = prefs.getInt('badgeCount') ?? 0;
//     currentCount++;
//     await prefs.setInt('badgeCount', currentCount);

//     // 👇 Notify listeners
//     badgeCountNotifier.value = currentCount;
//   }

//   /// Request notification permissions
//   static Future<void> _requestNotificationPermissions() async {
//     // For iOS
//     if (defaultTargetPlatform == TargetPlatform.iOS) {
//       await _messaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//       );
//     }
//     // For Android 13+
//     else if (defaultTargetPlatform == TargetPlatform.android) {
//       final status = await Permission.notification.request();
//       print('Notification permission status: $status');
//     }
//   }

//   /// 🔁 Optional reset method
//   static Future<void> resetBadgeCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('badgeCount', 0);
//     // 👇 Notify listeners
//     badgeCountNotifier.value = 0;
//   }

//   static Future<void> requestNotificationPermissions() async {
//     _permissionsRequested = true;
//     return _requestNotificationPermissions();
//   }

//   // Call this in main.dart after Firebase.initializeApp()
//   static Future<void> init(GlobalKey<NavigatorState> navKey) async {
//     navigatorKey = navKey;

//     // Request notification permissions
//     await _requestNotificationPermissions();

//     // Get device FCM token
//     String? token = await _messaging.getToken();
//     print('FCM Token: $token');
//     // TODO: Upload this token to your backend associated with the logged-in user

//     // Android initialization
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     // iOS initialization
//     const DarwinInitializationSettings iosSettings =
//         DarwinInitializationSettings(
//           requestAlertPermission: true,
//           requestBadgePermission: true,
//           requestSoundPermission: true,
//         );
//     // Combine both
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: androidSettings, iOS: iosSettings);

//     // Initialize local notification plugin
//     await _localNotifications.initialize(
//       initializationSettings,
//       // Optional: handle tap on notification
//       onDidReceiveNotificationResponse: (response) {
//         // Navigate to the Notification page
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(builder: (context) => NotificationPage()),
//         );
//         // You can navigate or handle notification tap here
//         print('Notification tapped with payload: ${response.payload}');
//       },
//     );

//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       String? title = message.notification?.title ?? 'Notification';
//       String? body = message.notification?.body ?? '';
//       String? payload = message.data.toString();
//       // ✅ Use the static method you just created
//       await incrementBadgeCount();

//       await _localNotifications.show(
//         message.notification.hashCode,
//         title,
//         body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'default_channel', // Channel id
//             'Default', // Channel name
//             icon: '@drawable/ic_notification', // ✅ Custom icon
//             importance: Importance.max,
//             priority: Priority.high,
//             channelShowBadge: true,
//           ),
//           iOS: DarwinNotificationDetails(badgeNumber: badgeCountNotifier.value),
//         ),
//         payload: payload,
//       );
//     });

//     // OPTIONAL: Handle background and terminated state
//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(builder: (context) => NotificationPage()),
//       );
//       // Handle navigation when user taps notification from background
//       print("Notification opened from background: ${message.data}");
//     });

//     // For background messages (outside app lifecycle)
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   }
// }

// // Top-level handler for background messages
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(); // Required in background isolate
//   await FirebaseService.incrementBadgeCount(); // ✅ This will update the badge
//   // You must call Firebase.initializeApp() here if not already done
//   print('Handling a background message: ${message.messageId}');
//   // Optionally show local notification, update local storage, etc.
// }

// //Correct with 152 line code changes
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/main/TransactionPage.dart';
import 'package:gb_merchant/services/user_balance_service.dart';
import 'package:gb_merchant/utils/balance_refresh_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/user_server.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static late GlobalKey<NavigatorState> navigatorKey;
  static ValueNotifier<int> badgeCountNotifier = ValueNotifier<int>(0);
  // ignore: unused_field
  static bool _permissionsRequested = false;

  static Future<void> sendFcmTokenToBackend({required String apiToken}) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      try {
        final result = await ApiService.uploadFcmToken(
          apiToken: apiToken,
          fcmToken: fcmToken,
        );
        print('✅ FCM token upload response: $result');
        if (result['success'] == true || result['result'] == 123) {
          print('✅ FCM token sent to backend successfully!');
        } else {
          print('❌ FCM token upload failed: ${result['message'] ?? result}');
        }
      } catch (e) {
        print('❌ Exception during FCM token upload: $e');
      }
    } else {
      print('❌ FCM token is null, not sent to backend.');
    }
  }

  /// 📌 Add this method here
  static Future<void> incrementBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('badgeCount') ?? 0;
    currentCount++;
    await prefs.setInt('badgeCount', currentCount);

    // 👇 Notify listeners
    badgeCountNotifier.value = currentCount;
  }

  /// Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    // For iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
    // For Android 13+
    else if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      print('Notification permission status: $status');
    }
  }

  /// 🔁 Optional reset method
  static Future<void> resetBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badgeCount', 0);
    // 👇 Notify listeners
    badgeCountNotifier.value = 0;
  }

  static Future<void> requestNotificationPermissions() async {
    _permissionsRequested = true;
    return _requestNotificationPermissions();
  }

  // Call this in main.dart after Firebase.initializeApp()
  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // Request notification permissions
    await _requestNotificationPermissions();

    // Get device FCM token
    String? fcmToken = await _messaging.getToken();
    print('FCM Token: $fcmToken');

    // Upload initial FCM token to backend if user is authenticated
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString('token');
    if (fcmToken != null && apiToken != null) {
      await sendFcmTokenToBackend(apiToken: apiToken);
    }

    // Listen for FCM token refresh events and upload new token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final apiToken = prefs.getString('token');
      if (userId != null && apiToken != null) {
        await sendFcmTokenToBackend(apiToken: apiToken);
      }
    });

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    // Combine both
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize local notification plugin
    // Initialize local notification plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        // Parse payload data
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            await handleNotificationData(Map<String, dynamic>.from(data));
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }

        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
      },
    );

    // Handle foreground messages
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      String? title = message.notification?.title ?? 'Notification';
      String? body = message.notification?.body ?? '';
      Map<String, dynamic> data = message.data;

      await incrementBadgeCount();

      // Handle notification data for balance updates
      await handleNotificationData(data);

      await _localNotifications.show(
        message.notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            icon: '@drawable/ic_notification',
            largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
            importance: Importance.max,
            priority: Priority.high,
            channelShowBadge: true,
          ),
          iOS: DarwinNotificationDetails(badgeNumber: badgeCountNotifier.value),
        ),
        payload: jsonEncode(data), // Send data as payload
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => NotificationPage()),
      );
      // Add this:
      BalanceRefreshNotifier().refreshBalances();
      print("Notification opened from background: ${message.data}");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // static Future<void> handleNotificationData(Map<String, dynamic> data) async {
  //   print('📲 Handling notification data: $data');

  //   // Check if this is a balance-related notification
  //   if (data.containsKey('type') && data['type'] == 'balance_update') {
  //     print('💰 Balance update notification received');

  //     // Force refresh balances
  //     try {
  //       final prefs = await SharedPreferences.getInstance();
  //       final token = prefs.getString('token');

  //       if (token != null) {
  //         // Force fetch fresh user profile with balance
  //         final userProfile = await ApiService.getUserProfile(token);

  //         if (userProfile['success'] == true && userProfile['data'] != null) {
  //           // Update balances in cache
  //           final balances = UserBalanceService.parseWalletsFromUserDetail(
  //             userProfile,
  //           );
  //           await UserBalanceService.setBalancesToCache(balances);

  //           // Notify all listeners about the balance update
  //           BalanceRefreshNotifier().refreshBalances();

  //           print('✅ Balances updated from notification: $balances');
  //         }
  //       }
  //     } catch (e) {
  //       print('❌ Error updating balances from notification: $e');
  //     }
  //   }
  // }

  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    print('📲 Handling notification data: $data');

    // Always refresh, regardless of data payload
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

// Top-level handler for background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FirebaseService.incrementBadgeCount();

  // Handle notification data for balance updates
  await FirebaseService.handleNotificationData(message.data);

  print('Handling a background message: ${message.messageId}');
}

//Correct with 269 line code changes
