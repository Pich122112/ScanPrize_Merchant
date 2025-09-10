import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../components/transfer_animation.dart';
import './transaction_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmTransferDialog extends StatelessWidget {
  final int points;
  final String recipientName;
  final String recipientPhone;
  final String companyCategoryName;
  final String productName;
  final int quantity;
  final Function(bool) onConfirm;

  const ConfirmTransferDialog({
    super.key,
    required this.points,
    required this.recipientName,
    required this.recipientPhone,
    required this.companyCategoryName,
    required this.onConfirm,
    required this.productName,
    required this.quantity,
  });

  // Add this method to get sender's phone
  Future<String> _getSenderPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone') ?? '';
  }

  // Phone number formatting function
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

  @override
  Widget build(BuildContext context) {
    final isDiamond = companyCategoryName.toLowerCase() == 'diamond';
    final pointsText = isDiamond ? 'Diamond' : 'score'.tr();
    final localeCode = context.locale.languageCode;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      title: Column(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 50,
            color: AppColors.primaryColor,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'are_you_sure_transfer'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$points $pointsText',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'confirm_transfer_to'.tr(
              namedArgs: {'phoneNumber': formatPhoneNumber(recipientPhone)},
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onPressed: () => onConfirm(false),
                child: Text(
                  'cancle'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                // Then modify the ElevatedButton's onPressed:
                onPressed: () async {
                  onConfirm(true);
                  Navigator.of(context).pop();

                  final senderPhone =
                      await _getSenderPhone(); // Get sender's phone

                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => TransferAnimation(
                            companyCategoryName: companyCategoryName,
                            recipientPhone: recipientPhone,
                            onAnimationComplete: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder:
                                      (context) => TransactionDetail(
                                        transactionDate: DateTime.now(),
                                        companyCategoryName:
                                            companyCategoryName,
                                        receiverPhone: recipientPhone,
                                        points: points,
                                        productName: productName,
                                        quantity: quantity,
                                        senderPhone: senderPhone,
                                      ),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'transfer'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Rotated arrow ↗
                    Transform.rotate(
                      angle: 0.25, // ~45 degrees in radians
                      child: Icon(
                        Icons.arrow_upward,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//Correct with 213 line code changes
