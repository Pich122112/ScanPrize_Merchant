import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gb_merchant/components/qr_scan_action_button.dart';
import 'package:gb_merchant/services/transfer_service.dart';
import 'package:gb_merchant/utils/qr_code_parser.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:qr_code_tools/qr_code_tools.dart';
import './ExchangePrizeList.dart';

String? getPhoneNumberFromQr(String qrPayload) {
  return null;
}

Future<void> showTransferPrizeScanDialog(BuildContext context) async {
  String? scannedQr;
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    barrierLabel: "TransferPrizeScan",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: TransferPrizeScan(
          onScanned: (qrCode) {
            scannedQr = qrCode;
          },
        ),
      );
    },
  );

  if (scannedQr != null) {
    String phoneNumber = 'Unknown';
    String userId = '0';
    String userName = 'Unknown';
    String signature = scannedQr!;

    try {
      // Parse the QR code using our signature parser
      final qrData = QrCodeParser.parseTransferQr(scannedQr!);
      phoneNumber = qrData['phoneNumber'] ?? 'Unknown';
      userName = qrData['name'] ?? 'Unknown';
      signature = qrData['signature'] ?? scannedQr!;

      print("📱 Parsed QR: Phone: $phoneNumber, Name: $userName");

      // Validate the user with the backend to get user ID
      try {
        // Clean phone number for API call (already in 855 format)
        String cleanPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

        // Ensure it's in international format for API
        if (cleanPhone.startsWith('0') && cleanPhone.length == 9) {
          cleanPhone = '855${cleanPhone.substring(1)}';
        }

        if (cleanPhone != '855Unknown') {
          final userData = await TransferService.verifyReceiver(cleanPhone);
          if (userData != null && userData['receiver'] != null) {
            final receiver = userData['receiver'];
            phoneNumber = receiver['phone_number'] ?? phoneNumber;
            userId = receiver['id']?.toString() ?? '0';
            userName = receiver['name'] ?? userName;
            print("✅ Validated user: $userName ($phoneNumber) ID: $userId");
          } else {
            print("⚠️ Receiver validation returned null data");
          }
        } else {
          print("⚠️ Invalid phone number format: $cleanPhone");
        }
      } catch (e) {
        print("⚠️ User validation failed: $e");
        // Continue with the parsed phone number even if validation fails
      }
    } catch (e) {
      print("⚠️ Error parsing QR: $e");
      phoneNumber = 'Unknown';
      userId = '0';
      userName = 'Unknown';
    }

    // Format phone number for display (convert to local format)
    final formattedPhone = QrCodeParser.formatPhoneNumber(phoneNumber);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ExchangePrizeDialog",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: ExchangePrizeDialog(
            phoneNumber: formattedPhone,
            scannedQr: signature,
            userId: userId,
          ),
        );
      },
    );
  }
}

// TransferPrizeScan widget (Scan direct and from image)
class TransferPrizeScan extends StatefulWidget {
  final Function(String) onScanned;
  final Map<String, dynamic> scannedData;

  const TransferPrizeScan({
    super.key,
    required this.onScanned,
    this.scannedData = const {},
  });

  @override
  State<TransferPrizeScan> createState() => _TransferPrizeScanState();
}

