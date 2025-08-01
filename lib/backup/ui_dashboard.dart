// import 'package:flutter/material.dart';
// import 'package:percent_indicator/percent_indicator.dart';
// import 'package:scanprize_frontend/utils/constants.dart';
// import '../components/transfer_prize_qr.dart';

// class ThreeBoxSection extends StatelessWidget {
//   const ThreeBoxSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Top box using the requested UI
//         Container(
//           margin: const EdgeInsets.only(left: 16, right: 16),
//           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//           decoration: BoxDecoration(
//             color: AppColors.primaryColor, // dark navy blue
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Row(
//             children: [
//               // Left Circular Wallet Icon
//               CircularPercentIndicator(
//                 radius: 50.0,
//                 lineWidth: 8.0,
//                 percent: 0.85,
//                 circularStrokeCap: CircularStrokeCap.round,
//                 backgroundColor: Colors.blue.shade900,
//                 progressColor: Colors.amber,
//                 center: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     Icon(
//                       Icons.account_balance_wallet_rounded,
//                       size: 30,
//                       color: Colors.amber,
//                     ),
//                     SizedBox(height: 5),
//                     Text(
//                       "គណនី",
//                       style: TextStyle(color: Colors.white, fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 20),
//               // Right Side with Balance
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Top row: label + eye icon
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         const Text(
//                           "សមតុល្យសរុប",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Color(0xFF1565C0),
//                           ),
//                           padding: const EdgeInsets.all(6),
//                           child: const Icon(
//                             Icons.remove_red_eye,
//                             size: 18,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     // Amount in Riel
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: const [
//                         Text(
//                           "352,042",
//                           style: TextStyle(
//                             fontSize: 22,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(width: 6),
//                         Text(
//                           "៛",
//                           style: TextStyle(
//                             color: Colors.amber,
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     // Amount in Dollar
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: const [
//                         Text(
//                           "1,020.50",
//                           style: TextStyle(
//                             fontSize: 22,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(width: 6),
//                         Text(
//                           "\$",
//                           style: TextStyle(
//                             color: Colors.lightBlueAccent,
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Two bottom buttons
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             InkWell(
//               onTap: () {
//                 showDialog(
//                   context: context,
//                   barrierColor: Colors.black87,
//                   builder: (context) => const TransferPrizeScan(),
//                 );
//               },
//               child: _buildActionButton(
//                 Icons.arrow_circle_up_sharp,
//                 "ផ្ញើររង្វាន់ចេញ",
//                 Colors.red,
//               ),
//             ),
//             _buildActionButton(
//               Icons.arrow_circle_down,
//               "ទទួលរង្វាន់ចូល",
//               Colors.lightBlue,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton(IconData icon, String label, Color iconColor) {
//     return Container(
//       width: 180,
//       height: 130,
//       margin: const EdgeInsets.only(top: 20),
//       decoration: BoxDecoration(
//         color: AppColors.primaryColor,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white, // Background behind the icon
//             ),
//             child: Icon(
//               icon,
//               color: iconColor,
//               size: 40, // Make icon bigger
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
