// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:http/http.dart' as http;
// import 'package:gb_merchant/components/user_qr_code_component.dart';
// import 'package:gb_merchant/main/TransactionPage.dart';
// import 'package:gb_merchant/services/scanqr_prize.dart';
// import 'package:gb_merchant/utils/constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
//   final VoidCallback? onMenuPressed;
//   final String phoneNumber;

//   const CustomAppBar({
//     super.key,
//     this.onMenuPressed,
//     required this.phoneNumber,
//   });

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
//   @override
//   Size get preferredSize => const Size.fromHeight(70.0);
// }

// class _CustomAppBarState extends State<CustomAppBar> {
//   String formatPhoneNumber(String raw) {
//     String digits = raw.replaceAll(RegExp(r'\D'), '');
//     if (digits.startsWith('855')) {
//       digits = digits.substring(3);
//     }
//     if (!digits.startsWith('0')) {
//       digits = '0$digits';
//     }

//     if (digits.length == 9) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     } else if (digits.length == 10) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     }

//     return digits;
//   }

//   Future<void> _showQrCode(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final qrPayload = prefs.getString('qrPayload');
//     final phoneNumber = prefs.getString('phoneNumber');

//     // Try to use cached QR first
//     if (qrPayload != null && phoneNumber != null) {
//       _showQrDialog(context, qrPayload, phoneNumber);
//       return;
//     }

//     // Fetch from backend if not cached
//     if (phoneNumber != null && phoneNumber.isNotEmpty) {
//       try {
//         final response = await http.get(
//           Uri.parse('${Constants.apiUrl}/auth/me/qr?phoneNumber=$phoneNumber'),
//           headers: {'Content-Type': 'application/json'},
//         );

//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           await prefs.setString('qrPayload', data['qrPayload']);
//           _showQrDialog(context, data['qrPayload'], phoneNumber);
//         } else {
//           throw Exception('Failed to fetch QR code: ${response.statusCode}');
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch QR code: ${e.toString()}')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Please login again')));
//     }
//   }

