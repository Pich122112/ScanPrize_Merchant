import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../utils/constants.dart';
import '../app/bottomAppbar.dart';
import '../services/user_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _apiService = ApiService();

  String _countryCode = '855'; // Default to Cambodia
  String? _phoneErrorText;
  bool _timing = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _otpRequested = false;
  bool _showResendBelow = false;
  bool _isLoading = false;

  void _startTimer() {
    setState(() {
      _timing = true;
      _secondsRemaining = 30;
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

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onRequestOtp() {
    setState(() {
      _otpRequested = true;
      _showResendBelow = false;
    });
    _startTimer();
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
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
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
    await prefs.reload(); // Make sure data is flushed
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) =>
                RomlousApp(phoneNumber: _countryCode + _phoneController.text),
      ),
    );
  }

  Future<void> _onSubmit() async {
    setState(() {
      _phoneErrorText = null;
    });

    bool isFieldsValid = _formKey.currentState?.validate() ?? false;

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

    if (isFieldsValid && (!_otpRequested || _showResendBelow)) {
      _onRequestOtp();
      return;
    }

    if (isFieldsValid) {
      final otpError =
          !_otpRequested
              ? null
              : (_otpController.text.isEmpty
                  ? 'សូមបញ្ចូលលេខកូដ OTP'
                  : (_otpController.text.length != 4
                      ? 'លេខកូដ OTP ត្រូវមានចំនួន 4 ខ្ទង់'
                      : null));
      if (otpError == null) {
        setState(() => _isLoading = true);
        try {
          final phone = _countryCode + _phoneController.text; // No '+'
          final data = await _apiService.signupWithPhone(
            phone,
          ); // Only call ONCE
          if (data != null && data['user'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true); // <-- Add this line
            await prefs.setString('token', data['token']); // ✅ Save token here
            print("💾 Saved token: ${data['token']}");
            await prefs.setString('userId', data['user']['userId'].toString());
            await prefs.setString('phoneNumber', data['user']['phoneNumber']);
            await prefs.setString('userName', data['user']['fullName'] ?? '');
            await prefs.setString(
              'qrGanzbergPayload',
              data['qrGanzbergPayload'] ?? '',
            );
            await prefs.setString('qrIdolPayload', data['qrIdolPayload'] ?? '');
            await prefs.setString(
              'qrBoostrongPayload',
              data['qrBoostrongPayload'] ?? '',
            );
            _showSuccessDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot fetch user info after register'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បញ្ចូលទិន្នន័យបរាជ័យ'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      } else {
        FocusScope.of(context).requestFocus(FocusNode());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(otpError), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget otpSuffix;
    if (_otpRequested && _timing) {
      otpSuffix = Text(
        '$_secondsRemaining វិនាទី',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      otpSuffix = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 50),
                        CircleAvatar(
                          backgroundColor: AppColors.primaryColor,
                          radius: 80,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 300,
                            height: 300,
                          ),
                        ),
                        const SizedBox(height: 40),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Text(
                                      'បង្កើតគណនីរបស់អ្នក',
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                  IntlPhoneField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      hintText: '(0) សូមបញ្ចូលលេខទូរស័ព្ទអ្នក',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                      errorText: _phoneErrorText,
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
                                      hintText: 'ចុចប៊ូតុងដើម្បីទទួល OTP',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.grey[200],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                                      suffix: SizedBox(
                                        width: 90,
                                        child: Center(child: otpSuffix),
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    validator: (value) {
                                      if (!_otpRequested) return null;
                                      if (value == null || value.isEmpty) {
                                        return 'សូមបញ្ចូលលេខកូដ OTP';
                                      } else if (value.length != 4) {
                                        return 'លេខកូដ OTP ត្រូវមានចំនួន 4 ខ្ទង់';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_showResendBelow)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'មិនទទួលបានកូដមែន​ទេ ?​ ចុចម្តងទៀត',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w600,
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
                                        backgroundColor: AppColors.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                              : (_showResendBelow
                                                  ? _onRequestOtp
                                                  : _onSubmit),
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
    );
  }
}

//Correct with 470 line code changes
