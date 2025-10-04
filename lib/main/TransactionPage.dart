import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/widgets/bottomsheet_transaction.dart';
import '../services/user_transaction_service.dart';
import '../widgets/custom_segment_controll.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/check_unread_notification.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int selectedIndex = 0;
  final options = ['transactions'.tr(), 'notifications'.tr()];
  Set<String> _readTransactions = {};

  // For storing transactions data
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  late ScrollController _scrollController;
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollDirection);
    _loadReadTransactions();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollDirection);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateUnreadStatus() {
    final hasUnread = _transactions.any((tx) {
      final txId = tx['id'].toString();
      return !_readTransactions.contains(txId);
    });
    CheckUnreadNotification.updateUnreadStatus(hasUnread);
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

    // Show FAB if user scrolls down (forward), hide if going up (reverse)
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

  Future<void> _loadReadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('readTransactions') ?? [];
    setState(() {
      _readTransactions = saved.toSet();
    });
    _updateUnreadStatus();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all transactions (you might need to adjust this based on your API)
      // For notifications, we want all transactions regardless of wallet type
      final transactionsData =
          await UserTransactionService.fetchAllUserTransactions();

      setState(() {
        _transactions = transactionsData;
        _isLoading = false;
      });
      _updateUnreadStatus();
    } catch (e) {
      // Detect common server-side error messages and set a friendly message
      String message = e.toString();
      if (message.contains('502') ||
          message.contains('503') ||
          message.contains('504') ||
          message.contains('SocketException') ||
          message.toLowerCase().contains('fail') ||
          message.toLowerCase().contains('server')) {
        message = 'server_problem_message'.tr();
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      _updateUnreadStatus();
      print('Error fetching transactions: $e');
    }
  }

  // Replace the entire build method with this:
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.primaryColor,
          body: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'notification'.tr(),
                      style: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Segmented Control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: KhmerSegmentedControl(
                  selectedIndex: selectedIndex,
                  options: options,
                  onChanged: (idx) => setState(() => selectedIndex = idx),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child:
                    selectedIndex == 1
                        ? _buildAnnouncementsTab()
                        : _buildTransactionsTab(),
              ),
            ],
          ),
          floatingActionButton:
              _showFAB
                  ? FloatingActionButton(
                    shape: const CircleBorder(), // 🔵 makes sure it's round

                    onPressed: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.arrow_upward,
                      color: AppColors.primaryColor,
                    ),
                  )
                  : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      // Show a friendly, styled server error message
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 48),
              const SizedBox(height: 18),
              Text(
                'server_problem_message'.tr(),
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

    // Replace the empty transactions message in _buildTransactionsTab():
    if (_transactions.isEmpty) {
      return Center(
        child: Text(
          'no_transactions'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontFamily: 'KhmerFont',
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      backgroundColor: Colors.white,
      color: AppColors.primaryColor,
      onRefresh: _fetchTransactions,
      child: ListView.builder(
        controller: _scrollController, // <-- Add this line!
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          return _buildTransactionCard(transaction: tx, index: index);
        },
      ),
    );
  }

  Widget _getWalletLogo(String walletType) {
    switch (walletType.toLowerCase()) {
      case 'gb':
        return Image.asset(
          'assets/images/gblogo.png',
          width: 26,
          height: 26,
          fit: BoxFit.cover,
        );
      case 'bs':
        return Image.asset(
          'assets/images/newbslogo.png',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        );
      case 'id':
        return Image.asset(
          'assets/images/idollogo.png',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        );
      case 'dm':
        return Image.asset(
          'assets/images/dmond.png',
          width: 26,
          height: 26,
          fit: BoxFit.contain,
        );
      default:
        return const Icon(
          Icons.account_balance_wallet,
          size: 24,
          color: Colors.grey,
        );
    }
  }

  Widget _buildAnnouncementsTab() {
    // Your existing announcements UI
    final List<Map<String, dynamic>> announcements = [
      {
        'image': 'assets/images/logo.png',
        'title': 'ជូនដំណឹងថ្មី!',
        'subtitle': 'សូមអញ្ជើញចូលរួមកម្មវិធីពិសេស',
        'date': 'ថ្ងៃអាទិត្យ ១៥ មិថុនា ២០២៥',
      },
      {
        'image': 'assets/images/idol.png',
        'title': 'សូមចូលរួម!',
        'subtitle': 'ព្រឹត្តិការណ៍អនុស្សាវរីយ៍កំពុងចាប់ផ្តើម',
        'date': 'ថ្ងៃសៅរ៍ ១៤ មិថុនា ២០២៥',
      },
      {
        'image': 'assets/images/boostrong.png',
        'title': 'ប្រកាសសំខាន់',
        'subtitle': 'ប្រើគោលការណ៍ថ្មីនៅថ្ងៃនេះ',
        'date': 'ថ្ងៃសុក្រ ១៣ មិថុនា ២០២៥',
      },
      {
        'image': 'assets/images/fordranger.png',
        'title': 'ប្រកាសសំខាន់',
        'subtitle': 'ប្រើគោលការណ៍ថ្មីនៅថ្ងៃនេះ',
        'date': 'ថ្ងៃសុក្រ ១៣ មិថុនា ២០២៥',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        final ann = announcements[index];
        return _buildAnnouncementCard(
          image: ann['image']!,
          title: ann['title']!,
          subtitle: ann['subtitle']!,
          date: ann['date']!,
        );
      },
    );
  }

  // Replace the _buildTransactionCard method with this:
  Widget _buildTransactionCard({
    required Map<String, dynamic> transaction,
    required int index,
  }) {
    final bool isCredit = transaction['is_credit'] ?? false;
    final String transactionType = transaction['transaction_type'] ?? '';
    final String fromUserName = transaction['FromUserName'] ?? 'N/A';
    final String fromPhoneNumber = transaction['FromPhoneNumber'] ?? '';
    final String toUserName = transaction['ToUserName'] ?? 'N/A';
    final String toPhoneNumber = transaction['ToPhoneNumber'] ?? '';
    final int amount =
        transaction['Amount'] is int
            ? transaction['Amount']
            : int.tryParse(transaction['Amount'].toString()) ?? 0;
    final String createdAt = transaction['created_at'] ?? '';
    final String walletType = transaction['wallet_type'] ?? '';
    final localeCode = context.locale.languageCode;
    final dynamic qtyValue = transaction['qty'];
    final String unitValue = (transaction['unit'] ?? '').toString();

    // Format phone numbers
    String formatPhoneNumber(String phone) {
      if (phone.isEmpty) return '';
      String digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('855')) {
        digits = digits.substring(3);
      }
      if (!digits.startsWith('0') && digits.isNotEmpty) {
        digits = '0$digits';
      }
      if (digits.length == 9 || digits.length == 10) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
      return digits;
    }

    // Helper to translate unit
    String _translateUnit(String unit) {
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

    Future<void> _saveReadTransactions() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('readTransactions', _readTransactions.toList());
      _updateUnreadStatus();
    }

    final String formattedFromPhone = formatPhoneNumber(fromPhoneNumber);
    final String formattedToPhone = formatPhoneNumber(toPhoneNumber);

    // Title setup
    String title;
    Widget iconWidget;
    Color amountColor = Colors.grey;

    if (transactionType == 'transfer_out') {
      final displayPhone =
          formattedToPhone.isNotEmpty ? formattedToPhone : toUserName;
      title = 'transferred_to'.tr(namedArgs: {'phoneNumber': displayPhone});
      iconWidget = const Icon(
        Icons.qr_code_scanner,
        size: 24,
        color: Colors.black,
      );
      amountColor = Colors.red;
    } else if (transactionType == 'transfer_in') {
      final displayPhone =
          formattedFromPhone.isNotEmpty ? formattedFromPhone : fromUserName;
      title = 'received_from'.tr(namedArgs: {'phoneNumber': displayPhone});
      iconWidget = _getWalletLogo(walletType);
      amountColor = Colors.green;
    } else {
      title = transactionType;
      iconWidget = const Icon(Icons.swap_horiz, size: 24, color: Colors.grey);
    }

    final String formattedDate = _formatDateTime(createdAt);

    final bool isRead = _readTransactions.contains(
      transaction['id'].toString(),
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _readTransactions.add(
            transaction['id'].toString(),
          ); // or created_at if no ID
        });
        _saveReadTransactions();
        // Show transaction detail modal
        // Ensure 'remark' is present (for demo/testing; remove if backend already provides it)
        final txWithRemark = Map<String, dynamic>.from(transaction);
        txWithRemark['remark'] =
            txWithRemark['remark']?.isNotEmpty == true
                ? txWithRemark['remark']
                : 'Test demo remark';
        print(
          'DEBUG txWithRemark remark before modal: ${txWithRemark['remark']}',
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (context) => TransactionDetailModal(
                transaction: txWithRemark,
              ), // <--- Use txWithRemark!
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: iconWidget,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF15365E),
                            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                          ),
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(238, 255, 82, 82),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${amount.abs()} ${"score".tr()} ', // ✅ Bold part
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              '${isCredit ? 'added_to'.tr() : 'deducted_from'.tr()} $walletType', // ✅ Normal text
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${amount.abs()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                    fontFamily: 'KhmerFont',
                  ),
                ),
                if (qtyValue != null &&
                    qtyValue.toString().isNotEmpty &&
                    unitValue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'x $qtyValue ${_translateUnit(unitValue)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isCredit ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'KhmerFont',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String image,
    required String title,
    required String subtitle,
    required String date,
  }) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          AspectRatio(
            aspectRatio: 2.8,
            child: Image.asset(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              color: Colors.black.withOpacity(0.22),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Gradient for text readability
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color.fromARGB(190, 0, 0, 0)],
                  ),
                ),
              ),
            ),
          ),
          // Announcement content at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.5,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
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

      final month = months[cambodiaTime.month - 1];
      final day = cambodiaTime.day;
      final year = cambodiaTime.year;

      final hour = cambodiaTime.hour % 12 == 0 ? 12 : cambodiaTime.hour % 12;
      final minute = cambodiaTime.minute.toString().padLeft(2, '0');
      final period = cambodiaTime.hour < 12 ? 'AM' : 'PM';

      return "$month $day, $year $hour:$minute $period";
    } catch (e) {
      return dateTimeString; // fallback if parsing fails
    }
  }
}

//Correct with 830 line code changes
