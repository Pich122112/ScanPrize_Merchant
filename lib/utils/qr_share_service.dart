import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class QrShareService {
  static Future<void> shareQrCode(
    GlobalKey globalKey,
    String phoneNumber,
  ) async {
    try {
      // Capture the QR widget as an image
      final RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Create temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/qr_code_$phoneNumber.png');
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Hello, Here is my personal Ganzberg QR Code',
        subject: 'Ganzberg QR Code',
      );
    } catch (e) {
      throw Exception('Failed to share QR code: $e');
    }
  }
}

//Correct with 38 line code changes
