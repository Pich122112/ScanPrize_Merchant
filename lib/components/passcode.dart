import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';

class CustomPasscodeDialog extends StatefulWidget {
  final String subtitle;
  final int digits;
  final void Function(String code)? onCompleted;
  final String? errorMessage; // <-- ADD THIS

  const CustomPasscodeDialog({
    Key? key,
    this.subtitle = 'បញ្ចូលលេខសម្ងាត់ របស់អ្នកដើម្បីបន្ត',
    this.digits = 4,
    this.onCompleted,
    this.errorMessage, // <-- ADD THIS
  }) : super(key: key);

  @override
  State<CustomPasscodeDialog> createState() => _CustomPasscodeDialogState();
}

class _CustomPasscodeDialogState extends State<CustomPasscodeDialog> {
  List<String> _input = [];

  void _onPressed(String value) {
    if (value == 'C') {
      setState(() {
        _input.clear();
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
        });
        if (_input.length == widget.digits) {
          Future.delayed(const Duration(milliseconds: 100), () {
            widget.onCompleted?.call(_input.join());
            Navigator.of(context).pop(_input.join());
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For Khmer font, set your custom font if you have one.
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            // Lock icon and subtitle
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white38,
                  child: Icon(Icons.lock_outline, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily:
                        "KhmerOS", // Set your Khmer font family if needed
                  ),
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 35),
            // Dots for input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.digits, (i) {
                return Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _input.length > i ? Colors.white : Colors.white24,
                  ),
                  child:
                      _input.length > i
                          ? Center(
                            child: Text(
                              '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : null,
                );
              }),
            ),
            const SizedBox(height: 34),
            // Custom Keypad
            _buildKeypad(),
          ],
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
              padding: const EdgeInsets.symmetric(vertical: 8),
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
    if (isClear) icon = Icons.refresh;
    if (isDel) icon = Icons.backspace;

    return GestureDetector(
      onTap: () => _onPressed(key),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                key == 'C' || key == 'DEL'
                    ? AppColors.primaryColor
                    : Colors.white.withOpacity(0.8),
            width: 2.2,
          ),
          color: Colors.black.withOpacity(isNumber ? 0.2 : 0.0),
        ),
        child: Center(
          child:
              isNumber
                  ? Text(
                    key,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  : Icon(icon, color: AppColors.primaryColor, size: 32),
        ),
      ),
    );
  }
}

//Correct with 200 line code changes
