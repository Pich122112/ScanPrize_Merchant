import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gb_merchant/screens/firstScreen.dart';
import 'package:gb_merchant/utils/device_uuid.dart';
import 'package:gb_merchant/widgets/start_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/bottomAppbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gb_merchant/main/TransactionPage.dart';
import 'package:gb_merchant/services/firebase_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseService.clearProcessedNotifications();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseService.init(navigatorKey);

  debugPrint = (String? message, {int? wrapWidth}) {
    print(message);
  };

  // Debug printer
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) print(message);
  };

  // Initialize device UUID early
  final deviceUuid = await DeviceUUID.getUUID();
  print('📱 MAIN: Device UUID initialized: $deviceUuid');

  // Check if app was opened from terminated state via notification
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await FirebaseService.incrementBadgeCount();

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
      startLocale: const Locale('km'), // force Khmer when app starts
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const MyApp({super.key, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Future<Map<String, dynamic>> _getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final phoneNumber = prefs.getString('phoneNumber') ?? '';
    print('DEBUG: isLoggedIn=$isLoggedIn, phoneNumber=$phoneNumber');
    return {'isLoggedIn': isLoggedIn, 'phoneNumber': phoneNumber};
  }

  bool _showStartScreen = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // First-time refresh when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseService.forceRefreshOnReopen();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called automatically when app state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back from background
      FirebaseService.forceRefreshOnReopen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,

      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // home:
      //     _showStartScreen
      //         ? StartScreen(
      //           onContinue: () {
      //             setState(() => _showStartScreen = false);
      //           },
      //         )
      //         : FutureBuilder<Map<String, dynamic>>(
      //           future: _getLoginState(),
      //           builder: (context, snapshot) {
      //             if (!snapshot.hasData) {
      //               return const Scaffold(
      //                 body: Center(child: CircularProgressIndicator()),
      //               );
      //             }
      //             final isLoggedIn = snapshot.data!['isLoggedIn'] as bool;

      //             // Use Firstscreen directly - it already has its own Scaffold
      //             return isLoggedIn ? RomlousApp() : Firstscreen();
      //           },
      //         ),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getLoginState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isLoggedIn = snapshot.data!['isLoggedIn'] as bool;

          if (!isLoggedIn) {
            // Brand new user: show signup/onboarding directly, never show StartScreen
            return Firstscreen();
          } else if (_showStartScreen) {
            // Returning user: show StartScreen only once after login/first open
            return StartScreen(
              onContinue: () {
                setState(() => _showStartScreen = false);
              },
            );
          } else {
            // Logged in user, main app
            return RomlousApp();
          }
        },
      ),
    );
  }
}
