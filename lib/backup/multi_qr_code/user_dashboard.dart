// import 'package:flutter/material.dart';
// import 'package:scanprize_frontend/utils/constants.dart';
// import './transfer_prize_qr.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../servers/scanqr_prize.dart';
// import '../components/passcode.dart';
// import '../widgets/attemp_time.dart';
// import 'package:scanprize_frontend/components/user_qr_code_component.dart';
// import 'package:shimmer/shimmer.dart';

// class ThreeBoxSection extends StatefulWidget {
//   const ThreeBoxSection({super.key});

//   @override
//   ThreeBoxSectionState createState() => ThreeBoxSectionState();
// }

// class ThreeBoxSectionState extends State<ThreeBoxSection> {
//   int ganzbergPoints = 0;
//   int idolPoints = 0;
//   int boostrongPoints = 0;
//   double moneyAmount = 0.0;
//   String? errorMessage;
//   int failedAttempts = 0;
//   bool _showAmount = false;

//   Future<void> refreshSummary() async {
//     await _fetchPrizeSummary();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchPrizeSummary();
//   }

//   Future<void> _fetchPrizeSummary() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userIdStr = prefs.getString('userId') ?? '';
//     final userId = int.tryParse(userIdStr) ?? 0;
//     if (userId == 0) return;

