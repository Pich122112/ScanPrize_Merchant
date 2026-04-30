import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';

class CustomPasscodeDialog extends StatefulWidget {
  final String subtitle;
  final int digits;
  final int maxAttempts;
  final int remainingAttempts;
  final Future<bool> Function(String code)? onValidate;

  const CustomPasscodeDialog({
    super.key,
    this.subtitle = 'បញ្ចូលលេខសម្ងាត់ របស់អ្នកដើម្បីបន្ត',
    this.digits = 4,
    this.maxAttempts = 3,
    this.remainingAttempts = 3,
    this.onValidate,
  });

  @override
  State<CustomPasscodeDialog> createState() => _CustomPasscodeDialogState();
}

class _CustomPasscodeDialogState extends State<CustomPasscodeDialog> {
  final List<String> _input = [];
  String? _errorMessage;
  // ignore: unused_field
  bool _isVerifying = false;
  int _remainingAttempts = 3;
  int _currentSessionAttempts = 0;

  @override
  void initState() {
    super.initState();
    _remainingAttempts = widget.remainingAttempts;

    if (_remainingAttempts == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _errorMessage = "passcode.wrong_passcode_once".tr();
        });
      });
    }
  }

  Future<void> _onPressed(String value) async {
    if (value == 'C') {
      setState(() {
        _input.clear();
        _errorMessage = null;
      });
    } else if (value == 'DEL') {
      if (_input.isNotEmpty) {
        setState(() {
          _input.removeLast();
        });
      }
    } else {
      if (_input.length < widget.digits) {
        setState(() {
          _input.add(value);
          _errorMessage = null;
        });
        if (_input.length == widget.digits) {
          if (widget.onValidate != null) {
            setState(() => _isVerifying = true);
            final valid = await widget.onValidate!(_input.join());
            setState(() => _isVerifying = false);

            if (valid) {
              Navigator.of(context).pop(_input.join());
            } else {
              _currentSessionAttempts++;
              if (widget.remainingAttempts == 1) {
                Navigator.of(context).pop('max_attempts_reached');
              } else {
                _remainingAttempts =
                    widget.remainingAttempts - _currentSessionAttempts;

                if (_remainingAttempts <= 0) {
                  Navigator.of(context).pop('max_attempts_reached');
                } else {
                  if (_remainingAttempts == 1) {
                    _errorMessage = "passcode.wrong_passcode_once".tr();
                  } else {
                    _errorMessage = "passcode.wrong_passcode".tr(
                      namedArgs: {"count": _remainingAttempts.toString()},
                    );
                  }
                  _input.clear();
                  setState(() {});
                }
              }
            }
          } else {
            Navigator.of(context).pop(_input.join());
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.black54, Colors.black87],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // iOS-like bounce
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Top Section: Cancel Button
                      SizedBox(height: 20),

                      Align(
                        alignment: Alignment.topLeft,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            "cancle".tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              fontFamily:
                                  localeCode == 'km' ? 'KhmerFont' : null,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Middle Section: Lock Icon, Subtitle, and Input Indicators
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height:
                                constraints.maxHeight *
                                0.12, // scales with screen height
                            child: CircleAvatar(
                              radius:
                                  constraints.maxWidth * 0.12, // dynamic radius
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size:
                                    constraints.maxWidth *
                                    0.1, // icon size scales
                              ),
                            ),
                          ),

                          SizedBox(height: 20), // instead of 15

                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              fontFamily:
                                  localeCode == 'km' ? 'KhmerFont' : null,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 15),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'KhmerFont',
                              ),
                            ),
                          ],
                          SizedBox(height: 30), // instead of 30

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(widget.digits, (i) {
                              return Container(
                                width: 26, // or whatever fixed size you prefer
                                height: 26,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _input.length > i
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),

                          SizedBox(
                            height: 42,
                          ), // or another fixed value you prefer
                          _buildKeypad(),
                        ],
                      ),
                      // Bottom Section: Keypad
                      // _buildKeypad(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', 'DEL'],
    ];
    return Column(
      children:
          keys.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    row.map((key) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _buildKey(key),
                      );
                    }).toList(),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isNumber = RegExp(r'^[0-9]$').hasMatch(key);
    final isClear = key == 'C';
    final isDel = key == 'DEL';
    IconData? icon;
    if (isDel) icon = Icons.backspace;

    final buttonSize = 75.0;

    return GestureDetector(
      onTap: () => _onPressed(key),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isNumber ? Colors.white.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color:
                isClear || isDel
                    ? AppColors.primaryColor
                    : Colors.white.withOpacity(0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child:
              isNumber
                  ? Text(
                    key,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  : isClear
                  ? Text(
                    "C",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : Icon(icon, color: AppColors.primaryColor, size: 33),
        ),
      ),
    );
  }
}

//Correct with 330 line code changes
