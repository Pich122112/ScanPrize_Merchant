// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:gb_merchant/utils/constants.dart';

// class CustomPasscodeDialog extends StatefulWidget {
//   final String subtitle;
//   final int digits;
//   final void Function(String code)? onCompleted;
//   final String? errorMessage;

//   const CustomPasscodeDialog({
//     Key? key,
//     this.subtitle = 'បញ្ចូលលេខសម្ងាត់ របស់អ្នកដើម្បីបន្ត',
//     this.digits = 4,
//     this.onCompleted,
//     this.errorMessage,
//   }) : super(key: key);

//   @override
//   State<CustomPasscodeDialog> createState() => _CustomPasscodeDialogState();
// }

// class _CustomPasscodeDialogState extends State<CustomPasscodeDialog> {
//   List<String> _input = [];

//   void _onPressed(String value) {
//     if (value == 'C') {
//       setState(() {
//         _input.clear();
//       });
//     } else if (value == 'DEL') {
//       if (_input.isNotEmpty) {
//         setState(() {
//           _input.removeLast();
//         });
//       }
//     } else {
//       if (_input.length < widget.digits) {
//         setState(() {
//           _input.add(value);
//         });
//         if (_input.length == widget.digits) {
//           Future.delayed(const Duration(milliseconds: 100), () {
//             widget.onCompleted?.call(_input.join());
//             Navigator.of(context).pop(_input.join());
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localeCode = context.locale.languageCode; // 'km' or 'en'

//     // For Khmer font, set your custom font if you have one.
//     return Dialog(
//       backgroundColor: Colors.black,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       insetPadding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Top-right Cancel button
//             Align(
//               alignment: Alignment.topRight,
//               child: TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: Text(
//                   "cancle".tr(),
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w800,
//                     fontSize: 16,
//                     fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),
//             // Lock icon and subtitle
//             Column(
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   backgroundColor: Colors.white38,
//                   child: Icon(
//                     Icons.lock_outline,
//                     color: Colors.white,
//                     size: 38,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   widget.subtitle,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontFamily:
//                         "KhmerOS", // Set your Khmer font family if needed
//                   ),
//                 ),
//                 if (widget.errorMessage != null) ...[
//                   const SizedBox(height: 10),
//                   Text(
//                     widget.errorMessage!,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.red, fontSize: 16),
//                   ),
//                 ],
//               ],
//             ),
//             const SizedBox(height: 35),
//             // Dots for input
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(widget.digits, (i) {
//                 return Container(
//                   width: 30,
//                   height: 30,
//                   margin: const EdgeInsets.symmetric(horizontal: 8),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _input.length > i ? Colors.white : Colors.white24,
//                   ),
//                   child:
//                       _input.length > i
//                           ? Center(
//                             child: Text(
//                               '',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           )
//                           : null,
//                 );
//               }),
//             ),
//             const SizedBox(height: 34),
//             // Custom Keypad
//             _buildKeypad(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildKeypad() {
//     final keys = [
//       ['1', '2', '3'],
//       ['4', '5', '6'],
//       ['7', '8', '9'],
//       ['C', '0', 'DEL'],
//     ];
//     return Column(
//       children:
//           keys.map((row) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children:
//                     row.map((key) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 15),
//                         child: _buildKey(key),
//                       );
//                     }).toList(),
//               ),
//             );
//           }).toList(),
//     );
//   }

//   Widget _buildKey(String key) {
//     final isNumber = RegExp(r'^[0-9]$').hasMatch(key);
//     final isClear = key == 'C';
//     final isDel = key == 'DEL';
//     IconData? icon;
//     if (isClear) icon = Icons.refresh;
//     if (isDel) icon = Icons.backspace;

//     return GestureDetector(
//       onTap: () => _onPressed(key),
//       child: Container(
//         width: 64,
//         height: 64,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(
//             color:
//                 key == 'C' || key == 'DEL'
//                     ? AppColors.primaryColor
//                     : Colors.white.withOpacity(0.8),
//             width: 2.2,
//           ),
//           color: Colors.black.withOpacity(isNumber ? 0.2 : 0.0),
//         ),
//         child: Center(
//           child:
//               isNumber
//                   ? Text(
//                     key,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 29,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   )
//                   : Icon(icon, color: AppColors.primaryColor, size: 32),
//         ),
//       ),
//     );
//   }
// }

// //Correct with 204 line code changes

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
    Key? key,
    this.subtitle = 'បញ្ចូលលេខសម្ងាត់ របស់អ្នកដើម្បីបន្ត',
    this.digits = 4,
    this.maxAttempts = 3,
    this.remainingAttempts = 3,
    this.onValidate,
  }) : super(key: key);

  @override
  State<CustomPasscodeDialog> createState() => _CustomPasscodeDialogState();
}

class _CustomPasscodeDialogState extends State<CustomPasscodeDialog> {
  List<String> _input = [];
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
                      SizedBox(
                        height: constraints.maxHeight * 0.025,
                      ), // instead of 20
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
                      SizedBox(
                        height: constraints.maxHeight * 0.025,
                      ), // instead of 20
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

                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ), // instead of 15
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
                          SizedBox(
                            height: constraints.maxHeight * 0.03,
                          ), // instead of 30
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(widget.digits, (i) {
                              return Container(
                                width:
                                    constraints.maxWidth *
                                    0.06, // responsive dot size
                                height: constraints.maxWidth * 0.06,
                                margin: EdgeInsets.symmetric(
                                  horizontal: constraints.maxWidth * 0.02,
                                ),
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

                          SizedBox(height: constraints.maxHeight * 0.05),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.18; // dynamic size for keypad

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
                      fontSize: screenWidth * 0.08, // dynamic font size
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  : isClear
                  ? Text(
                    "C",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: screenWidth * 0.09,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: screenWidth * 0.08,
                  ),
        ),
      ),
    );
  }
}

//Correct with 565 line code changes
