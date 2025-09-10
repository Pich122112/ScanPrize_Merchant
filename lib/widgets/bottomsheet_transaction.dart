import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gb_merchant/utils/transaction_share_service.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/constants.dart';

const channel = MethodChannel('qr_saver');

class TransactionDetailModal extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailModal({super.key, required this.transaction});

  @override
  State<TransactionDetailModal> createState() => _TransactionDetailModalState();
}

class _TransactionDetailModalState extends State<TransactionDetailModal> {
  final GlobalKey _receiptKey = GlobalKey(); // ✅ only receipt area
  bool _isSaving = false;
  bool _isSaved = false;
  bool _showBranding = false; // ✅ for logo + app name

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) return true;
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      if (await Permission.photos.request().isGranted) return true;
      return false;
    }
    return true;
  }

  Future<void> _refreshGallery(String filePath) async {
    if (Platform.isAndroid) {
      try {
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath',
        ]);
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_MOUNTED',
          '-d',
          'file://${File(filePath).parent.path}',
        ]);
      } catch (_) {}
    }
  }

  String _getFullWalletName(String code) {
    switch (code.toUpperCase()) {
      case 'GB':
        return 'Ganzberg';
      case 'BS':
        return 'Boostrong';
      case 'ID':
        return 'Idol';
      case 'DM':
        return 'Diamond';
      default:
        return code; // fallback to original if not matched
    }
  }

  /*
  Future<void> _saveTransactionAsImage() async {
    setState(() {
      _isSaving = true;
      _isSaved = false;
      _showBranding = true; // ✅ show branding only for saving
    });
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        setState(() {
          _isSaving = false;
          _showBranding = false; // hide again
        });
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final boundary = _receiptKey.currentContext?.findRenderObject();
      if (boundary == null || boundary is! RenderRepaintBoundary) {
        setState(() {
          _isSaving = false;
          _showBranding = false;
        });
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer.asUint8List();
      if (buffer == null) return;

      final directory =
          Platform.isAndroid
              ? Directory('/storage/emulated/0/Pictures/GB_Transactions')
              : await getApplicationDocumentsDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          'GB_Transaction_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      await File(filePath).writeAsBytes(buffer);

      try {
        await MediaScanner.loadMedia(path: filePath);
      } catch (_) {
        await _refreshGallery(filePath);
      }

      setState(() {
        _isSaving = false;
        _isSaved = true;
        // _showBranding = false; // ✅ hide branding again after save
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        // _showBranding = false;
      });
    }
  }
*/
  Future<void> _shareTransaction() async {
    setState(() {
      _showBranding = true; // Show branding for sharing
    });

    try {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Allow UI to update

      await TransactionShareService.shareTransaction(
        _receiptKey,
        widget.transaction,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to share transaction: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _showBranding = false; // Hide branding after sharing
      });
    }
  }

  Future<void> _saveTransactionAsImage() async {
    setState(() {
      _isSaving = true;
      _isSaved = false;
      _showBranding = true; // ✅ show branding only for saving
    });

    try {
      // Permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        setState(() {
          _isSaving = false;
          _showBranding = false;
        });
        return;
      }

      // Allow widget render
      await Future.delayed(const Duration(milliseconds: 500));

      final boundary = _receiptKey.currentContext?.findRenderObject();
      if (boundary == null || boundary is! RenderRepaintBoundary) {
        setState(() {
          _isSaving = false;
          _showBranding = false;
        });
        return;
      }

      // Capture
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer.asUint8List();
      if (buffer == null) throw Exception("Failed to convert to bytes");

      final fileName =
          'GB_Transaction_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isAndroid) {
        // ✅ Save to public Pictures folder
        final directory = Directory(
          '/storage/emulated/0/Pictures/GB_Transactions',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final filePath = '${directory.path}/$fileName';
        await File(filePath).writeAsBytes(buffer);

        try {
          // refresh gallery via native (replace MediaScanner with your MethodChannel if you want)
          await MediaScanner.loadMedia(path: filePath);
        } catch (e) {
          debugPrint("MediaScanner failed: $e");
          try {
            await _refreshGallery(filePath);
          } catch (e2) {
            debugPrint("Gallery refresh failed: $e2");
          }
        }

        setState(() {
          _isSaving = false;
          _isSaved = true;
          _showBranding = false;
        });
        return;
      }

      if (Platform.isIOS) {
        // ✅ Save to Photos via MethodChannel (qr_saver channel)
        try {
          final result = await channel.invokeMethod('saveToPhotos', {
            'bytes': buffer,
            'name': fileName,
          });
          debugPrint("iOS save result: $result");
          setState(() {
            _isSaving = false;
            _isSaved = true;
            _showBranding = false;
          });
        } catch (e) {
          debugPrint("iOS save error: $e");
          setState(() {
            _isSaving = false;
            _showBranding = false;
          });
        }
        return;
      }

      // Other platforms → just save locally
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      await File(filePath).writeAsBytes(buffer);

      setState(() {
        _isSaving = false;
        _isSaved = true;
        _showBranding = false;
      });
    } catch (e, stack) {
      debugPrint("Save error: $e\n$stack");
      setState(() {
        _isSaving = false;
        _showBranding = false;
      });
    }
  }

  String _avatarText(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855') && digits.length > 3) {
      final local = digits.substring(3);
      if (local.length >= 3) return local.substring(0, 3);
    }
    if (digits.length >= 3) return digits.substring(0, 3);

    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return '?';
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd / MMM / yyyy hh:mm a').format(dateTime);
    } catch (_) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final localeCode = context.locale.languageCode;

    final isCredit = transaction['is_credit'] ?? false;
    final transactionType = transaction['transaction_type'] ?? '';
    final fromUserName = transaction['FromUserName'] ?? 'N/A';
    final fromPhoneNumber = transaction['FromPhoneNumber'] ?? '';
    final toUserName = transaction['ToUserName'] ?? 'N/A';
    final toPhoneNumber = transaction['ToPhoneNumber'] ?? '';
    final int amount =
        transaction['Amount'] is int
            ? transaction['Amount']
            : int.tryParse(transaction['Amount'].toString()) ?? 0;
    final createdAt = transaction['created_at'] ?? '';
    final walletType = transaction['wallet_type'] ?? '';

    String formatPhoneNumber(String phone) {
      if (phone.isEmpty) return '';
      String digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('855')) digits = digits.substring(3);
      if (!digits.startsWith('0') && digits.isNotEmpty) digits = '0$digits';
      if (digits.length == 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      } else if (digits.length == 10) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return digits;
    }

    final String formattedFromPhone = formatPhoneNumber(fromPhoneNumber);
    final String formattedToPhone = formatPhoneNumber(toPhoneNumber);
    String title;
    Color amountColor;

    if (transactionType == 'transfer_out') {
      title =
          toPhoneNumber.isNotEmpty
              ? formatPhoneNumber(toPhoneNumber)
              : toUserName;
      amountColor = Colors.redAccent;
    } else if (transactionType == 'transfer_in') {
      title =
          fromPhoneNumber.isNotEmpty
              ? formatPhoneNumber(fromPhoneNumber)
              : fromUserName;
      amountColor = Colors.green;
    } else {
      title = transactionType;
      amountColor = Colors.grey;
    }

    final formattedDate = _formatDateTime(createdAt);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const ui.Color.fromARGB(0, 214, 214, 214),
            blurRadius: 8,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top bar
            Container(
              width: 40,
              height: 4,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 26,
              ), // 👈 add spacing
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 30),
            // ✅ Capture-only area
            RepaintBoundary(
              key: _receiptKey,
              child: Container(
                margin:
                    _showBranding
                        ? const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        )
                        : EdgeInsets.zero, // ← Margin only when saving
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const ui.Color.fromARGB(255, 255, 255, 255),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20), // 👈 space around card
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Header row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.yellow[700],
                          child: Text(
                            _avatarText(title),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily:
                                    localeCode == 'km' ? 'KhmerFont' : null,
                              ),
                            ),
                            Text(
                              '${isCredit ? '+' : '-'}${amount.abs()} ${"score".tr()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: 'KhmerFont',
                                fontSize: 20,
                                color: amountColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildDashedDivider(),
                    _buildInvoiceRow(
                      context,
                      transactionType == 'transfer_out'
                          ? 'Transfer To'
                          : 'Receive from',
                      transactionType == 'transfer_out'
                          ? (formattedToPhone.isNotEmpty
                              ? formattedToPhone
                              : toUserName)
                          : (formattedFromPhone.isNotEmpty
                              ? formattedFromPhone
                              : fromUserName),
                    ),
                    _buildDashedDivider(),
                    _buildInvoiceRow(
                      context,
                      'Wallet',
                      _getFullWalletName(walletType),
                      valueColor: AppColors.primaryColor,
                    ),
                    _buildDashedDivider(),
                    _buildInvoiceRow(
                      context,
                      'Amount',
                      '${isCredit ? '+' : '-'}${amount.abs()} ${"score".tr()}',
                      valueColor: amountColor,
                    ),
                    _buildDashedDivider(),
                    _buildInvoiceRow(context, 'Date', formattedDate),

                    if (_showBranding) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.asset(
                            'assets/images/logo.png', // ✅ replace with your logo path
                            height: 40,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "GANZBERG", // ✅ your app name
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                              fontFamily: 'KhmerFont',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Status outside capture
            if (_isSaving)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    'saving_transaction'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                      fontFamily: 'KhmerFont',
                    ),
                  ),
                ],
              )
            else if (_isSaved)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, size: 20, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'transaction_saved'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontFamily: 'KhmerFont',
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // ✅ Buttons outside capture
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconButton(
                  Icons.download_rounded,
                  "save".tr(),
                  _saveTransactionAsImage,
                ),
                const SizedBox(width: 30),
                _buildIconButton(
                  Icons.share_rounded,
                  "share".tr(),
                  _shareTransaction,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final localeCode = context.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 5.0;
          final dashSpace = 5.0;
          final dashCount =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return Container(
                width: dashWidth,
                height: 1,
                color: Colors.grey[300],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String text, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'KhmerFont',
          ),
        ),
      ],
    );
  }
}

//Correct with 678 line code changes
