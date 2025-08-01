import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Privacy & Policy',
          style: TextStyle(
            fontFamily: 'KhmerFont', // Use your desired font here
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card-like container for content
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _sectionTitle('1. Data We Collect'),
                    _sectionContent(
                      'When you use our company\'s app to scan QR codes to receive rewards, points, or cash, we only collect your phone number for registration purposes. We do not collect any other personal information.',
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('2. Purpose of Data Use'),
                    _sectionContent(
                      'We use your phone number for:\n'
                      '- Registration and user identification\n'
                      '- Providing services and distributing rewards, points, or cash\n'
                      '- Sending notifications or confirming activities in the app\n'
                      '- Improving system performance and enhancing your user experience',
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('3. Data Protection and Storage'),
                    _sectionContent(
                      'We take the security of your data very seriously. Your information is stored in a secure system and can only be accessed by authorized team members.',
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('4. Data Sharing'),
                    _sectionContent(
                      'We do not share or sell your information to any third parties, except as required by law or by requests from authorities.',
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('5. User Rights'),
                    _sectionContent(
                      'You may request to modify or delete your phone number from our system by contacting our support team.',
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle('6. Changes to This Policy'),
                    _sectionContent(
                      'We may update this policy at any time. We will notify you of any changes through the app. Continuing to use the app means you accept the new policy.',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.privacy_tip,
                          color: theme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "We respect your rights and privacy.",
                          style: TextStyle(
                            fontFamily: 'KhmerFont',
                            fontSize: 15,
                            color: theme.primaryColorDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'KhmerFont',
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xff2063d1),
      ),
    ),
  );

  Widget _sectionContent(String text) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'KhmerFont',
        fontSize: 15,
        color: Color(0xff3b3b3b),
        height: 1.5,
      ),
    ),
  );
}