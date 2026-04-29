import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String message;

  const SuccessDialog({
    Key? key,
    this.message = "លេខសម្ងាត់របស់អ្នកបង្កើតបានជោគជ័យ!",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.check, color: Colors.white, size: 35),
            ),
            const SizedBox(height: 40),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

//Correct with 59 line code changes
