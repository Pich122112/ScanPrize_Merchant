import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import '../components/transfer_animation.dart';
import './transaction_detail.dart';

class ConfirmTransferDialog extends StatelessWidget {
  final int points;
  final String recipientName;
  final String recipientPhone;
  final String companyCategoryName; // Add this property
  final String productName; // Add this property
  final int quantity; // Add this property

  final Function(bool) onConfirm;

  const ConfirmTransferDialog({
    super.key,
    required this.points,
    required this.recipientName,
    required this.recipientPhone,
    required this.companyCategoryName, // Add this parameter
    required this.onConfirm,
    required this.productName, // Add this parameter
    required this.quantity, // Add this parameter
  });

  // Phone number formatting function
  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Remove 855 country code if present at the start
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    // Add leading zero if not present
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    // Format 3-3-3 for Cambodian numbers
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    // fallback
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      title: Column(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 48,
            color: AppColors.primaryColor,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'តើអ្នកពិតជាចង់ផ្ទេរ',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '$points ពិន្ទុ',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ទៅគណនី ${formatPhoneNumber(recipientPhone)} មែនឬទេ?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                  'បោះបង់',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                onPressed: () async {
                  onConfirm(true);
                  Navigator.of(context).pop(); // Close the confirmation dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => TransferAnimation(
                            recipientPhone: recipientPhone,
                            onAnimationComplete: () {
                              Navigator.of(context).push(
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
                                        onComplete: () {
                                          Navigator.of(
                                            context,
                                          ).popUntil((route) => route.isFirst);
                                        },
                                      ),
                                ),
                              );
                            },
                          ),
                    ),
                  );
                },
                child: const Text(
                  'ផ្ទេរ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//Correct with 162 line code changes
