import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';

class TransactionDetail extends StatefulWidget {
  final VoidCallback onComplete;
  final DateTime transactionDate;
  final String
  companyCategoryName; // Change from senderName to be more specific
  final String receiverPhone;
  final num points;

  final String productName; // <-- add this
  final int quantity; // <-- add this
  const TransactionDetail({
    super.key,
    required this.onComplete,
    required this.transactionDate,
    required this.companyCategoryName,
    required this.receiverPhone,
    required this.points,
    required this.productName, // <-- add this
    required this.quantity, // <-- add this
  });

  @override
  State<TransactionDetail> createState() => _TransactionDetailState();
}

class _TransactionDetailState extends State<TransactionDetail> {
  bool _isButtonClicked = false; // Tracks if the button was clicked
  String getCleanProductName(String name) {
    final RegExp regExp = RegExp(r'^\d+\s*');
    return name.replaceFirst(regExp, '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Success Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Success Animation/Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Success Title
                    const Text(
                      'រួចរាល់',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 35),
                    // Transaction Card
                    _buildTransactionCard(),
                  ],
                ),
              ),
            ),
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    String logoAsset;
    switch (widget.companyCategoryName.toLowerCase()) {
      case 'ganzberg':
        logoAsset = 'assets/images/logo.png';
        break;
      case 'idol':
        logoAsset = 'assets/images/idollogo.png';
        break;
      case 'boostrong':
        logoAsset = 'assets/images/bstrong.png';
        break;
      case 'money':
        logoAsset = 'assets/images/dmond.png';
        break;
      default:
        logoAsset = 'assets/images/logo.png';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.only(top: 30, bottom: 30, left: 25, right: 25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Points Row
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  logoAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.scaleDown,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.points is int ? widget.points : widget.points.toStringAsFixed(2)} ${widget.companyCategoryName.toLowerCase() == 'money' ? 'D' : 'ពិន្ទុ'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Divider(color: Colors.white.withOpacity(0.5), height: 3),
          const SizedBox(height: 30),
          // Transaction Details
          _buildDetailRow(
            Icons.calendar_today,
            "កាលបរិច្ឆេទ",
            "${_formatDate(widget.transactionDate)} | ${_formatTime(widget.transactionDate)}",
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            Icons.person,
            "កាត់ចេញពី",
            widget.companyCategoryName,
          ),
          const SizedBox(height: 24),
          _buildDetailRow(
            Icons.card_giftcard,
            "ប្រភេទប្តូរ",
            "${widget.quantity} ${getCleanProductName(widget.productName)}",
          ),
          const SizedBox(height: 24),
          _buildDetailRow(Icons.phone, "អ្នកទទួល", widget.receiverPhone),
          const SizedBox(height: 24),
          _buildDetailRow(
            Icons.star,
            "ចំនួនផ្ទេរសរុប",
            '${widget.points is int ? widget.points : widget.points.toStringAsFixed(2)} ${widget.companyCategoryName.toLowerCase() == 'money' ? 'D' : 'ពិន្ទុ'}',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute$period';
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
      child: Column(
        children: [
          // Share/Save Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconButton(Icons.share_rounded, 'ចែករំលែក'),
              const SizedBox(width: 40),
              _buildIconButton(Icons.download_rounded, 'រក្សាទុក'),
            ],
          ),
          const SizedBox(height: 20),
          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: AppColors.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed:
                  _isButtonClicked
                      ? null
                      : () {
                        setState(() => _isButtonClicked = true);
                        // Close ALL routes and go back to root
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        // Then execute the callback
                        widget.onComplete();
                      },
              child: const Text(
                'រួចរាល់',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

//Correct with 307 line code changes
