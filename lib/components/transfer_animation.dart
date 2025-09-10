import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';

class TransferAnimation extends StatefulWidget {
  final String recipientPhone;
  final VoidCallback onAnimationComplete;
  final String companyCategoryName;

  const TransferAnimation({
    super.key,
    required this.recipientPhone,
    required this.onAnimationComplete,
    required this.companyCategoryName,
  });

  @override
  State<TransferAnimation> createState() => _TransferAnimationState();
}

class _TransferAnimationState extends State<TransferAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;
  late List<Animation<double>> _dotOpacities;

  final int rowCount = 3;
  final int colCount = 3;
  final double dotSpacing = 34.0;
  final double verticalTravel = 220.0;

  @override
  void initState() {
    super.initState();
    final dotCount = rowCount * colCount;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 5200),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete(); // Call the callback
      }
    });
    _controller.forward();
    // Use forward() instead of repeat() to play once

    _dotAnimations = [];
    _dotOpacities = [];
    for (int i = 0; i < dotCount; i++) {
      double start = (i % colCount) * 0.11 + (i ~/ colCount) * 0.12;
      double end = start + 0.55;
      if (start >= 1.0) {
        _dotAnimations.add(AlwaysStoppedAnimation<double>(1.0));
        _dotOpacities.add(AlwaysStoppedAnimation<double>(0.0));
        continue;
      }
      if (end > 1.0) end = 1.0;
      _dotAnimations.add(
        Tween<double>(begin: 0.0, end: -verticalTravel).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeInOutCubic),
          ),
        ),
      );
      double fadeStart = end - 0.30 * (end - start);
      if (fadeStart < start) fadeStart = start;
      _dotOpacities.add(
        Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(fadeStart, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildAnimatedDots(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final gridWidth = (colCount - 1) * dotSpacing;
    final baseTop = size.height * 0.62;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          children: List.generate(rowCount * colCount, (i) {
            final anim = _dotAnimations[i];
            final opacity = _dotOpacities[i].value;
            final col = i % colCount;
            final row = i ~/ colCount;

            final x = size.width / 2 - gridWidth / 2 + col * dotSpacing;
            final y = baseTop - (rowCount - 1 - row) * dotSpacing + anim.value;

            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withOpacity(0.87),
                        const Color.fromARGB(
                          255,
                          228,
                          229,
                          229,
                        ).withOpacity(0.82),
                        const Color.fromARGB(
                          255,
                          108,
                          108,
                          108,
                        ).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.13),
                        blurRadius: 13,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

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

  Widget _buildTransferIcon() {
    final walletName = widget.companyCategoryName.toLowerCase();

    switch (walletName) {
      case 'gb':
        return Image.asset('assets/images/logo.png', width: 45, height: 45);
      case 'bs':
        return Image.asset('assets/images/newbslogo.png', width: 45, height: 45);
      case 'id':
        return Image.asset('assets/images/idollogo.png', width: 45, height: 45);
      case 'dm':
        return Image.asset(
          'assets/images/dmond.png',
          width: 45,
          height: 45,
          color: Colors.white,
        );
      default:
        return const Icon(Icons.card_giftcard, size: 45, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.black,
                    child: Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 65,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatPhoneNumber(
                      widget.recipientPhone,
                    ), // Format the phone number here
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.93),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          buildAnimatedDots(context),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          _buildTransferIcon(), // Use our custom icon builder
                    ),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: AnimatedOpacity(
              opacity: _controller.value > 0.8 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'transfer_successful'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//Correct with 304 line code changes
