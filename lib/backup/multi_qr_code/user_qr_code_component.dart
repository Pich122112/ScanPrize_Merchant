// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:scanprize_frontend/utils/constants.dart';
// import '../components/action_icon_button.dart';

// class UserQrCodeComponent extends StatefulWidget {
//   final String qrGanzbergPayload;
//   final String qrIdolPayload;
//   final String qrBoostrongPayload;
//   final String phoneNumber; // Add this

//   final int initialIndex;

//   const UserQrCodeComponent({
//     super.key,
//     required this.qrGanzbergPayload,
//     required this.qrIdolPayload,
//     required this.qrBoostrongPayload,
//     required this.phoneNumber, // Add this!
//     this.initialIndex = 0,
//   });

//   @override
//   State<UserQrCodeComponent> createState() => _UserQrCodeComponentState();
// }

// class _UserQrCodeComponentState extends State<UserQrCodeComponent> {
//   int selectedIndex = 0; // Default to Item Account

//   @override
//   void initState() {
//     super.initState();
//     selectedIndex = widget.initialIndex;
//   }

//   String formatPhoneNumber(String raw) {
//     String digits = raw.replaceAll(RegExp(r'\D'), '');

//     // Remove 855 country code if present at the start
//     if (digits.startsWith('855')) {
//       digits = digits.substring(3);
//     }
//     // Remove leading + if any (already handled by \D above)
//     // Add leading zero if not present
//     if (!digits.startsWith('0')) {
//       digits = '0$digits';
//     }
//     // Format 3-3-3 for Cambodian numbers
//     if (digits.length == 9) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     }
//     // fallback for other lengths
//     return digits;
//   }

//   String get currentPayload =>
//       selectedIndex == 0
//           ? widget.qrGanzbergPayload
//           : (selectedIndex == 1
//               ? widget.qrIdolPayload
//               : widget.qrBoostrongPayload);

//   String get userName {
//     try {
//       final parts = currentPayload.split('|');
//       if (parts.length >= 2) {
//         return parts[1]; // userId
//       }
//     } catch (_) {}
//     return '';
//   }

//   Widget _buildQrWithImage({
//     required String data,
//     required String imagePath,
//     required Color color,
//   }) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Container(
//           width: 200,
//           height: 200,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         QrImageView(
//           data: data,
//           size: 200,
//           version: QrVersions.auto,
//           backgroundColor: Colors.transparent,
//           gapless: false,
//         ),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(0.18),
//                 blurRadius: 2,
//                 spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: Image.asset(imagePath, width: 40, height: 40),
//         ),
//       ],
//     );
//   }

//   // Account labels, icons and image paths
//   static final buttons = [
//     _AccountButtonData(
//       'assets/images/ganzberg.png',
//       'Ganzberg',
//       AppColors.textColor,
//     ),
//     _AccountButtonData('assets/images/idol.png', 'Idol', Colors.black),
//     _AccountButtonData(
//       'assets/images/boostrong.png',
//       'Boostrong',
//       AppColors.textColor,
//     ),
//   ];

//   void _showAccountSelectSheet() async {
//     final int? selected = await showModalBottomSheet<int>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
//       ),
//       builder:
//           (context) => _AccountSelectionSheet(initialSelection: selectedIndex),
//     );
//     if (selected != null) {
//       setState(() {
//         selectedIndex = selected;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final qrImagePath = buttons[selectedIndex].imagePath;
//     final qrColor = buttons[selectedIndex].color;

