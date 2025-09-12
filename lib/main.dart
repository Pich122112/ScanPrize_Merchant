import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gb_merchant/screens/firstScreen.dart';
import 'package:gb_merchant/utils/device_uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/bottomAppbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gb_merchant/main/TransactionPage.dart';
import 'package:gb_merchant/services/firebase_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FirebaseService.incrementBadgeCount();

  // Handle background message 855887776756 (can show notification, etc)
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseService.init(navigatorKey);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  debugPrint = (String? message, {int? wrapWidth}) {
    print(message);
  };

  // Initialize device UUID early
  final deviceUuid = await DeviceUUID.getUUID();
  print('📱 MAIN: Device UUID initialized: $deviceUuid');

  // Check if app was opened from terminated state via notification
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await FirebaseService.incrementBadgeCount(); // ✅ Add this line

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => NotificationPage()),
      );
    });
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('km')],
      path: 'assets/translations',
      fallbackLocale: const Locale('km'),
      startLocale: const Locale('km'), // 👈 force Khmer when app starts
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, dynamic>> _getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final phoneNumber = prefs.getString('phoneNumber') ?? '';
    print('DEBUG: isLoggedIn=$isLoggedIn, phoneNumber=$phoneNumber');
    return {'isLoggedIn': isLoggedIn, 'phoneNumber': phoneNumber};
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // <== ADD THIS LINE

      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getLoginState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isLoggedIn = snapshot.data!['isLoggedIn'] as bool;

          // Use Firstscreen directly - it already has its own Scaffold
          return isLoggedIn ? RomlousApp() : Firstscreen();
        },
      ),
    );
  }
}

//Correct with 94 line code changes
