import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String message;

  const SuccessDialog({
    Key? key,
    this.message =
        "លេខសម្ងាត់របស់អ្នកបង្កើតបានជោគជ័យ!", // "Passcode successfully created!"
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50), // green
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.check, color: Colors.white, size: 35),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            // Optionally you can add a fading progress bar
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Correct with 53 line code changes
