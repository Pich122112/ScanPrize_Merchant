import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gb_merchant/components/qr_scan_action_button.dart';
import 'package:gb_merchant/services/transfer_service.dart';
import 'package:gb_merchant/utils/qr_code_parser.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;
import 'package:qr_code_tools/qr_code_tools.dart';
import './ExchangePrizeList.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    with TickerProviderStateMixin {
  late MobileScannerController controller;
  bool isFlashOn = false;
  // String? scannedCode;
  bool _isProcessing = false;
  // ignore: unused_field
  bool _isValidQr = false;

  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  // Add for the border zoom animation
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;
  bool _isZooming = false;

  Color _currentBorderColor = Colors.white;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize MobileScannerController
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // For border zoom on correct scan
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _zoomAnimation = Tween<double>(begin: 1, end: 0.6).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOutBack),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white,
    ).animate(_colorController);

    _colorController.addListener(() {
      setState(() {
        _currentBorderColor = _colorAnimation.value ?? Colors.white;
      });
    });
  }

  @override
  void dispose() {
    // Stop animation first
    _animationController.stop();
    _animationController.dispose();
    _zoomController.dispose();
    _isZooming = false;
    _colorController.dispose();

    // Dispose mobile scanner controller
    try {
      controller.dispose();
    } catch (e) {
      print("Camera dispose error: $e");
    }

    super.dispose();
  }

  // Custom overlay builder for MobileScanner
  Widget _buildCustomOverlay(double cutOutSize) {
    return Positioned.fill(
      child: CustomPaint(
        painter: ScannerOverlayPainter(
          boxSize: cutOutSize,
          borderColor: _currentBorderColor,
          borderLength: 40,
          borderWidth: 5,
        ),
      ),
    );
  }

  void _handleQRDetection(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    if (barcodes.isNotEmpty && !_isProcessing && mounted) {
      final String scanData = barcodes.first.rawValue ?? '';

      if (scanData.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        // Validate QR format
        final isValid = _validateQrFormat(scanData);
        setState(() {
          _isValidQr = isValid;
        });
        // Animate border color: green for correct, red for incorrect
        _colorAnimation = ColorTween(
          begin: Colors.white,
          end: isValid ? Colors.yellowAccent : Colors.red,
        ).animate(_colorController);

        _colorController.forward(from: 0);

        // After a short delay, fade back to white
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            _colorAnimation = ColorTween(
              begin: isValid ? Colors.yellowAccent : Colors.red,
              end: Colors.white,
            ).animate(_colorController);
            _colorController.forward(from: 0);
          }
        });

        if (isValid && mounted) {
          print("✅ Valid TRANSFER QR detected: $scanData");

          // Start zoom animation
          setState(() {
            _isZooming = true;
          });
          _zoomController.forward();

          // Wait for animation to finish, then proceed
          await Future.delayed(_zoomController.duration!);

          if (mounted) {
            widget.onScanned(scanData);
            Navigator.of(context).pop();
          }
        } else if (mounted) {
          final errorMessage =
              _isPrizeQrCode(scanData)
                  ? 'QR មិនត្រឺមត្រូវសូមជ្រើសរើសម្តងទៀត'
                  : 'Incorrect transfer QR code format'.tr();

          _showModernErrorSnackBar(errorMessage);

          // Resume scanning after delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    }
  }

  void _showModernErrorSnackBar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 120, // below status bar
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: AnimatedSlide(
                offset: const Offset(0, -1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'KhmerFont',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  bool _validateQrFormat(String qrCode) {
    try {
      // First, check if this is a prize QR code (should be rejected)
      if (_isPrizeQrCode(qrCode)) {
        print("❌ Rejected: QR មិនត្រឺមត្រូវសូមជ្រើសរើសម្តងទៀត");
        return false;
      }

      // Try multiple parsing approaches
      String? phoneNumber;

      // Approach 1: Use your existing parser
      try {
        final parsed = QrCodeParser.parseTransferQr(qrCode);
        phoneNumber = parsed['phoneNumber'];
      } catch (e) {
        print("Standard parser failed: $e");
      }

      // Approach 2: Check if it's a simple phone number
      if (phoneNumber == null || phoneNumber == 'Unknown') {
        final cleanQr = qrCode.trim();
        if (cleanQr.length >= 9 && cleanQr.length <= 15) {
          // Check if it might be a raw phone number
          final digitsOnly = cleanQr.replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.length >= 9 && digitsOnly.length <= 12) {
            phoneNumber = digitsOnly;
          }
        }
      }

      // Approach 3: Check for JSON format
      if (phoneNumber == null && qrCode.startsWith('{')) {
        try {
          final jsonData = json.decode(qrCode);
          phoneNumber =
              jsonData['phone'] ??
              jsonData['phoneNumber'] ??
              jsonData['number'];
        } catch (e) {
          print("JSON parsing failed: $e");
        }
      }

      // Valid if we can extract a proper phone number
      return phoneNumber != null &&
          phoneNumber.isNotEmpty &&
          phoneNumber != 'Unknown' &&
          phoneNumber.length >= 9;
    } catch (e) {
      print("QR validation error: $e");
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
    try {
      await controller.toggleTorch();
      // Toggle the local state since mobile_scanner doesn't provide getTorchState
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      print("Toggle flash error: $e");
    }
  }

  Future<void> _pickQrFromGallery() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Only request Photos permission on iOS
    try {
      if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          final result = await Permission.photos.request();
          if (!result.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Failed to access gallery. Please check permissions.",
                  textAlign: TextAlign.center,
                ),
                duration: Duration(seconds: 3),
              ),
            );
            setState(() => _isProcessing = false);
            return;
          }
        }
      }
      // No Android storage permission required on Android 13+
    } catch (e) {
      print("Permission check error: $e");
    }

    // Stop camera before opening gallery
    try {
      await controller.stop();
    } catch (e) {
      print("Camera stop error: $e");
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
        if (mounted) {
          try {
            await controller.start();
          } catch (e) {
            print("Camera start error: $e");
          }
        }

        if (qrText != null && qrText.isNotEmpty && mounted) {
          print("Detected QR content: $qrText");

          if (_isValidQrContent(qrText)) {
            widget.onScanned(qrText);
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Invalid QR code format',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
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
        if (mounted) {
          try {
            await controller.start();
          } catch (e) {
            print("Camera start error: $e");
          }
        }
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print("Gallery picker error: $e");
      if (mounted) {
        try {
          await controller.start();
        } catch (e) {
          print("Camera start error: $e");
        }
      }
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to access gallery. Please check permissions.",
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 3),
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
    final double baseCutOutSize = 260;
    final double cutOutSize =
        baseCutOutSize * (_isZooming ? _zoomAnimation.value : 1.0);
    final double lineThickness = 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      elevation: 0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.9)),
        child: AnimatedBuilder(
          animation: _zoomAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: MobileScanner(
                    controller: controller,
                    onDetect: _handleQRDetection,
                  ),
                ),
                // Custom overlay on top of the scanner
                _buildCustomOverlay(cutOutSize),
                // Scanning Animation
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: AnimatedBuilder(
                        animation: _positionAnimation,
                        builder: (context, child) {
                          final double y =
                              _positionAnimation.value * (250 - lineThickness);
                          return Stack(
                            children: [
                              Positioned(
                                top: y,
                                left: 0,
                                right: 0,
                                child: Container(
                                  width:
                                      cutOutSize * 0.6, // 60% of scan box width
                                  height: lineThickness,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(40, 237, 221, 114),
                                        Colors.yellowAccent,
                                        Color.fromARGB(40, 237, 221, 114),
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
            );
          },
        ),
      ),
    );
  }
}

