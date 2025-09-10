import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/balance_refresh_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:gb_merchant/components/transfer_prize_qr.dart';
import 'package:zxing2/qrcode.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../components/qr_scan_action_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../services/scanqr_prize.dart';
import '../widgets//qr_scan_spin_wheel.dart';
import 'dart:math';
import '../components/ExchangePrizeList.dart';
import '../utils/qr_code_parser.dart'; // Import the parser
import 'package:qr_code_tools/qr_code_tools.dart';
import 'dart:typed_data';

Widget diamondIcon({double size = 22, Color color = Colors.amber}) {
  return Icon(Icons.diamond, size: size, color: color);
}

class OpenScan extends StatefulWidget {
  final Future<void> Function(String issuer, int newAmount)? onPrizeScanned;
  final VoidCallback? onReturnFromScan; // Add this callback

  const OpenScan({super.key, this.onPrizeScanned, this.onReturnFromScan});

  @override
  State<OpenScan> createState() => _OpenScanState();
}

class _OpenScanState extends State<OpenScan>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  bool _isProcessingImage = false;

  List<Map<String, String>> scanResults = [];

  List<InlineSpan> _getResultSpans(String result) {
    final spans = <InlineSpan>[];
    final reg = RegExp(r'(\d+)\s*D');
    final localeCode = context.locale.languageCode; // Get current locale

    int lastEnd = 0;

    for (final match in reg.allMatches(result)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: result.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(text: match.group(1)));
      spans.add(WidgetSpan(child: SizedBox(width: 8)));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: diamondIcon(size: 22, color: Colors.white),
        ),
      );
      lastEnd = match.end;
    }

    // Handle the remaining text and translate "ពិន្ទុ" to "score" for English
    if (lastEnd < result.length) {
      String remainingText = result.substring(lastEnd);

      // Translate "ពិន្ទុ" to "score" if locale is English
      if (localeCode == 'en') {
        remainingText = remainingText.replaceAll('ពិន្ទុ', 'score');
      }

      spans.add(TextSpan(text: remainingText));
    }

    return spans;
  }

  // Also update the _generateDefaultItems method to handle translation
  List<String> _generateDefaultItems(int points, int diamond) {
    final random = Random();
    final items = <String>[];
    final localeCode = context.locale.languageCode; // Get current locale

    if (random.nextDouble() < 0.7) {
      items.addAll(['motor', 'car']);
    }

    // Generate point items (2-4 items)
    final pointCount = random.nextInt(3) + 2;
    for (var i = 0; i < pointCount; i++) {
      final value = (random.nextInt(9) + 1) * 10; // 10, 20, ..., 90
      final pointText = localeCode == 'en' ? 'score' : 'ពិន្ទុ';
      items.add('$value $pointText');
    }

    // Generate diamond items (1-2 items)
    final diamondCount = random.nextInt(2) + 1;
    for (var i = 0; i < diamondCount; i++) {
      final value = (random.nextInt(4) + 1) * 5; // 5, 10, 15, 20
      items.add('$value D');
    }

    // Make sure we have at least 5 items total
    while (items.length < 5) {
      if (random.nextBool()) {
        final value = (random.nextInt(9) + 1) * 10;
        final pointText = localeCode == 'en' ? 'score' : 'ពិន្ទុ';
        items.add('$value $pointText');
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
    WidgetsBinding.instance.addObserver(this); // Add observer

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
    WidgetsBinding.instance.removeObserver(this); // Remove observer

    controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Add this method to detect when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, trigger balance refresh
      _refreshBalancesOnReturn();
    }
  }

  // Add this method to handle back button press
  Future<bool> _onWillPop() async {
    // Trigger balance refresh when going back
    _refreshBalancesOnReturn();
    return true;
  }

  // Add this method to refresh balances
  void _refreshBalancesOnReturn() {
    if (widget.onReturnFromScan != null) {
      widget.onReturnFromScan!();
    }
    // Also trigger the notification-style refresh
    BalanceRefreshNotifier().refreshBalances();
  }

  // Updated handleScanResult method to handle signature-only QR
  // Updated handleScanResult method to properly handle already redeemed codes
  Future<void> handleScanResult(String code) async {
    await controller?.pauseCamera();

    try {
      // First try to handle as prize QR
      final prizeResponse = await fetchPrizeByCode(code);

      if (prizeResponse['success'] == true) {
        await _handlePrizeQR(prizeResponse, code);
      } else {
        // Check if it's definitely a transfer QR
        final isTransferQr = prizeResponse['isTransferQr'] == true;
        final errorMessage =
            prizeResponse['error']?.toString().toLowerCase() ?? '';

        if (isTransferQr) {
          // This is definitely a transfer QR, process it normally
          await _handleTransferQR(code, prizeResponse);
        } else if (errorMessage.contains('already redeemed') ||
            errorMessage.contains('already used') ||
            errorMessage.contains('invalid or already')) {
          // Handle already redeemed prize code specifically
          _handleAlreadyRedeemedQR(code, prizeResponse);
        } else {
          // For other errors with prize QR codes, show error
          _handleInvalidQR(prizeResponse, code);
        }
      }
    } catch (e) {
      _handleScanError(e);
    } finally {
      if (mounted) {
        await controller?.resumeCamera();
      }
    }
  }

  void _handleAlreadyRedeemedQR(
    String code,
    Map<String, dynamic> prizeResponse,
  ) {
    // setState(() {
    //   scanResults.add({"code": code, "result": "QR​ ត្រូវបានប្រើរួចហើយ"});
    // });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Invalid or already redeemed code'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'KhmerFont',
            ),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleScanError(dynamic e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error scanning QR code: ${e.toString()}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Future<void> _handleTransferQR(
    String code,
    Map<String, dynamic> prizeResponse,
  ) async {
    try {
      // Try to parse as JSON first (old format)
      try {
        final transferData = json.decode(code) as Map<String, dynamic>;
        if (transferData.containsKey('userId') &&
            transferData.containsKey('phoneNumber')) {
          // Valid JSON transfer QR - directly open exchange prize dialog
          if (mounted) {
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
                    phoneNumber: transferData['phoneNumber'] ?? 'Unknown',
                    scannedQr: code,
                    userId: transferData['userId'].toString(),
                  ),
                );
              },
            );
          }
          return;
        }
      } catch (e) {
        // Not JSON format, continue to signature parsing
      }

      // Try to parse as signature format (new format)
      final qrData = QrCodeParser.parseTransferQr(code);
      final phoneNumber = qrData['phoneNumber'] ?? 'Unknown';

      // Validate that we got a proper phone number
      if (phoneNumber != 'Unknown' && phoneNumber.contains('855')) {
        if (mounted) {
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
                  phoneNumber: phoneNumber,
                  scannedQr: code,
                  userId: '0', // Will be fetched during validation
                ),
              );
            },
          );
        }
      } else {
        throw Exception('Invalid QR format - no valid phone number found');
      }
    } catch (e) {
      // Not a valid transfer QR either
      _handleInvalidQR(prizeResponse, code);
    }
  }

  Future<void> _handlePrizeQR(
    Map<String, dynamic> prizeResponse,
    String code,
  ) async {
    final issuer = prizeResponse['issuer'] ?? "";
    final newAmount = prizeResponse['new_amount'] ?? 0;
    final amount = prizeResponse['amount'] ?? 0;
    final walletName = prizeResponse['wallet_name'] ?? issuer;
    final localeCode = context.locale.languageCode; // Get current locale

    // Khmer names for wallets
    // final walletNames = {
    //   "BS": "Boostrong",
    //   "GB": "Ganzberg",
    //   "ID": "Idol",
    //   "DM": "Diamond",
    // };

    // Determine the logo based on issuer
    String prizeLogo = 'assets/images/default.png';

    // Use walletName to determine the logo
    switch (walletName.toUpperCase()) {
      case "GB":
        prizeLogo = 'assets/images/gblogo.png';
        break;
      case "BS":
        prizeLogo = 'assets/images/newbslogo.png';
        break;
      case "ID":
        prizeLogo = 'assets/images/idollogo.png';
        break;
      case "DM":
        prizeLogo = 'assets/images/dmond.png';
        break;
      default:
        prizeLogo = 'assets/images/default.png';
    }

    // String prizeDisplay = '';
    // if (issuer != "" && amount != 0) {
    //   final readableName = walletNames[issuer] ?? walletName;
    //   prizeDisplay = '$amount ពិន្ទុ $readableName';
    // } else {
    //   prizeDisplay = 'អ្នកទទួលបានរង្វាន់';
    // }

    String prizeDisplay = '';
    if (issuer != "" && amount != 0) {
      final pointText = localeCode == 'en' ? 'score' : 'ពិន្ទុ';
      prizeDisplay = '$amount $pointText';
    } else {
      prizeDisplay =
          localeCode == 'en' ? 'You received a prize' : 'អ្នកទទួលបានរង្វាន់';
    }

    // Refresh balances after successful scan
    if (widget.onPrizeScanned != null) {
      await widget.onPrizeScanned!(issuer, newAmount);
    }

    setState(() {
      scanResults.add({"code": code, "result": prizeDisplay});
    });

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => QrScanSpinWheelDialog(
              prize: prizeDisplay,
              defaultItems: _generateDefaultItems(amount, 0),
              onClose: () => controller?.resumeCamera(),
              prizeLogo: prizeLogo, // Pass the logo to the dialog
            ),
      );
    }
  }

  // Also update your _handleInvalidQR method to be more specific
  void _handleInvalidQR(Map<String, dynamic> prizeResponse, String code) {
    final errorMessage = prizeResponse['error']?.toString().toLowerCase() ?? '';

    String resultText;
    if (errorMessage.contains('invalid') ||
        errorMessage.contains('not valid')) {
      resultText = "QR​ មិនត្រឹមត្រូវ";
    } else {
      resultText = "QR​ នេះមិនមានទេ";
    }

    setState(() {
      scanResults.add({"code": code, "result": resultText});
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            prizeResponse['error'] ?? 'QR code not valid',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Future<void> showTransferDialog(
    BuildContext context,
    Map<String, dynamic> transferData,
  ) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "TransferPrizeScan",
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: TransferPrizeScan(
            scannedData: transferData,
            onScanned: (qrCode) {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    bool isProcessing = false;

    controller?.scannedDataStream.listen((scanData) async {
      if (!isProcessing && mounted && scanData.code != null) {
        isProcessing = true;
        try {
          await handleScanResult(scanData.code!);
        } finally {
          isProcessing = false;
        }
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

  //Start add code here

  //Start add code here
  Future<void> _pickQrFromGallery() async {
    if (_isProcessingImage) return;

    // Pause camera before opening gallery (same as transfer flow)
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
        // Show loading indicator ONLY during actual image processing
        setState(() => _isProcessingImage = true);

        String? qrText = await _decodeQRFromImage(File(image.path));

        // Resume camera after processing (same as transfer flow)
        if (mounted && controller != null) {
          try {
            await controller!.resumeCamera();
          } catch (e) {
            print("Camera resume error: $e");
          }
        }

        // Hide loading indicator before processing the result
        if (mounted) {
          setState(() => _isProcessingImage = false);
        }

        if (qrText != null && qrText.isNotEmpty && mounted) {
          print("Detected QR content: $qrText");

          // Handle the scanned QR code - check if it's a signature format first
          if (_isSignatureFormat(qrText)) {
            print("Signature format detected, processing as transfer QR");
            await _handleTransferQR(qrText, {});
          } else {
            await handleScanResult(qrText);
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
        }
      } else {
        // User cancelled gallery selection (same as transfer flow)
        if (mounted && controller != null) {
          try {
            await controller!.resumeCamera();
          } catch (e) {
            print("Camera resume error: $e");
          }
        }
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

      // Hide loading indicator if it was shown
      if (mounted && _isProcessingImage) {
        setState(() => _isProcessingImage = false);
      }

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

  // Enhanced QR decoding from image (same as transfer flow)
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

  bool _isSignatureFormat(String code) {
    // Check if it matches the signature pattern (long numeric string)
    final signaturePattern = RegExp(r'^\d{20,40}$');
    return signaturePattern.hasMatch(code);
  }

  @override
  Widget build(BuildContext context) {
    final double cutOutSize = MediaQuery.of(context).size.width * 0.7;
    final double lineThickness = 2.0;
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              _refreshBalancesOnReturn(); // Refresh when back button pressed
              Navigator.pop(context);
            },
          ),
          title: Text(
            'ganzbergscan'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.asset(
                'assets/images/logo.png',
                width: 60,
                height: 60,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 6,
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
                                            color: Colors.amber.withOpacity(
                                              0.3,
                                            ),
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
                    child: Container(
                      color: AppColors.primaryColor,
                      child: ListView.builder(
                        itemCount: scanResults.length,
                        itemBuilder: (context, index) {
                          final item = scanResults[index];
                          final localeCode =
                              context.locale.languageCode; // Get current locale
                          final resultText =
                              localeCode == 'en' ? 'Result: ' : 'លទ្ធផល: ';

                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily:
                                      localeCode == 'km' ? 'KhmerFont' : null,
                                ),
                                children: [
                                  TextSpan(
                                    text: resultText,
                                  ), // Use translated text
                                  ..._getResultSpans(item["result"] ?? ''),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Container(
                  color: AppColors.primaryColor,
                  child: QrScanActionButtons(
                    onToggleFlash: _toggleFlash,
                    onPickQr: _pickQrFromGallery,
                  ),
                ),
              ],
            ),
            //LOADING INDICATOR HERE:
            if (_isProcessingImage)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//Correct with 931 line code changes
