import 'package:flutter/material.dart';
import 'package:scanprize_frontend/utils/constants.dart';

class TransferAnimation extends StatefulWidget {
  final String recipientPhone; // Add recipientPhone parameter
  final VoidCallback onAnimationComplete;

  const TransferAnimation({
    super.key,
    required this.recipientPhone, // Make it required
    required this.onAnimationComplete,
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
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Remove 855 country code if present at the start
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    // Add leading zero if not present
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
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
                    child: const Center(
                      child: Icon(
                        Icons.card_giftcard,
                        size: 45,
                        color: Colors.white,
                      ),
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
              child: const Text(
                'ផ្ទេរបានជោគជ័យ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//Correct with 257 line code changes
