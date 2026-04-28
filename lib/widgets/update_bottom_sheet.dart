import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/version_service.dart';

class UpdateBottomSheet extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final bool isForceUpdate;
  final VoidCallback? onSkip;

  const UpdateBottomSheet({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    this.isForceUpdate = false,
    this.onSkip,
  });

  // ✅ Detect store name dynamically
  String getStoreName(bool isKm) {
    if (Platform.isIOS) {
      return "App Store";
    } else {
      return "Play Store";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKm = context.locale.languageCode == 'km';
    final storeName = getStoreName(isKm);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      isKm ? "អាចធ្វើបច្ចុប្បន្នភាព" : "Update Available",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    isKm
                        ? "ដំណើរការកម្មវិធីជំនាន់ថ្មី\nសូមធ្វើបច្ចុប្បន្នភាពជំនាន់ $latestVersion នៅ $storeName។"
                        : "A new version ($latestVersion) is available on $storeName.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // App Info Row
                  Row(
                    children: [
                      // App icon with shadow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            "assets/images/logo.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // App name + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKm ? "ហ្គ្រេនប៊ឺក អេប" : "GANZBERG APP",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Ganzberg German Premium Beer",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Buttons row
                  Row(
                    children: [
                      // Later button
                      if (!isForceUpdate)
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                onSkip ?? () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 3,
                              shadowColor:
                                  Colors.black.withOpacity(0.15),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isKm ? "ចាំពេលក្រោយ" : "Later",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      if (!isForceUpdate) const SizedBox(width: 12),

                      // Update button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _launchStore(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isKm
                                ? "ធ្វើបច្ចុប្បន្នភាព"
                                : "Update on $storeName",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchStore(BuildContext context) async {
    final url = Uri.parse(
      Platform.isIOS
          ? VersionService.iOSStoreUrl
          : VersionService.androidStoreUrl,
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUrl = Uri.parse(
          "https://apps.apple.com/app/idYOUR_APP_ID",
        );
        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl);
        }
      }
    } catch (e) {
      debugPrint("Error launching store: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot open store. Please update manually."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}