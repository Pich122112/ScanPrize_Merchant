import 'dart:convert';

import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_storage_service.dart'; // Add this import

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Method to get user name from SecureStorageService
  Future<String?> _getUserName() async {
    final secureStorage = SecureStorageService();

    // Try to get user name from secure storage first
    final userName = await secureStorage.getUserName();

    if (userName != null && userName.isNotEmpty) {
      return userName;
    }

    // Fallback: try to get from SharedPreferences if not in secure storage
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        final name = userData['data']['name'] as String?;

        // If found in SharedPreferences, save it to secure storage for next time
        if (name != null && name.isNotEmpty) {
          await secureStorage.setUserName(name);
        }

        return name;
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
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
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.primaryColor,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 20),

                // Title with dynamic user name
                FutureBuilder<String?>(
                  future: _getUserName(),
                  builder: (context, snapshot) {
                    String userName = 'ជូនចំពោះអ្នក';

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      userName = 'កំពុងផ្ទុក...';
                    } else if (snapshot.hasError) {
                      userName = 'ជូនចំពោះអ្នក';
                    } else if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.isNotEmpty) {
                      userName = snapshot.data!;
                    }

                    return Column(
                      children: [
                        Text(
                          "សូមស្វាគមន៍",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'KhmerFont',
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          userName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'KhmerFont',
                            height: 1.4,
                          ),
                        ),
                      ],
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
                    fontWeight: FontWeight.w900,
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
