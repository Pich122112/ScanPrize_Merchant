import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/services/user_transaction_service.dart';

class MerchantTransactionTable extends StatefulWidget {
  final String segment; // "ganzberg", "idol", "boostrong"
  final String
  dateFilter; // "Default", "On Today", "This Week", "This Month", "Custom"
  final DateTimeRange? customDateRange;

  const MerchantTransactionTable({
    super.key,
    required this.segment,
    required this.dateFilter,
    this.customDateRange,
  });

  @override
  State<MerchantTransactionTable> createState() =>
      _MerchantTransactionTableState();
}

class _MerchantTransactionTableState extends State<MerchantTransactionTable> {
  List<Map<String, dynamic>> transferToCompanyTxs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(covariant MerchantTransactionTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segment != widget.segment ||
        oldWidget.dateFilter != widget.dateFilter ||
        oldWidget.customDateRange != widget.customDateRange) {
      _loadTransactions();
    }
  }

  // Add this method to format the display text for the table using your custom function
  String get _displayFilterText {
    if (widget.dateFilter == 'Custom' && widget.customDateRange != null) {
      final start = _formatDateTime(
        widget.customDateRange!.start.toString(),
        context,
      );
      final end = _formatDateTime(
        widget.customDateRange!.end.toString(),
        context,
      );
      return '$start - $end';
    }
    return widget.dateFilter;
  }

  // Your custom date formatting function
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

  // Normalize helper
  String normalizePhone(String phone) {
    if (phone.isEmpty) return '';
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Date filtering helper
  bool _isTransactionInDateRange(Map<String, dynamic> tx) {
    if (widget.dateFilter == 'Default') {
      return true; // Show all transactions for Default filter
    }

    final createdAtStr = tx['created_at'] ?? '';
    if (createdAtStr.isEmpty) return false;

    DateTime txDate;
    try {
      txDate = DateTime.parse(createdAtStr).toLocal();
    } catch (_) {
      return false;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    // Calculate date range based on filter
    switch (widget.dateFilter) {
      case 'On Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      case 'Custom':
        if (widget.customDateRange != null) {
          startDate = DateTime(
            widget.customDateRange!.start.year,
            widget.customDateRange!.start.month,
            widget.customDateRange!.start.day,
          );
          endDate = DateTime(
            widget.customDateRange!.end.year,
            widget.customDateRange!.end.month,
            widget.customDateRange!.end.day,
            23,
            59,
            59,
            999,
          );
        } else {
          return true; // Fallback to show all if no custom range
        }
        break;
      default:
        return true; // Show all for unknown filters
    }

    // Check if transaction is within date range
    return !txDate.isBefore(startDate) && !txDate.isAfter(endDate);
  }

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);

    try {
      final allTxs = await UserTransactionService.fetchAllUserTransactions();

      String walletCode;
      switch (widget.segment.toLowerCase()) {
        case 'ganzberg':
          walletCode = 'gb';
          break;
        case 'idol':
          walletCode = 'id';
          break;
        case 'boostrong':
          walletCode = 'bs';
          break;
        default:
          walletCode = 'gb';
      }

      const companyName = 'hhh kk';
      const companyPhone = '85599666555';

      // Normalize company info
      final normalizedCompanyName = companyName.toLowerCase().replaceAll(
        ' ',
        '',
      );
      final normalizedCompanyPhone = normalizePhone(companyPhone);

      // Debug logging
      print('=== Loading Transactions ===');
      print('Total transactions: ${allTxs.length}');
      print('Wallet code: $walletCode');
      print('Date filter: ${widget.dateFilter}');
      print('Company: $normalizedCompanyName, Phone: $normalizedCompanyPhone');

      // Filter transactions for transfer TO company (company is receiver) with date filtering
      transferToCompanyTxs =
          allTxs.where((tx) {
            // First check date filter
            if (!_isTransactionInDateRange(tx)) {
              return false;
            }

            // Then check company and wallet filters
            final toName = (tx['ToUserName']?.toString().toLowerCase() ?? '')
                .replaceAll(' ', '');
            final toPhone = normalizePhone(
              tx['ToPhoneNumber']?.toString() ?? '',
            );
            final walletType =
                (tx['wallet_type']?.toString().toLowerCase() ?? '');

            final walletMatch = walletType == walletCode.toLowerCase();

            final isMatch =
                toName.contains(normalizedCompanyName) &&
                toPhone.endsWith(normalizedCompanyPhone) &&
                walletMatch;

            if (isMatch) {
              print(
                '✅ TRANSFER TO COMPANY: ${tx['id']} - Amount: ${tx['Amount']} - Date: ${tx['created_at']}',
              );
            }

            return isMatch;
          }).toList();

      // Sort transactions by date (newest first)
      transferToCompanyTxs.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      print('=== Results ===');
      print('Transfer to company: ${transferToCompanyTxs.length} transactions');
      print('Date filter applied: ${widget.dateFilter}');
    } catch (e) {
      print('Error loading transactions: $e');
      transferToCompanyTxs = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transfer To Company (${transferToCompanyTxs.length}) - $_displayFilterText",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'khmerFont',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        _buildTable(transferToCompanyTxs),
      ],
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> txs) {
    if (txs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            "No transactions found for ${widget.dateFilter}.",
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'KhmerFont',
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blueGrey[800]),
            dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.amber.withOpacity(0.2);
              }
              return Colors.white.withOpacity(0.05);
            }),
            columnSpacing: 28,
            horizontalMargin: 16,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(
                    fontFamily: 'KhmerFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Transaction ID',
                  style: TextStyle(
                    fontFamily: 'KhmerFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Amount',
                  style: TextStyle(
                    fontFamily: 'KhmerFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Received',
                  style: TextStyle(
                    fontFamily: 'KhmerFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Remaining',
                  style: TextStyle(
                    fontFamily: 'KhmerFont',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            rows: List.generate(txs.length, (index) {
              final tx = txs[index];

              final date = tx['created_at']?.toString() ?? 'N/A';
              final transactionId = tx['id']?.toString() ?? 'N/A';
              final amount = tx['Amount']?.toString() ?? '0';
              final unit = tx['unit']?.toString().toLowerCase() ?? '';
              final qty = tx['qty']?.toString() ?? '';
              final walletType =
                  tx['wallet_type']?.toString().toLowerCase() ?? '';

              String displayType;
              if (walletType == 'gb' ||
                  walletType == 'id' ||
                  walletType == 'bs') {
                displayType = 'Score';
              } else if (walletType == 'dm' || walletType == 'diamond') {
                displayType = 'Diamond';
              } else {
                displayType = 'Other';
              }

              return DataRow(
                cells: [
                  _tableCell(_formatDate(date)),
                  _tableCell(transactionId),
                  _tableCell(
                    (qty.isNotEmpty && unit.isNotEmpty)
                        ? '$amount $displayType\n(x$qty ${_formatUnit(unit)})'
                        : '$amount $displayType',
                  ),
                  _tableCell(tx['received']?.toString() ?? 'N/A'),
                  _tableCell(tx['remaining']?.toString() ?? 'N/A'),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  String _formatUnit(String unit) {
    if (unit.isEmpty) return 'N/A';
    return unit[0].toUpperCase() + unit.substring(1);
  }

  String _formatDate(String dateTimeString) {
    try {
      // Parse the date as UTC
      DateTime parsedUtc = DateTime.parse(dateTimeString).toUtc();

      // Convert to Cambodia time (UTC+7)
      DateTime cambodiaTime = parsedUtc.add(const Duration(hours: 7));

      final localeCode = context.locale.languageCode;
      final months =
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
      final day = cambodiaTime.day;
      final month = months[cambodiaTime.month - 1];
      final year = cambodiaTime.year;

      final hour = cambodiaTime.hour % 12 == 0 ? 12 : cambodiaTime.hour % 12;
      final minute = cambodiaTime.minute.toString().padLeft(2, '0');
      final period = cambodiaTime.hour < 12 ? 'AM' : 'PM';

      return "$day $month, $year $hour:$minute $period";
    } catch (e) {
      return dateTimeString; // fallback if parsing fails
    }
  }

  DataCell _tableCell(String text) {
    return DataCell(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'KhmerFont',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

//Correct with 544 line code changes