class _TransferPrizeScanState extends State<TransferPrizeScan>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;
  // String? scannedCode;
  bool _isProcessing = false;
  // ignore: unused_field
  bool _isValidQr = false;

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
    // Stop animation first
    _animationController.stop();
    _animationController.dispose();

    // Dispose camera controller safely
    if (controller != null) {
      try {
        controller!.dispose();
      } catch (e) {
        print("Camera dispose error: $e");
      }
    }

    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller?.scannedDataStream.listen((scanData) async {
      if (scanData.code != null && !_isProcessing && mounted) {
        setState(() {
          _isProcessing = true;
        });

        // Validate QR format before proceeding
        final isValid = _validateQrFormat(scanData.code!);

        setState(() {
          _isValidQr = isValid;
        });

        // Only proceed if QR is valid TRANSFER code
        if (isValid && mounted) {
          print("✅ Valid TRANSFER QR detected: ${scanData.code!}");

          // Add slight delay for better UX
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            widget.onScanned(scanData.code!);
            Navigator.of(context).pop();
          }
        } else if (mounted) {
          // Show specific error message for prize QR codes
          final errorMessage =
              _isPrizeQrCode(scanData.code!)
                  ? 'QR មិនត្រឺមត្រូវសូមជ្រើសរើសម្តងទៀត'
                  : 'Invalid transfer QR code format';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
              padding: const EdgeInsets.only(bottom: 30.0),
            ),
          );

          // Resume scanning after delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    });
  }

  // QR format validation
  // In _TransferPrizeScanState, update the validation
  // QR format validation - Only accept transfer QR codes
  bool _validateQrFormat(String qrCode) {
    try {
      // First, check if this is a prize QR code (should be rejected)
      if (_isPrizeQrCode(qrCode)) {
        print("❌ Rejected: QR មិនត្រឺមត្រូវសូមជ្រើសរើសម្តងទៀត");
        return false;
      }

      // Use the proper parser that handles both signature and JSON formats
      final parsed = QrCodeParser.parseTransferQr(qrCode);

      // Valid if we can extract a proper phone number
      final phone = parsed['phoneNumber'] ?? '';
      return phone != 'Unknown' && phone.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Helper function to detect prize QR codes
  bool _isPrizeQrCode(String code) {
    // Prize QR codes typically follow these patterns:
    final prizeQrPatterns = [
      RegExp(r'^[A-Z]{1,2}\d{6,9}$'), // Like B000194023, GB123456
      RegExp(r'^[A-Z]{2,3}\d+$'), // Like BS123, ID4567
      RegExp(r'^[A-Z]\d{8,10}$'), // Single letter prefix with numbers
    ];

    for (final pattern in prizeQrPatterns) {
      if (pattern.hasMatch(code)) {
        return true;
      }
    }

    // Also check for common prize code prefixes
    final prizePrefixes = ['B', 'GB', 'BS', 'ID', 'DM'];
    for (final prefix in prizePrefixes) {
      if (code.startsWith(prefix) && code.length >= 3) {
        // Check if the rest is numeric
        final numericPart = code.substring(prefix.length);
        if (numericPart.isNotEmpty &&
            RegExp(r'^\d+$').hasMatch(numericPart) &&
            numericPart.length >= 6) {
          return true;
        }
      }
    }

    return false;
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

  // add code here

  Future<void> _pickQrFromGallery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Pause camera before opening gallery
    if (controller != null && mounted) {
      try {
        await controller!.pauseCamera();
      } catch (e) {
        print("Camera pause error: $e");
      }
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (image != null && mounted) {
        String? qrText = await _decodeQRFromImage(File(image.path));

        // Resume camera
        if (mounted && controller != null) {
          try {
            await controller!.resumeCamera();
          } catch (e) {
            print("Camera resume error: $e");
          }
        }

        if (qrText != null && qrText.isNotEmpty && mounted) {
          print("Detected QR content: $qrText");

          // Check if it's a valid QR code (not just your specific format)
          if (_isValidQrContent(qrText)) {
            widget.onScanned(qrText);
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                padding: const EdgeInsets.only(bottom: 20.0, top: 10),
                content: Text(
                  'Invalid QR code format',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isProcessing = false);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "No QR code found in this image. Please choose another image or retake a clear photo of your QR code.",
                textAlign: TextAlign.center,
              ),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isProcessing = false);
        }
      } else {
        // User cancelled gallery selection
        if (mounted && controller != null) {
          try {
            await controller!.resumeCamera();
          } catch (e) {
            print("Camera resume error: $e");
          }
        }
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print("Gallery picker error: $e");
      if (mounted && controller != null) {
        try {
          await controller!.resumeCamera();
        } catch (e) {
          print("Camera resume error: $e");
        }
      }
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to access gallery. Please check permissions.",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Universal QR code validation - accepts any QR code content
  bool _isValidQrContent(String qrCode) {
    // Accept any non-empty QR code content
    return qrCode.isNotEmpty && qrCode.trim().isNotEmpty;
  }

  // Enhanced QR decoding from image
  Future<String?> _decodeQRFromImage(File imageFile) async {
    try {
      // Try multiple decoding approaches
      final decodingMethods = [
        _decodeWithQrCodeTools(imageFile),
        _decodeWithZxing(imageFile),
        _decodeWithImageProcessing(imageFile),
      ];

      // Try each method sequentially until we get a result
      for (final method in decodingMethods) {
        try {
          final result = await method;
          if (result != null && result.isNotEmpty) {
            return result;
          }
        } catch (e) {
          print("Decoding method failed: $e");
          continue;
        }
      }

      return null;
    } catch (e) {
      print("QR decoding error: $e");
      return null;
    }
  }

  Future<String?> _decodeWithQrCodeTools(File imageFile) async {
    try {
      return await QrCodeToolsPlugin.decodeFrom(imageFile.path);
    } catch (e) {
      print("QR Tools error: $e");
      return null;
    }
  }

  Future<String?> _decodeWithZxing(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) return null;

      final width = decodedImage.width;
      final height = decodedImage.height;
      final pixels = decodedImage.getBytes();

      // Convert to ARGB format that zxing expects
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
      final binarizer = HybridBinarizer(luminanceSource);
      final bitmap = BinaryBitmap(binarizer);
      final reader = QRCodeReader();

      try {
        final result = reader.decode(bitmap);
        return result.text;
      } catch (e) {
        print("ZXing decoding failed: $e");
        return null;
      }
    } catch (e) {
      print("ZXing processing error: $e");
      return null;
    }
  }

  Future<String?> _decodeWithImageProcessing(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) return null;

      // Try multiple image processing techniques
      final processingTechniques = [
        decodedImage, // Original
        img.grayscale(decodedImage), // Grayscale
        img.adjustColor(decodedImage, contrast: 1.8), // Higher contrast
        img.adjustColor(decodedImage, brightness: 1.2), // Brighter
        _binarizeImage(decodedImage, threshold: 150), // Black and white
      ];

      for (final processedImage in processingTechniques) {
        try {
          // Save processed image to temp file and try decoding
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/processed_qr.jpg');
          await tempFile.writeAsBytes(
            img.encodeJpg(processedImage, quality: 90),
          );

          // Try with QR Code Tools
          final result = await QrCodeToolsPlugin.decodeFrom(tempFile.path);
          if (result != null && result.isNotEmpty) {
            return result;
          }

          // Try with ZXing
          final zxingResult = await _decodeWithZxing(tempFile);
          if (zxingResult != null && zxingResult.isNotEmpty) {
            return zxingResult;
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      print("Image processing error: $e");
      return null;
    }
  }

  img.Image _binarizeImage(img.Image image, {int threshold = 128}) {
    final result = img.Image(width: image.width, height: image.height);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        final value = luminance > threshold ? 255 : 0;
        result.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }

    return result;
  }
  // Update your QR validation to accept any QR code

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
                child: Row(
                  children: [
                    // Close button on the left
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    // Spacer between button and title
                    const SizedBox(width: 16),
                    // Title centered (Expanded to take available space)
                    Expanded(
                      child: Center(
                        child: Text(
                          'transfer_out'.tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KhmerFont',
                          ),
                        ),
                      ),
                    ),
                    // Logo on the right
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom action buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: QrScanActionButtons(
                onToggleFlash: _toggleFlash,
                onPickQr: _pickQrFromGallery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Correct with 686 line code changes
