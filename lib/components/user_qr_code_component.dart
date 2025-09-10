// import 'dart:convert';

// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:gb_merchant/utils/constants.dart';
// import '../components/action_icon_button.dart';
// import 'package:flutter_dash/flutter_dash.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../widgets/qr_capture_service.dart';

// class UserQrCodeComponent extends StatelessWidget {
//   final String qrPayload;
//   final String phoneNumber;

//   UserQrCodeComponent({
//     super.key,
//     required this.qrPayload,
//     required this.phoneNumber,
//   });

//   String formatPhoneNumber(String raw) {
//     String digits = raw.replaceAll(RegExp(r'\D'), '');

//     // Remove 855 country code if present at the start
//     if (digits.startsWith('855')) {
//       digits = digits.substring(3);
//     }
//     // Add leading zero if not present
//     if (!digits.startsWith('0')) {
//       digits = '0$digits';
//     }

//     // Format with spaces for both 9 and 10 digit numbers
//     if (digits.length == 9) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     } else if (digits.length == 10) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     }

//     return digits;
//   }

//   // Add this method to get user name from SharedPreferences
//   Future<String?> _getUserName() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userDataString = prefs.getString('user_data');

//     if (userDataString != null) {
//       try {
//         final userData = json.decode(userDataString);
//         return userData['data']['name'] as String?;
//       } catch (e) {
//         print('Error parsing user name: $e');
//       }
//     }
//     return null;
//   }

//   final GlobalKey qrKey = GlobalKey();

//   Widget _buildQrWithImage(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isPortrait =
//         MediaQuery.of(context).orientation == Orientation.portrait;

//     final containerWidth = screenWidth * (isPortrait ? 0.85 : 0.60);
//     final qrSize = containerWidth * 0.65;
//     final logoSize = qrSize * 0.15;
//     final padding = qrSize * 0.05;
//     final fontSizeTitle = qrSize * 0.11;
//     final fontSizePhone = qrSize * 0.08;

//     return FutureBuilder<String?>(
//       future: _getUserName(),
//       builder: (context, snapshot) {
//         final userName = snapshot.data ?? 'UnknowName';

//         return RepaintBoundary(
//           key: qrKey,
//           child: Container(
//             width: containerWidth,
//             margin: EdgeInsets.symmetric(
//               horizontal: screenWidth * 0.05,
//               vertical: screenHeight * 0.02,
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Red KHQR header
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: 10),
//                   decoration: BoxDecoration(
//                     color: Color(0xFFFB0E0E),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(14),
//                       topRight: Radius.circular(14),
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       "KHQR",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: fontSizeTitle,
//                         letterSpacing: 1.2,
//                       ),
//                     ),
//                   ),
//                 ),
//                 // const SizedBox(height: 15),
//                 // Phone number area
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: padding),
//                   child: Column(
//                     children: [
//                       if (userName.isNotEmpty) ...[
//                         Text(
//                           userName,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 26,
//                             color: Colors.black54,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                       SizedBox(height: 6),

//                       Text(
//                         formatPhoneNumber(phoneNumber),
//                         style: TextStyle(
//                           fontWeight: FontWeight.w500,
//                           fontSize: fontSizePhone,
//                           color: Colors.black54,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 // Full-width dashed separator
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(horizontal: padding),
//                   child: LayoutBuilder(
//                     builder: (context, constraints) {
//                       return Dash(
//                         direction: Axis.horizontal,
//                         dashLength: 8,
//                         dashGap: 6,
//                         dashColor: Colors.grey,
//                         length: constraints.maxWidth,
//                       );
//                     },
//                   ),
//                 ),

//                 SizedBox(height: 33),

//                 // QR with logo
//                 Container(
//                   padding: EdgeInsets.all(padding),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(
//                       width: 1,
//                       color: const Color.fromARGB(108, 158, 158, 158),
//                     ),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: QrImageView(
//                           data: qrPayload,
//                           size: qrSize,
//                           version: QrVersions.auto,
//                           backgroundColor: Colors.white,
//                           gapless: false,
//                         ),
//                       ),
//                       Container(
//                         width: logoSize * 1.5,
//                         height: logoSize * 1.5,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 3,
//                               spreadRadius: 1,
//                             ),
//                           ],
//                         ),
//                         child: Image.asset(
//                           'assets/images/gblogo.png',
//                           width: logoSize,
//                           height: logoSize,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 SizedBox(height: 35),
//               ],
//             ),
//           ),
//         );

//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localeCode = context.locale.languageCode; // 'km' or 'en'

