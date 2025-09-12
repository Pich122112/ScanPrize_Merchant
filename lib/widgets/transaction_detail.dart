import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/transaction_share_service.dart';

const _channel = MethodChannel('qr_saver');

class TransactionDetail extends StatefulWidget {
  final DateTime transactionDate;
  final String companyCategoryName;
  final String receiverPhone;
  final num points;
  final String? senderPhone;
  final bool isPointTransfer; // Add this parameter

  final String productName;
  final int quantity;
  const TransactionDetail({
    super.key,
    required this.transactionDate,
    required this.companyCategoryName,
    required this.receiverPhone,
    required this.points,
    required this.productName,
    required this.quantity,
    this.senderPhone,
    this.isPointTransfer = false,
  });

  @override
  State<TransactionDetail> createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  bool _isButtonClicked = false;
  String getCleanProductName(String name) {
    final RegExp regExp = RegExp(r'^\d+\s*');
    return name.replaceFirst(regExp, '');
  }

  final GlobalKey _transactionKey = GlobalKey();
  bool _isSaving = false;

  Future<bool> _requestPermissions() async {
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

  /*
  Future<void> _saveTransactionAsImage() async {
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localeCode = context.locale.languageCode;

    try {
      // Show loading snackbar
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 10),
              Text(
                'saving_transaction'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Check permissions with the same method as QR service
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('storage_permission_required'.tr()),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Wait for widget to render
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture the widget
      final boundary = _transactionKey.currentContext?.findRenderObject();
      if (boundary == null || !(boundary is RenderRepaintBoundary)) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('capture_failed'.tr())),
        );
        return;
      }

      final image = await (boundary as RenderRepaintBoundary).toImage(
        pixelRatio: 3.0,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer.asUint8List();

      if (buffer == null) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('capture_failed'.tr())),
        );
        return;
      }

      // Use the same directory structure as QR service for consistency
      final directory =
          Platform.isAndroid
              ? Directory('/storage/emulated/0/Pictures/GB_Transactions')
              : await getApplicationDocumentsDirectory();

      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('create_directory_failed'.tr())),
          );
          return;
        }
      }

      final fileName =
          'GB_Transaction_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      try {
        final file = File(filePath);
        await file.writeAsBytes(buffer);

        // Refresh gallery using the same method as QR service
        bool refreshSuccess = false;

        // Method 1: Use media_scanner package
        try {
          final scanResult = await MediaScanner.loadMedia(path: filePath);
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

        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Center(
              child: Text(
                'transaction_saved'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily:
                      context.locale.languageCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (e) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('save_failed'.tr()),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('error_occurred'.tr()),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
*/

  Future<void> _shareTransaction() async {
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localeCode = context.locale.languageCode;

    try {
      // Show loading
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'preparing_share'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Use the separate service for sharing
      await TransactionShareService.shareTransaction(_transactionKey, {
        'receiverPhone': widget.receiverPhone,
        'points': widget.points,
        'company': widget.companyCategoryName,
        'quantity': widget.quantity,
        'productName': widget.productName,
        'transactionDate': widget.transactionDate.toIso8601String(),
      });

      scaffoldMessenger.hideCurrentSnackBar();
    } catch (e, stack) {
      debugPrint("Share error: $e\n$stack");
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('share_failed'.tr()),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String formatPhoneNumber(String raw) {
    // Ensure we have a non-null string to work with
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    if (!digits.startsWith('0') && digits.isNotEmpty) {
      digits = '0$digits';
    }

    // Format with spaces for both 9 and 10 digit numbers
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }

    return digits;
  }

  Future<void> _saveTransactionAsImage() async {
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localeCode = context.locale.languageCode;

    try {
      // Show loading
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'saving_transaction'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('storage_permission_required'.tr()),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Capture widget
      final boundary = _transactionKey.currentContext?.findRenderObject();
      if (boundary == null || boundary is! RenderRepaintBoundary) {
        throw Exception("RenderBoundary not found");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData?.buffer.asUint8List();
      if (buffer == null) throw Exception("Failed to convert image to bytes");

      final fileName =
          'GB_Transaction_${DateTime.now().millisecondsSinceEpoch}.png';

      if (Platform.isAndroid) {
        // ✅ Save to public folder
        final directory = Directory(
          '/storage/emulated/0/Pictures/GB_Transactions',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final filePath = '${directory.path}/$fileName';
        await File(filePath).writeAsBytes(buffer);

        try {
          await MediaScanner.loadMedia(path: filePath);
        } catch (e) {
          debugPrint('MediaScanner failed: $e');
          try {
            await _refreshGallery(filePath);
          } catch (e2) {
            debugPrint('Gallery refresh failed: $e2');
          }
        }
      } else if (Platform.isIOS) {
        // ✅ Save into Photos via MethodChannel
        await _channel.invokeMethod('saveToPhotos', {
          'bytes': buffer,
          'name': fileName,
        });
      } else {
        // Fallback for other platforms
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        await File(filePath).writeAsBytes(buffer);
      }

      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Center(
            child: Text(
              'transaction_saved'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
              ),
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e, stack) {
      debugPrint("Save error: $e\n$stack");
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('save_failed'.tr()),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _refreshGallery(String filePath) async {
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
        // Ignore if manual refresh also fails
      }
    }
  }

  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // Try multiple possible directories
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return Directory('${externalDir.path}/Pictures/GB_Transactions');
        }
      } catch (e) {
        // Fall through to next option
      }

      try {
        return Directory('/storage/emulated/0/Pictures/GB_Transactions');
      } catch (e) {
        // Fall through to next option
      }

      try {
        return Directory('/storage/emulated/0/Download/GB_Transactions');
      } catch (e) {
        // Final fallback
        return await getApplicationDocumentsDirectory();
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _refreshGalleryManually(String filePath) async {
    if (Platform.isAndroid) {
      try {
        // Method 1: Use media scanner intent
        final result = await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath',
        ]);

        if (result.exitCode != 0) {
          // Method 2: Alternative approach
          await Process.run('am', [
            'broadcast',
            '-a',
            'android.intent.action.MEDIA_MOUNTED',
            '-d',
            'file://${Directory(filePath).parent.path}',
          ]);
        }
      } catch (e) {
        // Ignore if manual refresh also fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.03,
              ), // Success Animation/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Success Title
              Text(
                'done'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),

              SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.02, // 2% of screen height
              ),
              // Transaction Card
              _buildTransactionCard(),

              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    final localeCode = context.locale.languageCode; // 'km' or 'en'
    String logoAsset;
    switch (widget.companyCategoryName.toLowerCase()) {
      case 'gb':
      case 'ganzberg':
        logoAsset = 'assets/images/gblogo.png';
        break;
      case 'bs':
      case 'boostrong':
        logoAsset = 'assets/images/newbslogo.png';
        break;
      case 'id':
      case 'idol':
        logoAsset = 'assets/images/idollogo.png';
        break;
      case 'dm':
      case 'diamond':
        logoAsset = 'assets/images/diamond.png';
        break;
      default:
        logoAsset = 'assets/images/default.png';
    }

    // Add this helper method to translate units
    String _translateUnit(String unit) {
      if (localeCode == 'km') {
        switch (unit.toLowerCase()) {
          case 'can':
            return 'កំប៉ុង';
          case 'bottle':
            return 'ដប';
          case 'piece':
            return 'ប្រអប់';
          case 'pack':
            return 'ប៉ាក';
          default:
            return unit;
        }
      }
      return unit;
    }

    return RepaintBoundary(
      key: _transactionKey,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        padding: const EdgeInsets.only(
          top: 35,
          bottom: 35,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Row
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    logoAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.scaleDown,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '- ${widget.points is int ? widget.points : widget.points.toStringAsFixed(2)} ${widget.companyCategoryName.toLowerCase() == 'dm' || widget.companyCategoryName.toLowerCase() == 'diamond' ? "diamond".tr() : "score".tr()}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                          ),
                        ),
                        // Only show quantity if it's not a point transfer
                        if (!widget.isPointTransfer) SizedBox(width: 12),
                        if (!widget.isPointTransfer)
                          Text(
                            '( ${widget.quantity} ${_translateUnit('can')} )',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily:
                                  localeCode == 'km' ? 'KhmerFont' : null,
                            ),
                          ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        formatPhoneNumber(widget.receiverPhone),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.03,
            ), // Divider
            SizedBox(
              height: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: List.generate(
                      (constraints.maxWidth / 6).floor(), // dash count
                      (index) => Expanded(
                        child: Container(
                          color:
                              index.isEven
                                  ? Colors.grey.withOpacity(0.5) // dash color
                                  : Colors.transparent, // gap
                          height: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.03,
            ), // Transaction Details
            _buildDetailRow(
              Icons.calendar_today,
              "transaction_date".tr(),
              "${_formatDate(widget.transactionDate, context)} | ${_formatTime(widget.transactionDate)}",
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            _buildDetailRow(
              Icons.remove_circle,
              "deduct_from".tr(),
              widget.companyCategoryName,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            // Only show exchange type if it's not a point transfer
            if (!widget.isPointTransfer)
              _buildDetailRow(
                Icons.card_giftcard,
                "exchange_type".tr(),
                "x ${widget.quantity} ${_translateUnit('can')}",
              ),
            if (!widget.isPointTransfer)
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            _buildDetailRow(
              Icons.phone,
              "receiver".tr(),
              formatPhoneNumber(widget.receiverPhone),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            _buildDetailRow(
              Icons.star,
              "total_transfer".tr(),
              '${widget.points is int ? widget.points : widget.points.toStringAsFixed(2)} ${widget.companyCategoryName.toLowerCase() == 'dm' || widget.companyCategoryName.toLowerCase() == 'diamond' ? 'Diamond' : 'score'.tr()}',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final localeCode = context.locale.languageCode;

    final List<String> months =
        localeCode == 'km'
            ? [
              "មករា",
              "កុម្ភៈ",
              "មីនា",
              "មេសា",
              "ឧសភា",
              "មិថុនា",
              "កក្កដា",
              "សីហា",
              "កញ្ញា",
              "តុលា",
              "វិច្ឆិកា",
              "ធ្នូ",
            ]
            : [
              "Jan",
              "Feb",
              "Mar",
              "Apr",
              "May",
              "Jun",
              "Jul",
              "Aug",
              "Sep",
              "Oct",
              "Nov",
              "Dec",
            ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute$period';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final localeCode = context.locale.languageCode;

    return Row(
      children: [
        Icon(icon, color: Colors.black54, size: 16),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        children: [
          // Share/Save Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconButton(
                Icons.download_rounded,
                "save".tr(),
                _saveTransactionAsImage,
              ),
              SizedBox(width: MediaQuery.of(context).size.height * 0.04),
              _buildIconButton(
                Icons.share_rounded,
                "share".tr(),
                _shareTransaction,
              ),
            ], //998765566
          ),

          const SizedBox(height: 20),
          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: AppColors.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed:
                  _isButtonClicked
                      ? null
                      : () async {
                        setState(() => _isButtonClicked = true);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => RomlousApp()),
                          (Route<dynamic> route) => false,
                        );
                      },
              child: Text(
                "done".tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String text, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

//Correct with 956 line code changes
