import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/app/bottomAppbar.dart';
import 'package:gb_merchant/services/passcode_service.dart';
import 'package:gb_merchant/services/transfer_service.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/qr_code_parser.dart';
import 'package:gb_merchant/widgets/remark_style.dart';
import '../models/exchange_prize_model.dart';
import '../services/user_balance_service.dart';
import '../utils/balance_refresh_notifier.dart';
import '../utils/show_dialog_util.dart';
import '../widgets/transaction_detail.dart';
import './transfer_animation.dart';
import '../services/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

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
  final TextEditingController _remarkController = TextEditingController();
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
      if (kDebugMode) {
        print('Error getting receiver name');
      }
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

  String _avatarText(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855') && digits.length >= 6) {
      // Take only the first three digits after 855
      return '0${digits.substring(3, 5)}';
    }
    if (digits.length >= 3) return digits.substring(0, 3);
    return '?';
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
    _remarkController.dispose(); // <-- add this

    _balanceNotifier?.removeListener(_handleBalanceRefresh);
    _balanceNotifier = null;
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _handleBalanceRefresh() {
    if (mounted) {
      if (kDebugMode) {
        print('DEBUG: Balance refresh notified in EnterQuantityDialog');
      }
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

  Future<void> _confirmAndProcessTransfer() async {
    try {
      // 1️⃣ Clean and validate phone number
      final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
      if (cleanPhone == 'Unknown' || !cleanPhone.startsWith('855')) {
        await showResultDialog(
          context,
          title: "បរាជ័យ",
          message: "លេខទូរស័ព្ទមិនត្រឹមត្រូវទេ",
          color: Colors.red,
        );
        return;
      }

      // 2️⃣ Get token & user phone from secure storage
      final secureStorage = SecureStorageService();
      final senderPhone = await secureStorage.getPhoneNumber() ?? '';
      // 3️⃣ Calculate points
      final int selectedQuantity = int.tryParse(quantity) ?? 0;
      final bool isWalletTransfer = widget.prize.point == 1;
      final pointsToTransfer =
          isWalletTransfer ? selectedQuantity : getDeductedPoints();
      final remainingPoints = getRemainingPoints();

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

      // 4️⃣ Verify receiver
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
      final verifiedPhone =
          receiverData['receiver']['phone_number'] ?? cleanPhone;

      // 5️⃣ Get QR signature
      final qrData = QrCodeParser.parseTransferQr(widget.scannedQr);
      // ignore: unused_local_variable
      final signature = qrData['signature'];
      if (kDebugMode) {
        print('DEBUG: Transfer initiated');
        print('Points: $pointsToTransfer');
      }

      // 6️⃣ Execute transfer
      final response = await TransferService.transferPoints(
        points: pointsToTransfer,
        walletId: widget.walletId,
        receiverId: receiverId,
        receiverPhone: verifiedPhone,
        prizeId: widget.fromWalletTab ? null : widget.prize.prizeId.toString(),
        prizePoint: widget.fromWalletTab ? null : widget.prize.point,
        qty: widget.fromWalletTab ? null : selectedQuantity,
        remark: _remarkController.text.trim(), // <-- add this line!
      );

      // 7️⃣ Handle response
      if (response.statusCode == 200) {
        await UserBalanceService.refreshBalancesAfterTransaction(
          isSender: true,
        );
        if (mounted) {
          final updatedSummary = await UserBalanceService.fetchUserBalances();
          setState(() {
            _userPointsSummary = updatedSummary;
            quantity = '0';
            _insufficientBalance = false;
          });
        }

        widget.onTransferSuccess?.call();

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) => TransferAnimation(
                    recipientPhone: widget.phoneNumber,
                    companyCategoryName: widget.prize.walletName,
                    onAnimationComplete: () {
                      final String transferUnit = widget.prize.unit;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder:
                              (_) => TransactionDetail(
                                transactionDate: DateTime.now(),
                                companyCategoryName: widget.prize.walletName,
                                receiverPhone: widget.phoneNumber,
                                points: pointsToTransfer,
                                productName:
                                    isWalletTransfer
                                        ? '${widget.prize.walletName} Points'
                                        : widget.prize.prizeName,
                                quantity: selectedQuantity,
                                senderPhone: senderPhone,
                                isPointTransfer:
                                    isWalletTransfer, // Set this flag
                                remark: _remarkController.text.trim(),
                                unit: transferUnit, // <-- Add this line!
                              ),
                        ),
                        (route) => false,
                      );
                    },
                  ),
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? "ការផ្ទេរបានបរាជ័យ។";

        if (message.contains('wallet_transaction_id')) {
          await showResultDialog(
            context,
            title: "System Error",
            message: "Please contact support. Database update required.",
            color: Colors.red,
          );
        } else if (message.toLowerCase().contains('insufficient')) {
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
            message: message,
            color: Colors.red,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Transfer failed');
      }
      String message;

      if (e.toString().contains('wallet_transaction_id')) {
        message = "Please contact support. Database update required.";
      } else if (e.toString().contains('No user found')) {
        message =
            context.locale.languageCode == 'km'
                ? "លេខទូរស័ព្ទនេះមិនត្រូវបានរកឃើញក្នុងប្រព័ន្ធទេ"
                : "This phone number was not found in the system";
      } else if (e.toString().contains('Insufficient balance')) {
        setState(() => _insufficientBalance = true);
        message =
            context.locale.languageCode == 'km'
                ? "មិនមានចំនួនពិន្ទុគ្រប់គ្រាន់"
                : "Insufficient balance";
      } else if (e.toString().contains(
        'You cannot select yourself as a receiver',
      )) {
        message =
            context.locale.languageCode == 'km'
                ? "អ្នកមិនអាចផ្ទេរទៅគណនីខ្លួនឯងបានទេ​!" // Khmer
                : "You cannot transfer to your own account!"; // English
      } else {
        message =
            context.locale.languageCode == 'km'
                ? "កំហុសមិនឃើញ: ${e.toString()}"
                : "Unknown error: ${e.toString()}";
      }
      await showResultDialog(
        context,
        title: context.locale.languageCode == 'km' ? "បរាជ័យ" : "Failed",
        message: message,
        color: Colors.red,
      );
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
                          backgroundColor: Colors.yellow[700],
                          child: Text(
                            _avatarText(widget.phoneNumber),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'KhmerFont',
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
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
                        SizedBox(height: screenHeight * 0.03),
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
                                              ? (widget.prize.walletName
                                                              .toLowerCase() ==
                                                          'dm' ||
                                                      widget.prize.walletName
                                                              .toLowerCase() ==
                                                          'diamond'
                                                  // For Diamond wallet show the diamond icon (keeps size similar to image)
                                                  ? Container(
                                                    width: 55,
                                                    height: 60,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.diamond,
                                                      size: 44,
                                                      color:
                                                          AppColors.textColor,
                                                    ),
                                                  )
                                                  // Other wallets keep showing the local asset
                                                  : Image.asset(
                                                    getPrizeImage(widget.prize),
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
                                                          Icons
                                                              .image_not_supported,
                                                          size: 30,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                      );
                                                    },
                                                  ))
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
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
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
                                                  if (kDebugMode) {
                                                    print(
                                                      "❌ Image load error: ${widget.prize.imageUrl}",
                                                    );
                                                  }
                                                  return Container(
                                                    width: 55,
                                                    height: 60,
                                                    color: Colors.grey[200],
                                                    child: Center(
                                                      child: Image.asset(
                                                        'assets/images/ganzberg_placeholder.png',
                                                        width: 50,
                                                        height: 60,
                                                        fit: BoxFit.contain,
                                                      ),
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
                                      child:
                                          widget.prize.walletName
                                                          .toLowerCase() ==
                                                      'dm' ||
                                                  widget.prize.walletName
                                                          .toLowerCase() ==
                                                      'diamond'
                                              ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '$basePoints ',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 10
                                                              : 12,
                                                      fontFamily:
                                                          localeCode == 'km'
                                                              ? 'KhmerFont'
                                                              : null,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.diamond,
                                                    size:
                                                        isSmallScreen ? 18 : 18,
                                                    color:
                                                        AppColors
                                                            .backgroundColor,
                                                  ),
                                                ],
                                              )
                                              : Text(
                                                '$basePoints ${_getBadgeTextForWallet(widget.prize.walletName)}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      isSmallScreen ? 10 : 12,
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
                        SizedBox(height: screenHeight * 0.03),
                        // Points Information
                        Flexible(
                          child: Column(
                            children: [
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
                                ],
                              ),
                              // Remark input field
                              SizedBox(height: screenHeight * 0.02),
                              RemarkInput(
                                controller: _remarkController,
                                localeCode: localeCode,
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
                        SizedBox(height: screenHeight * 0.02),
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
                                if (index == 11) {
                                  return buildIconKey(Icons.backspace_outlined);
                                }
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
                                      ? null
                                      : () async {
                                        // Step 1: Validate balance
                                        if (getRemainingPoints() < 0) {
                                          setState(
                                            () => _insufficientBalance = true,
                                          );
                                          return;
                                        }

                                        // Step 2: Require passcode (create or enter)
                                        final unlocked =
                                            await PasscodeService.requireUnlock(
                                              context,
                                              setExpiration: false,
                                            );
                                        if (!unlocked) return;

                                        // Step 3: Immediately proceed to transfer/animation
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

//Correct with 1235 line code changes
