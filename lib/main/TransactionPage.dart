import 'package:flutter/material.dart';
import '../widgets/custom_segment_controll.dart';

class Giftpage extends StatefulWidget {
  const Giftpage({super.key});

  @override
  State<Giftpage> createState() => _GiftpageState();
}

class _GiftpageState extends State<Giftpage> {
  int selectedIndex = 0;
  final options = ['ប្រតិបត្តិការ', 'សារជូនដំណឹង'];

  // Sample announcements data
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
      'image': 'assets/images/slider2.png',
      'title': 'ប្រកាសសំខាន់',
      'subtitle': 'ប្រើគោលការណ៍ថ្មីនៅថ្ងៃនេះ',
      'date': 'ថ្ងៃសុក្រ ១៣ មិថុនា ២០២៥',
    },
  ];

  // Sample transaction data (for other tab)
  final List<Map<String, dynamic>> transactions = [
    {
      'type': 'transaction',
      'icon': Icons.qr_code_scanner,
      'title': 'ផ្ទេរទៅ 067 834 618',
      'date': 'ថ្ងៃអង្គារ ០៤, ២០២៥ | ១២:០១ ល្ងាច',
      'subtitle': '10 ពិន្ទុ ត្រូវបានកាត់ចេញពី Ganzberg',
      'product': 'Ganzberg',
    },
    //...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 30),
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
                    ? ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _buildTransactionCard(
                          icon: tx['icon'],
                          image: tx['image'],
                          title: tx['title'],
                          date: tx['date'],
                          subtitle: tx['subtitle'],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String image,
    required String title,
    required String subtitle,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            aspectRatio: 2.8, // Modern look, wide banner
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.5,
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

  Widget _buildTransactionCard({
    IconData? icon,
    String? image,
    required String title,
    required String date,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon != null
              ? Icon(icon, size: 36, color: Colors.blueGrey)
              : image != null
              ? CircleAvatar(backgroundImage: AssetImage(image), radius: 19)
              : const SizedBox(width: 38, height: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF15365E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                    fontFamily: 'KhmerOS',
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }
}
