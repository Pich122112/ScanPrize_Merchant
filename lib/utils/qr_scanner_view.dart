// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:scanprize_frontend/utils/constants.dart';

// class QrScannerView extends StatefulWidget {
//   final void Function(String code)? onDetect;
//   final bool showOverlay;
//   final MobileScannerController controller; // make required

//   const QrScannerView({
//     super.key,
//     this.onDetect,
//     this.showOverlay = true,
//     required this.controller,
//   });

//   @override
//   State<QrScannerView> createState() => _QrScannerViewState();
// }

// class _QrScannerViewState extends State<QrScannerView>
//     with WidgetsBindingObserver, TickerProviderStateMixin {
//   final MobileScannerController _controller = MobileScannerController(
//     detectionSpeed: DetectionSpeed.normal,
//     facing: CameraFacing.back,
//   );

//   bool isProcessing = false;
//   double _defaultZoom = 1.0;
//   double _currentZoom = 1.0;
//   Timer? _zoomTimer;

//   static const double scanBoxSize = 250.0;

//   // Animation for smooth zoom
//   late AnimationController _animController;
//   late Animation<double> _zoomAnimation;

//   // Border color animation
//   Color _borderColor = Colors.white;
//   late AnimationController _colorAnimController;
//   late Animation<Color?> _colorAnimation;
//   Timer? _colorResetTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _zoomAnimation = Tween<double>(
//       begin: _defaultZoom,
//       end: _defaultZoom,
//     ).animate(
//       CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
//     );

//     widget.controller.start(); // start the **passed controller**

//     // Border color animation
//     _colorAnimController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 200),
//     );
//     _colorAnimation = ColorTween(
//       begin: Colors.white,
//       end: Colors.white,
//     ).animate(_colorAnimController);
//     _colorAnimController.addListener(() {
//       setState(() {
//         _borderColor = _colorAnimation.value ?? Colors.white;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _zoomTimer?.cancel();
//     _animController.dispose();
//     widget.controller.dispose(); // dispose passed controller
//     _colorAnimController.dispose();
//     _colorResetTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       _controller.stop();
//       _zoomTimer?.cancel();
//       _resetZoom();
//     } else if (state == AppLifecycleState.resumed) {
//       widget.controller.start();
//     }
//   }

//   void _resetZoom() {
//     _currentZoom = _defaultZoom;
//     _controller.setZoomScale(_currentZoom);
//   }

//   void _autoZoom(BarcodeCapture capture) {
//     if (capture.barcodes.isEmpty) return;
//     final barcode = capture.barcodes.first;
//     final corners = barcode.corners;
//     // ignore: unnecessary_null_comparison
//     if (corners == null || corners.length < 2) return;

//     final width = (corners[1].dx - corners[0].dx).abs();
//     final height = (corners[2].dy - corners[0].dy).abs();
//     const double threshold = 80;

//     _zoomTimer?.cancel();

//     if ((width < threshold && height < threshold) &&
//         _currentZoom == _defaultZoom) {
//       // Zoom in
//       _animateZoom(2.0);

//       // Back to normal after 3 seconds
//       _zoomTimer = Timer(const Duration(seconds: 3), () {
//         _animateZoom(_defaultZoom);
//       });
//     }
//   }

//   void _animateZoom(double targetZoom) {
//     _zoomAnimation = Tween<double>(
//       begin: _currentZoom,
//       end: targetZoom,
//     ).animate(
//       CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
//     )..addListener(() {
//       _controller.setZoomScale(_zoomAnimation.value);
//     });
//     _currentZoom = targetZoom;
//     _animController.forward(from: 0);
//   }

//   void _onDetect(BarcodeCapture capture) async {
//     _autoZoom(capture);

//     if (isProcessing) return;

//     final code = capture.barcodes.first.rawValue;
//     if (code == null || code.isEmpty) return;

//     // --- Animate border color on scan ---
//     _colorResetTimer?.cancel();

//     final isValid = code.isNotEmpty; // Or apply your validation here

//     _colorAnimation = ColorTween(
//       begin: Colors.white,
//       end: isValid ? AppColors.primaryColor : Colors.red,
//     ).animate(_colorAnimController);
//     _colorAnimController.forward(from: 0);

