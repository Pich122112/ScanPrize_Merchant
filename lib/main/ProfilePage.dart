import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/providers/theme_provider.dart';
import 'package:gb_merchant/widgets/call_animation.dart';
import 'package:provider/provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.primaryColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedCallIcon(isTablet: true),
              const SizedBox(height: 24),
              // Title
              Text(
                "contact_us".tr(),
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
              const SizedBox(height: 24),

              // Subtitle
              Text(
                "contact_platform".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 16,
                  color: Colors.white,
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
                  ),
                  label: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Facebook Messenger",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    shadowColor: Colors.white.withOpacity(0.4),
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

//Correct with 112 line code changes
