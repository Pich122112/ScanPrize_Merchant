import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/services/firebase_service.dart';
import 'package:gb_merchant/utils/device_uuid.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/user_server.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../services/secure_storage_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isRequestingOtp = false;
  final _otpController = TextEditingController();
  String? _appSignature;
  StreamSubscription<String>? _codeSubscription;
  bool _smsAutoFillInitialized = false;

  String _countryCode = '855'; // Default to Cambodia
  String? _phoneErrorText;
  bool _timing = false;
  int _secondsRemaining = 120;
  Timer? _timer;
  bool _otpRequested = false;
  bool _showResendBelow = false;
  bool _isLoading = false;
  bool _noInternet = false;
  bool _isBlackButton = false;
  bool _isVerifyingOtp = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  late SecureStorageService _secureStorage;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorageService();

    _initSmsAutofill(); // Add this line

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

  // Add this method to manually check SMS permissions and test
  void _debugSmsReception() async {
    print('\n=== 🔍 DEBUG SMS AUTO-FILL ===');
    print('📱 OTP Requested: $_otpRequested');
    print('📱 SMS Auto-fill Initialized: $_smsAutoFillInitialized');
    print('📱 App Signature: $_appSignature');
    print('📱 Code Subscription Active: ${_codeSubscription != null}');

    // Test if we can manually trigger SMS reading
    try {
      // ignore: unused_local_variable
      final testCode = await SmsAutoFill().getAppSignature;
      print('📱 Can access SMS API: true');
    } catch (e) {
      print('📱 Can access SMS API: false - Error: $e');
    }
    print('================================\n');
  }

  Future<void> _initSmsAutofill() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        // iOS: rely on native UITextContentType.oneTimeCode and AutofillGroup.
        if (kDebugMode) {
          print(
            'ℹ️ iOS detected: skipping Android SmsRetriever. Using native oneTimeCode autofill.',
          );
        }
        _smsAutoFillInitialized = false;
        _appSignature = null;
        return;
      }

      print('🔄 Initializing SMS Auto-fill for Android...');

      // Get app signature (Android only)
      _appSignature = await SmsAutoFill().getAppSignature;
      print('📱 App Signature: $_appSignature');

      // Safe restart of listener
      try {
        await SmsAutoFill().unregisterListener();
      } catch (_) {}

      await SmsAutoFill().listenForCode();
      print('✅ Started listening for SMS via SmsAutoFill.listenForCode()');

      // Listen for incoming SMS
      _codeSubscription?.cancel();
      _codeSubscription = SmsAutoFill().code.listen(
        (code) {
          print('\n🎉 SMS RECEIVED (Android): "$code"');

          // ignore: unnecessary_null_comparison
          if (code == null || code.isEmpty) {
            print('❌ Received empty or null SMS message');
            return;
          }

          // Extract OTP (robust)
          String extractedOtp = '';
          final otpMatch = RegExp(r'\b\d{4}\b').firstMatch(code);
          if (otpMatch != null) {
            extractedOtp = otpMatch.group(0)!;
          } else {
            final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length >= 4) extractedOtp = digits.substring(0, 4);
          }

          if (extractedOtp.length == 4 && mounted) {
            setState(() {
              _otpController.text = extractedOtp;
            });

            // Auto-verify after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _otpRequested && !_isLoading) {
                _onVerifyOtp();
              }
            });
          } else {
            print(
              '⚠️ Could not extract valid 4-digit OTP. Digits found: '
              '${code.replaceAll(RegExp(r'[^0-9]'), '')}',
            );
          }
        },
        onError: (error) {
          print('❌ SMS Listener Error: $error');
        },
        cancelOnError: false,
      );

      _smsAutoFillInitialized = true;
      print('✅ SMS Auto-fill initialized successfully for Android');
    } catch (e) {
      print('❌ SMS Auto-fill init error: $e');
      _smsAutoFillInitialized = false;
    }
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
    _otpController.dispose(); // Add this line
    _otpController.dispose();
    _timer?.cancel();
    _codeSubscription?.cancel(); // Add this line
    SmsAutoFill().unregisterListener(); // Add this line
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timing = true;
      _secondsRemaining = 120;
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

  void _showSmsInstructions(String phone) {
    print('\n=== 🚨 SMS AUTO-FILL REQUIREMENTS 🚨 ===');
    print('📱 For AUTO-FILL to work:');
    print('1. SMS must contain 4-digit OTP');
    print('2. SMS must contain app signature: $_appSignature');
    print('3. SMS format: "1234 is your code. $_appSignature"');
    print('');
    print('📲 If auto-fill fails:');
    print('1. Check your SMS app manually');
    print('2. Look for the REAL OTP (not 1234)');
    print('3. Enter it manually in the OTP field');
    print('4. Common OTPs: 5244, 1234, 0000, etc.');
    print('');
    print('📱 Testing Phone: $phone');
    print('==========================================\n');
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
          _secondsRemaining = 120;
        });
        _formKey.currentState?.validate();
        _startTimer();

        // Run debug checks
        _debugSmsReception();

        // Show instructions for real SMS testing
        _showSmsInstructions(phone);

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

          final userProfile = await ApiService.getUserProfile(token);

          // ignore: unnecessary_null_comparison
          if (userProfile != null && userProfile['success'] == true) {
            final data = userProfile['data'];

            // ✅ SECURE STORAGE - Store sensitive data
            await _secureStorage.setToken(token);
            await _secureStorage.setUserId(data['id'].toString());
            await _secureStorage.setPhoneNumber(data['phone_number'] ?? '');

            await FirebaseService.sendFcmTokenToBackend(apiToken: token);

            // ✅ Only store non-sensitive data in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);

            final hasPasscode =
                (data['passcode_hash'] != null &&
                    data['passcode_hash'].toString().isNotEmpty) ||
                (data['passcode'] != null &&
                    data['passcode'].toString().isNotEmpty);
            await prefs.setBool('hasPasscode', hasPasscode);

            final qrPayload = data['signature'];
            if (qrPayload != null && qrPayload.isNotEmpty) {
              await _secureStorage.setQrPayload(
                qrPayload,
              ); // ✅ Save to SecureStorage
            }

            print('✅ User data saved securely');

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

    // ✅ Get token from SecureStorage, NOT SharedPreferences
    final apiToken = await _secureStorage.getToken();
    print('🔐 Retrieved token from SecureStorage: $apiToken');

    if (apiToken != null && apiToken.isNotEmpty) {
      // Try to get stored FCM token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcm_token');

      if (fcmToken != null) {
        print('📱 Uploading stored FCM token after login...');
        await FirebaseService.sendFcmTokenToBackend(apiToken: apiToken);
      } else {
        print('⚠️ No FCM token stored, requesting fresh token...');

        // Request notification permission first (important for iOS)
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // Handle iOS APNS token requirement
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // Wait for APNS token on iOS
          String? apnsToken;
          for (int i = 0; i < 5; i++) {
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            print("📱 APNS Token attempt $i: $apnsToken");
            if (apnsToken != null) break;
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        // Get fresh FCM token
        final freshToken = await FirebaseMessaging.instance.getToken();
        print("🔥 Fresh FCM Token: $freshToken");

        if (freshToken != null) {
          // Store it for future use
          await prefs.setString('fcm_token', freshToken);
          await FirebaseService.sendFcmTokenToBackend(apiToken: apiToken);
        } else {
          print('❌ Could not get FCM token after login');
        }
      }
    } else {
      print('❌ No API token found in SecureStorage after login');
    }

    // Navigate to main app
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
                                child: AutofillGroup(
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                    _phoneController
                                                        .text = phone.number
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
                                            } else if (_phoneErrorText !=
                                                null) {
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
                                        const SizedBox(height: 18),
                                        AutofillGroup(
                                          child: TextFormField(
                                            controller: _otpController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 4,
                                            autofillHints: const [
                                              AutofillHints.oneTimeCode,
                                            ], // Add this line
                                            decoration: InputDecoration(
                                              hintText:
                                                  'សូមចុចលើប៊ូតុងយកកូដ ​OTP',
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
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                                              errorStyle: const TextStyle(
                                                fontFamily: 'KhmerFont',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
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
                                                            fontFamily:
                                                                'KhmerFont',
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
                                                    color:
                                                        AppColors.primaryColor,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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

//Correct with 968 line code changes
