import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import '../components/action_icon_button.dart';
import 'package:flutter_dash/flutter_dash.dart';
import '../widgets/qr_capture_service.dart';

class UserQrCodeComponent extends StatelessWidget {
  final String qrPayload;
  final String phoneNumber;

  UserQrCodeComponent({
    super.key,
    required this.qrPayload,
    required this.phoneNumber,
  });

  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Remove 855 country code if present at the start
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    // Add leading zero if not present
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return digits;
  }

  final GlobalKey qrKey = GlobalKey();

  Widget _buildQrWithImage(BuildContext context) {
    // Calculate responsive sizes based on screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    // Responsive sizing calculations
    final containerWidth = screenWidth * (isPortrait ? 0.85 : 0.65);
    final qrSize =
        containerWidth * 0.6; // QR code will be 60% of container width
    final logoSize = qrSize * 0.15; // Logo size relative to QR code
    final padding = qrSize * 0.05; // Padding relative to QR code size
    final fontSizeTitle = qrSize * 0.09;
    final fontSizePhone = qrSize * 0.11;

    return RepaintBoundary(
      key: qrKey,
      child: Container(
        width: containerWidth,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: padding),
              decoration: const BoxDecoration(
                color: Color(0xFFE60000),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  "KHQR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizeTitle,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: padding),
            Text(
              formatPhoneNumber(phoneNumber),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSizePhone,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: padding),
            Dash(
              direction: Axis.horizontal,
              dashLength: 6,
              dashColor: Colors.white.withOpacity(0.5),
            ),
            SizedBox(height: padding),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: QrImageView(
                      data: qrPayload,
                      size: qrSize,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      gapless: false,
                    ),
                  ),
                  Container(
                    width: logoSize * 1.5,
                    height: logoSize * 1.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/gblogo.png',
                      width: logoSize,
                      height: logoSize,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', width: 55, height: 55),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatPhoneNumber(phoneNumber),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                "បង្ហាញ​ QR​ នេះដើម្បីទទួលពិន្ទុពីអ្នកដ៏ទៃ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _buildQrWithImage(context),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // In your ActionIconButton for download:
                  ActionIconButton(
                    icon: Icons.download,
                    label: 'ទាញយក',
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final messenger =
                          scaffoldMessenger..hideCurrentSnackBar();

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 10),
                              Text('Saving QR code...'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      try {
                        final path = await QrCaptureService.captureAndSaveQr(
                          qrKey,
                        );

                        messenger.hideCurrentSnackBar();

                        if (path != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: const Text(
                                'QR របស់អ្នកត្រូវបានរក្សាទុកក្នុងរូបថត!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                'Failed to save QR. Please grant storage permissions.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Error: ${e.toString()}'),
                          ),
                        );
                      }
                    },
                  ),
                  ActionIconButton(
                    icon: Icons.qr_code,
                    label: ' ផ្ញើរ QR',
                    onPressed: () {},
                  ),
                  ActionIconButton(
                    icon: Icons.link_outlined,
                    label: 'ផ្ញើរលីង',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 311 line code changes