//     // After 500ms, animate back to white
//     _colorResetTimer = Timer(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         _colorAnimation = ColorTween(
//           begin: isValid ? AppColors.primaryColor : Colors.red,
//           end: Colors.white,
//         ).animate(_colorAnimController);
//         _colorAnimController.forward(from: 0);
//       }
//     });
//     // --- END border color animation block ---

//     isProcessing = true;
//     if (widget.onDetect != null) widget.onDetect!(code);

//     await Future.delayed(const Duration(seconds: 2));
//     isProcessing = false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         MobileScanner(controller: widget.controller, onDetect: _onDetect),
//         if (widget.showOverlay)
//           IgnorePointer(
//             ignoring: true,
//             child: Center(
//               child: CustomPaint(
//                 size: const Size(
//                   scanBoxSize,
//                   scanBoxSize,
//                 ), // fixed size scan box
//                 painter: _QrOverlayPainter(borderColor: _borderColor),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// class _QrOverlayPainter extends CustomPainter {
//   final Color borderColor;
//   _QrOverlayPainter({required this.borderColor});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final borderPaint =
//         Paint()
//           ..color = borderColor
//           ..strokeWidth = 4
//           ..style = PaintingStyle.stroke;

//     // final fillPaint =
//     //     Paint()
//     //       ..color = Colors.grey.withOpacity(0.1) // semi-transparent blue
//     //       ..style = PaintingStyle.fill;

//     final borderLength = 40.0;

//     // Fill the scanning area
//     // canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);

//     // Draw corners (top-left, top-right, bottom-left, bottom-right)
//     // Top-left
//     canvas.drawLine(Offset(0, 0), Offset(borderLength, 0), borderPaint);
//     canvas.drawLine(Offset(0, 0), Offset(0, borderLength), borderPaint);

//     // Top-right
//     canvas.drawLine(
//       Offset(size.width, 0),
//       Offset(size.width - borderLength, 0),
//       borderPaint,
//     );
//     canvas.drawLine(
//       Offset(size.width, 0),
//       Offset(size.width, borderLength),
//       borderPaint,
//     );

//     // Bottom-left
//     canvas.drawLine(
//       Offset(0, size.height),
//       Offset(borderLength, size.height),
//       borderPaint,
//     );
//     canvas.drawLine(
//       Offset(0, size.height),
//       Offset(0, size.height - borderLength),
//       borderPaint,
//     );

//     // Bottom-right
//     canvas.drawLine(
//       Offset(size.width, size.height),
//       Offset(size.width - borderLength, size.height),
//       borderPaint,
//     );
//     canvas.drawLine(
//       Offset(size.width, size.height),
//       Offset(size.width, size.height - borderLength),
//       borderPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _QrOverlayPainter oldDelegate) =>
//       oldDelegate.borderColor != borderColor;
// }

// //Correct with 276 line code changes

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gb_merchant/utils/constants.dart';

class QrScannerView extends StatefulWidget {
  final void Function(String code)? onDetect;
  final bool showOverlay;
  final MobileScannerController controller; // make required

