import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:zxing2/qrcode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import '../components/qr_scan_action_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
// import '../components/QrScanResultDialog.dart';
import '../services/scanqr_prize.dart';
// import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import '../widgets//qr_scan_spin_wheel.dart';
import 'dart:math';

class OpenScan extends StatefulWidget {
  const OpenScan({super.key});

  @override
  State<OpenScan> createState() => _OpenScanState();
}

class _OpenScanState extends State<OpenScan>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  // List to hold all scan results.
  List<Map<String, String>> scanResults = [];

  // Add this new method to the _OpenScanState class
  List<String> _generateDefaultItems(int points, int money) {
    final random = Random();
    final items = <String>[];

    // Always include the special prizes (but not too many)
    if (random.nextDouble() < 0.7) {
      // 70% chance to include at least one special prize
      items.addAll(['motor', 'car']);
    }

    // Generate point items (2-4 items)
    final pointCount = random.nextInt(3) + 2;
    for (var i = 0; i < pointCount; i++) {
      final value = (random.nextInt(9) + 1) * 10; // 10, 20, ..., 90
      items.add('$value ពិន្ទុ');
    }

    // Generate money items (1-2 items)
    final moneyCount = random.nextInt(2) + 1;
    for (var i = 0; i < moneyCount; i++) {
      final value = (random.nextInt(4) + 1) * 5; // 5, 10, 15, 20
      items.add('$value D');
    }

    // Make sure we have at least 5 items total
    while (items.length < 5) {
      if (random.nextBool()) {
        final value = (random.nextInt(9) + 1) * 10;
        items.add('$value ពិន្ទុ');
      } else {
        final value = (random.nextInt(4) + 1) * 5;
        items.add('$value D');
      }
    }

    return items..shuffle();
  }

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
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // In OpenScan.dart
  Future<void> handleScanResult(String code) async {
    await controller?.pauseCamera();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    try {
      final response = await fetchPrizeByCode(code, userId);

      if (response['success'] == true) {
        final prizeTitle = response['prizeTitle'] ?? '';
        final pointsAdded = response['pointsAdded'] ?? 0;
        final moneyAdded = response['moneyAdded'] ?? 0;

        String displayText = prizeTitle;

        // If no title or we need to combine points and money
        if (displayText.isEmpty) {
          if (pointsAdded > 0) {
            displayText = 'អ្នកទទួលបាន $pointsAdded ពិន្ទុ';
          }
          if (moneyAdded > 0) {
            if (displayText.isNotEmpty) displayText += ' និង ';
            displayText += '\$$moneyAdded';
          }
          if (displayText.isEmpty) {
            displayText = 'អ្នកទទួលបានរង្វាន់';
          }
        }

        setState(() {
          scanResults.add({"code": code, "result": displayText});
        });

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => QrScanSpinWheelDialog(
                  prize: displayText,
                  defaultItems: _generateDefaultItems(pointsAdded, moneyAdded),
                  onClose: () => controller?.resumeCamera(),
                ),
          );
          controller?.resumeCamera();
        }
      } else {
        setState(() {
          scanResults.add({"code": code, "result": "QR​ នេះមិនមានទេ"});
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                response['error'] ?? 'QR code not valid',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Error scanning QR code: ${e.toString()}',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        await controller?.resumeCamera();
      }
    }
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller?.scannedDataStream.listen((scanData) {
      if (mounted) {
        handleScanResult(scanData.code!);
      }
    });
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
      try {
        final bytes = await image.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to decode image")),
          );
          return;
        }

        final width = decodedImage.width;
        final height = decodedImage.height;
        final pixels =
            decodedImage.getBytes(); // Returns Uint8List in RGBA order

        final luminanceSource = RGBLuminanceSource(
          width,
          height,
          pixels.buffer.asInt32List(),
        );
        final bitmap = BinaryBitmap(HybridBinarizer(luminanceSource));
        final reader = QRCodeReader();
        final result = reader.decode(bitmap);

        if (!mounted) return;
        // ignore: unnecessary_null_comparison
        if (result != null && result.text.isNotEmpty) {
          handleScanResult(result.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No QR code found in this image")),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to scan QR from image")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cutOutSize = MediaQuery.of(context).size.width * 0.7;
    final double lineThickness = 2.0;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ស្គែន QR កំប៉ុង',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png', // Replace with your image path
              width: 60,
              height: 60,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                QRView(
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
                Center(
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
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
              ],
            ),
          ),
          if (scanResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final item = scanResults[index];
                  return Container(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    alignment: Alignment.topLeft,
                    child: Text(
                      'លទ្ធផល: ${item["result"]}',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      textAlign: TextAlign.start,
                    ),
                  );
                },
              ),
            ),
          QrScanActionButtons(
            onToggleFlash: _toggleFlash,
            onPickQr: _pickQrFromGallery,
          ),
        ],
      ),
    );
  }
}

//Correct with 381 line code changes