//     return Scaffold(
//       backgroundColor: AppColors.primaryColor,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Image.asset('assets/images/logo.png', width: 55, height: 55),
//           ),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 20),
//               Text(
//                 formatPhoneNumber(widget.phoneNumber),
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 30,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 25),
//               const Text(
//                 "បង្ហាញ​ QR​ នេះដើម្បីទទួលពិន្ទុពីអ្នកដ៏ទៃ",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 60),
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: _buildQrWithImage(
//                   data: currentPayload,
//                   imagePath: qrImagePath,
//                   color: qrColor,
//                 ),
//               ),
//               const SizedBox(height: 70),
//               AccountSelectionButton(
//                 selectedIndex: selectedIndex,
//                 onSelect: (int newIndex) {
//                   setState(() {
//                     selectedIndex = newIndex;
//                   });
//                 },
//                 onShowSheet: _showAccountSelectSheet,
//               ),
//               const SizedBox(height: 35),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ActionIconButton(
//                     icon: Icons.download,
//                     label: ' ទាញយក',
//                     onPressed: () {},
//                   ),
//                   ActionIconButton(
//                     icon: Icons.qr_code,
//                     label: ' ផ្ញើរ QR',
//                     onPressed: () {},
//                   ),
//                   ActionIconButton(
//                     icon: Icons.link_outlined,
//                     label: 'ផ្ញើរលីង',
//                     onPressed: () {},
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class AccountSelectionButton extends StatelessWidget {
//   final int selectedIndex;
//   final Function(int) onSelect;
//   final VoidCallback onShowSheet;

//   const AccountSelectionButton({
//     super.key,
//     required this.selectedIndex,
//     required this.onSelect,
//     required this.onShowSheet,
//   });

//   // Use the same buttons list as above for consistency
//   static final buttons = UserQrCodeComponentStateButtons.buttons;

//   @override
//   Widget build(BuildContext context) {
//     final color = buttons[selectedIndex].color;
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//       ),
//       onPressed: onShowSheet,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const SizedBox(width: 8),
//           Text(
//             buttons[selectedIndex].label,
//             style: const TextStyle(
//               fontWeight: FontWeight.w500,
//               fontSize: 18,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(width: 10),
//           const Icon(Icons.arrow_drop_down, size: 30, color: Colors.white),
//         ],
//       ),
//     );
//   }
// }

// class _AccountSelectionSheet extends StatelessWidget {
//   final int initialSelection;
//   // ignore: unused_element_parameter
//   const _AccountSelectionSheet({super.key, required this.initialSelection});

//   // Use the same buttons list as above for consistency
//   static final buttons = UserQrCodeComponentStateButtons.buttons;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Text(
//             'ជ្រើសរើសគណនីទទួលរង្វាន់',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
//           ),
//           const SizedBox(height: 60),
//           ...List.generate(buttons.length, (index) {
//             final isSelected = index == initialSelection;
//             final btn = buttons[index];
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 18),
//               child: ElevatedButton.icon(
//                 label: Text(
//                   btn.label,
//                   style: TextStyle(
//                     color: isSelected ? Colors.white : btn.color,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 18,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isSelected ? btn.color : Colors.white,
//                   foregroundColor: isSelected ? Colors.white : btn.color,
//                   minimumSize: const Size.fromHeight(48),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     side: BorderSide(
//                       color: btn.color.withOpacity(0.3),
//                       width: isSelected ? 2 : 1,
//                     ),
//                   ),
//                   elevation: 0,
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 12,
//                     horizontal: 16,
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.pop(context, index);
//                 },
//               ),
//             );
//           }),
//           const SizedBox(height: 120),
//         ],
//       ),
//     );
//   }
// }

// // Move the buttons list to a shared location for consistency across classes
// class UserQrCodeComponentStateButtons {
//   static final buttons = [
//     _AccountButtonData(
//       'assets/images/ganzberg.png',
//       'Ganzberg',
//       AppColors.textColor,
//     ),
//     _AccountButtonData('assets/images/idol.png', 'Idol', Colors.black),
//     _AccountButtonData(
//       'assets/images/boostrong.png',
//       'Boostrong',
//       AppColors.textColor,
//     ),
//   ];
// }

// class _AccountButtonData {
//   final String imagePath;
//   final String label;
//   final Color color;
//   const _AccountButtonData(this.imagePath, this.label, this.color);
// }

// //Correct with 358 line code changes