//   void _showQrDialog(
//     BuildContext context,
//     String qrPayload,
//     String phoneNumber,
//   ) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         fullscreenDialog: true,
//         builder:
//             (context) => Scaffold(
//               backgroundColor: AppColors.primaryColor,
//               body: SafeArea(
//                 child: UserQrCodeComponent(
//                   qrPayload: qrPayload,
//                   phoneNumber: phoneNumber,
//                 ),
//               ),
//             ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localeCode = context.locale.languageCode; // 'km' or 'en'
//     return Padding(
//       padding: const EdgeInsets.only(),
//       child: AppBar(
//         backgroundColor: AppColors.primaryColor,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: Row(
//           children: [
//             GestureDetector(
//               onTap: widget.onMenuPressed,
//               child: const CircleAvatar(
//                 backgroundColor: AppColors.primaryColor,
//                 radius: 33,
//                 backgroundImage: AssetImage('assets/images/logo.png'),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'welcome'.tr(),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   formatPhoneNumber(widget.phoneNumber),
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           buildNotificationButton(context, 4),
//           IconButton(
//             icon: const Icon(Icons.qr_code, color: Colors.white),
//             onPressed: () => _showQrCode(context),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildNotificationButton(BuildContext context, int badgeCount) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         IconButton(
//           icon: const Icon(Icons.notifications, color: Colors.white),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => Transactionpage()),
//             );
//           },
//         ),
//         if (badgeCount > 0)
//           Positioned(
//             right: 4,
//             top: 4,
//             child: Container(
//               padding: const EdgeInsets.all(2),
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               constraints: const BoxConstraints(minWidth: 20, minHeight: 16),
//               child: Text(
//                 '$badgeCount',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// //Correct with 201 line code changes

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gb_merchant/services/firebase_service.dart';
import 'package:http/http.dart' as http;
import 'package:gb_merchant/components/user_qr_code_component.dart';
import 'package:gb_merchant/main/TransactionPage.dart';
import 'package:gb_merchant/services/scanqr_prize.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final String phoneNumber;

  const CustomAppBar({
    super.key,
    this.onMenuPressed,
    required this.phoneNumber,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late ValueNotifier<int> _badgeNotifier;

  @override
  void initState() {
    super.initState();

    _badgeNotifier = FirebaseService.badgeCountNotifier;

    // Load saved value once at startup
    SharedPreferences.getInstance().then((prefs) {
      int savedCount = prefs.getInt('badgeCount') ?? 0;
      _badgeNotifier.value = savedCount;
    });
  }

  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }

    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }

    return digits;
  }

  // In CustomAppBar class, modify the _showQrCode method:
  // In CustomAppBar class, modify the _showQrCode method:
  Future<void> _showQrCode(BuildContext context) async {
    print('DEBUG: _showQrCode called');

    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    print('DEBUG: userDataString from prefs: $userDataString');

    int userStatus = 1; // Default to approved

    // First try to get status from SharedPreferences
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        userStatus = userData['data']['status'] ?? 1;
        print('DEBUG: User status from prefs: $userStatus');
      } catch (e) {
        print('DEBUG: Error parsing user data from prefs: $e');
        // If parsing fails, proceed normally instead of blocking
        userStatus = 1;
      }
    }

    // Check the status - status 2 means pending approval
    if (userStatus == 2) {
      print('DEBUG: Showing approval dialog (status 2)');
      _showApprovalRequiredDialog(context);
      return;
    } else {
      print(
        'DEBUG: User approved (status $userStatus), proceeding with QR code',
      );
    }

    // Rest of your QR code logic...
    final qrPayload = prefs.getString('qrPayload');
    final phoneNumber = prefs.getString('phoneNumber');

    // Try to use cached QR first
    if (qrPayload != null && phoneNumber != null) {
      _showQrDialog(context, qrPayload, phoneNumber);
      return;
    }

    // Fetch from backend if not cached
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('${Constants.apiUrl}/auth/me/qr?phoneNumber=$phoneNumber'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await prefs.setString('qrPayload', data['qrPayload']);
          _showQrDialog(context, data['qrPayload'], phoneNumber);
        } else {
          throw Exception('Failed to fetch QR code: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch QR code: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please login again')));
    }
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

  // Add this method to show approval dialog
  void _showApprovalRequiredDialog(BuildContext context) {
    final localeCode = context.locale.languageCode;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 60, color: Colors.orange),
                  const SizedBox(height: 20),
                  Text(
                    'សូមអភ័យទោស អ្នកមិនអាចដំណើរការមុខងារនេះបានទេ!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'សូមរង់ចាំការអនុញ្ញាតពីក្រុមហ៊ុនជាមុនសិន',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'យល់ព្រម',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showQrDialog(
    BuildContext context,
    String qrPayload,
    String phoneNumber,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => Scaffold(
              backgroundColor: AppColors.primaryColor,
              body: SafeArea(
                child: UserQrCodeComponent(
                  qrPayload: qrPayload,
                  phoneNumber: phoneNumber,
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'
    return Padding(
      padding: const EdgeInsets.only(),
      child: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: FutureBuilder<String?>(
          future: _getUserName(),
          builder: (context, snapshot) {
            final userName = snapshot.data ?? 'UnknowName';
            final formattedPhone = formatPhoneNumber(widget.phoneNumber);

            return Row(
              children: [
                GestureDetector(
                  onTap: widget.onMenuPressed,
                  child: const CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    radius: 33,
                    backgroundImage: AssetImage('assets/images/logo.png'),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username on first line
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Phone number on second line
                    Text(
                      formattedPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _badgeNotifier,
            builder: (context, badgeCount, _) {
              return buildNotificationButton(context, badgeCount);
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            onPressed: () => _showQrCode(context),
          ),
        ],
      ),
    );
  }

  Widget buildNotificationButton(BuildContext context, int badgeCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () async {
            // Reset badge count when user views notifications
            await FirebaseService.resetBadgeCount();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          },
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 16),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'KhmerFont',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

//Correct with 564 line code changes
