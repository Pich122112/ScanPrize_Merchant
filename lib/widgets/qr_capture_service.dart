import 'dart:io';
// ignore: unused_import
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';

class QrCaptureService {
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // First try with storage permission (works for most cases)
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // For Android 11+ (API 30+), try manage external storage
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      // As a last resort, try photos permission (for Android 13+)
      if (await Permission.photos.request().isGranted) {
        return true;
      }

      return false;
    }
    return true; // iOS doesn't need these permissions
  }

  static Future<String?> captureAndSaveQr(GlobalKey qrKey) async {
    try {
      // Wait for widget to render
      await Future.delayed(const Duration(milliseconds: 500));

      // Check permissions with more detailed error handling
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        debugPrint('Storage permission denied');
        // Open app settings to let user enable permissions
        await openAppSettings();
        return null;
      }

      // Capture the widget
      final boundary = qrKey.currentContext?.findRenderObject();
      if (boundary == null || !(boundary is RenderRepaintBoundary)) {
        debugPrint('RenderBoundary not found');
        return null;
      }

      // ignore: unnecessary_cast
      final image = await (boundary as RenderRepaintBoundary).toImage(
        pixelRatio: 3.0,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer.asUint8List();
      if (buffer == null) return null;

      // Use getExternalStorageDirectory for better compatibility
      final directory =
          Platform.isAndroid
              ? Directory('/storage/emulated/0/Pictures/GB_Prize')
              : await getApplicationDocumentsDirectory();

      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          debugPrint('Error creating directory: $e');
          return null;
        }
      }

      final fileName = 'GB_QR_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      try {
        final file = File(filePath);
        await file.writeAsBytes(buffer);
        debugPrint('File saved at: $filePath');
      } catch (e) {
        debugPrint('Error writing file: $e');
        return null;
      }

      // Use multiple methods to ensure gallery refresh
      bool refreshSuccess = false;

      // Method 1: Use media_scanner package
      try {
        final scanResult = await MediaScanner.loadMedia(path: filePath);
        debugPrint('MediaScanner result: $scanResult');
        refreshSuccess = scanResult != null;
      } catch (e) {
        debugPrint('MediaScanner error: $e');
      }

      // Method 2: Alternative refresh if first method failed
      if (!refreshSuccess) {
        try {
          await _refreshGallery(filePath);
          refreshSuccess = true;
        } catch (e) {
          debugPrint('Alternative refresh error: $e');
        }
      }

      if (!refreshSuccess) {
        debugPrint('Failed to refresh gallery');
      }

      return filePath;
    } catch (e, stack) {
      debugPrint('Error saving QR: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }

  static Future<void> _refreshGallery(String filePath) async {
    if (Platform.isAndroid) {
      try {
        // Method 1: Standard media scan intent
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath',
        ]);

        // Method 2: Alternative for some devices
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_MOUNTED',
          '-d',
          'file://${File(filePath).parent.path}',
        ]);
      } catch (e) {
        debugPrint('Gallery refresh error: $e');
        rethrow;
      }
    }
  }
}
