import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanprize_frontend/components/qr_scan_action_button.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;
import '../services/exchange_prize_service.dart';
import 'dart:typed_data';
import 'package:qr_code_tools/qr_code_tools.dart';
import './ExchangePrizeList.dart';

// Helper: Parse phone number from qrPayload (customize this if QR changes)
String? getPhoneNumberFromQr(String qrPayload) {
  // Example qrPayload: ganzbergqr:ganzberg,idol,boostrong,money:3109-all|3109|<signature>
  // You may need to decode phone number via an API call using userId (3109 in this example)
  // Here, just return null (you will fetch from backend below)
  return null;
}

// Show scan dialog, then show prize exchange dialog with phone number from QR
Future<void> showTransferPrizeScanDialog(BuildContext context) async {
  String? scannedQr;
  await showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder:
        (context) => TransferPrizeScan(
          onScanned: (qrCode) {
            scannedQr = qrCode;
          },
        ),
  );
  if (scannedQr != null) {
    // Get phone number of scanned user from backend using userId from QR
    String? phoneNumber;
    try {
      // Parse userId from qrPayload
      final parts = scannedQr!.split(':');
      if (parts.length > 2) {
        final rest = parts[2];
        final userId = rest.split('|')[1];
        // Fetch from backend
        // Replace with your actual API URL
        final response = await ExchangePrizeService().fetchUserById(userId);
        phoneNumber = response?.phoneNumber ?? 'Unknown';
      }
    } catch (_) {
      phoneNumber = 'Unknown';
    }
    // In showTransferPrizeScanDialog
    await showDialog(
      context: context,
      builder:
          (context) => ExchangePrizeDialog(
            phoneNumber: phoneNumber ?? 'Unknown',
            scannedQr: scannedQr!, // <-- add this!
          ),
    );
  }
}

// TransferPrizeScan widget (Scan direct and from image)
class TransferPrizeScan extends StatefulWidget {
  final Function(String) onScanned;
  const TransferPrizeScan({super.key, required this.onScanned});

  @override
  State<TransferPrizeScan> createState() => _TransferPrizeScanState();
}

class _TransferPrizeScanState extends State<TransferPrizeScan>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;
  // String? scannedCode;
  bool _isProcessing = false; // Add processing state
  // ignore: unused_field
  bool _isValidQr = false; // Add QR validation state

  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller?.scannedDataStream.listen((scanData) async {
      if (scanData.code != null && !_isProcessing) {
        setState(() {
          _isProcessing = true;
          // scannedCode = scanData.code;
        });

        // Validate QR format before proceeding
        final isValid = _validateQrFormat(scanData.code!);

        setState(() {
          _isValidQr = isValid;
        });

        // Only proceed if QR is valid
        if (isValid) {
          // Add slight delay for better UX
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            widget.onScanned(scanData.code!);
            Navigator.of(context).pop();
          }
        } else {
          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid QR code format'),
              duration: Duration(seconds: 2),
            ),
          );

          // Resume scanning after delay
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            _isProcessing = false;
            // scannedCode = null;
          });
        }
      }
    });
  }

  // QR format validation
  bool _validateQrFormat(String qrCode) {
    try {
      final parts = qrCode.split(':');
      if (parts.length < 3) return false;

      final prefix = parts[0];
      if (prefix != 'ganzbergqr') return false;

      final rest = parts[2];
      final qrData = rest.split('|');
      if (qrData.length < 3) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      final flashStatus = await controller!.getFlashStatus();
      setState(() {
        isFlashOn = flashStatus ?? false;
      });
    }
  }

  Future<void> _pickQrFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String? qrText;
      try {
        // Try qr_code_tools first (platform native, works best)
        qrText = await QrCodeToolsPlugin.decodeFrom(image.path);
      } catch (e) {
        // If plugin throws but not a 'not found' error, show it
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to scan QR from image: ${e.toString()}"),
          ),
        );
        return;
      }

      if (qrText == null || qrText.isEmpty) {
        // Try zxing2 fallback (pure Dart, works with more image types)
        try {
          final bytes = await image.readAsBytes();
          final decodedImage = img.decodeImage(bytes);
          if (decodedImage != null) {
            final width = decodedImage.width;
            final height = decodedImage.height;
            final pixels = decodedImage.getBytes();
            final intCount = pixels.length ~/ 4;
            final argbInts = Int32List(intCount);
            for (var i = 0; i < intCount; i++) {
              final r = pixels[i * 4];
              final g = pixels[i * 4 + 1];
              final b = pixels[i * 4 + 2];
              final a = pixels[i * 4 + 3];
              argbInts[i] = ((a << 24) | (r << 16) | (g << 8) | b);
            }
            final luminanceSource = RGBLuminanceSource(width, height, argbInts);
            final bitmap = BinaryBitmap(HybridBinarizer(luminanceSource));
            final reader = QRCodeReader();
            Result? result;
            try {
              result = reader.decode(bitmap);
              qrText = result.text;
            } catch (e) {
              // Still failed, show friendly message
              qrText = null;
            }
          }
        } catch (e) {
          qrText = null;
        }
      }

      if (qrText != null && qrText.isNotEmpty) {
        // setState(() {
        //   // scannedCode = qrText;
        // });
        widget.onScanned(qrText);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No QR code found in this image. Please choose another image or retake a clear photo of your QR code.",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cutOutSize = MediaQuery.of(context).size.width * 0.7;
    final double lineThickness = 2.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.9)),
        child: Stack(
          children: [
            Positioned.fill(
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: 12,
                  borderLength: 40,
                  borderWidth: 12,
                  cutOutSize: cutOutSize,
                ),
              ),
            ),
            // Scanning Animation
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: cutOutSize,
                  height: cutOutSize,
                  child: AnimatedBuilder(
                    animation: _positionAnimation,
                    builder: (context, child) {
                      final double y =
                          _positionAnimation.value *
                          (cutOutSize - lineThickness);
                      return Stack(
                        children: [
                          Positioned(
                            top: y,
                            left: 0,
                            right: 0,
                            child: Container(
                              width: cutOutSize - 10,
                              height: lineThickness,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.amber,
                                    Colors.yellowAccent,
                                    Colors.amber,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Header with close button
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                height: kToolbarHeight,
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'ផ្ទេរចេញ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom action buttons
            // Replace the bottom action buttons with QrScanActionButtons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: QrScanActionButtons(
                onToggleFlash: _toggleFlash,
                onPickQr: _pickQrFromGallery,
              ),
            ),
            // Scan result display
            //   if (scannedCode != null)
            //     Positioned(
            //       bottom: 100,
            //       left: 0,
            //       right: 0,
            //       child: Center(
            //         child: Container(
            //           padding: const EdgeInsets.all(16),
            //           decoration: BoxDecoration(
            //             color: Colors.black.withOpacity(0.7),
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           child: Text(
            //             'Scanned: $scannedCode',
            //             style: const TextStyle(fontSize: 18, color: Colors.white),
            //           ),
            //         ),
            //       ),
            //     ),
          ],
        ),
      ),
    );
  }
}

//Correct with 405 line code changes
