import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:gb_merchant/services/passcode_service.dart';
import 'package:gb_merchant/services/transfer_service.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/qr_code_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import '../widgets/confirm_transfer_dialog.dart';
// ignore: unused_import
import './transfer_animation.dart';
import '../models/exchange_prize_model.dart';
import '../utils/show_dialog_util.dart';
import '../services/user_balance_service.dart';
import '../widgets/transaction_detail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../utils/balance_refresh_notifier.dart';

class EnterQuantityDialog extends StatefulWidget {
  final ExchangePrize prize;
  final String phoneNumber;
  final String scannedQr;
  final String receiverId;
  final String walletId;
  final String routeSource;
  final VoidCallback? onTransferSuccess;
  final bool fromWalletTab;

  const EnterQuantityDialog({
    super.key,
    required this.prize,
    required this.phoneNumber,
    required this.scannedQr,
    required this.receiverId,
    required this.walletId,
    this.routeSource = 'exchangeList',
    this.fromWalletTab = false,

    this.onTransferSuccess,
  });

  @override
  State<EnterQuantityDialog> createState() => _EnterQuantityDialogState();
}

class _EnterQuantityDialogState extends State<EnterQuantityDialog>
    with SingleTickerProviderStateMixin {
  String quantity = '0';
  bool _insufficientBalance = false;
  bool _noInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  BalanceRefreshNotifier? _balanceNotifier;
  bool get isWalletTransfer => widget.prize.point == 1;
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;
  int get basePoints {
    final numericString = widget.prize.point.toString();

    final parsed = int.tryParse(numericString);

    assert(parsed != null, 'Invalid ExchangePrizeValue: ${widget.prize.point}');

    return parsed ?? 0;
  }

  int failedAttempts = 0;
  String? errorMessage;

  void onKeyPressed(String key) {
    setState(() {
      if (key == '.' && quantity.contains('.')) return;

      if (quantity == '0' && key != '.') {
        quantity = key;
      } else {
        quantity += key;
      }

      // Auto-check balance after each key press
      _checkBalance();
    });
  }

  Future<Map<String, dynamic>> _fetchUserPointsSummary() async {
    try {
      return await UserBalanceService.fetchUserBalances();
    } catch (e) {
      return {'ganzberg': 0, 'idol': 0, 'boostrong': 0, 'diamond': 0.0};
    }
  }

  void onBackspacePressed() {
    setState(() {
      if (quantity.isNotEmpty) {
        quantity = quantity.substring(0, quantity.length - 1);
        if (quantity.isEmpty) quantity = '0';
      }

      // Auto-check balance after backspace
      _checkBalance();
    });
  }

  void onClearPressed() {
    setState(() {
      _insufficientBalance = false;
      quantity = '0';

      // Auto-check balance after clear
      _checkBalance();
    });
  }

  void _checkBalance() {
    final remainingPoints = getRemainingPoints();

    // Check if balance is insufficient
    if (remainingPoints < 0) {
      _insufficientBalance = true;
    } else {
      _insufficientBalance = false;
    }

    // Check if quantity is valid (at least 1)
    final quantityInt = int.tryParse(quantity) ?? 0;
    if (quantityInt < 1) {
      // You might want to set another flag for minimum quantity error
    } else {
      // Valid quantity
    }
  }

  int getDeductedPoints() {
    int qty = int.tryParse(quantity) ?? 0;
    return qty * basePoints;
  }

  String _mapWalletNameToBalanceKey(String walletName) {
    switch (walletName.toLowerCase()) {
      case 'gb':
        return 'ganzberg';
      case 'bs':
        return 'boostrong';
      case 'id':
        return 'idol';
      case 'dm':
        return 'diamond';
      default:
        return walletName.toLowerCase();
    }
  }

  Future<String?> _getReceiverName() async {
    try {
      // Parse the scanned QR code to get receiver information
      final qrData = QrCodeParser.parseTransferQr(widget.scannedQr);
      // ignore: unused_local_variable
      final signature = qrData['signature'];

      // If we have a receiver ID from QR parsing, try to get their name
      if (widget.receiverId.isNotEmpty && widget.receiverId != 'Unknown') {
        // Try to verify the receiver to get their name
        final receiverData = await TransferService.verifyReceiver(
          widget.phoneNumber,
        );

        if (receiverData != null && receiverData['receiver'] != null) {
          return receiverData['receiver']['name'] as String?;
        }
      }

      return null; // Return null if no name found
    } catch (e) {
      print('Error getting receiver name: $e');
      return null;
    }
  }

  String _getBadgeTextForWallet(String walletName) {
    final lowerCaseName = walletName.toLowerCase();

    if (lowerCaseName == 'dm' || lowerCaseName == 'diamond') {
      return 'D'; // Show "D" for Diamond wallet
    } else {
      return 'score'.tr(); // Show translated "Score" for other wallets
    }
  }

  int getRemainingPoints() {
    final walletKey = _mapWalletNameToBalanceKey(
      widget.prize.walletName.toLowerCase(),
    );
    final currentPoints = _userPointsSummary[walletKey] ?? 0;

    // Convert currentPoints to int if it's a double
    final int currentPointsInt;
    if (currentPoints is double) {
      currentPointsInt = currentPoints.toInt();
    } else if (currentPoints is int) {
      currentPointsInt = currentPoints;
    } else {
      currentPointsInt = 0;
    }

    if (isWalletTransfer) {
      // For wallet transfers, remaining points = current balance - quantity
      final quantityInt = int.tryParse(quantity) ?? 0;
      return currentPointsInt - quantityInt;
    } else {
      // For prize exchanges, remaining points = current balance - (quantity * basePoints)
      return currentPointsInt - getDeductedPoints();
    }
  }

  Map<String, dynamic> _userPointsSummary = {
    'ganzberg': 0,
    'idol': 0,
    'boostrong': 0,
    'diamond': 0,
  };

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _cursorAnimation = CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOut,
    );
    _fetchUserPointsSummary().then((summary) {
      setState(() {
        _userPointsSummary = summary;
      });
    });
    // Listen for balance refresh events
    _balanceNotifier = BalanceRefreshNotifier();
    _balanceNotifier?.addListener(_handleBalanceRefresh);

    // Check connection and listen for changes
    _checkConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool nowOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      setState(() {
        _noInternet = nowOffline;
      });
    });
  }

  String _getScoreTextForWallet(String walletName) {
    final lowerCaseName = walletName.toLowerCase();

    if (lowerCaseName == 'dm' || lowerCaseName == 'diamond') {
      return 'Diamond '; // Space added
    } else {
      return '${'score'.tr()} '; // Space added after translated "Score"
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();

    _balanceNotifier?.removeListener(_handleBalanceRefresh);
    _balanceNotifier = null;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _handleBalanceRefresh() {
    if (mounted) {
      print('DEBUG: Balance refresh notified in EnterQuantityDialog');
      _fetchUserPointsSummary().then((summary) {
        if (mounted) {
          setState(() {
            _userPointsSummary = summary;
          });
        }
      });
    }
  }

  int getDisplayBalance() {
    final remainingPoints = getRemainingPoints();
    // Return 0 if remaining points is negative, otherwise return the actual remaining points
    return remainingPoints < 0 ? 0 : remainingPoints;
  }

  Future<void> _checkConnection() async {
    var results = await Connectivity().checkConnectivity();
    setState(() {
      _noInternet =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    });
  }

  // String formatPhoneNumber(String raw) {
  //   return QrCodeParser.formatPhoneNumber(raw);
  // }

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

  String getPrizeImage(ExchangePrize prize) {
    // If from wallet tab, show wallet logos
    if (widget.fromWalletTab) {
      switch (prize.walletName.toLowerCase()) {
        case 'ganzberg':
        case 'gb':
          return 'assets/images/gblogo.png';
        case 'boostrong':
        case 'bs':
          return 'assets/images/newbslogo.png';
        case 'idol':
        case 'id':
          return 'assets/images/idollogo.png';
        case 'diamond':
        case 'dm':
          return 'assets/images/dmond.png';
        default:
          return 'assets/images/gblogo.png';
      }
    } else {
      // For exchange prizes, show the actual prize images based on prize ID or name
      // Use the same logic as in ExchangePrizeDialog to maintain consistency
      switch (prize.prizeName.toLowerCase()) {
        case 'snow':
        case 'gb':
          return 'assets/images/snow.png';
        case 'bscan':
        case 'bs':
          return 'assets/images/bscan.png';
        case 'canidol':
        case 'id':
          return 'assets/images/CanIdol.png';
        case 'dollas':
        case 'dm':
          return 'assets/images/dollas.png';
        default:
          // Fallback to wallet-specific images if prize name doesn't match
          switch (prize.walletName.toLowerCase()) {
            case 'ganzberg':
            case 'gb':
              return 'assets/images/gblogo.png';
            case 'boostrong':
            case 'bs':
              return 'assets/images/newbslogo.png';
            case 'idol':
            case 'id':
              return 'assets/images/idollogo.png';
            case 'diamond':
            case 'dm':
              return 'assets/images/dmond.png';
            default:
              return 'assets/images/default.png';
          }
      }
    }
  }

  // Transfer with confirm dialog
  // Future<void> _confirmAndProcessTransfer() async {
  //   try {
  //     // Validate phone number first
  //     final cleanPhone = widget.phoneNumber
  //         .replaceAll(' ', '')
  //         .replaceAll('-', '');

  //     if (cleanPhone == 'Unknown' || !cleanPhone.startsWith('855')) {
  //       await showResultDialog(
  //         context,
  //         title: "បរាជ័យ",
  //         message: "លេខទូរស័ព្ទមិនត្រឹមត្រូវទេ",
  //         color: Colors.red,
  //       );
  //       return;
  //     }

  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token');
  //     print("DEBUG TOKEN: $token");

  //     // Store the points before making the transfer
  //     final int selectedQuantity = int.tryParse(quantity) ?? 0;
  //     final String selectedProductName = widget.prize.prizeName;

  //     // Check if this is a wallet transfer (point value is 1)
  //     final bool isWalletTransfer = widget.prize.point == 1;
  //     final pointsToTransfer =
  //         isWalletTransfer ? selectedQuantity : getDeductedPoints();

  //     // ✅ FIRST VERIFY THE RECEIVER
  //     print('🔍 Verifying receiver: $cleanPhone');
  //     final receiverData = await TransferService.verifyReceiver(cleanPhone);

  //     if (receiverData == null || receiverData['receiver'] == null) {
  //       await showResultDialog(
  //         context,
  //         title: "បរាជ័យ",
  //         message: "មិនអាចផ្ទៀងផ្ទាត់អ្នកទទួលបានទេ",
  //         color: Colors.red,
  //       );
  //       return;
  //     }

  //     final receiverId = receiverData['receiver']['id'].toString();
  //     final receiverName = receiverData['receiver']['name'] ?? 'Unknown';
  //     final verifiedPhone =
  //         receiverData['receiver']['phone_number'] ?? cleanPhone;

  //     print(
  //       '✅ Verified receiver: $receiverName ($verifiedPhone) ID: $receiverId',
  //     );

  //     // Show confirmation dialog with verified receiver info
  //     final confirmed = await showDialog<bool>(
  //       context: context,
  //       builder:
  //           (context) => ConfirmTransferDialog(
  //             points: pointsToTransfer,
  //             recipientPhone: widget.phoneNumber,
  //             recipientName: receiverName,
  //             companyCategoryName: widget.prize.walletName,
  //             productName:
  //                 isWalletTransfer
  //                     ? '${widget.prize.walletName} Points'
  //                     : selectedProductName,
  //             quantity: selectedQuantity,
  //             onConfirm: (result) => Navigator.of(context).pop(result),
  //           ),
  //     );

  //     if (confirmed != true) return;

  //     // Get QR signature
  //     final qrData = QrCodeParser.parseTransferQr(widget.scannedQr);
  //     final signature = qrData['signature'];
  //     // ✅ UPDATED: TRANSFER WITH ADDITIONAL FIELDS
  //     // print('🔍 ======= BEFORE TRANSFER CALL =======');
  //     // print(
  //     //   '🔍 Prize ID: ${widget.prize.prizeId} (will convert to: ${widget.prize.prizeId.toString()})',
  //     // );
  //     // print('🔍 Prize Point: ${widget.prize.point}');
  //     // print('🔍 Quantity: $selectedQuantity');
  //     // print('🔍 Points to Transfer: $pointsToTransfer');
  //     // print('🔍 Wallet ID: ${widget.walletId}');
  //     // print('🔍 Receiver Phone: $verifiedPhone');
  //     // print('🔍 ===================================');

  //     // ✅ TRANSFER USING RECEIVER PHONE
  //     final response = await TransferService.transferPoints(
  //       points: pointsToTransfer,
  //       walletId: widget.walletId,
  //       receiverPhone: verifiedPhone,
  //       signature: signature,
  //       prizeId: widget.prize.prizeId.toString(), // Convert int to String
  //       prizePoint: widget.prize.point, // Add prize_point
  //       qty: selectedQuantity, // Add qty
  //     );

  //     if (response.statusCode == 200) {
  //       await UserBalanceService.refreshBalancesAfterTransaction(
  //         isSender: true,
  //       );

  //       // ✅ Check if widget is still mounted before calling setState
  //       // ✅ Update local state
  //       if (mounted) {
  //         final updatedSummary = await UserBalanceService.fetchUserBalances();
  //         setState(() {
  //           _userPointsSummary = updatedSummary;
  //           quantity = '0';
  //           _insufficientBalance = false;
  //           _showQuantityError = false;
  //         });
  //       }
  //       // ✅ Call the success callback if provided
  //       if (widget.onTransferSuccess != null) {
  //         widget.onTransferSuccess!();
  //       }

  //       final prefs = await SharedPreferences.getInstance();
  //       final senderPhone = prefs.getString('userPhone') ?? '';

  //       // Show transfer animation
  //       if (mounted) {
  //         await Navigator.of(context).push(
  //           MaterialPageRoute(
  //             builder:
  //                 (context) => TransferAnimation(
  //                   recipientPhone: widget.phoneNumber,
  //                   companyCategoryName: widget.prize.walletName,
  //                   onAnimationComplete: () {
  //                     Navigator.of(context).pushAndRemoveUntil(
  //                       MaterialPageRoute(
  //                         builder:
  //                             (context) => TransactionDetail(
  //                               transactionDate: DateTime.now(),
  //                               companyCategoryName: widget.prize.walletName,
  //                               receiverPhone: widget.phoneNumber,
  //                               points: pointsToTransfer,
  //                               productName:
  //                                   isWalletTransfer
  //                                       ? '${widget.prize.walletName} Points'
  //                                       : selectedProductName,
  //                               quantity: selectedQuantity,
  //                               senderPhone: senderPhone,
  //                             ),
  //                       ),
  //                       (route) => false,
  //                     );
  //                   },
  //                 ),
  //           ),
  //         );
  //       }

  //       // Close the quantity dialog
  //       if (mounted) {
  //         Navigator.of(context).pop();
  //       }
  //     } else {
  //       final errorData = json.decode(response.body);
  //       await showResultDialog(
  //         context,
  //         title: "បរាជ័យ",
  //         message: errorData['message'] ?? "ការផ្ទេរបានបរាជ័យ។",
  //         color: Colors.red,
  //       );
  //     }
  //   } catch (e) {
  //     print('❌ Transfer failed: $e');
  //     // Handle the specific case where no user is found
  //     if (e.toString().contains('No user found')) {
  //       await showResultDialog(
  //         context,
  //         title: "បរាជ័យ",
  //         message: "លេខទូរស័ព្ទនេះមិនត្រូវបានរកឃើញក្នុងប្រព័ន្ធទេ",
  //         color: Colors.red,
  //       );
  //     } else {
  //       await showResultDialog(
  //         context,
  //         title: "បរាជ័យ",
  //         message: "កំហុសមិនឃើញ: ${e.toString()}",
  //         color: Colors.red,
  //       );
  //     }
  //   }
  // }

  //Transfer without confirm dialog
  Future<void> _confirmAndProcessTransfer() async {
    try {
      // Validate phone number first
      final cleanPhone = widget.phoneNumber
          .replaceAll(' ', '')
          .replaceAll('-', '');

      if (cleanPhone == 'Unknown' || !cleanPhone.startsWith('855')) {
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "លេខទូរស័ព្ទមិនត្រឹមត្រូវទេ",
          color: Colors.red,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print("DEBUG TOKEN: $token");

      // Store the points before making the transfer
      final int selectedQuantity = int.tryParse(quantity) ?? 0;
      final String selectedProductName = widget.prize.prizeName;

      // Check if this is a wallet transfer (point value is 1)
      final bool isWalletTransfer = widget.prize.point == 1;
      final pointsToTransfer =
          isWalletTransfer ? selectedQuantity : getDeductedPoints();

      // ✅ Check balance BEFORE proceeding with verification
      final remainingPoints = getRemainingPoints();
      print('🔍 Current remaining points: $remainingPoints');
      print('🔍 Points to transfer: $pointsToTransfer');

      if (remainingPoints < 0) {
        setState(() => _insufficientBalance = true);
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "មិនមានចំនួនពិន្ទុគ្រប់គ្រាន់",
          color: Colors.red,
        );
        return;
      }

      // ✅ FIRST VERIFY THE RECEIVER
      print('🔍 Verifying receiver: $cleanPhone');
      final receiverData = await TransferService.verifyReceiver(cleanPhone);

      if (receiverData == null || receiverData['receiver'] == null) {
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "មិនអាចផ្ទៀងផ្ទាត់អ្នកទទួលបានទេ",
          color: Colors.red,
        );
        return;
      }

      final receiverId = receiverData['receiver']['id'].toString();
      final receiverName = receiverData['receiver']['name'] ?? 'Unknown';
      final verifiedPhone =
          receiverData['receiver']['phone_number'] ?? cleanPhone;

      print(
        '✅ Verified receiver: $receiverName ($verifiedPhone) ID: $receiverId',
      );

      // Get QR signature
      final qrData = QrCodeParser.parseTransferQr(widget.scannedQr);
      final signature = qrData['signature'];

      // DEBUG: Print all transfer parameters
      print('🔍 ======= TRANSFER PARAMETERS =======');
      print('🔍 Points: $pointsToTransfer');
      print('🔍 Wallet ID: ${widget.walletId}');
      print('🔍 Receiver Phone: $verifiedPhone');
      print('🔍 Signature: $signature');
      print('🔍 Prize ID: ${widget.prize.prizeId}');
      print('🔍 Prize Point: ${widget.prize.point}');
      print('🔍 Quantity: $selectedQuantity');
      print('🔍 ===================================');

      // ✅ TRANSFER
      final response = await TransferService.transferPoints(
        points: pointsToTransfer,
        walletId: widget.walletId,
        receiverId: receiverId,
        receiverPhone: verifiedPhone,
        prizeId: widget.fromWalletTab ? null : widget.prize.prizeId.toString(),
        prizePoint: widget.fromWalletTab ? null : widget.prize.point,
        qty: widget.fromWalletTab ? null : selectedQuantity,
      );

      if (response.statusCode == 200) {
        await UserBalanceService.refreshBalancesAfterTransaction(
          isSender: true,
        );

        // ✅ Check if widget is still mounted before calling setState
        if (mounted) {
          final updatedSummary = await UserBalanceService.fetchUserBalances();
          setState(() {
            _userPointsSummary = updatedSummary;
            quantity = '0';
            _insufficientBalance = false;
          });
        }

        // ✅ Call the success callback if provided
        if (widget.onTransferSuccess != null) {
          widget.onTransferSuccess!();
        }

        final prefs = await SharedPreferences.getInstance();
        final senderPhone = prefs.getString('userPhone') ?? '';

        // Show transfer animation
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => TransferAnimation(
                    recipientPhone: widget.phoneNumber,
                    companyCategoryName: widget.prize.walletName,
                    onAnimationComplete: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder:
                              (context) => TransactionDetail(
                                transactionDate: DateTime.now(),
                                companyCategoryName: widget.prize.walletName,
                                receiverPhone: widget.phoneNumber,
                                points: pointsToTransfer,
                                productName:
                                    isWalletTransfer
                                        ? '${widget.prize.walletName} Points'
                                        : selectedProductName,
                                quantity: selectedQuantity,
                                senderPhone: senderPhone,
                              ),
                        ),
                        (route) => false,
                      );
                    },
                  ),
            ),
          );
        }

        // Close the quantity dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ Transfer failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');

        // Handle database schema errors
        if (errorData['message']?.toString().contains(
              'wallet_transaction_id',
            ) ??
            false) {
          // This is a database schema issue - show appropriate message
          await showResultDialog(
            context,
            title: "System Error",
            message: "Please contact support. Database update required.",
            color: Colors.red,
          );
        }
        // Handle insufficient balance error from server
        else if (errorData['message']?.toString().toLowerCase().contains(
              'insufficient',
            ) ??
            false) {
          setState(() => _insufficientBalance = true);
          await showResultDialog(
            context,
            title: "បរាជ័យ",
            message: "មិនមានចំនួនពិន្ទុគ្រប់គ្រាន់",
            color: Colors.red,
          );
        } else {
          await showResultDialog(
            context,
            title: "បរាជ័យ",
            message: errorData['message'] ?? "ការផ្ទេរបានបរាជ័យ។",
            color: Colors.red,
          );
        }
      }
    } catch (e) {
      print('❌ Transfer failed: $e');

      // Handle database schema errors
      if (e.toString().contains('wallet_transaction_id')) {
        await showResultDialog(
          context,
          title: "System Error",
          message: "Please contact support. Database update required.",
          color: Colors.red,
        );
      }
      // Handle the specific case where no user is found
      else if (e.toString().contains('No user found')) {
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "លេខទូរស័ព្ទនេះមិនត្រូវបានរកឃើញក្នុងប្រព័ន្ធទេ",
          color: Colors.red,
        );
      } else if (e.toString().contains('Insufficient balance')) {
        setState(() => _insufficientBalance = true);
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "មិនមានចំនួនពិន្ទុគ្រប់គ្រាន់",
          color: Colors.red,
        );
      } else {
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "កំហុសមិនឃើញ: ${e.toString()}",
          color: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // int deductedPoints = getDeductedPoints();
    // ignore: unused_local_variable
    int remainingPoints = getRemainingPoints();

    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 350;
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          if (!_noInternet)
            Container(
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (widget.routeSource == 'exchangeList') {
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => RomlousApp(),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: screenWidth * 0.06,
                                ),
                                color: Colors.white,
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Flexible(
                                child: Text(
                                  'transfer_to'.tr(
                                    namedArgs: {
                                      'phoneNumber': formatPhoneNumber(
                                        widget.phoneNumber,
                                      ),
                                    },
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'KhmerFont',
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
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
                        // Text(
                        //   'អ្នកទទួល​ ${formatPhoneNumber(widget.phoneNumber)}',
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontWeight: FontWeight.bold,
                        //     fontSize: isSmallScreen ? 16 : 18,
                        //   ),
                        // ),
                        FutureBuilder<String?>(
                          future: _getReceiverName(),
                          builder: (context, snapshot) {
                            final receiverName =
                                snapshot.data ?? 'Unknown Name';

                            return Text(
                              receiverName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontFamily:
                                    localeCode == 'km' ? 'KhmerFont' : null,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.045),
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
                                        fontFamily:
                                            localeCode == 'km'
                                                ? 'KhmerFont'
                                                : null,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'x',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily:
                                          localeCode == 'km'
                                              ? 'KhmerFont'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              // Blinking cursor
                              SizedBox(width: screenWidth * 0.01),
                              FadeTransition(
                                opacity: _cursorAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 30,
                                  ), // 👈 pushes it down
                                  child: Text(
                                    '|',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.1, // smaller
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      height: 1.0, // baseline alignment
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: // Replace the Image.network section with this code:
                                          widget.fromWalletTab
                                              ? Image.asset(
                                                getPrizeImage(
                                                  widget.prize,
                                                ), // This returns asset paths for wallets
                                                width: 55,
                                                height: 60,
                                                fit: BoxFit.contain,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    width: 55,
                                                    height: 60,
                                                    color: Colors.grey[200],
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 30,
                                                      color: Colors.grey[400],
                                                    ),
                                                  );
                                                },
                                              )
                                              : Image.network(
                                                widget
                                                    .prize
                                                    .imageUrl, // ← USE API IMAGE URL for exchange prizes
                                                width: 55,
                                                height: 60,
                                                fit: BoxFit.contain,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    width: 55,
                                                    height: 60,
                                                    alignment: Alignment.center,
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  print(
                                                    "❌ Image load error: ${widget.prize.imageUrl}, error: $error",
                                                  );
                                                  return Container(
                                                    width: 55,
                                                    height: 60,
                                                    color: Colors.grey[200],
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 30,
                                                      color: Colors.grey[400],
                                                    ),
                                                  );
                                                },
                                              ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: -screenWidth * 0.14,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.03,
                                        vertical: screenHeight * 0.006,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$basePoints ${_getBadgeTextForWallet(widget.prize.walletName)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmallScreen ? 10 : 12,
                                          fontFamily:
                                              localeCode == 'km'
                                                  ? 'KhmerFont'
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        // Points Information
                        Flexible(
                          child: Column(
                            children: [
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: [
                              //     Flexible(
                              //       child: Text(
                              //         "deduct_from:  ${widget.prize.walletName}"
                              //             .tr(),
                              //         style: TextStyle(
                              //           color: Colors.white,
                              //           fontSize: isSmallScreen ? 14 : 16,
                              //           fontFamily:
                              //               localeCode == 'km'
                              //                   ? 'KhmerFont'
                              //                   : null,
                              //         ),
                              //         maxLines: 1,
                              //         overflow: TextOverflow.ellipsis,
                              //       ),
                              //     ),
                              //     SizedBox(width: screenWidth * 0.03),
                              //     Container(
                              //       padding: EdgeInsets.symmetric(
                              //         horizontal: screenWidth * 0.03,
                              //         vertical: screenHeight * 0.005,
                              //       ),
                              //       decoration: BoxDecoration(
                              //         color: Colors.white,
                              //         borderRadius: BorderRadius.circular(50),
                              //       ),
                              //       child: Text(
                              //         // Modified this line to check for diamond category
                              //         '$deductedPoints ${widget.prize.walletName.toLowerCase() == 'diamond' ? 'D' : 'ពិន្ទុ'}',
                              //         style: TextStyle(
                              //           color: Colors.red,
                              //           fontSize: isSmallScreen ? 12 : 14,
                              //           fontWeight: FontWeight.w600,
                              //           fontFamily:
                              //               localeCode == 'km'
                              //                   ? 'KhmerFont'
                              //                   : null,
                              //         ),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              SizedBox(height: screenHeight * 0.02),
                              Column(
                                children: [
                                  // Show current balance with modern design
                                  // Replace the current balance display section with this code:
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${'balance'.tr()}:  ',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  localeCode == 'km'
                                                      ? 'KhmerFont'
                                                      : null,
                                            ),
                                          ),
                                          // Use getDisplayBalance() instead of getRemainingPoints()
                                          TextSpan(
                                            text: '${getDisplayBalance()} ',
                                            style: TextStyle(
                                              color: AppColors.backgroundColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  localeCode == 'km'
                                                      ? 'KhmerFont'
                                                      : null,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                '${_getScoreTextForWallet(widget.prize.walletName)} ',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily:
                                                  localeCode == 'km'
                                                      ? 'KhmerFont'
                                                      : null,
                                            ),
                                          ),
                                          TextSpan(
                                            text: widget.prize.walletName,
                                            style: TextStyle(
                                              color: Colors.amber[300],
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              fontFamily:
                                                  localeCode == 'km'
                                                      ? 'KhmerFont'
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),

                              if (_insufficientBalance)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'notenoughbalance'.tr(),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontFamily:
                                          localeCode == 'km'
                                              ? 'KhmerFont'
                                              : null,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.055),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.11,
                            ),
                            child: GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              mainAxisSpacing: screenHeight * 0.01,
                              crossAxisSpacing: screenWidth * 0.03,
                              childAspectRatio: 2,
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
                        const SizedBox(height: 30),
                        // Transfer Button
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.05,
                            right: screenWidth * 0.05,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.065,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (quantity == '0' || quantity.isEmpty)
                                        ? Colors
                                            .grey // Default grey when invalid
                                        : Colors
                                            .black, // Active black when valid
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  (quantity == '0' ||
                                          quantity.isEmpty ||
                                          _insufficientBalance)
                                      ? null // Disabled when invalid
                                      : () async {
                                        // Step 1: Validate balance
                                        if (getRemainingPoints() < 0) {
                                          setState(
                                            () => _insufficientBalance = true,
                                          );
                                          return;
                                        }

                                        // Step 2: Require passcode
                                        final unlocked =
                                            await PasscodeService.requireUnlock(
                                              context,
                                              setExpiration: false,
                                            );
                                        if (!unlocked) return;

                                        // Step 3: Proceed transfer
                                        await _confirmAndProcessTransfer();
                                      },
                              child: Text(
                                'transfer_now'.tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontFamily:
                                      localeCode == 'km' ? 'KhmerFont' : null,
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
          // Fullscreen overlay message when NO INTERNET
          if (_noInternet)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.red, size: 60),
                    SizedBox(height: 24),
                    Text(
                      "មិនមានការតភ្ជាប់អ៊ីនធឺណិត",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        fontFamily: 'KhmerFont',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "សូមភ្ជាប់អ៊ីនធឺណិត រួចសាកល្បងម្តងទៀត",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontFamily: 'KhmerFont',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
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

//Correct with 1438 line code changes