//     final url = '${Constants.apiUrl}/user-prizes/$userId/summary';
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {"x-app-secret": Constants.appSecret},
//     );
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       setState(() {
//         ganzbergPoints = data['ganzberg'] ?? 0;
//         idolPoints = data['idol'] ?? 0;
//         boostrongPoints = data['boostrong'] ?? 0;
//         moneyAmount = (data['money'] ?? 0).toDouble(); // <-- add this
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16),
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           decoration: BoxDecoration(
//             color: AppColors.primaryColor,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Stack(
//             children: [
//               // The eye icon at the top right
//               Positioned(
//                 top: -15,
//                 right: 0,
//                 child: IconButton(
//                   icon: Icon(
//                     _showAmount
//                         ? Icons.visibility_outlined
//                         : Icons.visibility_off,
//                     color: Colors.white,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _showAmount = !_showAmount;
//                     });
//                   },
//                 ),
//               ),
//               // Main content centered
//               Center(
//                 child: SizedBox(
//                   height: 40,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _showAmount
//                           ? Text(
//                             moneyAmount.toStringAsFixed(
//                               2,
//                             ), // <-- show money amount
//                             style: const TextStyle(
//                               fontSize: 22,
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 1.1,
//                             ),
//                           )
//                           : Shimmer.fromColors(
//                             baseColor: Colors.white.withOpacity(0.2),
//                             highlightColor: Colors.white.withOpacity(0.5),
//                             child: Container(
//                               width: 80,
//                               height: 32,
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.70),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               alignment: Alignment.center,
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: List.generate(
//                                   4,
//                                   (index) => Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 2,
//                                     ),
//                                     child: Container(
//                                       width: 10,
//                                       height: 10,
//                                       decoration: BoxDecoration(
//                                         color: Colors.white.withOpacity(0.8),
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       const SizedBox(width: 12),
//                       Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.attach_money,
//                           color: Colors.green,
//                           size: 24,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 20),
//         Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16),
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           decoration: BoxDecoration(
//             color: AppColors.primaryColor,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: SizedBox(
//             height: 115,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildInfoBox(
//                   imagePath: 'assets/images/ganzberg.png',
//                   value: _showAmount ? '$ganzbergPoints' : null,
//                   label: 'ពិន្ទុ',
//                 ),
//                 _verticalDivider(),
//                 _buildInfoBox(
//                   imagePath: 'assets/images/idol.png',
//                   value: _showAmount ? '$idolPoints' : null,
//                   label: 'ពិន្ទុ',
//                 ),
//                 _verticalDivider(),
//                 _buildInfoBox(
//                   imagePath: 'assets/images/boostrong.png',
//                   value: _showAmount ? '$boostrongPoints' : null,
//                   label: 'ពិន្ទុ',
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Row(
//             children: [
//               Expanded(
//                 child: InkWell(
//                   onTap: () async {
//                     final prefs = await SharedPreferences.getInstance();
//                     final userIdStr = prefs.getString('userId') ?? '';
//                     final userId = int.tryParse(userIdStr) ?? 0;

//                     // NEW: Check lockout time before any passcode input
//                     final nowMillis = DateTime.now().millisecondsSinceEpoch;
//                     final unlockAtMillis =
//                         prefs.getInt('passcode_unlock_at') ?? 0;
//                     if (unlockAtMillis > nowMillis) {
//                       final secondsLeft =
//                           ((unlockAtMillis - nowMillis) / 1000).ceil();
//                       await showDialog(
//                         context: context,
//                         barrierDismissible: true,
//                         builder:
//                             (context) =>
//                                 LockTimerDialog(initialSeconds: secondsLeft),
//                       );
//                       // Do NOT allow passcode input yet
//                       return;
//                     }
//                     // 1. Check if passcode is set
//                     final checkResp = await http.post(
//                       Uri.parse('${Constants.apiUrl}/user-passcode/check'),
//                       headers: {
//                         "x-app-secret": Constants.appSecret,
//                         "Content-Type": "application/json",
//                       },
//                       body: json.encode({"userId": userId}),
//                     );
//                     final isSet = json.decode(checkResp.body)['isSet'] == true;

//                     if (!isSet) {
//                       // 2. Create passcode (input twice)
//                       final code1 = await showDialog<String>(
//                         context: context,
//                         builder:
//                             (context) => CustomPasscodeDialog(
//                               subtitle: 'សូមធ្វើការបង្កើតលេខសម្ងាត់របស់អ្នក',
//                             ),
//                       );
//                       if (code1 == null || code1.length != 4) return;

//                       final code2 = await showDialog<String>(
//                         context: context,
//                         builder:
//                             (context) => CustomPasscodeDialog(
//                               subtitle: 'សូមបញ្ចូលលេខសម្ងាត់អ្នកម្តងទៀត',
//                             ),
//                       );
//                       if (code2 == null || code2.length != 4) return;

//                       if (code1 != code2) {
//                         // Show error, let user try again
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'លេខសម្ងាត់ដែលអ្នកបញ្ចូលមិនដូចគ្នា សូមបង្កើតម្តងទៀត',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             backgroundColor: AppColors.secondaryColor,
//                           ),
//                         );
//                         return;
//                       }

//                       final createResp = await http.post(
//                         Uri.parse('${Constants.apiUrl}/user-passcode/create'),
//                         headers: {
//                           "x-app-secret": Constants.appSecret,
//                           "Content-Type": "application/json",
//                         },
//                         body: json.encode({
//                           "userId": userId,
//                           "passcode": code1,
//                           "passcodeConfirm": code2,
//                         }),
//                       );
//                       if (createResp.statusCode == 200) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             backgroundColor: Colors.green,
//                             content: Text(
//                               'បង្កើតលេខសម្ងាត់ជោគជ័យ',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         );
//                         //For auto open after create
//                         // Ready for transfer
//                         // showDialog(
//                         //   context: context,
//                         //   barrierColor: Colors.black87,
//                         //   builder: (context) => const TransferPrizeScan(),
//                         // );
//                         // Do NOT open scan dialog, just return (let user tap again to enter passcode and scan)
//                         return;
//                       } else {
//                         // Show error
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'បង្កើតលេខសម្ងាត់បរាជ័យ',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             backgroundColor: Colors.red,
//                           ),
//                         );
//                       }
//                     } else {
//                       // 3. Verify passcode (with lockout)
//                       for (;;) {
//                         final code = await showDialog<String>(
//                           context: context,
//                           builder:
//                               (context) => CustomPasscodeDialog(
//                                 subtitle:
//                                     'សូមបញ្ចូលលេខសម្ងាត់របស់អ្នកដើម្បីបន្ត',
//                                 errorMessage:
//                                     errorMessage != null && failedAttempts > 0
//                                         ? 'លេខសម្ងាត់មិនត្រឹមត្រូវ $failedAttempts/5'
//                                         : null,
//                               ),
//                         );
//                         if (code == null || code.length != 4) return;

//                         final verifyResp = await http.post(
//                           Uri.parse('${Constants.apiUrl}/user-passcode/verify'),
//                           headers: {
//                             "x-app-secret": Constants.appSecret,
//                             "Content-Type": "application/json",
//                           },
//                           body: json.encode({
//                             "userId": userId,
//                             "passcode": code,
//                           }),
//                         );
//                         if (verifyResp.statusCode == 200) {
//                           // Success, reset error and attempts!
//                           errorMessage = null;
//                           failedAttempts = 0;

//                           showDialog(
//                             context: context,
//                             barrierColor: Colors.black87,
//                             builder: (context) => const TransferPrizeScan(),
//                           );
//                           break;
//                         } else if (verifyResp.statusCode == 423) {
//                           final waitSeconds =
//                               json.decode(verifyResp.body)['waitSeconds'] ?? 0;
//                           // Save lockout end time in local storage
//                           final prefs = await SharedPreferences.getInstance();
//                           final unlockAt = DateTime.now().add(
//                             Duration(seconds: waitSeconds),
//                           );
//                           await prefs.setInt(
//                             'passcode_unlock_at',
//                             unlockAt.millisecondsSinceEpoch,
//                           );

//                           await showDialog(
//                             context: context,
//                             barrierDismissible: true,
//                             builder:
//                                 (context) => LockTimerDialog(
//                                   initialSeconds: waitSeconds,
//                                 ),
//                           );
//                           // After dialog closes (wait over or closed manually), user must tap again to retry, logic will check unlock time again.
//                           break;
//                         } else {
//                           // Incorrect, get failedAttempts from backend response
//                           final respBody = json.decode(verifyResp.body);
//                           failedAttempts = respBody['failedAttempts'] ?? 0;
//                           errorMessage =
//                               'លេខសម្ងាត់មិនត្រឹមត្រូវ $failedAttempts/5';
//                           // Loop to allow retry (dialog will show errorMessage)
//                         }
//                       }
//                     }
//                   },
//                   child: _buildActionButton(
//                     Icons.arrow_circle_up_sharp,
//                     "ផ្ញើរចេញ",
//                     Colors.red,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: InkWell(
//                   onTap: () async {
//                     final prefs = await SharedPreferences.getInstance();
//                     String? qrGanzbergPayload = prefs.getString(
//                       'qrGanzbergPayload',
//                     );
//                     String? qrIdolPayload = prefs.getString('qrIdolPayload');
//                     String? qrBoostrongPayload = prefs.getString(
//                       'qrBoostrongPayload',
//                     );
//                     final phoneNumber = prefs.getString('phoneNumber');

//                     // If already cached, show dialog
//                     if ((qrGanzbergPayload != null &&
//                             qrGanzbergPayload.isNotEmpty) &&
//                         (qrIdolPayload != null && qrIdolPayload.isNotEmpty) &&
//                         (phoneNumber != null && phoneNumber.isNotEmpty)) {
//                       showDialog(
//                         context: context,
//                         builder:
//                             (context) => UserQrCodeComponent(
//                               qrGanzbergPayload: qrGanzbergPayload ?? '',
//                               qrIdolPayload: qrIdolPayload ?? '',
//                               qrBoostrongPayload: qrBoostrongPayload ?? '',
//                               phoneNumber: phoneNumber,
//                               initialIndex: 0,
//                             ),
//                       );
//                       return;
//                     }

//                     // Otherwise, fetch from backend
//                     if (phoneNumber != null && phoneNumber.isNotEmpty) {
//                       try {
//                         final ganzbergResponse = await http.get(
//                           Uri.parse(
//                             '${Constants.apiUrl}/auth/me/qr?phoneNumber=$phoneNumber&type=ganzberg',
//                           ),
//                           headers: {'Content-Type': 'application/json'},
//                         );
//                         final idolResponse = await http.get(
//                           Uri.parse(
//                             '${Constants.apiUrl}/auth/me/qr?phoneNumber=$phoneNumber&type=idol',
//                           ),
//                           headers: {'Content-Type': 'application/json'},
//                         );
//                         final boostrongResponse = await http.get(
//                           Uri.parse(
//                             '${Constants.apiUrl}/auth/me/qr?phoneNumber=$phoneNumber&type=boostrong',
//                           ),
//                           headers: {'Content-Type': 'application/json'},
//                         );

//                         if (ganzbergResponse.statusCode == 200 &&
//                             idolResponse.statusCode == 200 &&
//                             boostrongResponse.statusCode == 200) {
//                           final ganzbergData = json.decode(
//                             ganzbergResponse.body,
//                           );
//                           final idolData = json.decode(idolResponse.body);
//                           final boostrongData = json.decode(
//                             boostrongResponse.body,
//                           );

//                           qrGanzbergPayload = ganzbergData['qrPayload'];
//                           qrIdolPayload = idolData['qrPayload'];
//                           qrBoostrongPayload = boostrongData['qrPayload'];

//                           if (qrGanzbergPayload != null &&
//                               qrIdolPayload != null) {
//                             await prefs.setString(
//                               'qrGanzbergPayload',
//                               qrGanzbergPayload,
//                             );
//                             await prefs.setString(
//                               'qrIdolPayload',
//                               qrIdolPayload,
//                             );
//                             await prefs.setString(
//                               'qrBoostrongPayload',
//                               qrBoostrongPayload ?? '',
//                             );
//                             showDialog(
//                               context: context,
//                               builder:
//                                   (context) => UserQrCodeComponent(
//                                     qrGanzbergPayload: qrGanzbergPayload!,
//                                     qrIdolPayload: qrIdolPayload!,
//                                     qrBoostrongPayload:
//                                         qrBoostrongPayload ?? '',
//                                     phoneNumber: phoneNumber,
//                                     initialIndex: 0,
//                                   ),
//                             );
//                             return;
//                           } else {
//                             throw Exception('QR payload is null');
//                           }
//                         } else {
//                           throw Exception('Failed to fetch QR code');
//                         }
//                       } catch (e) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Failed to fetch QR code: ${e.toString()}',
//                             ),
//                           ),
//                         );
//                         return;
//                       }
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Please login again')),
//                       );
//                       return;
//                     }
//                   },
//                   child: _buildActionButton(
//                     Icons.arrow_circle_down,
//                     "ទទួលចូល",
//                     Colors.lightBlue,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoBox({
//     required String imagePath,
//     String? value, // now nullable
//     required String label,
//   }) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         CircleAvatar(
//           radius: 22,
//           backgroundColor: Colors.white,
//           child: ClipOval(
//             child: Image.asset(
//               imagePath,
//               width: 36,
//               height: 36,
//               fit: BoxFit.fill,
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         value != null
//             ? Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             )
//             : Shimmer.fromColors(
//               baseColor: Colors.white.withOpacity(0.2),
//               highlightColor: Colors.white.withOpacity(0.5),
//               child: Container(
//                 width: 80,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.70),
//                   borderRadius: BorderRadius.circular(50),
//                 ),
//                 alignment: Alignment.center,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(
//                     4,
//                     (index) => Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 2),
//                       child: Container(
//                         width: 10,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.8),
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         const SizedBox(height: 6),
//         Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
//       ],
//     );
//   }

//   Widget _verticalDivider() {
//     return Container(width: 1, height: 45, color: Colors.white);
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
//               color: Colors.white,
//             ),
//             child: Icon(icon, color: iconColor, size: 40),
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

// //Correct with 644 line code
