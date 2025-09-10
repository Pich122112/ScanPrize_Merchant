import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';

class TransactionShareService {
  static Future<void> shareTransaction(
    GlobalKey globalKey,
    String receiverPhone,
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
      final String phoneNumber = receiverPhone.replaceAll(RegExp(r'\D'), '');
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

  static Future<Uint8List> captureTransactionImage(GlobalKey globalKey) async {
    try {
      final RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to capture transaction image: $e');
    }
  }

  static Future<File> saveTransactionImageToTemp(
    Uint8List imageBytes,
    String receiverPhone,
  ) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String phoneNumber = receiverPhone.replaceAll(RegExp(r'\D'), '');
      final File file = File('${tempDir.path}/transaction_$phoneNumber.png');
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      throw Exception('Failed to save transaction image: $e');
    }
  }
}

//Correct with 73 line code changes
