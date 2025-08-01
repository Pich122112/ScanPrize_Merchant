import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanprize_frontend/authentication/signIn.dart';
import '../app/bottomAppbar.dart';

void main() {
  // Enable debug printing
  debugPrint = (String? message, {int? wrapWidth}) {
    print(message);
  };

  runApp(const MyApp());
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
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getLoginState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isLoggedIn = snapshot.data!['isLoggedIn'] as bool;
          final phoneNumber = snapshot.data!['phoneNumber'] as String;
          return isLoggedIn
              ? RomlousApp(phoneNumber: phoneNumber)
              : LoginPage();
        },
      ),
    );
  }
}

//Correct with 44 line code changes
