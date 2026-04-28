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
import '../utils//constants.dart';

class QrScannerView extends StatefulWidget {
  final void Function(String code)? onDetect;
  final bool showOverlay;
  final MobileScannerController controller;

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
  final double _defaultZoom = 1.0;
  double _currentZoom = 1.0;
  Timer? _zoomTimer;
  double _targetZoom = 1.0;
  // ignore: unused_field
  bool _isAnimatingZoom = false;
  VoidCallback? _zoomTickListener;
  AnimationStatusListener? _zoomStatusListener;
  bool _userZoomed = false; // true when user double-tapped to zoom in

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
    // ignore: unnecessary_null_comparison
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
    // clamp and cancel pending auto-zoom timer
    targetZoom = targetZoom.clamp(1.0, 5.0);
    _zoomTimer?.cancel();
    _targetZoom = targetZoom;

    // stop any existing animation and remove listeners
    try {
      if (_zoomTickListener != null) {
        _animController.removeListener(_zoomTickListener!);
      }
    } catch (_) {}
    _zoomTickListener = null;

    try {
      if (_zoomStatusListener != null) {
        _animController.removeStatusListener(_zoomStatusListener!);
      }
    } catch (_) {}
    _zoomStatusListener = null;

    // Create fresh animation from current zoom to target
    _animController.reset();
    _zoomAnimation = Tween<double>(
      begin: _currentZoom,
      end: _targetZoom,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Tick listener: update controller with animation frames
    _zoomTickListener = () {
      final val = _zoomAnimation.value;
      // best-effort; don't await to avoid blocking UI
      widget.controller.setZoomScale(val).catchError((_) {});
    };
    _animController.addListener(_zoomTickListener!);

    // Replace the existing status handler inside _animateZoom with this block
    _zoomStatusListener = (AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        // finalize current zoom
        _currentZoom = _targetZoom;
        _isAnimatingZoom = false;

        // Debug print — show zoom finished and flags
        debugPrint(
          'zoom finished: _currentZoom=$_currentZoom target=$_targetZoom _userZoomed=$_userZoomed',
        );

        // If we've returned to default, allow auto-zoom again
        if ((_currentZoom - _defaultZoom).abs() < 0.05) {
          _userZoomed = false;
          debugPrint('zoom returned to default -> userZoomed cleared');
        }

        // if we just returned to default, restart the camera to refresh the preview.
        widget.controller
            .setZoomScale(_currentZoom)
            .then((_) async {
              debugPrint('setZoomScale succeeded -> currentZoom=$_currentZoom');

              // If returned to default, restart the camera to force preview refresh (platform-specific fix)
              if ((_currentZoom - _defaultZoom).abs() < 0.05) {
                try {
                  debugPrint('Restarting camera to refresh preview...');
                  await widget.controller.stop();
                  // tiny delay to let the camera fully stop
                  await Future.delayed(const Duration(milliseconds: 150));
                  await widget.controller.start();
                  debugPrint('Camera restart succeeded');
                } catch (e) {
                  debugPrint('Camera restart failed: $e');
                }
              }
            })
            .catchError((err) async {
              debugPrint(
                'setZoomScale failed on finalize: $err. Trying fallback.',
              );
              // Fallback: attempt to force default zoom then restart camera
              try {
                await widget.controller.setZoomScale(_defaultZoom);
                _currentZoom = _defaultZoom;
                debugPrint(
                  'fallback setZoomScale succeeded -> forced default zoom',
                );
                try {
                  await widget.controller.stop();
                  await Future.delayed(const Duration(milliseconds: 150));
                  await widget.controller.start();
                  debugPrint('Camera restart after fallback succeeded');
                } catch (e2) {
                  debugPrint('Camera restart after fallback failed: $e2');
                }
              } catch (err2) {
                debugPrint('fallback setZoomScale failed: $err2');
              }
            });

        // cleanup listeners
        try {
          if (_zoomTickListener != null) {
            _animController.removeListener(_zoomTickListener!);
          }
        } catch (_) {}
        _zoomTickListener = null;

        try {
          if (_zoomStatusListener != null) {
            _animController.removeStatusListener(_zoomStatusListener!);
          }
        } catch (_) {}
        _zoomStatusListener = null;
      }
    };
    _animController.addStatusListener(_zoomStatusListener!);

