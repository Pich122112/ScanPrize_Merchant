import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gb_merchant/widgets/bottomsheet_transaction.dart';
import '../services/user_transaction_service.dart';
import 'dart:async';

class TransactionByAccount extends StatefulWidget {
  final String account; // 'GB', 'BS', 'ID', 'DM'
  final String logoPath;
  final int balance;
  const TransactionByAccount({
    super.key,
    required this.account,
    required this.logoPath,
    required this.balance,
  });

  @override
  State<TransactionByAccount> createState() => _TransactionByAccountState();
}

class _TransactionByAccountState extends State<TransactionByAccount> {
  late Future<List<Map<String, dynamic>>> _futureTransactions;
  bool _noInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
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
    _connectivitySubscription?.cancel();
    super.dispose();
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          children: [
            // --- Header and account info ---
            Container(
              alignment: Alignment.topLeft,
              decoration: const BoxDecoration(color: Color(0xFFFF6600)),
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            widget.logoPath,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
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
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.red, size: 60),
                            const SizedBox(height: 16),
                            const Text(
                              'មិនមានការតភ្ជាប់អ៊ីនធឺណិត',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'KhmerFont',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'សូមភ្ជាប់អ៊ីនធឺណិត ដើម្បីមើលប្រវត្តិប្រតិបត្តិការ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[300],
                                fontFamily: 'KhmerFont',
                              ),
                            ),
                          ],
                        ),
                      )
                      : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _futureTransactions,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 60,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'you_not_have_any_transaction'.tr(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
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
                            padding: const EdgeInsets.all(16),
                            itemCount: groupedByDate.length,

                            // In the FutureBuilder section, replace the itemBuilder with this:
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
                                    final toPhone = item['ToPhoneNumber'] ?? '';
                                    return fromPhone !=
                                        toPhone; // Exclude transfers from self to self
                                  }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                              ? item['FromUserName'] ?? 'N/A'
                                              : item['ToUserName'] ?? 'N/A',
                                      phone:
                                          item['is_credit'] == true
                                              ? item['FromPhoneNumber'] ?? ''
                                              : item['ToPhoneNumber'] ?? '',
                                      points: item['Amount'],
                                      isIn: item['is_credit'] == true,
                                      account:
                                          item['wallet_type'] ?? widget.account,
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
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
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
      }
      return digits;
    }

    String getTransactionTitle(bool isIn) {
      return isIn
          ? 'transaction_received_from'.tr()
          : 'transaction_sent_to'.tr();
    }

    String getDisplayName() {
      if (name != 'N/A' && name.isNotEmpty) {
        return name;
      }

      final displayPhone = formatPhoneNumber(phone);
      if (displayPhone.isNotEmpty) {
        return displayPhone;
      }

      return isIn ? 'អ្នកប្រើប្រាស់' : 'អ្នកទទួល';
    }

    String _getQuantityUnit(String accountCode) {
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

    final String quantityUnit = _translateUnit(_getQuantityUnit(account));
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
              Text(
                "${isIn ? "+" : "-"}$points $unit",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIn ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontFamily: 'KhmerFont',
                ),
              ),
              // Only show quantity if it's not null
              if (showQuantity) const SizedBox(height: 4),
              if (showQuantity)
                Text(
                  'x $qtyValue $quantityUnit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontFamily: 'KhmerFont',
                  ),
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

//Correct with 533 line code changes