//     return Scaffold(
//       backgroundColor: AppColors.primaryColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Image.asset('assets/images/logo.png', width: 55, height: 55),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Text(
//                 //   formatPhoneNumber(phoneNumber),
//                 //   style: const TextStyle(
//                 //     fontWeight: FontWeight.bold,
//                 //     fontSize: 30,
//                 //     color: Colors.white,
//                 //   ),
//                 // ),
//                 Text(
//                   'Ganzberg QR'.toUpperCase(),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 30,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 14),
//                 Text(
//                   'showyourqr'.tr(),
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: Colors.white,
//                     fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 _buildQrWithImage(context),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // In your ActionIconButton for download:
//                     ActionIconButton(
//                       icon: Icons.download,
//                       label: 'download',
//                       onPressed: () async {
//                         final scaffoldMessenger = ScaffoldMessenger.of(context);
//                         final messenger =
//                             scaffoldMessenger..hideCurrentSnackBar();

//                         messenger.showSnackBar(
//                           const SnackBar(
//                             content: Row(
//                               children: [
//                                 CircularProgressIndicator(),
//                                 SizedBox(width: 10),
//                                 Text('Saving QR code...'),
//                               ],
//                             ),
//                             duration: const Duration(seconds: 2),
//                           ),
//                         );

//                         try {
//                           final path = await QrCaptureService.captureAndSaveQr(
//                             qrKey,
//                           );

//                           messenger.hideCurrentSnackBar();

//                           if (path != null) {
//                             messenger.showSnackBar(
//                               SnackBar(
//                                 backgroundColor: Colors.green,
//                                 content: const Text(
//                                   'QR របស់អ្នកត្រូវបានរក្សាទុកក្នុងរូបថត!',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 16,
//                                     fontFamily: 'KhmerFont',
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             );
//                           } else {
//                             messenger.showSnackBar(
//                               const SnackBar(
//                                 backgroundColor: Colors.red,
//                                 content: Text(
//                                   'Failed to save QR. Please grant storage permissions.',
//                                 ),
//                               ),
//                             );
//                           }
//                         } catch (e) {
//                           messenger.hideCurrentSnackBar();
//                           messenger.showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               content: Text('Error: ${e.toString()}'),
//                             ),
//                           );
//                         }
//                       },
//                     ),
//                     const SizedBox(width: 40),
//                     ActionIconButton(
//                       icon: Icons.qr_code,
//                       label: 'shareqr',
//                       onPressed: () {},
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// //Correct with 367 line code changes

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../components/action_icon_button.dart';
import 'package:flutter_dash/flutter_dash.dart';
import '../widgets/qr_capture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Format with spaces for both 9 and 10 digit numbers
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }

    return digits;
  }

  // Add this method to get user name from SharedPreferences
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

  final GlobalKey qrKey = GlobalKey();

  Widget _buildQrWithImage(BuildContext context) {
    // ✅ fixed sizes (you can adjust as needed)
    final double containerWidth = 280;
    final double qrSize = 200;
    final double logoSize = 30;
    final double padding = 16;
    final double fontSizeTitle = 24;
    final double fontSizePhone = 14;
    return FutureBuilder<String?>(
      future: _getUserName(),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'UnknowName';

        return RepaintBoundary(
          key: qrKey,
          child: Container(
            width: containerWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red KHQR header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Color(0xFFFB0E0E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
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
                          fontFamily: 'KhmerFont',
                        ),
                      ),
                    ),
                  ),
                  // Phone number area
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: padding),
                    child: Column(
                      children: [
                        if (userName.isNotEmpty) ...[
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.black54,
                              fontFamily: 'KhmerFont',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: 6),

                        Text(
                          formatPhoneNumber(phoneNumber),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSizePhone,
                            color: Colors.black54,
                            fontFamily: 'KhmerFont',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  // Full-width dashed separator
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Dash(
                          direction: Axis.horizontal,
                          dashLength: 8,
                          dashGap: 6,
                          dashColor: Colors.grey,
                          length: constraints.maxWidth,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  // QR with logo
                  Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: Colors.white,
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

                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

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
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text(
                //   formatPhoneNumber(phoneNumber),
                //   style: const TextStyle(
                //     fontWeight: FontWeight.bold,
                //     fontSize: 30,
                //     color: Colors.white,
                //   ),
                // ),
                const SizedBox(height: 30),
                Text(
                  'Ganzberg QR'.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.white,
                    fontFamily: 'KhmerFont',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'showyourqr'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  ),
                ),
                const SizedBox(height: 30),
                _buildQrWithImage(context),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // In your ActionIconButton for download:
                    ActionIconButton(
                      icon: Icons.download,
                      label: 'download',
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
                                Text(
                                  'Saving QR code...',
                                  style: TextStyle(
                                    fontFamily: 'KhmerFont',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                                    fontFamily: 'KhmerFont',
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
                                  style: TextStyle(
                                    fontFamily: 'KhmerFont',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                'Error: ${e.toString()}',
                                style: TextStyle(
                                  fontFamily: 'KhmerFont',
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 40),
                    ActionIconButton(
                      icon: Icons.qr_code,
                      label: 'shareqr',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Correct with 753 line code changes
