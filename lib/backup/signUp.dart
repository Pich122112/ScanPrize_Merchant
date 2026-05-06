import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/stores/json_service.dart';
import 'package:gb_merchant/stores/open_camera_identity.dart';
import 'package:gb_merchant/stores/welcome_screen.dart';
import 'package:gb_merchant/services/firebase_service.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/device_uuid.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../services/user_server.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
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
  File? _nationalIdFrontImage;
  File? _nationalIdBackImage;
  bool _isUploadingDocuments = false;
  final _nameController = TextEditingController();
  // ignore: unused_field
  String? _nameErrorText;
  String? _provinceErrorText;
  String? _districtErrorText;
  String? _communeErrorText;
  String? _villageErrorText;
  String? _nationalIdFrontErrorText;
  String? _nationalIdBackErrorText;
  bool _nationalIdFrontUploaded = false;
  bool _nationalIdBackUploaded = false;
  @override
  void initState() {
    super.initState();
    _initSmsAutofill(); // Add this line

    _checkConnection();
    _loadLocationData();

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

  // Replace hardcoded location data with these
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _communes = [];

  String? _selectedProvinceId;
  String? _selectedDistrictId;
  String? _selectedCommuneId;
  String? _selectedVillageId;

  Future<void> _loadLocationData() async {
    try {
      await LocationService.loadLocationData();

      setState(() {
        _provinces = LocationService.getProvinces();
        print("=== DEBUG: Loaded ${_provinces.length} provinces ===");

        // Print all available provinces for debugging
        for (var province in _provinces) {
          print(
            "Province: ${province['name_kh']} (ID: ${province['id']}, ISO: ${province['iso']})",
          );
        }
        print("==============================================");

        // If we have a previously selected district, try to restore its communes
        if (_selectedDistrictId != null) {
          _communes = LocationService.getCommunesByDistrict(
            _selectedDistrictId!,
          );
          print(
            "Restored ${_communes.length} communes for district $_selectedDistrictId",
          );
        }
      });
    } catch (e) {
      print("Error loading location data: $e");
      // Fallback to empty lists instead of crashing
      setState(() {
        _provinces = [];
        _districts = [];
        _communes = [];
      });
    }
  }

  Future<void> _initSmsAutofill() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        print('ℹ️ iOS detected: Using native oneTimeCode autofill.');
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
            print('🎯 Extracted OTP: $extractedOtp');
            setState(() {
              _otpController.text = extractedOtp;
            });

            // Auto-verify after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _otpRequested && !_isLoading) {
                print('🚀 Auto-verifying OTP: $extractedOtp');
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

  void _debugSmsReception() async {
    print('\n=== 🔍 DEBUG SMS AUTO-FILL ===');
    print('📱 OTP Requested: $_otpRequested');
    print('📱 SMS Auto-fill Initialized: $_smsAutoFillInitialized');
    print('📱 App Signature: $_appSignature');
    print('📱 Code Subscription Active: ${_codeSubscription != null}');
    print('📱 Current OTP: ${_otpController.text}');
    print(
      '📱 Is Listening: ${_codeSubscription != null && !_codeSubscription!.isPaused}',
    );

    try {
      // ignore: unused_local_variable
      final testCode = await SmsAutoFill().getAppSignature;
      print('📱 Can access SMS API: true');
    } catch (e) {
      print('📱 Can access SMS API: false - Error: $e');
    }
    print('================================\n');
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

  void _onProvinceChanged(String? provinceId) {
    setState(() {
      _selectedProvinceId = provinceId;
      _selectedDistrictId = null;
      _selectedCommuneId = null;

      if (provinceId != null) {
        // Use the numeric ID to find districts
        _districts = LocationService.getDistrictsByProvince(provinceId);
        print(
          "📊 Found ${_districts.length} districts for province $provinceId",
        );
      } else {
        _districts = [];
      }

      _communes = [];
    });
  }

  void _onDistrictChanged(String? districtId) {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedCommuneId = null;
      _communes =
          districtId != null
              ? LocationService.getCommunesByDistrict(districtId)
              : [];
    });
  }

  void _onCommuneChanged(String? communeId) {
    setState(() {
      _selectedCommuneId = communeId;
    });
  }

  Future<void> _checkConnection() async {
    var results = await Connectivity().checkConnectivity();
    setState(() {
      _noInternet =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    });
  }

  String _getLabel(bool showFront, String locale) {
    if (locale == "km") {
      return showFront ? "រូបផ្នែកខាងមុខ" : "រូបផ្នែកខាងក្រោយ";
    } else {
      return showFront ? "Front Image" : "Back Image";
    }
  }

  void _showImageDialog(BuildContext context, {required bool showFront}) {
    File? imageToShow =
        showFront ? _nationalIdFrontImage : _nationalIdBackImage;
    String label = _getLabel(
      showFront,
      Localizations.localeOf(context).languageCode,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black87, // darker background overlay
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent, // make dialog background clean
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Image section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 0.5,
                            fontFamily: 'KhmerFont',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child:
                            imageToShow != null
                                ? ClipRRect(
                                  child: Image.file(
                                    imageToShow,
                                    width: double.infinity,
                                    fit: BoxFit.fitWidth,
                                  ),
                                )
                                : const Center(
                                  child: Text(
                                    'Cannot load image',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                      ),
                    ],
                  ),

                  // Close button (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose(); // Add this line
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

  String validatePhone(String phone) {
    // Remove any non-digit characters
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Replace your current validateId function with this:
  String validateId(String? id) {
    // Ensure ID is not null or empty, use default value if null
    return id?.isEmpty ?? true ? '1' : id!;
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

  Future<void> _onRequestOtp() async {
    _setButtonBlackTemporarily();

    setState(() {
      _nameErrorText = null;
      _phoneErrorText = null;
      _provinceErrorText = null;
      _districtErrorText = null;
      _communeErrorText = null;
      _nationalIdFrontErrorText = null;
      _nationalIdBackErrorText = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameErrorText = 'សូមបញ្ចូលឈ្មោះ';
      });
      hasError = true;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneErrorText = 'សូមបញ្ចូលលេខទូរស័ព្ទ';
      });
      hasError = true;
    } else if (_phoneController.text.length < 8) {
      setState(() {
        _phoneErrorText = 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
      });
      hasError = true;
    } else if (_phoneController.text.startsWith('0')) {
      setState(() {
        _phoneErrorText = 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
      });
      hasError = true;
    }

    if (_selectedProvinceId == null) {
      setState(() {
        _provinceErrorText = 'សូមជ្រើសរើសខេត្ត/ក្រុង';
      });
      hasError = true;
    }
    if (_selectedDistrictId == null) {
      setState(() {
        _districtErrorText = 'សូមជ្រើសរើសស្រុក/ខណ្ឌ';
      });
      hasError = true;
    }
    if (_selectedCommuneId == null) {
      setState(() {
        _communeErrorText = 'សូមជ្រើសរើសឃុំ/សង្កាត់';
      });
      hasError = true;
    }
    if (_nationalIdFrontImage == null) {
      setState(() {
        _nationalIdFrontErrorText = 'សូមបញ្ចូលរូបភាពស្នាមមុខអត្តសញ្ញាណ';
      });
      hasError = true;
    }
    if (_nationalIdBackImage == null) {
      setState(() {
        _nationalIdBackErrorText = 'សូមបញ្ចូលរូបភាពខាងក្រោយអត្តសញ្ញាណ';
      });
      hasError = true;
    }

    if (hasError) return;

    // Your existing request OTP logic below (unchanged)
    final phone = _countryCode + _phoneController.text.trim();
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.requestSignUpOtp(phone);
      // final result = await ApiService.testSignUpWithExactValues();

      if (result['success'] == true) {
        setState(() {
          _otpRequested = true;
          _otpController.clear();
          _secondsRemaining = 120;
        });
        _formKey.currentState?.validate();
        _startTimer();
        // 🆕 ADD THESE LINES FOR SMS AUTO-FILL
        print('📤 OTP Requested for: $phone');
        print('📱 SMS Auto-fill Status: $_smsAutoFillInitialized');
        print('📱 App Signature: $_appSignature');

        // Run debug checks
        _debugSmsReception();

        // Show instructions for real SMS testing
        _showSmsInstructions(phone);
        // 🆕 END OF ADDED LINES

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
        final match = RegExp(r'(\d+)').firstMatch(message);
        if (match != null) {
          int waitSeconds = int.parse(match.group(1)!);
          setState(() {
            _secondsRemaining = waitSeconds;
            _timing = true;
          });
          _startTimer();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'KhmerFont',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ការបញ្ជូន OTP បរាជ័យ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'KhmerFont',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Replace your current _onVerifyOtp method with this one
  Future<void> _onVerifyOtp() async {
    setState(() {
      _phoneErrorText = null;
      _isVerifyingOtp = true;
    });

    // Validate all form fields including location fields
    bool isFieldsValid = _formKey.currentState?.validate() ?? false;
    // Validate that both ID images are captured
    if (_nationalIdFrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'សូមបញ្ចូលរូបភាពស្នាមមុខអត្តសញ្ញាណ',
            style: TextStyle(
              fontFamily: 'KhmerFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      isFieldsValid = false;
    }

    if (_nationalIdBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'សូមបញ្ចូលរូបភាពខាងក្រោយអត្តសញ្ញាណ',
            style: TextStyle(
              fontFamily: 'KhmerFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      isFieldsValid = false;
    }
    // Additional validation for location fields
    if (_selectedProvinceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'សូមជ្រើសរើសខេត្ត/ក្រុង',
            style: TextStyle(
              fontFamily: 'KhmerFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      isFieldsValid = false;
    }

    if (_selectedDistrictId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'សូមជ្រើសរើសស្រុក/ខណ្ឌ',
            style: TextStyle(
              fontFamily: 'KhmerFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      isFieldsValid = false;
    }

    if (_selectedCommuneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'សូមជ្រើសរើសឃុំ/សង្កាត់',
            style: TextStyle(
              fontFamily: 'KhmerFont',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      isFieldsValid = false;
    }

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
        // Validate that all location fields are selected
        if (_selectedProvinceId == null ||
            _selectedDistrictId == null ||
            _selectedCommuneId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'សូមជ្រើសរើសទីតាំងឲ្យបានពេញលេញ',
                style: TextStyle(
                  fontFamily: 'KhmerFont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // In your _onVerifyOtp method, update the signup call:
        final validatedPhone = validatePhone(
          _countryCode + _phoneController.text.trim(),
        );
        final validatedDistrict = validateId(_selectedDistrictId);
        final validatedCommune = validateId(_selectedCommuneId);
        final validatedVillage = validateId(_selectedVillageId);
        // Get device UUID and FCM token
        final deviceUuid = await DeviceUUID.getUUID();
        // final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
        String? fcmToken = await _messaging.getToken();

        // ⬇️ Try fallback if null
        if (fcmToken == null) {
          // Make sure APNs is linked to FCM
          String? apnsToken = await _messaging.getAPNSToken();
          print('📱 APNs Token: $apnsToken');

          fcmToken = await _messaging.getToken();
        }

        if (fcmToken == null) {
          print('❌ Still no FCM token, continue without sending to backend.');
        } else {
          print('🔥 Got FCM token: $fcmToken');
        }

        final signupResult = await ApiService.signUp(
          name: _nameController.text.trim(),
          phone: validatedPhone,
          otp: _otpController.text.trim(),
          provinceId: _selectedProvinceId!, // Pass numeric ID directly
          district: validatedDistrict,
          commune: validatedCommune,
          village: validatedVillage,
          deviceUuid: deviceUuid, // Add device UUID
          fcmToken: fcmToken!, // Add FCM token
        );
        if (signupResult['success'] == true && signupResult['data'] != null) {
          final token =
              signupResult['data']['authToken']; // Changed from 'token' to 'authToken'
          print('🔐 SIGNUP SUCCESSFUL TOKEN: $token');

          // Upload identity documents
          setState(() => _isUploadingDocuments = true);

          final uploadResult = await ApiService.uploadIdentityDocuments(
            token: token,
            nationalIdFront: _nationalIdFrontImage!,
            nationalIdBack: _nationalIdBackImage!,
          );

          setState(() {
            _nationalIdFrontUploaded = uploadResult['success'] == true;
            _nationalIdBackUploaded = uploadResult['success'] == true;
            // do not show any snackbar/message for upload success
          });
          // ignore: unused_local_variable
          final userProfile = await ApiService.getUserProfile(token);

          // ignore: unnecessary_null_comparison
          if (token != null) {
            final userProfile = await ApiService.getUserProfile(token);

            // ignore: unnecessary_null_comparison
            if (userProfile != null && userProfile['success'] == true) {
              final data = userProfile['data'];
              final prefs = await SharedPreferences.getInstance();

              // Save user data
              await prefs.setString('userDetailData', jsonEncode(data));
              await prefs.setString('token', token);
              await prefs.setString('phoneNumber', data['phone_number'] ?? '');
              await prefs.setString('userId', data['id'].toString());
              // ✅ ADD THIS LINE - Send FCM token to backend
              await FirebaseService.sendFcmTokenToBackend(apiToken: token);

              await prefs.setBool('isLoggedIn', true);
              await prefs.setString(
                'user_data',
                jsonEncode(userProfile),
              ); // NEW LINE

              // Save user status (NEW - check status instead of passcode)
              final userStatus = data['status'] ?? 1;
              await prefs.setBool('isUserApproved', userStatus == 1);
              print(
                '🔐 USER STATUS: $userStatus (Approved: ${userStatus == 1})',
              );
              // Save passcode status
              final hasPasscode =
                  (data['passcode_hash'] != null &&
                      data['passcode_hash'].toString().isNotEmpty) ||
                  (data['passcode'] != null &&
                      data['passcode'].toString().isNotEmpty);
              await prefs.setBool('hasPasscode', hasPasscode);

              // Save QR payload
              final qrPayload = data['signature'];
              await prefs.setString('qrPayload', qrPayload);

              _showSuccessDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'មិនអាចយកព័ត៌មានអ្នកប្រើបានទេ',
                    style: TextStyle(
                      fontFamily: 'KhmerFont',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            _showSuccessDialog();
          }
        } else {
          // Improved error handling
          final message = signupResult['message'] ?? 'ការចុះឈ្មោះមិនជោគជ័យ';
          final errors = signupResult['errors'] ?? {};

          print('❌ SIGNUP FAILED: $message');
          print('❌ ERRORS: $errors');

          // Show specific error messages if available
          String errorMessage = message;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ការចុះឈ្មោះមិនជោគជ័យ',
              style: TextStyle(
                fontFamily: 'KhmerFont',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }

    setState(() {
      _isVerifyingOtp = false;
    });
  }

  void _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                    'បង្កើតគណនីជោគជ័យ !',
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
    ).pushReplacement(MaterialPageRoute(builder: (context) => WelcomeScreen()));
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
                            const SizedBox(height: 20),
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
                                                'បង្កើតគណនីរបស់អ្នក',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.black,
                                                  fontFamily: 'KhmerFont',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 30),
                                        // 1. Full Name field
                                        TextFormField(
                                          controller: _nameController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.grey[200],
                                            hintText: 'បញ្ចូលឈ្មោះពេញ',
                                            prefixIcon: Icon(
                                              Icons.person_outline,
                                              color: Colors.grey[600],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                            errorText: _nameErrorText,
                                            errorStyle: const TextStyle(
                                              fontFamily: 'KhmerFont',
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight
                                                      .w500, // ✅ makes it bold
                                              color: Colors.red,
                                            ),
                                          ),

                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'KhmerFont',
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'សូមបញ្ចូលឈ្មោះ';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

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
                                                      .w500, // ✅ makes it bold
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

                                        const SizedBox(height: 12),

                                        // 2. Four dropdown fields for location (simplified example, you need to provide the list and logic)
                                        DropdownButtonFormField<String>(
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.grey[200],
                                            prefixIcon: Icon(
                                              Icons.location_on,
                                              color: Colors.grey[600],
                                            ),
                                            errorText: _provinceErrorText,
                                            errorStyle: const TextStyle(
                                              fontFamily: 'KhmerFont',
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight
                                                      .w500, // ✅ makes it bold
                                              color: Colors.red,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 18,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          hint: Text(
                                            'ខេត្ត/ក្រុង',
                                            style: TextStyle(
                                              fontFamily: 'KhmerFont',
                                            ),
                                          ),
                                          initialValue: _selectedProvinceId,
                                          items:
                                              _provinces.map((province) {
                                                // Safely extract the province ID
                                                String provinceId =
                                                    (province['id']
                                                                ?.toString() ??
                                                            province['numeric_id']
                                                                ?.toString() ??
                                                            '')
                                                        .toString();

                                                return DropdownMenuItem<String>(
                                                  value: provinceId,
                                                  child: Text(
                                                    province['name_kh'] ??
                                                        province['name_en'] ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      fontFamily: 'KhmerFont',
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: _onProvinceChanged,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'សូមជ្រើសរើសខេត្ត/ក្រុង';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 12),
                                        // District dropdown
                                        DropdownButtonFormField<String>(
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            errorText: _districtErrorText,
                                            errorStyle: const TextStyle(
                                              fontFamily: 'KhmerFont',
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight
                                                      .w500, // ✅ makes it bold
                                              color: Colors.red,
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[200],
                                            prefixIcon: Icon(
                                              Icons.location_on,
                                              color: Colors.grey[600],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 18,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          hint: Text(
                                            'ស្រុក/ខណ្ឌ',
                                            style: TextStyle(
                                              fontFamily: 'KhmerFont',
                                            ),
                                          ),
                                          initialValue: _selectedDistrictId,
                                          items:
                                              _districts.map((district) {
                                                return DropdownMenuItem<String>(
                                                  value:
                                                      district['geocode']
                                                          ?.toString(), // Ensure string value
                                                  child: Text(
                                                    district['name_kh'] ??
                                                        district['name_en'] ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      fontFamily: 'KhmerFont',
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged:
                                              _selectedProvinceId != null
                                                  ? _onDistrictChanged
                                                  : null,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'សូមជ្រើសរើសស្រុក/ខណ្ឌ';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        // Commune dropdown
                                        DropdownButtonFormField<String>(
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            errorText: _communeErrorText,
                                            errorStyle: const TextStyle(
                                              fontFamily: 'KhmerFont',
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight
                                                      .w500, // ✅ makes it bold
                                              color: Colors.red,
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[200],
                                            prefixIcon: Icon(
                                              Icons.location_on,
                                              color: Colors.grey[600],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 18,
                                                  horizontal: 10,
                                                ),
                                          ),
                                          hint: Text(
                                            'ឃុំ/សង្កាត់',
                                            style: TextStyle(
                                              fontFamily: 'KhmerFont',
                                            ),
                                          ),
                                          initialValue: _selectedCommuneId,
                                          items:
                                              _communes.map((commune) {
                                                return DropdownMenuItem<String>(
                                                  value:
                                                      commune['geocode']
                                                          ?.toString(), // Ensure string value
                                                  child: Text(
                                                    commune['name_kh'] ??
                                                        commune['name_en'] ??
                                                        'Unknown',
                                                    style: TextStyle(
                                                      fontFamily: 'KhmerFont',
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged:
                                              _selectedDistrictId != null
                                                  ? _onCommuneChanged
                                                  : null,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'សូមជ្រើសរើសឃុំ/សង្កាត់';
                                            }
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 12),
                                        TextFormField(
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.grey[200],
                                            prefixIcon: Icon(
                                              Icons.location_on,
                                              color: Colors.grey[600],
                                            ),
                                            hintText:
                                                'ភូមិ (អាចមិនបំពេញបាន)', // Village (optional)
                                            hintStyle: TextStyle(
                                              fontFamily: 'KhmerFont',
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 18,
                                                  horizontal: 10,
                                                ),
                                            errorText: _villageErrorText,
                                            errorStyle: const TextStyle(
                                              fontFamily: 'KhmerFont',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.red,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontFamily: 'KhmerFont',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedVillageId =
                                                  value; // or use a new variable if you want
                                              _villageErrorText = null;
                                            });
                                          },
                                          validator: (value) {
                                            // Optional: allow empty input
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        // 3. Two image upload fields
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap:
                                                    (_nationalIdFrontImage !=
                                                            null)
                                                        ? () =>
                                                            _showImageDialog(
                                                              context,
                                                              showFront: true,
                                                            )
                                                        : null,
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    errorText:
                                                        _nationalIdFrontErrorText,
                                                    errorStyle: const TextStyle(
                                                      fontFamily: 'KhmerFont',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.grey[200],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          _nationalIdFrontUploaded
                                                              ? const BorderSide(
                                                                color:
                                                                    Colors
                                                                        .green,
                                                                width: 2,
                                                              )
                                                              : BorderSide.none,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.fromLTRB(
                                                          20,
                                                          16,
                                                          12,
                                                          16,
                                                        ),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .camera_alt_outlined,
                                                        color: Colors.grey[600],
                                                      ),
                                                      onPressed: () async {
                                                        final imageFile =
                                                            await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => const OpenCameraIdentity(
                                                                      isFront:
                                                                          true,
                                                                    ),
                                                              ),
                                                            );
                                                        if (imageFile != null &&
                                                            imageFile is File) {
                                                          setState(() {
                                                            _nationalIdFrontImage =
                                                                imageFile;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      _nationalIdFrontImage !=
                                                              null
                                                          ? _nationalIdFrontImage!
                                                              .path
                                                              .split('/')
                                                              .last
                                                          : 'បញ្ជូលរូបភាពស្នាមមុខអត្តសញ្ញាណ',
                                                      style: TextStyle(
                                                        color:
                                                            _nationalIdFrontImage !=
                                                                    null
                                                                ? Colors.blue
                                                                : Colors
                                                                    .grey[600],
                                                        fontFamily: 'KhmerFont',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: InkWell(
                                                onTap:
                                                    (_nationalIdBackImage !=
                                                            null)
                                                        ? () =>
                                                            _showImageDialog(
                                                              context,
                                                              showFront: false,
                                                            )
                                                        : null,
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    errorText:
                                                        _nationalIdBackErrorText,
                                                    errorStyle: const TextStyle(
                                                      fontFamily: 'KhmerFont',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red,
                                                    ),
                                                    filled: true,
                                                    fillColor: Colors.grey[200],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      borderSide:
                                                          _nationalIdBackUploaded
                                                              ? const BorderSide(
                                                                color:
                                                                    Colors
                                                                        .green,
                                                                width: 2,
                                                              )
                                                              : BorderSide.none,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.fromLTRB(
                                                          20,
                                                          16,
                                                          12,
                                                          16,
                                                        ),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .camera_alt_outlined,
                                                        color: Colors.grey[600],
                                                      ),
                                                      onPressed: () async {
                                                        final imageFile =
                                                            await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => const OpenCameraIdentity(
                                                                      isFront:
                                                                          false,
                                                                    ),
                                                              ),
                                                            );
                                                        if (imageFile != null &&
                                                            imageFile is File) {
                                                          setState(() {
                                                            _nationalIdBackImage =
                                                                imageFile;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      _nationalIdBackImage !=
                                                              null
                                                          ? _nationalIdBackImage!
                                                              .path
                                                              .split('/')
                                                              .last
                                                          : 'បញ្ជូលរូបភាពខាងក្រោយអត្តសញ្ញាណ',
                                                      style: TextStyle(
                                                        color:
                                                            _nationalIdFrontImage !=
                                                                    null
                                                                ? Colors.blue
                                                                : Colors
                                                                    .grey[600],
                                                        fontFamily: 'KhmerFont',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
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
                                                          style: TextStyle(
                                                            color:
                                                                AppColors
                                                                    .primaryColor,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                            ),
                                            validator: (value) {
                                              if (_isVerifyingOtp) {
                                                if (!_otpRequested) {
                                                  return 'សូមចុច "យកកូដ OTP" ជាមុនសិន';
                                                }
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
                                              children: [
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
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _isBlackButton
                                                      ? Colors.black
                                                      : AppColors.primaryColor,
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
                                                    : _isUploadingDocuments
                                                    ? Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: const [
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          'កំពុងផ្ទុកឯកសារ...',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontFamily:
                                                                'KhmerFont',
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
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

//Correct with 1688 line code changes ( OTP Auto Fill )

//Default Code
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:gb_merchant/stores/json_service.dart';
// import 'package:gb_merchant/stores/open_camera_identity.dart';
// import 'package:gb_merchant/stores/welcome_screen.dart';
// import 'package:gb_merchant/services/firebase_service.dart';
// import 'package:gb_merchant/utils/constants.dart';
// import 'package:gb_merchant/utils/device_uuid.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../services/user_server.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   _SignUpPageState createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   final _otpController = TextEditingController();

//   String _countryCode = '855'; // Default to Cambodia
//   String? _phoneErrorText;
//   bool _timing = false;
//   int _secondsRemaining = 120;
//   Timer? _timer;
//   bool _otpRequested = false;
//   bool _showResendBelow = false;
//   bool _isLoading = false;
//   bool _noInternet = false;
//   bool _isBlackButton = false;
//   bool _isVerifyingOtp = false;
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   File? _nationalIdFrontImage;
//   File? _nationalIdBackImage;
//   bool _isUploadingDocuments = false;
//   final _nameController = TextEditingController();
//   // ignore: unused_field
//   String? _nameErrorText;
//   String? _provinceErrorText;
//   String? _districtErrorText;
//   String? _communeErrorText;
//   String? _villageErrorText;
//   String? _nationalIdFrontErrorText;
//   String? _nationalIdBackErrorText;
//   bool _nationalIdFrontUploaded = false;
//   bool _nationalIdBackUploaded = false;
//   @override
//   void initState() {
//     super.initState();
//     _checkConnection();
//     _loadLocationData();

//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       results,
//     ) {
//       bool nowOffline =
//           results.isEmpty || results.every((r) => r == ConnectivityResult.none);
//       setState(() {
//         _noInternet = nowOffline;
//       });
//     });
//   }

//   // Replace hardcoded location data with these
//   List<Map<String, dynamic>> _provinces = [];
//   List<Map<String, dynamic>> _districts = [];
//   List<Map<String, dynamic>> _communes = [];

//   String? _selectedProvinceId;
//   String? _selectedDistrictId;
//   String? _selectedCommuneId;
//   String? _selectedVillageId;

//   Future<void> _loadLocationData() async {
//     try {
//       await LocationService.loadLocationData();

//       setState(() {
//         _provinces = LocationService.getProvinces();
//         print("=== DEBUG: Loaded ${_provinces.length} provinces ===");

//         // Print all available provinces for debugging
//         for (var province in _provinces) {
//           print(
//             "Province: ${province['name_kh']} (ID: ${province['id']}, ISO: ${province['iso']})",
//           );
//         }
//         print("==============================================");

//         // If we have a previously selected district, try to restore its communes
//         if (_selectedDistrictId != null) {
//           _communes = LocationService.getCommunesByDistrict(
//             _selectedDistrictId!,
//           );
//           print(
//             "Restored ${_communes.length} communes for district $_selectedDistrictId",
//           );
//         }
//       });
//     } catch (e) {
//       print("Error loading location data: $e");
//       // Fallback to empty lists instead of crashing
//       setState(() {
//         _provinces = [];
//         _districts = [];
//         _communes = [];
//       });
//     }
//   }

//   void _onProvinceChanged(String? provinceId) {
//     setState(() {
//       _selectedProvinceId = provinceId;
//       _selectedDistrictId = null;
//       _selectedCommuneId = null;

//       if (provinceId != null) {
//         // Use the numeric ID to find districts
//         _districts = LocationService.getDistrictsByProvince(provinceId);
//         print(
//           "📊 Found ${_districts.length} districts for province $provinceId",
//         );
//       } else {
//         _districts = [];
//       }

//       _communes = [];
//     });
//   }

//   void _onDistrictChanged(String? districtId) {
//     setState(() {
//       _selectedDistrictId = districtId;
//       _selectedCommuneId = null;
//       _communes =
//           districtId != null
//               ? LocationService.getCommunesByDistrict(districtId)
//               : [];
//     });
//   }

//   void _onCommuneChanged(String? communeId) {
//     setState(() {
//       _selectedCommuneId = communeId;
//     });
//   }

//   Future<void> _checkConnection() async {
//     var results = await Connectivity().checkConnectivity();
//     setState(() {
//       _noInternet =
//           results.isEmpty || results.every((r) => r == ConnectivityResult.none);
//     });
//   }

//   String _getLabel(bool showFront, String locale) {
//     if (locale == "km") {
//       return showFront ? "រូបផ្នែកខាងមុខ" : "រូបផ្នែកខាងក្រោយ";
//     } else {
//       return showFront ? "Front Image" : "Back Image";
//     }
//   }

//   void _showImageDialog(BuildContext context, {required bool showFront}) {
//     File? imageToShow =
//         showFront ? _nationalIdFrontImage : _nationalIdBackImage;
//     String label = _getLabel(
//       showFront,
//       Localizations.localeOf(context).languageCode,
//     );

//     showDialog(
//       context: context,
//       barrierColor: Colors.black87, // darker background overlay
//       builder:
//           (_) => Dialog(
//             backgroundColor: Colors.transparent, // make dialog background clean
//             insetPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 12,
//             ),
//             child: Container(
//               height: 350,
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.5),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Stack(
//                 children: [
//                   // Image section
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 12.0),
//                         child: Text(
//                           label,
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 18,
//                             letterSpacing: 0.5,
//                             fontFamily: 'KhmerFont',
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       Expanded(
//                         child:
//                             imageToShow != null
//                                 ? ClipRRect(
//                                   child: Image.file(
//                                     imageToShow,
//                                     width: double.infinity,
//                                     fit: BoxFit.fitWidth,
//                                   ),
//                                 )
//                                 : const Center(
//                                   child: Text(
//                                     'Cannot load image',
//                                     style: TextStyle(color: Colors.redAccent),
//                                   ),
//                                 ),
//                       ),
//                     ],
//                   ),

//                   // Close button (top right)
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: InkWell(
//                       onTap: () => Navigator.of(context).pop(),
//                       child: Icon(Icons.close, color: Colors.white, size: 30),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     _phoneController.dispose();
//     _otpController.dispose();
//     _nameController.dispose(); // Add this line

//     _timer?.cancel();
//     super.dispose();
//   }

//   void _startTimer() {
//     setState(() {
//       _timing = true;
//       _secondsRemaining = 120;
//       _showResendBelow = false;
//     });
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_secondsRemaining == 0) {
//         setState(() {
//           _timing = false;
//           _showResendBelow = true;
//         });
//         timer.cancel();
//       } else {
//         setState(() {
//           _secondsRemaining--;
//         });
//       }
//     });
//   }

//   String validatePhone(String phone) {
//     // Remove any non-digit characters
//     return phone.replaceAll(RegExp(r'[^\d]'), '');
//   }

//   // Replace your current validateId function with this:
//   String validateId(String? id) {
//     // Ensure ID is not null or empty, use default value if null
//     return id?.isEmpty ?? true ? '1' : id!;
//   }

//   void _setButtonBlackTemporarily() {
//     setState(() {
//       _isBlackButton = true;
//     });
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         setState(() {
//           _isBlackButton = false;
//         });
//       }
//     });
//   }

//   Future<void> _onRequestOtp() async {
//     _setButtonBlackTemporarily();

//     setState(() {
//       _nameErrorText = null;
//       _phoneErrorText = null;
//       _provinceErrorText = null;
//       _districtErrorText = null;
//       _communeErrorText = null;
//       _nationalIdFrontErrorText = null;
//       _nationalIdBackErrorText = null;
//     });

//     bool hasError = false;

//     if (_nameController.text.trim().isEmpty) {
//       setState(() {
//         _nameErrorText = 'សូមបញ្ចូលឈ្មោះ';
//       });
//       hasError = true;
//     }

//     if (_phoneController.text.trim().isEmpty) {
//       setState(() {
//         _phoneErrorText = 'សូមបញ្ចូលលេខទូរស័ព្ទ';
//       });
//       hasError = true;
//     } else if (_phoneController.text.length < 8) {
//       setState(() {
//         _phoneErrorText = 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
//       });
//       hasError = true;
//     } else if (_phoneController.text.startsWith('0')) {
//       setState(() {
//         _phoneErrorText = 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
//       });
//       hasError = true;
//     }

//     if (_selectedProvinceId == null) {
//       setState(() {
//         _provinceErrorText = 'សូមជ្រើសរើសខេត្ត/ក្រុង';
//       });
//       hasError = true;
//     }
//     if (_selectedDistrictId == null) {
//       setState(() {
//         _districtErrorText = 'សូមជ្រើសរើសស្រុក/ខណ្ឌ';
//       });
//       hasError = true;
//     }
//     if (_selectedCommuneId == null) {
//       setState(() {
//         _communeErrorText = 'សូមជ្រើសរើសឃុំ/សង្កាត់';
//       });
//       hasError = true;
//     }
//     if (_nationalIdFrontImage == null) {
//       setState(() {
//         _nationalIdFrontErrorText = 'សូមបញ្ចូលរូបភាពស្នាមមុខអត្តសញ្ញាណ';
//       });
//       hasError = true;
//     }
//     if (_nationalIdBackImage == null) {
//       setState(() {
//         _nationalIdBackErrorText = 'សូមបញ្ចូលរូបភាពខាងក្រោយអត្តសញ្ញាណ';
//       });
//       hasError = true;
//     }

//     if (hasError) return;

//     // Your existing request OTP logic below (unchanged)
//     final phone = _countryCode + _phoneController.text.trim();
//     setState(() => _isLoading = true);

//     try {
//       final result = await ApiService.requestSignUpOtp(phone);
//       // final result = await ApiService.testSignUpWithExactValues();

//       if (result['success'] == true) {
//         setState(() {
//           _otpRequested = true;
//           _otpController.clear();
//           _secondsRemaining = 120;
//         });
//         _formKey.currentState?.validate();
//         _startTimer();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'OTP បានបញ្ជូន! សូមពិនិត្យទូរស័ព្ទរបស់អ្នក។',
//               style: TextStyle(fontSize: 16, fontFamily: 'KhmerFont'),
//               textAlign: TextAlign.center,
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 6),
//           ),
//         );
//       } else {
//         final message = result['message'] ?? 'មានបញ្ហា!';
//         final match = RegExp(r'(\d+)').firstMatch(message);
//         if (match != null) {
//           int waitSeconds = int.parse(match.group(1)!);
//           setState(() {
//             _secondsRemaining = waitSeconds;
//             _timing = true;
//           });
//           _startTimer();
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Center(
//               child: Text(
//                 message,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.white,
//                   fontFamily: 'KhmerFont',
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             backgroundColor: AppColors.primaryColor,
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'ការបញ្ជូន OTP បរាជ័យ',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontFamily: 'KhmerFont',
//             ),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Replace your current _onVerifyOtp method with this one
//   Future<void> _onVerifyOtp() async {
//     setState(() {
//       _phoneErrorText = null;
//       _isVerifyingOtp = true;
//     });

//     // Validate all form fields including location fields
//     bool isFieldsValid = _formKey.currentState?.validate() ?? false;
//     // Validate that both ID images are captured
//     if (_nationalIdFrontImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'សូមបញ្ចូលរូបភាពស្នាមមុខអត្តសញ្ញាណ',
//             style: TextStyle(
//               fontFamily: 'KhmerFont',
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       isFieldsValid = false;
//     }

//     if (_nationalIdBackImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'សូមបញ្ចូលរូបភាពខាងក្រោយអត្តសញ្ញាណ',
//             style: TextStyle(
//               fontFamily: 'KhmerFont',
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       isFieldsValid = false;
//     }
//     // Additional validation for location fields
//     if (_selectedProvinceId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'សូមជ្រើសរើសខេត្ត/ក្រុង',
//             style: TextStyle(
//               fontFamily: 'KhmerFont',
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       isFieldsValid = false;
//     }

//     if (_selectedDistrictId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'សូមជ្រើសរើសស្រុក/ខណ្ឌ',
//             style: TextStyle(
//               fontFamily: 'KhmerFont',
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       isFieldsValid = false;
//     }

//     if (_selectedCommuneId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'សូមជ្រើសរើសឃុំ/សង្កាត់',
//             style: TextStyle(
//               fontFamily: 'KhmerFont',
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       isFieldsValid = false;
//     }

//     if (_phoneController.text.trim().isEmpty) {
//       setState(() {
//         _phoneErrorText = 'សូមបញ្ចូលលេខទូរស័ព្ទ';
//       });
//       isFieldsValid = false;
//     } else if (_phoneController.text.length < 8) {
//       setState(() {
//         _phoneErrorText = 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
//       });
//       isFieldsValid = false;
//     } else if (_phoneController.text.startsWith('0')) {
//       setState(() {
//         _phoneErrorText = 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
//       });
//       isFieldsValid = false;
//     }

//     if (isFieldsValid) {
//       setState(() => _isLoading = true);
//       try {
//         // Validate that all location fields are selected
//         if (_selectedProvinceId == null ||
//             _selectedDistrictId == null ||
//             _selectedCommuneId == null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'សូមជ្រើសរើសទីតាំងឲ្យបានពេញលេញ',
//                 style: TextStyle(
//                   fontFamily: 'KhmerFont',
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//           setState(() => _isLoading = false);
//           return;
//         }

//         // In your _onVerifyOtp method, update the signup call:
//         final validatedPhone = validatePhone(
//           _countryCode + _phoneController.text.trim(),
//         );
//         final validatedDistrict = validateId(_selectedDistrictId);
//         final validatedCommune = validateId(_selectedCommuneId);
//         final validatedVillage = validateId(_selectedVillageId);
//         // Get device UUID and FCM token
//         final deviceUuid = await DeviceUUID.getUUID();
//         // final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
//         String? fcmToken = await _messaging.getToken();

//         // ⬇️ Try fallback if null
//         if (fcmToken == null) {
//           // Make sure APNs is linked to FCM
//           String? apnsToken = await _messaging.getAPNSToken();
//           print('📱 APNs Token: $apnsToken');

//           fcmToken = await _messaging.getToken();
//         }

//         if (fcmToken == null) {
//           print('❌ Still no FCM token, continue without sending to backend.');
//         } else {
//           print('🔥 Got FCM token: $fcmToken');
//         }

//         final signupResult = await ApiService.signUp(
//           name: _nameController.text.trim(),
//           phone: validatedPhone,
//           otp: _otpController.text.trim(),
//           provinceId: _selectedProvinceId!, // Pass numeric ID directly
//           district: validatedDistrict,
//           commune: validatedCommune,
//           village: validatedVillage,
//           deviceUuid: deviceUuid, // Add device UUID
//           fcmToken: fcmToken!, // Add FCM token
//         );
//         if (signupResult['success'] == true && signupResult['data'] != null) {
//           final token =
//               signupResult['data']['authToken']; // Changed from 'token' to 'authToken'
//           print('🔐 SIGNUP SUCCESSFUL TOKEN: $token');

//           // Upload identity documents
//           setState(() => _isUploadingDocuments = true);

//           final uploadResult = await ApiService.uploadIdentityDocuments(
//             token: token,
//             nationalIdFront: _nationalIdFrontImage!,
//             nationalIdBack: _nationalIdBackImage!,
//           );

//           setState(() {
//             _nationalIdFrontUploaded = uploadResult['success'] == true;
//             _nationalIdBackUploaded = uploadResult['success'] == true;
//             // do not show any snackbar/message for upload success
//           });
//           // ignore: unused_local_variable
//           final userProfile = await ApiService.getUserProfile(token);

//           // ignore: unnecessary_null_comparison
//           if (token != null) {
//             final userProfile = await ApiService.getUserProfile(token);

//             // ignore: unnecessary_null_comparison
//             if (userProfile != null && userProfile['success'] == true) {
//               final data = userProfile['data'];
//               final prefs = await SharedPreferences.getInstance();

//               // Save user data
//               await prefs.setString('userDetailData', jsonEncode(data));
//               await prefs.setString('token', token);
//               await prefs.setString('phoneNumber', data['phone_number'] ?? '');
//               await prefs.setString('userId', data['id'].toString());
//               // ✅ ADD THIS LINE - Send FCM token to backend
//               await FirebaseService.sendFcmTokenToBackend(apiToken: token);

//               await prefs.setBool('isLoggedIn', true);
//               await prefs.setString(
//                 'user_data',
//                 jsonEncode(userProfile),
//               ); // NEW LINE

//               // Save user status (NEW - check status instead of passcode)
//               final userStatus = data['status'] ?? 1;
//               await prefs.setBool('isUserApproved', userStatus == 1);
//               print(
//                 '🔐 USER STATUS: $userStatus (Approved: ${userStatus == 1})',
//               );
//               // Save passcode status
//               final hasPasscode =
//                   (data['passcode_hash'] != null &&
//                       data['passcode_hash'].toString().isNotEmpty) ||
//                   (data['passcode'] != null &&
//                       data['passcode'].toString().isNotEmpty);
//               await prefs.setBool('hasPasscode', hasPasscode);

//               // Save QR payload
//               final qrPayload = data['signature'];
//               await prefs.setString('qrPayload', qrPayload);

//               _showSuccessDialog();
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                     'មិនអាចយកព័ត៌មានអ្នកប្រើបានទេ',
//                     style: TextStyle(
//                       fontFamily: 'KhmerFont',
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           } else {
//             _showSuccessDialog();
//           }
//         } else {
//           // Improved error handling
//           final message = signupResult['message'] ?? 'ការចុះឈ្មោះមិនជោគជ័យ';
//           final errors = signupResult['errors'] ?? {};

//           print('❌ SIGNUP FAILED: $message');
//           print('❌ ERRORS: $errors');

//           // Show specific error messages if available
//           String errorMessage = message;
//           if (errors.isNotEmpty) {
//             final firstError = errors.values.first;
//             if (firstError is List && firstError.isNotEmpty) {
//               errorMessage = firstError.first;
//             }
//           }

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'ការចុះឈ្មោះមិនជោគជ័យ',
//               style: TextStyle(
//                 fontFamily: 'KhmerFont',
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }

//     setState(() {
//       _isVerifyingOtp = false;
//     });
//   }

//   void _showSuccessDialog() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             backgroundColor: Colors.white,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 45),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.green[100],
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.check_circle,
//                       color: Colors.green[600],
//                       size: 60,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   const Text(
//                     'បង្កើតគណនីជោគជ័យ !',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                       fontFamily: 'KhmerFont',
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );

//     await Future.delayed(const Duration(seconds: 2));
//     if (Navigator.of(context, rootNavigator: true).canPop()) {
//       Navigator.of(context, rootNavigator: true).pop();
//     }
//     // Ensure all writes are done before navigating!
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.reload();
//     // Replace RomlousApp with your home page
//     Navigator.of(
//       context,
//     ).pushReplacement(MaterialPageRoute(builder: (context) => WelcomeScreen()));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Scaffold(
//           backgroundColor: AppColors.primaryColor,
//           body: SafeArea(
//             child: LayoutBuilder(
//               builder:
//                   (context, constraints) => SingleChildScrollView(
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(
//                         minHeight: constraints.maxHeight,
//                       ),
//                       child: IntrinsicHeight(
//                         child: Column(
//                           children: <Widget>[
//                             const SizedBox(height: 20),
//                             CircleAvatar(
//                               backgroundColor: AppColors.primaryColor,
//                               radius: 80,
//                               child: Image.asset(
//                                 'assets/images/logo.png',
//                                 width: 300,
//                                 height: 300,
//                               ),
//                             ),
//                             const SizedBox(height: 30),
//                             Expanded(
//                               child: Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 20,
//                                   vertical: 20,
//                                 ),
//                                 decoration: const BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.only(
//                                     topLeft: Radius.circular(40),
//                                     topRight: Radius.circular(40),
//                                   ),
//                                 ),
//                                 child: Form(
//                                   key: _formKey,
//                                   autovalidateMode: AutovalidateMode.disabled,
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                     children: [
//                                       const SizedBox(height: 20),
//                                       Row(
//                                         children: [
//                                           IconButton(
//                                             icon: Icon(
//                                               Icons.arrow_back_ios,
//                                               size: 25,
//                                               color: Colors.grey,
//                                             ),
//                                             onPressed: () {
//                                               Navigator.of(context).pop();
//                                             },
//                                           ),
//                                           const SizedBox(width: 8),
//                                           Align(
//                                             alignment: Alignment.centerLeft,
//                                             child: const Text(
//                                               'បង្កើតគណនីរបស់អ្នក',
//                                               style: TextStyle(
//                                                 fontSize: 24,
//                                                 color: Colors.black,
//                                                 fontFamily: 'KhmerFont',
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 30),
//                                       // 1. Full Name field
//                                       TextFormField(
//                                         controller: _nameController,
//                                         decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           hintText: 'បញ្ចូលឈ្មោះពេញ',
//                                           prefixIcon: Icon(
//                                             Icons.person_outline,
//                                             color: Colors.grey[600],
//                                           ),
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding: EdgeInsets.symmetric(
//                                             vertical: 16,
//                                           ),
//                                           errorText: _nameErrorText,
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 14,
//                                             fontWeight:
//                                                 FontWeight
//                                                     .w500, // ✅ makes it bold
//                                             color: Colors.red,
//                                           ),
//                                         ),

//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontFamily: 'KhmerFont',
//                                         ),
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'សូមបញ្ចូលឈ្មោះ';
//                                           }
//                                           return null;
//                                         },
//                                       ),
//                                       const SizedBox(height: 12),

//                                       IntlPhoneField(
//                                         controller: _phoneController,
//                                         decoration: InputDecoration(
//                                           hintText:
//                                               '(0) សូមបញ្ចូលលេខទូរស័ព្ទអ្នក',
//                                           hintStyle: TextStyle(
//                                             color: Colors.grey[600],
//                                             fontSize: 16,
//                                             fontFamily: 'KhmerFont',
//                                           ),
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding:
//                                               const EdgeInsets.symmetric(
//                                                 vertical: 16,
//                                               ),
//                                           errorText: _phoneErrorText,
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 14,
//                                             fontWeight:
//                                                 FontWeight
//                                                     .w500, // ✅ makes it bold
//                                             color: Colors.red,
//                                           ),
//                                         ),
//                                         initialCountryCode: 'KH',
//                                         disableLengthCheck: true,
//                                         validator: (phone) {
//                                           if (phone != null &&
//                                               phone.number.startsWith('0')) {
//                                             return 'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
//                                           }
//                                           return null;
//                                         },
//                                         onChanged: (phone) {
//                                           if (phone.number.startsWith('0')) {
//                                             WidgetsBinding.instance
//                                                 .addPostFrameCallback((_) {
//                                                   _phoneController.text = phone
//                                                       .number
//                                                       .replaceFirst(
//                                                         RegExp(r'^0+'),
//                                                         '',
//                                                       );
//                                                   _phoneController.selection =
//                                                       TextSelection.fromPosition(
//                                                         TextPosition(
//                                                           offset:
//                                                               _phoneController
//                                                                   .text
//                                                                   .length,
//                                                         ),
//                                                       );
//                                                 });
//                                             setState(() {
//                                               _phoneErrorText =
//                                                   'លេខទូរស័ព្ទមិនអាចចាប់ផ្តើមដោយ 0';
//                                             });
//                                           } else if (_phoneErrorText != null) {
//                                             setState(() {
//                                               _phoneErrorText = null;
//                                             });
//                                           }
//                                         },
//                                         onCountryChanged: (country) {
//                                           setState(() {
//                                             _countryCode = country.dialCode;
//                                             _phoneController.clear();
//                                           });
//                                         },
//                                       ),

//                                       const SizedBox(height: 12),

//                                       // 2. Four dropdown fields for location (simplified example, you need to provide the list and logic)
//                                       DropdownButtonFormField<String>(
//                                         dropdownColor: Colors.white,
//                                         decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           prefixIcon: Icon(
//                                             Icons.location_on,
//                                             color: Colors.grey[600],
//                                           ),
//                                           errorText: _provinceErrorText,
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 16,
//                                             fontWeight:
//                                                 FontWeight
//                                                     .w500, // ✅ makes it bold
//                                             color: Colors.red,
//                                           ),
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding: EdgeInsets.symmetric(
//                                             vertical: 18,
//                                             horizontal: 10,
//                                           ),
//                                         ),
//                                         hint: Text(
//                                           'ខេត្ត/ក្រុង',
//                                           style: TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                           ),
//                                         ),
//                                         value: _selectedProvinceId,
//                                         items:
//                                             _provinces.map((province) {
//                                               // Safely extract the province ID
//                                               String provinceId =
//                                                   (province['id']?.toString() ??
//                                                           province['numeric_id']
//                                                               ?.toString() ??
//                                                           '')
//                                                       .toString();

//                                               return DropdownMenuItem<String>(
//                                                 value: provinceId,
//                                                 child: Text(
//                                                   province['name_kh'] ??
//                                                       province['name_en'] ??
//                                                       'Unknown',
//                                                   style: TextStyle(
//                                                     fontFamily: 'KhmerFont',
//                                                   ),
//                                                 ),
//                                               );
//                                             }).toList(),
//                                         onChanged: _onProvinceChanged,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'សូមជ្រើសរើសខេត្ត/ក្រុង';
//                                           }
//                                           return null;
//                                         },
//                                       ),
//                                       SizedBox(height: 12),
//                                       // District dropdown
//                                       DropdownButtonFormField<String>(
//                                         dropdownColor: Colors.white,
//                                         decoration: InputDecoration(
//                                           errorText: _districtErrorText,
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 16,
//                                             fontWeight:
//                                                 FontWeight
//                                                     .w500, // ✅ makes it bold
//                                             color: Colors.red,
//                                           ),
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           prefixIcon: Icon(
//                                             Icons.location_on,
//                                             color: Colors.grey[600],
//                                           ),
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding: EdgeInsets.symmetric(
//                                             vertical: 18,
//                                             horizontal: 10,
//                                           ),
//                                         ),
//                                         hint: Text(
//                                           'ស្រុក/ខណ្ឌ',
//                                           style: TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                           ),
//                                         ),
//                                         value: _selectedDistrictId,
//                                         items:
//                                             _districts.map((district) {
//                                               return DropdownMenuItem<String>(
//                                                 value:
//                                                     district['geocode']
//                                                         ?.toString(), // Ensure string value
//                                                 child: Text(
//                                                   district['name_kh'] ??
//                                                       district['name_en'] ??
//                                                       'Unknown',
//                                                   style: TextStyle(
//                                                     fontFamily: 'KhmerFont',
//                                                   ),
//                                                 ),
//                                               );
//                                             }).toList(),
//                                         onChanged:
//                                             _selectedProvinceId != null
//                                                 ? _onDistrictChanged
//                                                 : null,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'សូមជ្រើសរើសស្រុក/ខណ្ឌ';
//                                           }
//                                           return null;
//                                         },
//                                       ),
//                                       const SizedBox(height: 12),
//                                       // Commune dropdown
//                                       DropdownButtonFormField<String>(
//                                         dropdownColor: Colors.white,
//                                         decoration: InputDecoration(
//                                           errorText: _communeErrorText,
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 16,
//                                             fontWeight:
//                                                 FontWeight
//                                                     .w500, // ✅ makes it bold
//                                             color: Colors.red,
//                                           ),
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           prefixIcon: Icon(
//                                             Icons.location_on,
//                                             color: Colors.grey[600],
//                                           ),
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding: EdgeInsets.symmetric(
//                                             vertical: 18,
//                                             horizontal: 10,
//                                           ),
//                                         ),
//                                         hint: Text(
//                                           'ឃុំ/សង្កាត់',
//                                           style: TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                           ),
//                                         ),
//                                         value: _selectedCommuneId,
//                                         items:
//                                             _communes.map((commune) {
//                                               return DropdownMenuItem<String>(
//                                                 value:
//                                                     commune['geocode']
//                                                         ?.toString(), // Ensure string value
//                                                 child: Text(
//                                                   commune['name_kh'] ??
//                                                       commune['name_en'] ??
//                                                       'Unknown',
//                                                   style: TextStyle(
//                                                     fontFamily: 'KhmerFont',
//                                                   ),
//                                                 ),
//                                               );
//                                             }).toList(),
//                                         onChanged:
//                                             _selectedDistrictId != null
//                                                 ? _onCommuneChanged
//                                                 : null,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'សូមជ្រើសរើសឃុំ/សង្កាត់';
//                                           }
//                                           return null;
//                                         },
//                                       ),
//                                       SizedBox(height: 12),
//                                       TextFormField(
//                                         decoration: InputDecoration(
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           prefixIcon: Icon(
//                                             Icons.location_on,
//                                             color: Colors.grey[600],
//                                           ),
//                                           hintText:
//                                               'ភូមិ (អាចមិនបំពេញបាន)', // Village (optional)
//                                           hintStyle: TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                           ),
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding: EdgeInsets.symmetric(
//                                             vertical: 18,
//                                             horizontal: 10,
//                                           ),
//                                           errorText: _villageErrorText,
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.red,
//                                           ),
//                                         ),
//                                         style: TextStyle(
//                                           fontFamily: 'KhmerFont',
//                                         ),
//                                         onChanged: (value) {
//                                           setState(() {
//                                             _selectedVillageId =
//                                                 value; // or use a new variable if you want
//                                             _villageErrorText = null;
//                                           });
//                                         },
//                                         validator: (value) {
//                                           // Optional: allow empty input
//                                           return null;
//                                         },
//                                       ),
//                                       const SizedBox(height: 12),
//                                       // 3. Two image upload fields
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: InkWell(
//                                               onTap:
//                                                   (_nationalIdFrontImage !=
//                                                           null)
//                                                       ? () => _showImageDialog(
//                                                         context,
//                                                         showFront: true,
//                                                       )
//                                                       : null,
//                                               child: InputDecorator(
//                                                 decoration: InputDecoration(
//                                                   errorText:
//                                                       _nationalIdFrontErrorText,
//                                                   errorStyle: const TextStyle(
//                                                     fontFamily: 'KhmerFont',
//                                                     fontSize: 16,
//                                                     fontWeight: FontWeight.w500,
//                                                     color: Colors.red,
//                                                   ),
//                                                   filled: true,
//                                                   fillColor: Colors.grey[200],
//                                                   border: OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           10,
//                                                         ),
//                                                     borderSide:
//                                                         _nationalIdFrontUploaded
//                                                             ? const BorderSide(
//                                                               color:
//                                                                   Colors.green,
//                                                               width: 2,
//                                                             )
//                                                             : BorderSide.none,
//                                                   ),
//                                                   contentPadding:
//                                                       const EdgeInsets.fromLTRB(
//                                                         20,
//                                                         16,
//                                                         12,
//                                                         16,
//                                                       ),
//                                                   suffixIcon: IconButton(
//                                                     icon: Icon(
//                                                       Icons.camera_alt_outlined,
//                                                       color: Colors.grey[600],
//                                                     ),
//                                                     onPressed: () async {
//                                                       final imageFile =
//                                                           await Navigator.push(
//                                                             context,
//                                                             MaterialPageRoute(
//                                                               builder:
//                                                                   (_) =>
//                                                                       const OpenCameraIdentity(
//                                                                         isFront:
//                                                                             true,
//                                                                       ),
//                                                             ),
//                                                           );
//                                                       if (imageFile != null &&
//                                                           imageFile is File) {
//                                                         setState(() {
//                                                           _nationalIdFrontImage =
//                                                               imageFile;
//                                                         });
//                                                       }
//                                                     },
//                                                   ),
//                                                 ),
//                                                 child: Align(
//                                                   alignment:
//                                                       Alignment.centerLeft,
//                                                   child: Text(
//                                                     _nationalIdFrontImage !=
//                                                             null
//                                                         ? _nationalIdFrontImage!
//                                                             .path
//                                                             .split('/')
//                                                             .last
//                                                         : 'បញ្ជូលរូបភាពស្នាមមុខអត្តសញ្ញាណ',
//                                                     style: TextStyle(
//                                                       color:
//                                                           _nationalIdFrontImage !=
//                                                                   null
//                                                               ? Colors.blue
//                                                               : Colors
//                                                                   .grey[600],
//                                                       fontFamily: 'KhmerFont',
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     ),
//                                                     maxLines: 1,
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           SizedBox(width: 10),
//                                           Expanded(
//                                             child: InkWell(
//                                               onTap:
//                                                   (_nationalIdBackImage != null)
//                                                       ? () => _showImageDialog(
//                                                         context,
//                                                         showFront: false,
//                                                       )
//                                                       : null,
//                                               child: InputDecorator(
//                                                 decoration: InputDecoration(
//                                                   errorText:
//                                                       _nationalIdBackErrorText,
//                                                   errorStyle: const TextStyle(
//                                                     fontFamily: 'KhmerFont',
//                                                     fontSize: 16,
//                                                     fontWeight: FontWeight.w500,
//                                                     color: Colors.red,
//                                                   ),
//                                                   filled: true,
//                                                   fillColor: Colors.grey[200],
//                                                   border: OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           10,
//                                                         ),
//                                                     borderSide:
//                                                         _nationalIdBackUploaded
//                                                             ? const BorderSide(
//                                                               color:
//                                                                   Colors.green,
//                                                               width: 2,
//                                                             )
//                                                             : BorderSide.none,
//                                                   ),
//                                                   contentPadding:
//                                                       const EdgeInsets.fromLTRB(
//                                                         20,
//                                                         16,
//                                                         12,
//                                                         16,
//                                                       ),
//                                                   suffixIcon: IconButton(
//                                                     icon: Icon(
//                                                       Icons.camera_alt_outlined,
//                                                       color: Colors.grey[600],
//                                                     ),
//                                                     onPressed: () async {
//                                                       final imageFile =
//                                                           await Navigator.push(
//                                                             context,
//                                                             MaterialPageRoute(
//                                                               builder:
//                                                                   (
//                                                                     _,
//                                                                   ) => const OpenCameraIdentity(
//                                                                     isFront:
//                                                                         false,
//                                                                   ),
//                                                             ),
//                                                           );
//                                                       if (imageFile != null &&
//                                                           imageFile is File) {
//                                                         setState(() {
//                                                           _nationalIdBackImage =
//                                                               imageFile;
//                                                         });
//                                                       }
//                                                     },
//                                                   ),
//                                                 ),
//                                                 child: Align(
//                                                   alignment:
//                                                       Alignment.centerLeft,
//                                                   child: Text(
//                                                     _nationalIdBackImage != null
//                                                         ? _nationalIdBackImage!
//                                                             .path
//                                                             .split('/')
//                                                             .last
//                                                         : 'បញ្ជូលរូបភាពខាងក្រោយអត្តសញ្ញាណ',
//                                                     style: TextStyle(
//                                                       color:
//                                                           _nationalIdFrontImage !=
//                                                                   null
//                                                               ? Colors.blue
//                                                               : Colors
//                                                                   .grey[600],
//                                                       fontFamily: 'KhmerFont',
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     ),
//                                                     maxLines: 1,
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 12),
//                                       TextFormField(
//                                         controller: _otpController,
//                                         keyboardType: TextInputType.number,
//                                         maxLength: 4,
//                                         decoration: InputDecoration(
//                                           hintText: 'សូមចុចលើប៊ូតុងយកកូដ ​OTP',
//                                           hintStyle: TextStyle(
//                                             color: Colors.grey[600],
//                                             fontSize: 16,
//                                             fontFamily: 'KhmerFont',
//                                           ),
//                                           counterText: '',
//                                           filled: true,
//                                           fillColor: Colors.grey[200],
//                                           border: OutlineInputBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             borderSide: BorderSide.none,
//                                           ),
//                                           contentPadding:
//                                               const EdgeInsets.symmetric(
//                                                 vertical: 16,
//                                               ),
//                                           prefixIcon: Icon(
//                                             Icons.sms,
//                                             color: Colors.grey[600],
//                                           ),
//                                           errorStyle: const TextStyle(
//                                             fontFamily: 'KhmerFont',
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.red,
//                                           ),
//                                           // ✅ show countdown in OTP field
//                                           suffixIcon:
//                                               (_otpRequested && _timing)
//                                                   ? Padding(
//                                                     padding:
//                                                         const EdgeInsets.only(
//                                                           right: 12,
//                                                           top: 13,
//                                                         ),
//                                                     child: Text(
//                                                       '$_secondsRemaining វិនាទី',
//                                                       style: const TextStyle(
//                                                         color:
//                                                             AppColors
//                                                                 .primaryColor,
//                                                         fontSize: 14,
//                                                         fontWeight:
//                                                             FontWeight.w600,
//                                                         fontFamily: 'KhmerFont',
//                                                       ),
//                                                     ),
//                                                   )
//                                                   : null,
//                                         ),
//                                         style: const TextStyle(
//                                           fontSize: 18,
//                                           color: Colors.black,
//                                         ),
//                                         validator: (value) {
//                                           if (_isVerifyingOtp) {
//                                             if (!_otpRequested)
//                                               return 'សូមចុច "យកកូដ OTP" ជាមុនសិន';
//                                             if (value == null ||
//                                                 value.isEmpty) {
//                                               return 'សូមបញ្ចូលលេខកូដ OTP';
//                                             } else if (value.length != 4) {
//                                               return 'លេខកូដ OTP ត្រូវមានចំនួន 4 ខ្ទង់';
//                                             }
//                                           }
//                                           return null;
//                                         },
//                                       ),

//                                       const SizedBox(height: 16),
//                                       if (_showResendBelow)
//                                         Padding(
//                                           padding: const EdgeInsets.only(
//                                             top: 10,
//                                           ),
//                                           child: Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: const [
//                                               Text(
//                                                 'មិនទទួលបានកូដមែន​ទេ ?​ សូមចុចម្តងទៀត',
//                                                 style: TextStyle(
//                                                   color: AppColors.primaryColor,
//                                                   fontWeight: FontWeight.w600,
//                                                   fontFamily: 'KhmerFont',
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       const SizedBox(height: 20),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         child: ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 _isBlackButton
//                                                     ? Colors.black
//                                                     : AppColors.primaryColor,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                             padding: const EdgeInsets.symmetric(
//                                               vertical: 16,
//                                             ),
//                                             elevation: 2,
//                                             textStyle: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 20,
//                                             ),
//                                           ),
//                                           onPressed:
//                                               _isLoading
//                                                   ? null
//                                                   : (!_otpRequested ||
//                                                           _showResendBelow
//                                                       ? _onRequestOtp
//                                                       : _onVerifyOtp),
//                                           child:
//                                               _isLoading
//                                                   ? const CircularProgressIndicator(
//                                                     color: Colors.white,
//                                                   )
//                                                   : _isUploadingDocuments
//                                                   ? Column(
//                                                     mainAxisSize:
//                                                         MainAxisSize.min,
//                                                     children: const [
//                                                       CircularProgressIndicator(
//                                                         color: Colors.white,
//                                                       ),
//                                                       SizedBox(height: 4),
//                                                       Text(
//                                                         'កំពុងផ្ទុកឯកសារ...',
//                                                         style: TextStyle(
//                                                           color: Colors.white,
//                                                           fontSize: 12,
//                                                           fontFamily:
//                                                               'KhmerFont',
//                                                           fontWeight:
//                                                               FontWeight.w600,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   )
//                                                   : Text(
//                                                     (!_otpRequested ||
//                                                             _showResendBelow)
//                                                         ? 'យកកូដ OTP'
//                                                         : 'បញ្ជាក់ OTP',
//                                                     style: const TextStyle(
//                                                       color: Colors.white,
//                                                       fontFamily: 'KhmerFont',
//                                                     ),
//                                                   ),
//                                         ),
//                                       ),

//                                       const SizedBox(height: 20),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//             ),
//           ),
//         ),
//         if (_noInternet)
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               color: Colors.red[600],
//               padding: const EdgeInsets.symmetric(vertical: 26),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Icon(Icons.wifi_off, color: Colors.white, size: 20),
//                   SizedBox(width: 8),
//                   Text(
//                     "មិនមានការតភ្ជាប់អ៊ីនធឺណិត",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'KhmerFont',
//                       decoration: TextDecoration.none,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// //Correct with 1688 line code changes
