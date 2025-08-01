import 'package:flutter/material.dart';
import 'package:scanprize_frontend/services/transfer_service.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/passcode.dart';
import '../widgets/attemp_time.dart';
import '../services/scanqr_prize.dart';
import '../widgets/confirm_transfer_dialog.dart';
// ignore: unused_import
import './transfer_animation.dart';
import '../models/exchange_prize_model.dart';
import '../utils/show_dialog_util.dart';
import '../services/user_balance_service.dart';
import '../widgets/transaction_detail.dart';

class EnterQuantityDialog extends StatefulWidget {
  final ExchangePrize prize;
  final String phoneNumber;
  final String scannedQr;

  const EnterQuantityDialog({
    super.key,
    required this.prize,
    required this.phoneNumber,
    required this.scannedQr,
  });

  @override
  State<EnterQuantityDialog> createState() => _EnterQuantityDialogState();
}

class _EnterQuantityDialogState extends State<EnterQuantityDialog> {
  String quantity = '0';
  bool _insufficientBalance = false;
  bool _showQuantityError = false;

  int get basePoints {
    final numericString = widget.prize.exchangePrizeValue.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final parsed = int.tryParse(numericString);

    assert(
      parsed != null,
      'Invalid ExchangePrizeValue: ${widget.prize.exchangePrizeValue}',
    );

    return parsed ?? 0;
  }

  int failedAttempts = 0;
  String? errorMessage;

  void onKeyPressed(String key) {
    setState(() {
      _insufficientBalance = false;
      if (key == '.' && quantity.contains('.')) return;

      if (quantity == '0' && key != '.') {
        quantity = key;
      } else {
        quantity += key;
      }
    });
  }

  Future<Map<String, dynamic>> _fetchUserPointsSummary() async {
    try {
      return await UserBalanceService.fetchUserBalances();
    } catch (e) {
      return {'ganzberg': 0, 'idol': 0, 'boostrong': 0, 'money': 0.0};
    }
  }

  void onBackspacePressed() {
    setState(() {
      if (quantity.isNotEmpty) {
        quantity = quantity.substring(0, quantity.length - 1);
        if (quantity.isEmpty) quantity = '0';
      }
    });
  }

  void onClearPressed() {
    setState(() {
      _insufficientBalance = false;
      quantity = '0';
    });
  }

  int getDeductedPoints() {
    int qty = int.tryParse(quantity) ?? 0;
    return qty * basePoints;
  }

  int getRemainingPoints() {
    // final category = widget.prize.companyCategoryName?.toLowerCase() ?? '';
    final category = widget.prize.companyCategoryName.toLowerCase();
    final currentPoints = _userPointsSummary[category] ?? 0;
    return currentPoints - getDeductedPoints();
  }

  Map<String, dynamic> _userPointsSummary = {
    'ganzberg': 0,
    'idol': 0,
    'boostrong': 0,
    'money': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserPointsSummary().then((summary) {
      setState(() {
        _userPointsSummary = summary;
      });
    });
  }

  // ignore: unused_element
  void _processTransfer() {
    // Implement transfer logic
  }

  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
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

