import 'package:flutter/material.dart';

class QrScanActionButtons extends StatelessWidget {
  final Future<void> Function()? onToggleFlash;
  final Future<void> Function()? onPickQr;

  const QrScanActionButtons({
    Key? key,
    required this.onToggleFlash,
    this.onPickQr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, top: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: onToggleFlash,
              icon: const Icon(Icons.flashlight_on),
              label: const Text("បើកពិល"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            // Only show if onPickQr is not null
            if (onPickQr != null)
              ElevatedButton.icon(
                onPressed: onPickQr,
                icon: const Icon(Icons.qr_code),
                label: const Text("បើក QR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//Correct with 62 line code changes
