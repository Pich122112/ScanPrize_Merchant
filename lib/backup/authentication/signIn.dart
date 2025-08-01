// import 'package:flutter/material.dart';
// import '../../app/bottomAppbar.dart';
// import 'signUp.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import '../../servers/user_server.dart';
// import '../../changes/forget_password.dart';
// import '../../utils/constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   bool _obscureText = true;
//   final _formKey = GlobalKey<FormState>();
//   final _passwordController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _apiService = ApiService();
//   bool _isLoading = false;
//   String? _countryCode;
//   String? _phoneNumber;
//   String? _phoneError;
//   String? _passwordError;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.primaryColor, // Top background color
//       body: Column(
//         children: <Widget>[
//           SizedBox(height: 100),
//           CircleAvatar(
//             backgroundColor: AppColors.primaryColor,
//             radius: 80,
//             child: Image.asset(
//               'assets/images/logo.png',
//               width: 300,
//               height: 300,
//             ),
//           ),
//           SizedBox(height: 50),
//           Expanded(
//             child: Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(40),
//                   topRight: Radius.circular(40),
//                 ),
//               ),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     SizedBox(height: 30),
//                     Title(
//                       color: Colors.white,
//                       child: Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'ចូលទៅកាន់គណនី',
//                           style: TextStyle(fontSize: 28, color: Colors.black),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 40),
//                     IntlPhoneField(
//                       controller: _phoneController,
//                       decoration: InputDecoration(
//                         hintText: 'បញ្ចូលលេខទូរស័ព្ទរបស់អ្នក',
//                         hintStyle: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 16,
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[200],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 16,
//                           horizontal: 20,
//                         ),
//                         errorText: _phoneError,
//                       ),
//                       initialCountryCode: 'KH',
//                       disableLengthCheck: true,
//                       onChanged: (phone) {
//                         setState(() {
//                           _countryCode = phone.countryCode;
//                           _phoneNumber = phone.number;
//                           _phoneError = null;
//                         });
//                       },
//                       onCountryChanged: (country) {
//                         setState(() {
//                           _countryCode = country.dialCode;
//                           _phoneController.clear();
//                         });
//                       },
//                     ),
//                     SizedBox(height: 18),
//                     TextFormField(
//                       obscureText: _obscureText,
//                       controller: _passwordController,
//                       decoration: InputDecoration(
//                         hintText: 'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក',
//                         hintStyle: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 16,
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[200],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 16,
//                           horizontal: 20,
//                         ),
//                         prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscureText
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                             color: Colors.grey[600],
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscureText = !_obscureText;
//                             });
//                           },
//                         ),
//                         errorText: _passwordError,
//                       ),
//                       style: TextStyle(fontSize: 18, color: Colors.black),
//                       onChanged: (text) {
//                         setState(() {
//                           _passwordError = null; // Clear the error message
//                         });
//                       },
//                     ),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ForgetPassword(),
//                             ),
//                           );
//                         },
//                         child: Text(
//                           'ភ្លេចពាក្យសម្ងាត់',
//                           style: TextStyle(color: AppColors.secondaryColor),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primaryColor,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           padding: EdgeInsets.symmetric(vertical: 15),
//                         ),
//                         onPressed:
//                             _isLoading
//                                 ? null
//                                 : () async {
//                                   if (_phoneNumber == null ||
//                                       _phoneNumber!.isEmpty) {
//                                     setState(() {
//                                       _phoneError =
//                                           'សូមបញ្ចូលលេខទូរស័ព្ទរបស់អ្នក';
//                                     });
//                                     return;
//                                   }
//                                   if (_passwordController.text.isEmpty) {
//                                     setState(() {
//                                       _passwordError =
//                                           'សូមបញ្ចូលពាក្យសម្ងាត់របស់អ្នក';
//                                     });
//                                     return;
//                                   }

//                                   setState(() => _isLoading = true);

//                                   try {
//                                     final fullPhoneNumber =
//                                         '($_countryCode) $_phoneNumber';
//                                     final password = _passwordController.text;

//                                     final result = await _apiService.login(
//                                       fullPhoneNumber,
//                                       password,
//                                     );

//                                     if (mounted) {
//                                       final loggedInUserName =
//                                           result['fullName'] ??
//                                           result['name'] ??
//                                           result['username'] ??
//                                           result['user']?['fullName'] ??
//                                           result['user']?['name'] ??
//                                           'Guest User';
//                                       final loggedInPhoneNumber =
//                                           result['user']?['phoneNumber'] ??
//                                           result['phoneNumber'] ??
//                                           '';

//                                       // Save login status, username, and phone number in SharedPreferences
//                                       final prefs =
//                                           await SharedPreferences.getInstance();

//                                       await prefs.setString(
//                                         'userId',
//                                         result['user']?['userId']?.toString() ??
//                                             '', // <-- correct
//                                       );
//                                       // Normalize phone number before saving
//                                       String normalizedPhone =
//                                           (loggedInPhoneNumber)
//                                               .replaceAll('(', '')
//                                               .replaceAll(')', '')
//                                               .replaceAll(' ', '');

//                                       await prefs.setString(
//                                         'qrPayload',
//                                         result['qrPayload'] ?? '',
//                                       );
//                                       await prefs.setBool('isLoggedIn', true);
//                                       await prefs.setString(
//                                         'userName',
//                                         loggedInUserName,
//                                       );
//                                       await prefs.setString(
//                                         'phoneNumber',
//                                         normalizedPhone,
//                                       );
//                                       await prefs.setString(
//                                         'qrGanzbergPayload',
//                                         result['qrGanzbergPayload'] ?? '',
//                                       );
//                                       await prefs.setString(
//                                         'qrIdolPayload',
//                                         result['qrIdolPayload'] ?? '',
//                                       );
//                                       await prefs.setString(
//                                         'qrBoostrongPayload',
//                                         result['qrBoostrongPayload'] ?? '',
//                                       );

//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         SnackBar(
//                                           backgroundColor: Colors.green,
//                                           content: Text(
//                                             'ចូលគណនីបានជោគជ័យ',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                       );

//                                       Navigator.pushReplacement(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder:
//                                               (context) => RomlousApp(
//                                                 userName: loggedInUserName,
//                                               ),
//                                         ),
//                                       );
//                                     }
//                                   } catch (e) {
//                                     if (mounted) {
//                                       String errorMessage = e.toString();
//                                       if (errorMessage.contains(
//                                         "រកមិនឃើញអ្នកប្រើប្រាស់ទេ",
//                                       )) {
//                                         errorMessage =
//                                             "សូមអភ័យទោស រកមិនឃើញអ្នកប្រើប្រាស់!";
//                                       }
//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         SnackBar(
//                                           backgroundColor: Colors.red,
//                                           content: Text(
//                                             errorMessage,
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     }
//                                   } finally {
//                                     if (mounted) {
//                                       setState(() => _isLoading = false);
//                                     }
//                                   }
//                                 },
//                         child: Text(
//                           'ចូលគណនី',
//                           style: TextStyle(color: Colors.white, fontSize: 20),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Text("មិនមានគណនីមែនទេ ?"),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => SignUpPage(),
//                               ),
//                             );
//                           },
//                           child: Text(
//                             'បង្កើតគណនី',
//                             style: TextStyle(color: AppColors.secondaryColor),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// //Correct with 362 line code changes
