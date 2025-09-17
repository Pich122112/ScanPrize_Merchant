import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/services/firebase_service.dart';
import 'package:gb_merchant/utils/device_uuid.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/user_server.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isRequestingOtp = false;

  String _countryCode = '855'; // Default to Cambodia
  String? _phoneErrorText;
  bool _timing = false;
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _otpRequested = false;
  bool _showResendBelow = false;
  bool _isLoading = false;
  bool _noInternet = false;
  bool _isBlackButton = false;
  bool _isVerifyingOtp = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String _currentLanguage = 'km'; // or 'en' - set based on your app/user

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool nowOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      setState(() {
        _noInternet = nowOffline;
      });
    });
  }

  Future<void> _checkConnection() async {
    var results = await Connectivity().checkConnectivity();
    setState(() {
      _noInternet =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timing = true;
      _secondsRemaining = 60;
      _showResendBelow = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _timing = false;
          _showResendBelow = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _setButtonBlackTemporarily() {
    setState(() {
      _isBlackButton = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isBlackButton = false;
        });
      }
    });
  }

  void _showAccountInactiveDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Icon(Icons.warning_amber, color: Colors.red, size: 60),
            content: Text(
              'គណនីរបស់អ្នកនៅមិនទាន់អនុញ្ញាតិទេ។ សូមរង់ចាំការអនុញ្ញាត់ពីក្រុមហ៊ុនសិន។',
              style: TextStyle(fontSize: 18, fontFamily: 'KhmerFont'),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'យល់ព្រម',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'KhmerFont',
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _onRequestOtp() async {
    // Prevent multiple simultaneous requests
    if (_isRequestingOtp) return;

    _setButtonBlackTemporarily();
    setState(() => _isRequestingOtp = true);

    final phone = _countryCode + _phoneController.text.trim();
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneErrorText = 'សូមបញ្ចូលលេខទូរស័ព្ទ';
        _isRequestingOtp = false;
      });
      return;
    }
    if (_phoneController.text.length < 8) {
      setState(() {
        _phoneErrorText = 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
        _isRequestingOtp = false;
      });
      return;
    }
    if (_phoneController.text.startsWith('0')) {
      setState(() {
        _phoneErrorText = 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
        _isRequestingOtp = false;
      });
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.requestSignInOtp(phone);
      if (result['success'] == true) {
        setState(() {
          _otpRequested = true;
          _otpController.clear();
          _secondsRemaining = 60;
        });
        _formKey.currentState?.validate();
        _startTimer();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP បានបញ្ជូន! សូមពិនិត្យទូរស័ព្ទរបស់អ្នក។',
              style: TextStyle(fontSize: 16, fontFamily: 'KhmerFont'),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        final message = result['message'] ?? 'មានបញ្ហា!';

        // Check if the message is "Validation failed (Account inactive)"
        if (message.contains("Validation failed (Account inactive)") ||
            message.contains("ការផ្ទៀងផ្ទាត់បរាជ័យ (គណនីមិនសកម្ម)") ||
            message.contains(
              "ការផ្ទៀងផ្ទាត់បរាជ័យ (គណនីរបស់អ្នកនៅមិនទាន់អនុញ្ញាតិទេ)",
            )) {
          _showAccountInactiveDialog();
          return;
        } else if (message.contains("User not yet register")) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'អ្នកមិនទាន់បានចុះឈ្មោះទេ សូមចុះឈ្មោះជាមុនសិន។',
                style: TextStyle(
                  fontFamily: 'KhmerFont',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          final match = RegExp(r'(\d+)').firstMatch(message);
          if (match != null) {
            int waitSeconds = int.parse(match.group(1)!);
            setState(() {
              _secondsRemaining = waitSeconds;
              _timing = true;
            });
            _startTimer();
          }
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              backgroundColor: AppColors.primaryColor,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ការបញ្ជូន OTP បរាជ័យ',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isRequestingOtp = false;
      });
    }
  }

  Future<void> _onVerifyOtp() async {
    setState(() {
      _phoneErrorText = null;
      _isVerifyingOtp = true;
    });

    bool isFieldsValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isVerifyingOtp = false;
    });

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneErrorText = 'សូមបញ្ចូលលេខទូរស័ព្ទ';
      });
      isFieldsValid = false;
    } else if (_phoneController.text.length < 8) {
      setState(() {
        _phoneErrorText = 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
      });
      isFieldsValid = false;
    } else if (_phoneController.text.startsWith('0')) {
      setState(() {
        _phoneErrorText = 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
      });
      isFieldsValid = false;
    }

    if (isFieldsValid) {
      setState(() => _isLoading = true);
      try {
        final phone = _countryCode + _phoneController.text.trim();
        final otp = _otpController.text.trim();
        // Get device UUID and FCM token
        final deviceUuid = await DeviceUUID.getUUID();
        final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';

        final verifyResult = await ApiService.verifyOtpV2(
          phone,
          otp,
          deviceUuid, // Add device UUID
          fcmToken,
        );

        if (verifyResult['success'] == true && verifyResult['data'] != null) {
          final token = verifyResult['data']['token'];
          print('🔐 VERIFIED TOKEN: $token');

          final userProfile = await ApiService.getUserProfile(token);

          // ignore: unnecessary_null_comparison
          if (userProfile != null && userProfile['success'] == true) {
            final data = userProfile['data'];
            final prefs = await SharedPreferences.getInstance();

            // Save whole profile as JSON
            await prefs.setString('userDetailData', jsonEncode(data));
            await prefs.setString('token', token);
            await prefs.setString('phoneNumber', data['phone_number'] ?? '');
            await prefs.setString('userId', data['id'].toString());
            // ✅ ADD THIS LINE - Send FCM token to backend
            await FirebaseService.sendFcmTokenToBackend(apiToken: token);

            await prefs.setBool('isLoggedIn', true);

            // NEW: Save passcode status - check both passcode_hash and passcode fields
            final hasPasscode =
                (data['passcode_hash'] != null &&
                    data['passcode_hash'].toString().isNotEmpty) ||
                (data['passcode'] != null &&
                    data['passcode'].toString().isNotEmpty);
            await prefs.setBool('hasPasscode', hasPasscode);

            // Generate and save QR payload if needed by your QR code page
            // final qrPayload = jsonEncode({
            //   "userId": data['id'],
            //   "phoneNumber": data['phone_number'],
            //   "signature": data['signature'],
            // }); 004bb921-54bc-48ab-a18d-728c7c25acc9
            //     004bb921-54bc-48ab-a18d-728c7c25acc9
            //93ef3b81-a3c8-4b8f-9256-97aeffbff5f0
            final qrPayload =
                data['signature']; // Use only the signature from backend

            await prefs.setString('qrPayload', qrPayload);
            _showSuccessDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('មិនអាចយកព័ត៌មានអ្នកប្រើបានទេ'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          final message = verifyResult['message'] ?? 'OTP មិនត្រឹមត្រូវ';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
          // Check if the message is "Validation failed (Account inactive)"
          if (message.contains("Validation failed (Account inactive)") ||
              message.contains("ការផ្ទៀងផ្ទាត់បរាជ័យ (គណនីមិនសកម្ម)") ||
              message.contains(
                "ការផ្ទៀងផ្ទាត់បរាជ័យ (គណនីរបស់អ្នកនៅមិនទាន់អនុញ្ញាតិទេ)",
              )) {
            _showAccountInactiveDialog();
            return;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'បញ្ជាក់ OTP បរាជ័យ',
              style: TextStyle(fontFamily: 'KhmerFont', fontSize: 16),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 45),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'ចូលប្រើគណនីជោគជ័យ !',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'KhmerFont',
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    // Ensure all writes are done before navigating!
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    // Replace RomlousApp with your home page
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => RomlousApp()));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.primaryColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder:
                  (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: 40),
                            CircleAvatar(
                              backgroundColor: AppColors.primaryColor,
                              radius: 80,
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 300,
                                height: 300,
                              ),
                            ),

                            const SizedBox(height: 30),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 20,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(40),
                                    topRight: Radius.circular(40),
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_back_ios,
                                              size: 25,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: const Text(
                                              'ចូលប្រើប្រាស់គណនី',
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: Colors.black,
                                                fontFamily: 'KhmerFont',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 50),
                                      IntlPhoneField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          hintText:
                                              '(0) សូមបញ្ចូលលេខទូរស័ព្ទអ្នក',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                            fontFamily: 'KhmerFont',
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                          errorText: _phoneErrorText,
                                          errorStyle: const TextStyle(
                                            fontFamily: 'KhmerFont',
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight
                                                    .bold, // ✅ makes it bold
                                            color: Colors.red,
                                          ),
                                        ),
                                        initialCountryCode: 'KH',
                                        disableLengthCheck: true,
                                        validator: (phone) {
                                          if (phone != null &&
                                              phone.number.startsWith('0')) {
                                            return 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
                                          }
                                          return null;
                                        },
                                        onChanged: (phone) {
                                          if (phone.number.startsWith('0')) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  _phoneController.text = phone
                                                      .number
                                                      .replaceFirst(
                                                        RegExp(r'^0+'),
                                                        '',
                                                      );
                                                  _phoneController.selection =
                                                      TextSelection.fromPosition(
                                                        TextPosition(
                                                          offset:
                                                              _phoneController
                                                                  .text
                                                                  .length,
                                                        ),
                                                      );
                                                });
                                            setState(() {
                                              _phoneErrorText =
                                                  'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
                                            });
                                          } else if (_phoneErrorText != null) {
                                            setState(() {
                                              _phoneErrorText = null;
                                            });
                                          }
                                        },
                                        onCountryChanged: (country) {
                                          setState(() {
                                            _countryCode = country.dialCode;
                                            _phoneController.clear();
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      TextFormField(
                                        controller: _otpController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 4,
                                        decoration: InputDecoration(
                                          hintText: 'សូមចុចលើប៊ូតុងយកកូដ ​OTP',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                            fontFamily: 'KhmerFont',
                                            fontWeight: FontWeight.w500,
                                          ),
                                          counterText: '',
                                          filled: true,
                                          fillColor: Colors.grey[200],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                          prefixIcon: Icon(
                                            Icons.sms,
                                            color: Colors.grey[600],
                                          ),

                                          // ✅ show countdown in OTP field
                                          suffixIcon:
                                              (_otpRequested && _timing)
                                                  ? Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 12,
                                                          top: 13,
                                                        ),
                                                    child: Text(
                                                      '$_secondsRemaining វិនាទី',
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors
                                                                .primaryColor,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'KhmerFont',
                                                      ),
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                          fontFamily: 'KhmerFont',
                                        ),
                                        validator: (value) {
                                          if (_isVerifyingOtp) {
                                            if (!_otpRequested)
                                              return 'សូមចុច "យកកូដ OTP" ជាមុនសិន';
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'សូមបញ្ចូលលេខកូដ OTP';
                                            } else if (value.length != 4) {
                                              return 'លេខកូដ OTP ត្រូវមានចំនួន 4 ខ្ទង់';
                                            }
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 16),
                                      if (_showResendBelow)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'មិនទទួលបានកូដមែន​ទេ ?​ សូមចុចម្តងទៀត',
                                                style: TextStyle(
                                                  color: AppColors.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'KhmerFont',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 60),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _isBlackButton
                                                    ? Colors.black
                                                    : AppColors
                                                        .primaryColor, // Change to your theme color
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            elevation: 2,
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : (!_otpRequested ||
                                                          _showResendBelow
                                                      ? _onRequestOtp
                                                      : _onVerifyOtp),
                                          child:
                                              _isLoading
                                                  ? const CircularProgressIndicator(
                                                    color: Colors.white,
                                                  )
                                                  : Text(
                                                    (!_otpRequested ||
                                                            _showResendBelow)
                                                        ? 'យកកូដ OTP'
                                                        : 'បញ្ជាក់ OTP',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'KhmerFont',
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
        if (_noInternet)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.red[600],
              padding: const EdgeInsets.symmetric(vertical: 26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "មិនមានការតភ្ជាប់អ៊ីនធឺណិត",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KhmerFont',
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

//Correct with 802 line code changes
