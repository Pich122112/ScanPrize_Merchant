import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class TransactionShareService {
  static Future<bool> shareTransaction(
    GlobalKey globalKey,
    Map<String, dynamic> transaction,
    BuildContext context, // ✅ Added context parameter
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
      final String phoneNumber =
          transaction['FromPhoneNumber'] ??
          transaction['ToPhoneNumber'] ??
          'transaction';
      final File file = File('${tempDir.path}/transaction_$phoneNumber.png');
      await file.writeAsBytes(pngBytes);

      // ✅ Get the render box for share position origin (required for iOS)
      final box = context.findRenderObject() as RenderBox?;

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'share_transaction_message'.tr(),
        subject: 'share_transaction_subject'.tr(),
        sharePositionOrigin:
            box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null, // ✅ Critical for iOS
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      throw Exception('Failed to share transaction: $e');
    }
  }
}
