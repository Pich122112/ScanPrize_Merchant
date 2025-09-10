import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class TransactionShareService {
  static Future<void> shareTransaction(
    GlobalKey globalKey,
    Map<String, dynamic> transaction,
  ) async {
    try {
      // Capture the transaction widget as an image
      final RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Create temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String phoneNumber =
          transaction['FromPhoneNumber'] ??
          transaction['ToPhoneNumber'] ??
          'transaction';
      final File file = File('${tempDir.path}/transaction_$phoneNumber.png');
      await file.writeAsBytes(pngBytes);

      // Share the file with translated text
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'share_transaction_message'.tr(),
        subject: 'share_transaction_subject'.tr(),
      );
    } catch (e) {
      throw Exception('Failed to share transaction: $e');
    }
  }
}

//Correct with 47 line code changes
