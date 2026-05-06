import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/widgets/bottomsheet_transaction.dart';
import '../services/user_transaction_service.dart';
import 'dart:async';

class TransactionByAccount extends StatefulWidget {
  final String account; // 'GB', 'BS', 'ID', 'DM'
  final String? logoPath;
  final Widget? logoWidget;
  final int balance;
  const TransactionByAccount({
    super.key,
    required this.account,
    this.logoPath,
    this.logoWidget,
    required this.balance,
  });

  @override
  State<TransactionByAccount> createState() => _TransactionByAccountState();
}

class _TransactionByAccountState extends State<TransactionByAccount> {
  late Future<List<Map<String, dynamic>>> _futureTransactions;
  bool _noInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late ScrollController _scrollController;
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollDirection);
    _checkConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool nowOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      setState(() {
        _noInternet = nowOffline;
      });
      // Optionally: refetch transactions when back online
      if (!nowOffline) {
        setState(() {
          _futureTransactions = UserTransactionService.fetchUserTransactions(
            widget.account,
          );
        });
      }
    });
    _futureTransactions = UserTransactionService.fetchUserTransactions(
      widget.account,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollDirection);
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _handleScrollDirection() {
    if (!_scrollController.hasClients) return;

    // Hide FAB if at the very top
    if (_scrollController.offset <= 0) {
      if (_showFAB) {
        setState(() {
          _showFAB = false;
        });
      }
      return;
    }

    // Get scroll direction
    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.forward && !_showFAB) {
      setState(() {
        _showFAB = true;
      });
    } else if (direction == ScrollDirection.reverse && _showFAB) {
      setState(() {
        _showFAB = false;
      });
    }
  }

  Future<void> _checkConnection() async {
    var results = await Connectivity().checkConnectivity();
    setState(() {
      _noInternet =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    });
  }

  // Add this helper method to _TransactionByAccountState
  String _getWalletUnit(String accountCode) {
    switch (accountCode.toUpperCase()) {
      case 'DM':
        return 'Diamond';
      case 'GB':
      case 'BS':
      case 'ID':
      default:
        return 'score'.tr();
    }
  }

  // Add this helper method to _TransactionByAccountState class
  // Update the _formatDateTime method to handle both ISO strings and formatted dates
  // Update the _formatDateTime method to handle DD/MM/YYYY format
  String _formatDateTime(String dateString, BuildContext context) {
    try {
      DateTime date;

      if (dateString.contains('/')) {
        // Parse DD/MM/YYYY format (common in many countries)
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          date = DateTime(year, month, day);
        } else {
          return dateString;
        }
      } else {
        // Parse ISO date string
        date = DateTime.parse(dateString).toLocal();
      }

      final localeCode = context.locale.languageCode;

      if (localeCode == 'km') {
        // Khmer date format
        final months = [
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
        ];

        final month = months[date.month - 1];
        final day = date.day;
        final year = date.year;

        return "$day $month $year";
      } else {
        // English date format
        final months = [
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

        final month = months[date.month - 1];
        final day = date.day;
        final year = date.year;

        return "$month $day, $year";
      }
    } catch (e) {
      return dateString; // fallback if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return Scaffold(
      body: Stack(
        children: [
          Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Column(
                children: [
                  // --- Header and account info ---
                  Container(
                    alignment: Alignment.topLeft,
                    decoration: const BoxDecoration(),
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 60,
                      bottom: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 18, height: 40),
                            Expanded(
                              child: Text(
                                'history'.tr(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily:
                                      localeCode == 'km' ? 'KhmerFont' : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child:
                                  widget.logoWidget ??
                                  (widget.logoPath != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.asset(
                                          widget.logoPath!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                      : Icon(
                                        Icons.account_circle, // fallback icon
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      )),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'balance'.tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily:
                                        localeCode == 'km' ? 'KhmerFont' : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.balance} ${_getWalletUnit(widget.account)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'KhmerFont',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Transaction History ---
                  Expanded(
                    child:
                        _noInternet
                            ? Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                              ),
                              child: Center(
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 6,
                                  shadowColor: Colors.red.withOpacity(0.2),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 32,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.wifi_off_rounded,
                                          color: Colors.red.shade400,
                                          size: 80,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'no_internet'.tr(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'KhmerFont',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'check_connection'.tr(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontFamily: 'KhmerFont',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            : FutureBuilder<List<Map<String, dynamic>>>(
                              future: _futureTransactions,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  // Detect server/network errors and show a friendly message
                                  String message = snapshot.error.toString();
                                  if (message.contains('502') ||
                                      message.contains('503') ||
                                      message.contains('504') ||
                                      message.contains('SocketException') ||
                                      message.toLowerCase().contains('fail') ||
                                      message.toLowerCase().contains(
                                        'server',
                                      )) {
                                    message = 'server_problem_message'.tr();
                                  }
                                  return Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 32,
                                      ),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.97),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.13,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.cloud_off,
                                            color: Colors.red,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            message,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                              fontFamily: 'KhmerFont',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'you_not_have_any_transaction'.tr(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'KhmerFont',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final groupedByDate = snapshot.data!;

                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: groupedByDate.length,
                                  itemBuilder: (context, index) {
                                    final group = groupedByDate[index];
                                    final dateLabel = group['date'];
                                    final allTransactions =
                                        group['transactions']
                                            as List<Map<String, dynamic>>;

                                    // Filter out transfers to/from self
                                    final filteredTransactions =
                                        allTransactions.where((item) {
                                          final fromPhone =
                                              item['FromPhoneNumber'] ?? '';
                                          final toPhone =
                                              item['ToPhoneNumber'] ?? '';
                                          return fromPhone !=
                                              toPhone; // Exclude transfers from self to self
                                        }).toList();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        sectionTitle(
                                          dateLabel,
                                          context,
                                        ), // Pass context here
                                        // Show ALL transactions in chronological order (newest first)
                                        ...filteredTransactions.map(
                                          (item) => transactionSummaryTile(
                                            name:
                                                item['is_credit'] == true
                                                    ? item['FromUserName'] ??
                                                        'N/A'
                                                    : item['ToUserName'] ??
                                                        'N/A',
                                            phone:
                                                item['is_credit'] == true
                                                    ? item['FromPhoneNumber'] ??
                                                        ''
                                                    : item['ToPhoneNumber'] ??
                                                        '',
                                            points: item['Amount'],
                                            isIn: item['is_credit'] == true,
                                            account:
                                                item['wallet_type'] ??
                                                widget.account,
                                            transactionType: item['Type'],
                                            transactionData: item,
                                            context: context,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          _showFAB
              ? RawMaterialButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                  );
                },
                fillColor: Colors.white,
                shape: const CircleBorder(),
                constraints: const BoxConstraints.tightFor(
                  width: 56,
                  height: 56,
                ),
                elevation: 2,
                child: Icon(Icons.arrow_upward, color: AppColors.primaryColor),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget sectionTitle(String title, BuildContext context) {
    // Parse the date and format it based on locale
    final formattedDate = _formatDateTime(title, context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        formattedDate,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: context.locale.languageCode == 'km' ? 'KhmerFont' : null,
        ),
      ),
    );
  }

  static Widget transactionSummaryTile({
    required String name,
    required String phone,
    required num points,
    required bool isIn,
    required String account,
    required String transactionType,
    required Map<String, dynamic> transactionData,
    required BuildContext context,
  }) {
    final String unit = _getWalletUnitStatic(account);
    final dynamic qtyValue = transactionData['qty']; // Get the raw qty value
    final bool showQuantity = qtyValue != null; // Only show if qty is not null

    final localeCode = Localizations.localeOf(context).languageCode;

    String formatPhoneNumber(String raw) {
      String digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('855')) {
        digits = digits.substring(3);
      }
      if (!digits.startsWith('0') && digits.isNotEmpty) {
        digits = '0$digits';
      }
      if (digits.length == 9) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      } else if (digits.length == 10) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return digits;
    }

    String getTransactionTitle(bool isIn) {
      return isIn
          ? 'transaction_received_from'.tr()
          : 'transaction_sent_to'.tr();
    }

    String getDisplayName() {
      // If name is present and looks like a phone number, format it!
      final digits = name.replaceAll(RegExp(r'\D'), '');
      if (name != 'N/A' &&
          name.isNotEmpty &&
          digits.length >= 9 &&
          (digits.startsWith('855') || digits.startsWith('0'))) {
        return formatPhoneNumber(name);
      }
      // If name is present and not a phone number, show as is
      if (name != 'N/A' && name.isNotEmpty) {
        return name;
      }
      // Fallback to phone, format if possible
      final displayPhone = formatPhoneNumber(phone);
      if (displayPhone.isNotEmpty) {
        return displayPhone;
      }
      // Fallback default
      return isIn ? 'អ្នកប្រើប្រាស់' : 'អ្នកទទួល';
    }

    String getQuantityUnit(String accountCode) {
      switch (accountCode.toUpperCase()) {
        case 'GB':
          return 'can';
        case 'BS':
          return 'can';
        case 'ID':
          return 'can';
        case 'DM':
          return 'piece';
        default:
          return 'piece';
      }
    }

    String translateUnit(String unit) {
      if (localeCode == 'km') {
        switch (unit.toLowerCase()) {
          case 'can':
            return 'កំប៉ុង';
          case 'case':
            return 'កេស';
          case 'bottle':
            return 'ដប';
          case 'shirt':
            return 'អាវ';
          case 'ball':
            return 'បាល់';
          case 'umbrella':
            return 'ឆ័ត្រ';
          case 'dolla':
            return 'ដុល្លា';
          case 'helmet':
            return 'មួក';
          case 'bucket':
            return 'ធុងទឹកកក';
          case 'motor':
            return 'ម៉ូតូ';
          case 'car':
            return 'ឡាន';
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

    // Determine the correct unit based on transaction data
    String getUnitFromTransaction(
      Map<String, dynamic> transactionData,
      String account,
    ) {
      // If the API provides a "unit" field in the transaction, use it (with translation)
      final dynamic unitFromApi = transactionData['unit'];
      if (unitFromApi != null && unitFromApi.toString().isNotEmpty) {
        return translateUnit(unitFromApi.toString());
      }
      // Fallback to default mapping
      return translateUnit(getQuantityUnit(account));
    }

    final String quantityUnit = getUnitFromTransaction(
      transactionData,
      account,
    );
    final IconData icon = isIn ? Icons.arrow_downward : Icons.arrow_upward;
    final double rotation = isIn ? 0.8 : 0.8;
    final Color iconColor = Colors.white;
    final Color containerColor = isIn ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () {
        // Create a copy of transactionData with the correct wallet_type
        final modifiedTransactionData = Map<String, dynamic>.from(
          transactionData,
        );
        modifiedTransactionData['wallet_type'] = account; // Add the wallet_type
        modifiedTransactionData['remark'] ??=
            'This is a test remark.'; // <-- add this line for testing

        // Show transaction detail modal like in notification code
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) =>
                  TransactionDetailModal(transaction: modifiedTransactionData),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: containerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
          ),
          title: Text(
            getTransactionTitle(isIn),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'KhmerFont',
            ),
          ),
          subtitle: Text(
            getDisplayName(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'KhmerFont',
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${isIn ? "+" : "-"}$points ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIn ? Colors.green : Colors.red,
                      fontSize: 20,
                      fontFamily: 'KhmerFont',
                    ),
                  ),
                  // Show diamond icon when account is DM, otherwise show unit text
                  if (account.toUpperCase() == 'DM')
                    Icon(
                      Icons.diamond,
                      size: 22,
                      color: isIn ? Colors.green : Colors.red,
                    )
                  else
                    Text(
                      unit,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIn ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontFamily: 'KhmerFont',
                      ),
                    ),
                ],
              ),
              // Only show quantity if available
              if (showQuantity) const SizedBox(height: 4),
              if (showQuantity)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'x $qtyValue ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isIn ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerFont',
                      ),
                    ),
                    // For DM show a small diamond icon as the unit, otherwise show translated unit text
                    if (account.toUpperCase() == 'DM')
                      Icon(
                        Icons.diamond,
                        size: 12,
                        color: isIn ? Colors.red : Colors.green,
                      )
                    else
                      Text(
                        quantityUnit,
                        style: TextStyle(
                          fontSize: 12,
                          color: isIn ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'KhmerFont',
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Make this helper function static for use in static methods
  static String _getWalletUnitStatic(String accountCode) {
    switch (accountCode.toUpperCase()) {
      case 'DM':
        return 'D';
      case 'GB':
      case 'BS':
      case 'ID':
      default:
        return 'score'.tr();
    }
  }
}

//Correct with 872 line code changes
