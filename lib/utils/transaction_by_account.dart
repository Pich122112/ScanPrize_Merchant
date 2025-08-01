// Change _futureTransactions type, and use the correct FutureBuilder and UI group logic

import 'package:flutter/material.dart';
import '../services/user_transaction_service.dart';

class TransactionByAccount extends StatefulWidget {
  final String account; // 'ganzberg', 'idol', 'boostrong', 'money'
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

  @override
  void initState() {
    super.initState();
    _futureTransactions = UserTransactionService.fetchUserTransactions(
      widget.account,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Container(
              alignment: Alignment.topLeft,
              decoration: const BoxDecoration(color: Color(0xFFFF6600)),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 40,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Text(
                          'មើលប្រវត្តិ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                          const Text(
                            'សមតុល្យ',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.balance} ${widget.account == 'money' ? 'Diamond' : 'ពិន្ទុ'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Transaction list
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureTransactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.hasError) {
                    return Center(child: Text('No data or error occurred'));
                  }
                  final groupedByDate = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedByDate.length,
                    itemBuilder: (context, index) {
                      final group = groupedByDate[index];
                      final dateLabel = group['date'];
                      final transferIn = group['transfer_in'] as List;
                      final transferOut = group['transfer_out'] as List;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionTitle(dateLabel),
                          ...transferIn.map(
                            (item) => transactionSummaryTile(
                              name: item['FromUserName'] ?? '',
                              phone: item['FromPhone'] ?? '',
                              points: item['Amount'],
                              isIn: true,
                              account: widget.account, // <-- Add this
                            ),
                          ),
                          ...transferOut.map(
                            (item) => transactionSummaryTile(
                              name: item['ToUserName'] ?? '',
                              phone: item['ToPhone'] ?? '',
                              points: item['Amount'],
                              isIn: false,
                              account: widget.account,
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

  static Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
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
  }) {
    // 2. Set the unit label based on the account:
    final String unit = account == 'money' ? 'D' : 'ពិន្ទុ';

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isIn ? Colors.green : Colors.red,
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
              angle: isIn ? 4.0 : 0.8,
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        title: Text(
          (name.isNotEmpty) ? name : phone,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: (name.isNotEmpty) ? Text(phone) : null,
        trailing: Text(
          "${isIn ? "+" : "-"}$points $unit", // <-- Use the unit here
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIn ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

//Correct with 260 line code changes
