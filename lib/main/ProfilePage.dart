import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Future<void> _openMessenger() async {
    const messengerUrl = "https://m.me/moeys.gov.kh"; // official Messenger link
    final uri = Uri.parse(messengerUrl);

    if (await canLaunchUrl(uri)) {
      // Try opening Messenger app
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: open in browser
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } else {
      // Last fallback: force open in browser
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final localeCode = context.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circle with soft shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Icon(
                  Icons.call,
                  size: isTablet ? 60 : 50,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                "contact_us".tr(),
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                "contact_platform".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                  height: 1.5,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
              const SizedBox(height: 80),

              // Messenger Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openMessenger, // ✅ Open Messenger
                  icon: Image.asset(
                    "assets/images/messengerlogo.png",
                    height: 28,
                    width: 28,
                    color: Colors.white,
                  ),
                  label: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Facebook Messenger",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    shadowColor: Colors.deepOrange.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 127 line code changes
