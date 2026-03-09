import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QrShareService {
  static Future<bool> shareQrCode(
    GlobalKey globalKey,
    String phoneNumber,
    BuildContext context, // Add context parameter
  ) async {
    try {
      final RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/qr_code_$phoneNumber.png');
      await file.writeAsBytes(pngBytes);

      // For iOS, we need to provide the share position origin
      final box = context.findRenderObject() as RenderBox?;

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'share_qr_message'.tr(),
        subject: 'share_qr_subject'.tr(),
        sharePositionOrigin:
            box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null, // ✅ null is safe - falls back to default behavior 99 666 358
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      throw Exception('Failed to share QR code: $e');
    }
  }
}
 