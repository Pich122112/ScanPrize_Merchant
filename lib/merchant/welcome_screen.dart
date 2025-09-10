import 'dart:convert';

import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your home screen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Method to get user name from SharedPreferences
  Future<String?> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        return userData['data']['name'] as String?;
      } catch (e) {
        print('Error parsing user name: $e');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 106, 0),
              Color.fromARGB(255, 186, 81, 1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(),

                // Checkmark icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFFF6F00),
                    size: 80,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                // Title with dynamic user name
                FutureBuilder<String?>(
                  future: _getUserName(),
                  builder: (context, snapshot) {
                    final userName = snapshot.data ?? 'UnknowUser';
                    return Text(
                      "សូមស្វាគមន៍ $userName",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'KhmerFont',
                        height: 1.4,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Description
                const Text(
                  "អ្នកបានចូលជោគជ័យក្នុងប្រព័ន្ធ។\nសូមរីករាយជាមួយបទពិសោធន៍ថ្មីរបស់អ្នក។",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                    fontFamily: 'KhmerFont',
                  ),
                ),

                const Spacer(),

                // Bottom Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      // Navigate to home screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => RomlousApp()),
                      );
                    },
                    child: const Text(
                      "ចាប់ផ្តើមប្រើប្រាស់",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'KhmerFont',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