    _isAnimatingZoom = true;
    _animController.forward(from: 0);
  }

  void _onDoubleTap() {
    // cancel any auto-zoom timer (user action overrides auto)
    _zoomTimer?.cancel();

    const double userTargetZoom = 2.0;

    // Toggle user zoom state
    _userZoomed = !_userZoomed;

    final double target = _userZoomed ? userTargetZoom : _defaultZoom;

    debugPrint(
      'doubleTap -> userZoomed=$_userZoomed target=$target (current=$_currentZoom)',
    );

    // Animate toward the chosen target
    _animateZoom(target);

    // If user tapped to return to default, schedule a fallback check and restart
    if (!_userZoomed) {
      Future.delayed(const Duration(milliseconds: 400), () async {
        try {
          await widget.controller.setZoomScale(_defaultZoom);
          _currentZoom = _defaultZoom;
          debugPrint(
            'doubleTap -> forced reset to default zoom succeeded (setZoomScale)',
          );
        } catch (e) {
          debugPrint(
            'doubleTap -> forced setZoomScale failed: $e. Trying camera restart...',
          );
        }

        // Ensure preview updates by restarting camera as final fallback
        try {
          await widget.controller.stop();
          await Future.delayed(const Duration(milliseconds: 150));
          await widget.controller.start();
          _currentZoom = _defaultZoom;
          _userZoomed = false;
          debugPrint(
            'doubleTap -> camera restart fallback succeeded, preview refreshed',
          );
        } catch (e) {
          debugPrint('doubleTap -> camera restart fallback failed: $e');
        }
      });
    }
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
      end: isValid ? Colors.yellowAccent : Colors.red,
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
              child: CustomPaint(
                size: Size.infinite,
                painter: _QrOverlayPainter(
                  borderColor: _borderColor,
                  scanBoxSize: scanBoxSize,
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
  final double scanBoxSize;

  _QrOverlayPainter({required this.borderColor, required this.scanBoxSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate centered scan box position
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final scanBoxRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    // Draw dark overlay areas around the scan box
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.2);

    // Top dark area
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanBoxRect.top),
      darkPaint,
    );

    // Bottom dark area
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        scanBoxRect.bottom,
        size.width,
        size.height - scanBoxRect.bottom,
      ),
      darkPaint,
    );

    // Left dark area
    canvas.drawRect(
      Rect.fromLTWH(0, scanBoxRect.top, scanBoxRect.left, scanBoxSize),
      darkPaint,
    );

    // Right dark area
    canvas.drawRect(
      Rect.fromLTWH(
        scanBoxRect.right,
        scanBoxRect.top,
        size.width - scanBoxRect.right,
        scanBoxSize,
      ),
      darkPaint,
    );

    // Draw border corners
    final borderPaint =
        Paint()
          ..color = borderColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final borderLength = 40.0;

    // Top-left
    canvas.drawLine(
      scanBoxRect.topLeft,
      Offset(scanBoxRect.topLeft.dx + borderLength, scanBoxRect.topLeft.dy),
      borderPaint,
    );
    canvas.drawLine(
      scanBoxRect.topLeft,
      Offset(scanBoxRect.topLeft.dx, scanBoxRect.topLeft.dy + borderLength),
      borderPaint,
    );

    // Top-right
    canvas.drawLine(
      scanBoxRect.topRight,
      Offset(scanBoxRect.topRight.dx - borderLength, scanBoxRect.topRight.dy),
      borderPaint,
    );
    canvas.drawLine(
      scanBoxRect.topRight,
      Offset(scanBoxRect.topRight.dx, scanBoxRect.topRight.dy + borderLength),
      borderPaint,
    );

    // Bottom-left
    canvas.drawLine(
      scanBoxRect.bottomLeft,
      Offset(
        scanBoxRect.bottomLeft.dx + borderLength,
        scanBoxRect.bottomLeft.dy,
      ),
      borderPaint,
    );
    canvas.drawLine(
      scanBoxRect.bottomLeft,
      Offset(
        scanBoxRect.bottomLeft.dx,
        scanBoxRect.bottomLeft.dy - borderLength,
      ),
      borderPaint,
    );

    // Bottom-right
    canvas.drawLine(
      scanBoxRect.bottomRight,
      Offset(
        scanBoxRect.bottomRight.dx - borderLength,
        scanBoxRect.bottomRight.dy,
      ),
      borderPaint,
    );
    canvas.drawLine(
      scanBoxRect.bottomRight,
      Offset(
        scanBoxRect.bottomRight.dx,
        scanBoxRect.bottomRight.dy - borderLength,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

//Correct with 819 line code changes
