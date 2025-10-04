import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class QrShareService {
  static Future<bool> shareQrCode(
    GlobalKey globalKey,
    String phoneNumber,
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

      // 🔥 get result from share_plus
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'share_qr_message'.tr(),
        subject: 'share_qr_subject'.tr(),
      );

      return result.status ==
          ShareResultStatus.success; // ✅ return true only if shared
    } catch (e) {
      throw Exception('Failed to share QR code: $e');
    }
  }
}

//Correct with 43 line code changes
