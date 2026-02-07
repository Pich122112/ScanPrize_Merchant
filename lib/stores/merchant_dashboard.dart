import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/stores/dashboard_segment_controll.dart';
import 'package:gb_merchant/stores/date_filter_dialog.dart';
import 'package:gb_merchant/stores/receive_summary_dashboard.dart';
import 'package:gb_merchant/stores/received_from_company_dashboard.dart';
import 'package:gb_merchant/stores/table_transaction_dashboard.dart';
import 'package:gb_merchant/stores/transfer_to_company_dashboard.dart';
import 'package:gb_merchant/utils/constants.dart';

class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  int _refreshKey = 0;
  int _selectedSegmentIndex = 0;
  String _selectedDateFilter = 'Default';
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  bool _isRefreshing = false;
  double _refreshRotation = 0.0;

  final List<String> _segmentOptions = ['ganzberg', 'idol', 'boostrong'];

  // Add this method to format the date range display
  String get _displayFilterText {
    if (_selectedDateFilter == 'Custom' && _customDateRange != null) {
      final start = _formatDateTime(
        _customDateRange!.start.toString(),
        context,
      );
      final end = _formatDateTime(_customDateRange!.end.toString(), context);
      return '$start - $end';
    }
    return _selectedDateFilter;
  }

  // Helper method to format dates for display
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize data when the screen loads
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a small delay to ensure all data is loaded
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _isLoading = false;
    });
  }

  void _onSegmentChanged(int index) {
    setState(() {
      _selectedSegmentIndex = index;
      _refreshKey++;
    });
  }

  void _refreshAll() async {
    setState(() {
      _isRefreshing = true;
      _refreshRotation = 0.0;
    });

    // Start continuous rotation
    _startContinuousRotation();

    // Simulate data loading
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _refreshKey++;
      _isRefreshing = false;
    });
  }

  void _startContinuousRotation() {
    const duration = Duration(milliseconds: 50);

    void rotate() {
      if (_isRefreshing && mounted) {
        Future.delayed(duration, () {
          if (_isRefreshing && mounted) {
            setState(() {
              _refreshRotation += 0.3; // Adjust rotation speed
              if (_refreshRotation > 2 * pi) {
                _refreshRotation = 0.0;
              }
            });
            rotate();
          }
        });
      }
    }

    rotate();
  }

  void _onDateFilterSelected(String? filter) {
    if (filter != null) {
      setState(() {
        _selectedDateFilter = filter;
        _refreshKey++;
      });
    }
  }

  void _onCustomDateRangeSelected(DateTimeRange? dateRange) {
    setState(() {
      _customDateRange = dateRange;
      _selectedDateFilter = 'Custom';
      _refreshKey++;
    });
  }

  String get _currentWalletType => _segmentOptions[_selectedSegmentIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "My_Dashboard".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'KhmerFont',
            fontSize: 22,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Transform.rotate(
                  angle: _refreshRotation,
                  child: Icon(
                    Icons.refresh,
                    color: _isRefreshing ? Colors.black : Colors.white,
                    size: 26,
                  ),
                ),
                onPressed: _isRefreshing ? null : _refreshAll,
                tooltip: "Refresh",
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 16),
              child: DashboardSegmentControll(
                selectedIndex: _selectedSegmentIndex,
                options: _segmentOptions,
                onChanged: _onSegmentChanged,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingState()
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Data Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'KhmerFont',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.4,
                                      ),
                                      child: Text(
                                        _displayFilterText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'KhmerFont',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.calendar_month,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          final selected =
                                              await DateFilterDialog.show(
                                                context,
                                                currentFilter:
                                                    _selectedDateFilter,
                                                currentDateRange:
                                                    _customDateRange,
                                              );
                                          if (selected != null) {
                                            if (selected is String) {
                                              _onDateFilterSelected(selected);
                                            } else if (selected
                                                is DateTimeRange) {
                                              _onCustomDateRangeSelected(
                                                selected,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Cards as a beautiful 2x2 grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                double cardWidth =
                                    (constraints.maxWidth - 16) / 2;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: cardWidth,
                                      child: _DualDataCard(
                                        key: ValueKey(
                                          "Transfer In Today -$_refreshKey",
                                        ),
                                        icon: Icons.arrow_downward,
                                        iconRotation: -0.80,
                                        title: "Transfer In Today ",
                                        leftLabel: "Points",
                                        leftValue: "0",
                                        rightLabel: "Diamonds",
                                        rightValue: "0",
                                        selectedSegment: _currentWalletType,
                                        dateFilter: _selectedDateFilter,
                                        customDateRange: _customDateRange,
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _DualDataCard(
                                        key: ValueKey(
                                          "Transfer To Company-$_refreshKey",
                                        ),
                                        icon: Icons.arrow_downward,
                                        iconRotation: -3 * pi / 4,
                                        title: "Transfer To Company",
                                        leftLabel: "Points",
                                        leftValue: "0",
                                        rightLabel: "Diamonds",
                                        rightValue: "0",
                                        selectedSegment: _currentWalletType,
                                        dateFilter: _selectedDateFilter,
                                        customDateRange: _customDateRange,
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _DualDataCard(
                                        key: ValueKey(
                                          "Received From Company-$_refreshKey",
                                        ),
                                        icon: Icons.account_balance,
                                        title: "Received From Company",
                                        leftLabel: "Points",
                                        leftValue: "0",
                                        rightLabel: "Diamonds",
                                        rightValue: "0",
                                        selectedSegment: _currentWalletType,
                                        dateFilter: _selectedDateFilter,
                                        customDateRange: _customDateRange,
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _DualDataCard(
                                        key: ValueKey("Remaining-$_refreshKey"),
                                        icon: Icons.account_balance,
                                        title: "Remaining",
                                        leftLabel: "Points",
                                        leftValue: "0",
                                        rightLabel: "Diamonds",
                                        rightValue: "0",
                                        selectedSegment: _currentWalletType,
                                        dateFilter: _selectedDateFilter,
                                        customDateRange: _customDateRange,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            MerchantTransactionTable(
                              key: ValueKey(
                                'transaction-table-$_refreshKey-$_currentWalletType-$_selectedDateFilter',
                              ),
                              segment: _currentWalletType,
                              dateFilter: _selectedDateFilter,
                              customDateRange: _customDateRange,
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Dashboard...',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'KhmerFont',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DualDataCard extends StatefulWidget {
  final IconData icon;
  final double iconRotation;
  final String title;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String selectedSegment;
  final String dateFilter;
  final DateTimeRange? customDateRange;

  const _DualDataCard({
    super.key,
    required this.icon,
    this.iconRotation = 0.0,
    required this.title,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.selectedSegment,
    required this.dateFilter,
    this.customDateRange,
  });

  @override
  State<_DualDataCard> createState() => _DualDataCardState();
}

class _DualDataCardState extends State<_DualDataCard> {
  int totalPoints = 0;
  int totalDiamonds = 0;
  bool _isLoading = true;
  bool _hasError = false;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  @override
  void didUpdateWidget(covariant _DualDataCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSegment != widget.selectedSegment ||
        oldWidget.dateFilter != widget.dateFilter ||
        oldWidget.customDateRange != widget.customDateRange) {
      _retryCount = 0; // Reset retry count when filters change
      _loadTotals();
    }
  }

  Future<void> _loadTotals() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      String? walletTypeFilter;
      switch (widget.selectedSegment.toLowerCase()) {
        case 'ganzberg':
          walletTypeFilter = 'gb';
          break;
        case 'idol':
          walletTypeFilter = 'id';
          break;
        case 'boostrong':
          walletTypeFilter = 'bs';
          break;
        default:
          walletTypeFilter = null;
      }

      // Check if we should show ALL data (for specific cards when filter is 'Default')
      bool showAllData =
          widget.dateFilter == 'Default' &&
          (widget.title == 'Transfer To Company' ||
              widget.title == 'Received From Company' ||
              widget.title == 'Remaining');

      if (widget.title == 'Transfer In Today ') {
        // Transfer In Today: Use 'Today' when filter is 'Default', otherwise use selected filter
        final effectiveDateFilter =
            widget.dateFilter == 'Default' ? 'Today' : widget.dateFilter;
        final totals = await TransactionSummaryService.getFilteredTotals(
          walletType: walletTypeFilter,
          dateFilter: effectiveDateFilter,
          customDateRange: widget.customDateRange,
        );
        if (mounted) {
          setState(() {
            totalPoints = totals['points'] ?? 0;
            totalDiamonds = totals['diamonds'] ?? 0;
            _isLoading = false;
            _hasError = false;
            _retryCount = 0;
          });
        }
      } else if (widget.title == 'Transfer To Company') {
        final totals =
            showAllData
                ? await TransferToCompanyService.getAllTimeTotals(
                  walletCode: walletTypeFilter,
                )
                : await TransferToCompanyService.getFilteredTransferTotals(
                  walletCode: walletTypeFilter,
                  dateFilter: widget.dateFilter,
                  customDateRange: widget.customDateRange,
                );
        if (mounted) {
          setState(() {
            totalPoints = totals['points'] ?? 0;
            totalDiamonds = totals['diamonds'] ?? 0;
            _isLoading = false;
            _hasError = false;
            _retryCount = 0;
          });
        }
      } else if (widget.title == 'Received From Company') {
        final totals =
            showAllData
                ? await ReceivedFromCompanyService.getAllTimeTotals(
                  walletCode: walletTypeFilter,
                )
                : await ReceivedFromCompanyService.getFilteredReceivedTotals(
                  walletCode: walletTypeFilter,
                  dateFilter: widget.dateFilter,
                  customDateRange: widget.customDateRange,
                );
        if (mounted) {
          setState(() {
            totalPoints = totals['points'] ?? 0;
            totalDiamonds = totals['diamonds'] ?? 0;
            _isLoading = false;
            _hasError = false;
            _retryCount = 0;
          });
        }
      } else if (widget.title == 'Remaining') {
        if (showAllData) {
          // Calculate from ALL TIME data
          final transferTotals =
              await TransferToCompanyService.getAllTimeTotals(
                walletCode: walletTypeFilter,
              );
          final receivedTotals =
              await ReceivedFromCompanyService.getAllTimeTotals(
                walletCode: walletTypeFilter,
              );
          if (mounted) {
            setState(() {
              totalPoints =
                  (transferTotals['points'] ?? 0) -
                  (receivedTotals['points'] ?? 0);
              totalDiamonds =
                  (transferTotals['diamonds'] ?? 0) -
                  (receivedTotals['diamonds'] ?? 0);
              _isLoading = false;
              _hasError = false;
              _retryCount = 0;
            });
          }
        } else {
          // Calculate from FILTERED data
          final transferTotals =
              await TransferToCompanyService.getFilteredTransferTotals(
                walletCode: walletTypeFilter,
                dateFilter: widget.dateFilter,
                customDateRange: widget.customDateRange,
              );
          final receivedTotals =
              await ReceivedFromCompanyService.getFilteredReceivedTotals(
                walletCode: walletTypeFilter,
                dateFilter: widget.dateFilter,
                customDateRange: widget.customDateRange,
              );
          if (mounted) {
            setState(() {
              totalPoints =
                  (transferTotals['points'] ?? 0) -
                  (receivedTotals['points'] ?? 0);
              totalDiamonds =
                  (transferTotals['diamonds'] ?? 0) -
                  (receivedTotals['diamonds'] ?? 0);
              _isLoading = false;
              _hasError = false;
              _retryCount = 0;
            });
          }
        }
      }
    } catch (error) {
      print('Error loading totals for ${widget.title}: $error');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });

        // Auto-retry logic
        if (_retryCount < _maxRetries) {
          _retryCount++;
          print(
            'Auto-retrying ${widget.title} (attempt $_retryCount/$_maxRetries)...',
          );

          // Wait 2 seconds before retrying
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _loadTotals();
            }
          });
        } else {
          print('Max retries reached for ${widget.title}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    child: Transform.rotate(
                      angle: widget.iconRotation,
                      child: Icon(
                        widget.icon,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                _buildCardLoading()
              else if (_hasError)
                _buildCardError()
              else
                _buildCardContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              totalPoints.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.leftLabel,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              totalDiamonds.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.rightLabel,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 60,
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.leftLabel,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 60,
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.rightLabel,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange.shade700, size: 16),
            const SizedBox(width: 4),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//Correct with 867 line code changes
