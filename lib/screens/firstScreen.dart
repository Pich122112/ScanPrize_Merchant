import 'package:gb_merchant/authentication/signIn.dart';
import 'package:gb_merchant/merchant/privacypolicy.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:flutter/material.dart';

class Firstscreen extends StatelessWidget {
  const Firstscreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(251, 96, 0, 1),
              Color.fromRGBO(250, 99, 5, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),

              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: screenHeight * 0.18,
              ),
              const SizedBox(height: 24),

              // Titles
              Text(
                'GANZBERG MERCHANT',
                style: TextStyle(
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'សូមស្វាគមន៍',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  color: Colors.white,
                  fontFamily: 'KhmerFont',
                ),
              ),

              const Spacer(),

              // First Button
              _buildCustomButton(
                icon: Icons.person_outline,
                text: 'បង្កើតគណនី',
                subtext: 'សម្រាប់អ្នកដែលមិនទាន់មានគណនី',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Agreement()),
                  );
                },
                screenWidth: screenWidth,
              ),

              const SizedBox(height: 20),

              // Divider with "ឬ" - FIXED THIS PART
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.25,
                      height: 1,
                      color: Colors.white,
                      margin: const EdgeInsets.only(left: 8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ឬ',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'KhmerFont',
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.25,
                      height: 1,
                      color: Colors.white,
                      margin: const EdgeInsets.only(left: 8),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Second Button
              _buildCustomButton(
                icon: Icons.login,
                text: 'ចូលទៅកាន់គណនី',
                subtext: 'សម្រាប់អ្នកដែលមានគណនីរួចរាល់',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                },
                screenWidth: screenWidth,
              ),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required String text,
    required String subtext,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: screenWidth * 0.08,
                  color: AppColors.textColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'KhmerFont',
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtext,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black87,
                          fontFamily: 'KhmerFont',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.045,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Correct with 202 line code changes