  const QrScannerView({
    super.key,
    this.onDetect,
    this.showOverlay = true,
    required this.controller,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool isProcessing = false;
  double _defaultZoom = 1.0;
  double _currentZoom = 1.0;
  Timer? _zoomTimer;

  static const double scanBoxSize = 250.0;

  // Animation for smooth zoom
  late AnimationController _animController;
  late Animation<double> _zoomAnimation;

  // Border color animation
  Color _borderColor = Colors.white;
  late AnimationController _colorAnimController;
  late Animation<Color?> _colorAnimation;
  Timer? _colorResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _zoomAnimation = Tween<double>(
      begin: _defaultZoom,
      end: _defaultZoom,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Start the passed controller (caller provided)
    try {
      widget.controller.start();
    } catch (_) {}

    // Border color animation
    _colorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white,
    ).animate(_colorAnimController);
    _colorAnimController.addListener(() {
      if (mounted) {
        setState(() {
          _borderColor = _colorAnimation.value ?? Colors.white;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _zoomTimer?.cancel();
    _animController.dispose();
    // IMPORTANT: do not dispose widget.controller here — caller owns it.
    _colorAnimController.dispose();
    _colorResetTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      try {
        await widget.controller.stop();
      } catch (_) {}
      _zoomTimer?.cancel();
      _resetZoom();
    } else if (state == AppLifecycleState.resumed) {
      try {
        await widget.controller.start();
      } catch (_) {}
    }
  }

  Future<void> _resetZoom() async {
    _zoomTimer?.cancel();
    _currentZoom = _defaultZoom;
    try {
      await widget.controller.setZoomScale(_currentZoom);
    } catch (_) {
      // ignore if controller doesn't support zoom on this platform/version
    }
  }

  void _autoZoom(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first;

    // Build a Rect from corner points if available
    Rect? rect;
    final corners = barcode.corners;
    if (corners != null && corners.isNotEmpty) {
      final xs = corners.map((p) => p.dx);
      final ys = corners.map((p) => p.dy);
      final minX = xs.reduce(min);
      final maxX = xs.reduce(max);
      final minY = ys.reduce(min);
      final maxY = ys.reduce(max);
      rect = Rect.fromLTRB(minX, minY, maxX, maxY);
    }

    // Fallback: try dynamic access to boundingBox if it exists at runtime
    if (rect == null) {
      try {
        final dynamic maybeRect = (barcode as dynamic).boundingBox;
        if (maybeRect is Rect) rect = maybeRect;
      } catch (_) {
        // ignore - property not present
      }
    }

    if (rect == null) return;

    final double width = rect.width.abs();
    final double height = rect.height.abs();

    // Small QR on preview -> zoom in; thresholds tuned experimentally
    const double threshold = 80;

    _zoomTimer?.cancel();

    if ((width < threshold && height < threshold) &&
        _currentZoom == _defaultZoom) {
      // Zoom in
      _animateZoom(2.0);

      // Back to normal after 1.8 seconds
      _zoomTimer = Timer(const Duration(milliseconds: 1800), () {
        _animateZoom(_defaultZoom);
      });
    }
  }

  void _animateZoom(double targetZoom) {
    // Guard target
    targetZoom = targetZoom.clamp(1.0, 5.0);
    _zoomAnimation = Tween<double>(
      begin: _currentZoom,
      end: targetZoom,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Remove previous listeners to avoid duplicates
    _zoomAnimation.removeListener(() {});

    // Each frame set controller zoom (best-effort)
    _zoomAnimation.addListener(() async {
      final val = _zoomAnimation.value;
      try {
        await widget.controller.setZoomScale(val);
      } catch (_) {
        // ignore if not supported
      }
    });

    _currentZoom = targetZoom;
    _animController.forward(from: 0);
  }

  // New: handle double-tap from user to reset zoom immediately
  void _onDoubleTap() {
    _zoomTimer?.cancel();
    _animateZoom(_defaultZoom);
  }

  void _onDetect(BarcodeCapture capture) async {
    // Try to visually zoom towards the QR region (best-effort)
    try {
      _autoZoom(capture);
    } catch (_) {}

    if (isProcessing) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // --- Animate border color on scan ---
    _colorResetTimer?.cancel();

    final isValid = code.isNotEmpty; // Or apply your validation here

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: isValid ? AppColors.primaryColor : Colors.red,
    ).animate(_colorAnimController);
    _colorAnimController.forward(from: 0);

    // After 500ms, animate back to white
    _colorResetTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _colorAnimation = ColorTween(
          begin: isValid ? AppColors.primaryColor : Colors.red,
          end: Colors.white,
        ).animate(_colorAnimController);
        _colorAnimController.forward(from: 0);
      }
    });
    // --- END border color animation block ---

    isProcessing = true;
    if (widget.onDetect != null) widget.onDetect!(code);

    // Keep a short delay to avoid repeated rapid triggers
    await Future.delayed(const Duration(seconds: 2));
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          MobileScanner(controller: widget.controller, onDetect: _onDetect),
          if (widget.showOverlay)
            IgnorePointer(
              ignoring: true,
              child: Center(
                child: CustomPaint(
                  size: const Size(
                    scanBoxSize,
                    scanBoxSize,
                  ), // fixed size scan box
                  painter: _QrOverlayPainter(borderColor: _borderColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  final Color borderColor;
  _QrOverlayPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint =
        Paint()
          ..color = borderColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final borderLength = 40.0;

    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(borderLength, 0), borderPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, borderLength), borderPaint);

    // Top-right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - borderLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, borderLength),
      borderPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(borderLength, size.height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - borderLength),
      borderPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - borderLength, size.height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