  // In enter_quantity_dialog.dart
  Future<void> _confirmAndProcessTransfer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "សូមចូលឡើងវិញ",
          color: Colors.red,
        );
        return;
      }

      // Store the points before making the transfer
      final pointsToTransfer = getDeductedPoints();
      final int selectedQuantity = int.tryParse(quantity) ?? 0;
      final String selectedProductName = widget.prize.exchangePrizeName;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => ConfirmTransferDialog(
              points: getDeductedPoints(),
              recipientPhone: widget.phoneNumber,
              recipientName: "",
              companyCategoryName: widget.prize.companyCategoryName,
              productName: selectedProductName, // <-- add
              quantity: selectedQuantity, // <-- add
              onConfirm: (result) => Navigator.of(context).pop(result),
            ),
      );

      if (confirmed != true) return;

      final response = await TransferService.transferPoints(
        points: pointsToTransfer,
        productCategoryId: widget.prize.productCategoryID,
        recipientPhone: widget.phoneNumber,
        token: token,
      );

      if (response.statusCode == 200) {
        // Update local state
        final updatedSummary = await UserBalanceService.fetchUserBalances();
        setState(() {
          _userPointsSummary = updatedSummary;
          quantity = '0';
        });

        // Show transfer animation
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => TransferAnimation(
                  recipientPhone: widget.phoneNumber,
                  onAnimationComplete: () {
                    // Show transaction detail after animation
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => TransactionDetail(
                              transactionDate: DateTime.now(),
                              companyCategoryName:
                                  widget
                                      .prize
                                      .companyCategoryName, // Pass the exact category name
                              receiverPhone: widget.phoneNumber,
                              points: pointsToTransfer, // Use the stored points
                              productName: selectedProductName, // <-- add
                              quantity: selectedQuantity, // <-- add
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
        // Close the quantity dialog
        Navigator.of(context).pop();
      } else {
        final errorData = json.decode(response.body);
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: errorData['message'] ?? "ការផ្ទេរបានបរាជ័យ។",
          color: Colors.red,
        );
      }
    } catch (e) {
      await showResultDialog(
        context,
        title: "បរាជ័យ",
        message: "កំហុសមិនឃើញ: ${e.toString()}",
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int deductedPoints = getDeductedPoints();
    // ignore: unused_local_variable
    int remainingPoints = getRemainingPoints();

    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 350;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primaryColor,
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: screenWidth * 0.06,
                          ),
                          color: Colors.white,
                        ),
                        Flexible(
                          child: Text(
                            'ផ្ទេរទៅ ${formatPhoneNumber(widget.phoneNumber)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.12), // Balance the row
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  CircleAvatar(
                    radius: screenWidth * 0.08,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: screenWidth * 0.1,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Text(
                    'អ្នកទទួល​ ${formatPhoneNumber(widget.phoneNumber)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: screenWidth * 0.07,
                                top: screenHeight * 0.02,
                              ),
                              child: Text(
                                quantity.isEmpty ? '0' : quantity,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'x',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: screenHeight * 0.025,
                              ),
                              child:
                                  widget.prize.imageFileName.startsWith('http')
                                      ? Image.network(
                                        widget.prize.imageFileName,
                                        height: screenWidth * 0.15,
                                        width: screenWidth * 0.15,
                                      )
                                      : Image.network(
                                        'http://192.168.1.28:8080/uploads/${widget.prize.imageFileName}',
                                        height: screenWidth * 0.15,
                                        width: screenWidth * 0.15,
                                      ),
                            ),
                            Positioned(
                              top: 0,
                              right: -screenWidth * 0.1,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$basePoints ${widget.prize.companyCategoryName.toLowerCase() == 'money' ? 'D' : 'ពិន្ទុ'}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 10 : 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Points Information
                  Flexible(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                "កាត់ចេញពី: ${widget.prize.companyCategoryName}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenHeight * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                // Modified this line to check for Money category
                                '$deductedPoints ${widget.prize.companyCategoryName.toLowerCase() == 'money' ? 'D' : 'ពិន្ទុ'}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'សមតុល្យ: ${getRemainingPoints()} ${widget.prize.companyCategoryName.toLowerCase() == 'money' ? 'D' : 'ពិន្ទុ'} ${widget.prize.companyCategoryName}',
                          style: TextStyle(
                            color:
                                getRemainingPoints() < 0
                                    ? Colors.white70
                                    : Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                        if (_insufficientBalance)
                          Text(
                            'សមតុល្យ​អ្នកមិនគ្រប់គ្រាន់ទេ!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        if (_showQuantityError)
                          Text(
                            'សូមបញ្ចូលចំនួនយ៉ាងតិចមួយោះ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.07,
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        mainAxisSpacing: screenHeight * 0.02,
                        crossAxisSpacing: screenWidth * 0.04,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(12, (index) {
                          if (index == 9) return buildClearKey();
                          if (index == 10) return buildKey('0');
                          if (index == 11)
                            return buildIconKey(Icons.backspace_outlined);
                          return buildKey('${index + 1}');
                        }),
                      ),
                    ),
                  ),

                  // Transfer Button
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (quantity == '0' || quantity.isEmpty) {
                            setState(() {
                              _showQuantityError = true;
                            });
                            return;
                          } else {
                            setState(() {
                              _showQuantityError = false;
                            });
                          }
                          // Check balance first
                          if (getRemainingPoints() < 0) {
                            setState(() => _insufficientBalance = true);
                            return;
                          }
                          final prefs = await SharedPreferences.getInstance();
                          final userIdStr = prefs.getString('userId') ?? '';
                          final userId = int.tryParse(userIdStr) ?? 0;

                          final nowMillis =
                              DateTime.now().millisecondsSinceEpoch;
                          final unlockAtMillis =
                              prefs.getInt('passcode_unlock_at') ?? 0;
                          if (unlockAtMillis > nowMillis) {
                            final secondsLeft =
                                ((unlockAtMillis - nowMillis) / 1000).ceil();
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder:
                                  (context) => LockTimerDialog(
                                    initialSeconds: secondsLeft,
                                  ),
                            );
                            return;
                          }

                          final checkResp = await http.post(
                            Uri.parse(
                              '${Constants.apiUrl}/user-passcode/check',
                            ),
                            headers: {
                              "x-app-secret": Constants.appSecret,
                              "Content-Type": "application/json",
                            },
                            body: json.encode({"userId": userId}),
                          );
                          final isSet =
                              json.decode(checkResp.body)['isSet'] == true;

                          if (!isSet) {
                            final code1 = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => CustomPasscodeDialog(
                                    subtitle:
                                        'សូមធ្វើការបង្កើតលេខសម្ងាត់របស់អ្នក',
                                  ),
                            );
                            if (code1 == null || code1.length != 4) return;

                            final code2 = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => CustomPasscodeDialog(
                                    subtitle:
                                        'សូមផ្ទៀងផ្ទាត់លេខសម្ងាត់អ្នកម្តងទៀត',
                                  ),
                            );
                            if (code2 == null || code2.length != 4) return;

                            if (code1 != code2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'លេខសម្ងាត់ដែលអ្នកបញ្ចូលមិនដូឫគ្នា សូមបង្កើតម្តងទៀត',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            final createResp = await http.post(
                              Uri.parse(
                                '${Constants.apiUrl}/user-passcode/create',
                              ),
                              headers: {
                                "x-app-secret": Constants.appSecret,
                                "Content-Type": "application/json",
                              },
                              body: json.encode({
                                "userId": userId,
                                "passcode": code1,
                                "passcodeConfirm": code2,
                              }),
                            );

                            if (createResp.statusCode == 200) {
                              await _confirmAndProcessTransfer();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'បង្កើតលេខសម្ងាត់បរាជ័យ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            for (;;) {
                              final code = await showDialog<String>(
                                context: context,
                                builder:
                                    (context) => CustomPasscodeDialog(
                                      subtitle:
                                          'បញ្ចូលលេខសម្ងាត់របស់អ្នកដើម្បីបញ្ជាក់',
                                      errorMessage:
                                          errorMessage != null &&
                                                  failedAttempts > 0
                                              ? 'លេខសម្ងាត់មិនត្រឹមត្រូវ​ (អាចព្យាយាម​ ${(3 - failedAttempts)} ដងទៀត)'
                                              : null,
                                    ),
                              );
                              if (code == null || code.length != 4) return;

                              final verifyResp = await http.post(
                                Uri.parse(
                                  '${Constants.apiUrl}/user-passcode/verify',
                                ),
                                headers: {
                                  "x-app-secret": Constants.appSecret,
                                  "Content-Type": "application/json",
                                },
                                body: json.encode({
                                  "userId": userId,
                                  "passcode": code,
                                }),
                              );

                              if (verifyResp.statusCode == 200) {
                                setState(() {
                                  errorMessage = null;
                                  failedAttempts = 0;
                                });
                                await _confirmAndProcessTransfer();
                                break;
                              } else if (verifyResp.statusCode == 423) {
                                final waitSeconds =
                                    json.decode(
                                      verifyResp.body,
                                    )['waitSeconds'] ??
                                    0;
                                final unlockAt = DateTime.now().add(
                                  Duration(seconds: waitSeconds),
                                );
                                await prefs.setInt(
                                  'passcode_unlock_at',
                                  unlockAt.millisecondsSinceEpoch,
                                );

                                await showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder:
                                      (context) => LockTimerDialog(
                                        initialSeconds: waitSeconds,
                                      ),
                                );
                                break;
                              } else {
                                final respBody = json.decode(verifyResp.body);
                                setState(() {
                                  failedAttempts =
                                      respBody['failedAttempts'] ?? 0;
                                  errorMessage =
                                      'លេខសម្ងាត់មិនត្រឹមត្រូវ​ (អាចព្យាយាម​ ${(3 - failedAttempts)} ដងទៀត)';
                                });
                              }
                            }
                          }
                        },
                        child: const Text(
                          'ផ្ទេរឥឡូវ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Update key widgets to be responsive
  Widget buildKey(String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () => onKeyPressed(value),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildIconKey(IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onBackspacePressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: screenWidth * 0.07),
      ),
    );
  }

  Widget buildClearKey() {
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onClearPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          'C',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

//Correct with 781 line code changes
