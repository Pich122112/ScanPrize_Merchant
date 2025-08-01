// import 'package:flutter/material.dart';
// import 'package:scanprize_frontend/utils/constants.dart';

// class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
//   final VoidCallback? onMenuPressed;
//   final String userName;

//   const CustomAppBar({super.key, this.onMenuPressed, required this.userName});

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
//   @override
//   Size get preferredSize => const Size.fromHeight(70.0);
// }

// class _CustomAppBarState extends State<CustomAppBar> {
//   String currentLanguageCode = 'km';

//   // Future<void> _showQrCode(BuildContext context) async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   String? qrGanzbergPayload = prefs.getString('qrGanzbergPayload');
//   //   String? qrIdolPayload = prefs.getString('qrIdolPayload');
//   //   String? qrBoostrongPayload = prefs.getString('qrBoostrongPayload');
//   //   final phoneNumber = prefs.getString('phoneNumber');

//   //   // Try to fetch from local storage first
//   //   if ((qrGanzbergPayload != null && qrGanzbergPayload.isNotEmpty) &&
//   //       (qrIdolPayload != null && qrIdolPayload.isNotEmpty)) {
//   //     // Show QR from local storage (always available)
//   //     showDialog(
//   //       context: context,
//   //       builder:
//   //           (context) => UserQrCodeComponent(
//   //             qrGanzbergPayload: qrGanzbergPayload ?? '',
//   //             qrIdolPayload: qrIdolPayload ?? '',
//   //             qrBoostrongPayload: qrBoostrongPayload ?? '',
//   //             userName: widget.userName, // Pass the userName from CustomAppBar
//   //             initialIndex: 0,
//   //           ),
//   //     );
//   //     return;
//   //   }

//   //   // If either payload is missing, try to fetch from backend
//   //   if (phoneNumber != null && phoneNumber.isNotEmpty) {
//   //     try {
//   //       // Fetch item QR
//   //       final ganzbergResponse = await http.get(
//   //         Uri.parse(
//   //           'http://172.17.5.242:8080/api/auth/me/qr?phoneNumber=$phoneNumber&type=ganzberg',
//   //         ),
//   //         headers: {'Content-Type': 'application/json'},
//   //       );
//   //       // Fetch money QR
//   //       final idolResponse = await http.get(
//   //         Uri.parse(
//   //           'http://172.17.5.242:8080/api/auth/me/qr?phoneNumber=$phoneNumber&type=idol',
//   //         ),
//   //         headers: {'Content-Type': 'application/json'},
//   //       );
//   //       // fetch for big prize
//   //       final boostrongResponse = await http.get(
//   //         Uri.parse(
//   //           'http://172.17.5.242:8080/api/auth/me/qr?phoneNumber=$phoneNumber&type=boostrong',
//   //         ),
//   //         headers: {'Content-Type': 'application/json'},
//   //       );

//   //       if (ganzbergResponse.statusCode == 200 &&
//   //           idolResponse.statusCode == 200 &&
//   //           boostrongResponse.statusCode == 200) {
//   //         final ganzbergData = json.decode(ganzbergResponse.body);
//   //         final idolData = json.decode(idolResponse.body);
//   //         final boostrongData = json.decode(boostrongResponse.body);

//   //         qrGanzbergPayload = ganzbergData['qrPayload'];
//   //         qrIdolPayload = idolData['qrPayload'];
//   //         qrBoostrongPayload = boostrongData['qrPayload'];
//   //         if (qrGanzbergPayload != null && qrIdolPayload != null) {
//   //           await prefs.setString('qrGanzbergPayload', qrGanzbergPayload);
//   //           await prefs.setString('qrIdolPayload', qrIdolPayload);
//   //           await prefs.setString('qrBoostrongPayload', qrBoostrongPayload!);

//   //           showDialog(
//   //             context: context,
//   //             builder:
//   //                 (context) => UserQrCodeComponent(
//   //                   qrGanzbergPayload: qrGanzbergPayload!,
//   //                   qrIdolPayload: qrIdolPayload!,
//   //                   qrBoostrongPayload: qrBoostrongPayload!,
//   //                   userName: widget.userName,
//   //                   initialIndex: 0,
//   //                 ),
//   //           );
//   //           return;
//   //         } else {
//   //           throw Exception('QR payload is null');
//   //         }
//   //       } else {
//   //         throw Exception(
//   //           'Failed with status ${ganzbergResponse.statusCode}, ${idolResponse.statusCode}',
//   //         );
//   //       }
//   //     } catch (e) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(content: Text('Failed to fetch QR code: ${e.toString()}')),
//   //       );
//   //       return;
//   //     }
//   //   } else {
//   //     ScaffoldMessenger.of(
//   //       context,
//   //     ).showSnackBar(SnackBar(content: Text('Please login again')));
//   //     return;
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
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
//             const SizedBox(width: 2),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "សូមស្វាគមន័ 👋",
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),

