import 'package:flutter/material.dart';

class QrCodeTemplate extends StatelessWidget {
  const QrCodeTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      fallbackHeight: 200,
      fallbackWidth: 200,
      color: Colors.blue,
      strokeWidth: 2,
      child: Center(
        child: Text(
          'QR Code Placeholder',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
