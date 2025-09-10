import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';

class LockTimerDialog extends StatefulWidget {
  final int initialSeconds;

  const LockTimerDialog({Key? key, required this.initialSeconds})
    : super(key: key);

  @override
  State<LockTimerDialog> createState() => _LockTimerDialogState();
}

class _LockTimerDialogState extends State<LockTimerDialog> {
  late int secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    secondsLeft = widget.initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (secondsLeft > 0) {
          secondsLeft--;
        }
      });
      if (secondsLeft <= 0) {
        _timer?.cancel();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedTime {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
          bottom: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 25),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Icon(Icons.lock_clock, color: AppColors.backgroundColor, size: 60),
            const SizedBox(height: 18),
            Text(
              'attemp_lock'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'សូមរង់ចាំ $formattedTime វិនាទី',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

//Correct with 99 line code changes