// Custom painter for the QR scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  final double boxSize;
  final Color borderColor;
  final double borderLength;
  final double borderWidth;

  ScannerOverlayPainter({
    required this.boxSize,
    required this.borderColor,
    required this.borderLength,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centeredRect = Alignment.center.inscribe(
      Size(boxSize, boxSize),
      Offset.zero & size,
    );

    // Draw dark overlay areas
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.2);

    // Top dark area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, centeredRect.top),
      darkPaint,
    );

    // Bottom dark area
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        centeredRect.bottom,
        size.width,
        size.height - centeredRect.bottom,
      ),
      darkPaint,
    );

    // Left dark area
    canvas.drawRect(
      Rect.fromLTWH(0, centeredRect.top, centeredRect.left, boxSize),
      darkPaint,
    );

    // Right dark area
    canvas.drawRect(
      Rect.fromLTWH(
        centeredRect.right,
        centeredRect.top,
        size.width - centeredRect.right,
        boxSize,
      ),
      darkPaint,
    );

    // Draw border corners
    final borderPaint =
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(
      centeredRect.topLeft,
      Offset(centeredRect.topLeft.dx + borderLength, centeredRect.topLeft.dy),
      borderPaint,
    );
    canvas.drawLine(
      centeredRect.topLeft,
      Offset(centeredRect.topLeft.dx, centeredRect.topLeft.dy + borderLength),
      borderPaint,
    );

    // Top-right corner
    canvas.drawLine(
      centeredRect.topRight,
      Offset(centeredRect.topRight.dx - borderLength, centeredRect.topRight.dy),
      borderPaint,
    );
    canvas.drawLine(
      centeredRect.topRight,
      Offset(centeredRect.topRight.dx, centeredRect.topRight.dy + borderLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      centeredRect.bottomLeft,
      Offset(
        centeredRect.bottomLeft.dx + borderLength,
        centeredRect.bottomLeft.dy,
      ),
      borderPaint,
    );
    canvas.drawLine(
      centeredRect.bottomLeft,
      Offset(
        centeredRect.bottomLeft.dx,
        centeredRect.bottomLeft.dy - borderLength,
      ),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      centeredRect.bottomRight,
      Offset(
        centeredRect.bottomRight.dx - borderLength,
        centeredRect.bottomRight.dy,
      ),
      borderPaint,
    );
    canvas.drawLine(
      centeredRect.bottomRight,
      Offset(
        centeredRect.bottomRight.dx,
        centeredRect.bottomRight.dy - borderLength,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.boxSize != boxSize;
  }
}

//Correct with 1043 line code changes