//                 // Text(
//                 //   widget.userName,
//                 //   style: TextStyle(
//                 //     fontSize: 18,
//                 //     color: Colors.white,
//                 //     fontWeight: FontWeight.w500,
//                 //   ),
//                 // ),
//                 Text(
//                   '092787171',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           // Language Selection
//           TextButton.icon(
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//             ),
//             icon: Text(
//               currentLanguageCode == 'km'
//                   ? '🇰🇭'
//                   : currentLanguageCode == 'en'
//                   ? '🇺🇸'
//                   : '🇨🇳', // Add more flags if you have more languages
//               style: const TextStyle(fontSize: 20),
//             ),
//             label: Row(
//               children: [
//                 Text(
//                   currentLanguageCode == 'km'
//                       ? 'ខ្មែរ'
//                       : currentLanguageCode == 'en'
//                       ? 'អង់គ្លេស'
//                       : '中文',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 const SizedBox(width: 4),
//                 const Icon(Icons.keyboard_arrow_down, color: Colors.white),
//               ],
//             ),
//             onPressed: () async {
//               final selected = await showModalBottomSheet<String>(
//                 backgroundColor: Colors.white,
//                 context: context,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//                 ),
//                 builder: (context) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const SizedBox(height: 10),
//                       ListTile(
//                         leading: const Text(
//                           '🇰🇭',
//                           style: TextStyle(fontSize: 20),
//                         ),
//                         title: const Text('ភាសាខ្មែរ'),
//                         onTap: () => Navigator.pop(context, 'km'),
//                       ),
//                       ListTile(
//                         leading: const Text(
//                           '🇺🇸',
//                           style: TextStyle(fontSize: 20),
//                         ),
//                         title: const Text('អង់គ្លេស'),
//                         onTap: () => Navigator.pop(context, 'en'),
//                       ),
//                       const SizedBox(height: 40),
//                     ],
//                   );
//                 },
//               );

//               if (selected != null && selected != currentLanguageCode) {
//                 setState(() {
//                   currentLanguageCode = selected;
//                 });
//               }
//             },
//           ),
//           // IconButton(
//           //   padding: EdgeInsets.zero,
//           //   icon: Icon(Icons.qr_code, color: Colors.white),
//           //   onPressed: () => _showQrCode(context),
//           // ),
//           // IconButton(
//           //   padding: EdgeInsets.zero,
//           //   icon: Icon(Icons.notifications_outlined, color: Colors.white),
//           //   onPressed: () {},
//           // ),
//         ],
//       ),
//     );
//   }
// }

// //Correct with 232 line code changes

import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final String
  phoneNumber; // Accepts anything: "099929292", "+85599929292", "99929292"

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
  String currentLanguageCode = 'km';

  /// Always show phone as local (0xx xxx xxx).
  /// If phoneNumber contains "855" or "+855", strip it and add leading 0.
  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Remove 855 country code if present at the start
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    // Remove leading + if any (already handled by \D above)
    // Add leading zero if not present
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    // Format 3-3-3 for Cambodian numbers
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    // fallback for other lengths
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(),
      child: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: widget.onMenuPressed,
              child: const CircleAvatar(
                backgroundColor: AppColors.primaryColor,
                radius: 33,
                backgroundImage: AssetImage('assets/images/logo.png'),
              ),
            ),
            const SizedBox(width: 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "សូមស្វាគមន៍ 👋",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPhoneNumber(widget.phoneNumber),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: Text(
              currentLanguageCode == 'km'
                  ? '🇰🇭'
                  : currentLanguageCode == 'en'
                  ? '🇺🇸'
                  : '🇨🇳',
              style: const TextStyle(fontSize: 20),
            ),
            label: Row(
              children: [
                Text(
                  currentLanguageCode == 'km'
                      ? 'KH'
                      : currentLanguageCode == 'en'
                      ? 'English'
                      : '中文',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
            onPressed: () async {
              final selected = await showModalBottomSheet<String>(
                backgroundColor: Colors.white,
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Text(
                          '🇰🇭',
                          style: TextStyle(fontSize: 20),
                        ),
                        title: const Text('Khmer'),
                        onTap: () => Navigator.pop(context, 'km'),
                      ),
                      ListTile(
                        leading: const Text(
                          '🇺🇸',
                          style: TextStyle(fontSize: 20),
                        ),
                        title: const Text('English'),
                        onTap: () => Navigator.pop(context, 'en'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              );

              if (selected != null && selected != currentLanguageCode) {
                setState(() {
                  currentLanguageCode = selected;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

//Correct with 164 line code changes
