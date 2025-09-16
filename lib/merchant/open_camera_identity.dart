import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OpenCameraIdentity extends StatefulWidget {
  final bool isFront; // true = front ID, false = back ID
  const OpenCameraIdentity({super.key, required this.isFront});

  @override
  State<OpenCameraIdentity> createState() => _OpenCameraIdentityState();
}

class _OpenCameraIdentityState extends State<OpenCameraIdentity> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false, // Disable audio for photo capture
    );
    await _cameraController!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null) {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        Navigator.pop(context, imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;

    try {
      final XFile file = await _cameraController!.takePicture();
      final savedImage = File(file.path);
      Navigator.pop(context, savedImage); // This returns the File
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isCameraInitialized
              ? Stack(
                children: [
                  /// Full screen camera preview
                  Positioned.fill(child: CameraPreview(_cameraController!)),

                  /// Semi-transparent overlay with cutout
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DocumentFramePainter(
                        cutoutWidth: MediaQuery.of(context).size.width * 0.85,
                        cutoutHeight: MediaQuery.of(context).size.height * 0.28,
                      ),
                    ),
                  ),

                  /// Instruction Text
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 80,
                    left: 20,
                    right: 20,
                    child: const Text(
                      "Position your document inside the frame.\nMake sure the document is correct and clear enough.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  /// Top Bar Icons
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleFlash,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(
                                  Icons.help_outline,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  // Show help dialog
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Bottom Capture Controls
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          widget.isFront ? "ID CARD (Front)" : "ID CARD (Back)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Gallery button
                            IconButton(
                              icon: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: _pickImageFromGallery,
                            ),
                            const SizedBox(width: 40),

                            // Capture Button
                            GestureDetector(
                              onTap: _takePicture,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),

                            // Flip camera button (disabled if only one camera)
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed:
                                  (_cameras?.length ?? 0) > 1
                                      ? () {
                                        // Implement camera flip logic
                                      }
                                      : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
    );
  }
}

/// Custom Painter for the transparent frame
class DocumentFramePainter extends CustomPainter {
  final double cutoutWidth;
  final double cutoutHeight;

  const DocumentFramePainter({this.cutoutWidth = 300, this.cutoutHeight = 200});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..style = PaintingStyle.fill;

    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: cutoutWidth,
        height: cutoutHeight,
      ),
      const Radius.circular(12),
    );

    // Full screen dark layer
    final fullRect =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cut-out area (document frame)
    final cutoutPath = Path()..addRRect(cutoutRect);

    // Apply difference (screen dark except cutout)
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullRect,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, paint);

    // White border around cutout
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(cutoutRect, borderPaint);

    // Add corner indicators
    final cornerPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final cornerOffset = 16.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left + cornerOffset, cutoutRect.top)
        ..lineTo(cutoutRect.left, cutoutRect.top)
        ..lineTo(cutoutRect.left, cutoutRect.top + cornerOffset),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - cornerOffset, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top + cornerOffset),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.bottom - cornerOffset)
        ..lineTo(cutoutRect.left, cutoutRect.bottom)
        ..lineTo(cutoutRect.left + cornerOffset, cutoutRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - cornerOffset, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom - cornerOffset),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//Correct with 352 line code changes
