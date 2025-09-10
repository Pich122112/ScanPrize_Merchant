import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:confetti/confetti.dart';

class Spinwheelpage extends StatefulWidget {
  const Spinwheelpage({super.key});

  @override
  State<Spinwheelpage> createState() => _SpinwheelpageState();
}

class _SpinwheelpageState extends State<Spinwheelpage> {
  final items = ['1ពិន្ទុ', '2ពិន្ទុ', '168D', '1 Motor', '1 Car'];
  final StreamController<int> selected = StreamController<int>();
  int point = 0;
  bool isSpinning = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  void spinWheel() async {
    if (isSpinning) return;
    setState(() => isSpinning = true);

    final newIndex = Random().nextInt(items.length);
    selected.add(newIndex);

    await Future.delayed(const Duration(seconds: 5)); // Wait for animation

    // Update points
    final result = items[newIndex];
    bool isWin = result != "Thank You";
    if (result.contains('\$')) {
      point += int.tryParse(result.replaceAll('\$', '')) ?? 0;
    } else if (result == '1 Can') {
      point += 10;
    }
    setState(() => isSpinning = false);

    // Show congratulation modal when win
    if (isWin) {
      _confettiController.play(); // Start confetti

      showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (ctx) => Stack(
              alignment: Alignment.topCenter,
              children: [
                Dialog(
                  backgroundColor: Colors.white,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtle animated checkmark or trophy (use Lottie or keep Icon for now)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.13),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.22),
                                blurRadius: 25,
                                spreadRadius: 4,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber[700],
                            size: 72,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'សូមអបអរសាទរ!', // "Congratulations!"
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF212121),
                            letterSpacing: 1.4,
                            wordSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.amber[400],
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'អ្នកទទួលបាន $result',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B4957),
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 45),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text(
                              'យល់ព្រម',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Add confetti widget above the dialog
                Positioned(
                  top: 0,
                  left: 150,
                  right: 150,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.amber,
                      Colors.pink,
                      Colors.blue,
                      Colors.green,
                    ],
                    numberOfParticles: 40,
                    maxBlastForce: 25,
                    minBlastForce: 8,
                    gravity: 0.6,
                  ),
                ),
              ],
            ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    selected.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  'ពិន្ទុរបស់អ្នកបច្ចុប្បន្ន : $point ពិន្ទុ',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'សូមធ្វើការបង្វិលដើម្បីមានឧកាសឈ្នះរង្វាន់​',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              SizedBox(
                height: 310,
                width: 310,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Custom glowing bulbs and border
                    CustomPaint(
                      size: const Size(310, 310),
                      painter: WheelBulbPainter(
                        bulbCount: 12,
                        bulbColor: Colors.white,
                        glowColor: Colors.yellowAccent.withOpacity(0.38),
                        borderColor: Colors.black,
                        borderWidth: 14,
                      ),
                    ),
                    // The wheel itself
                    SizedBox(
                      height: 270,
                      width: 270,
                      child: FortuneWheel(
                        selected: selected.stream,
                        animateFirst: false,
                        duration: const Duration(seconds: 5),
                        indicators: [],
                        items: [
                          for (int i = 0; i < items.length; i++)
                            FortuneItem(
                              style: FortuneItemStyle(
                                color:
                                    i.isEven
                                        ? AppColors
                                            .primaryColor // Pink
                                        : Colors.black,
                                borderColor: Colors.transparent,
                                borderWidth: 0,
                              ),
                              child: Transform.rotate(
                                angle: -pi / 2,
                                child: Center(
                                  child: Text(
                                    items[i],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Center circle
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Top pointer
                    Positioned(
                      top: 16,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: const Size(26, 26),
                          painter: WheelPointerPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 65),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      shadowColor: Colors.yellowAccent.withOpacity(0.1),
                    ),
                    onPressed: isSpinning ? null : spinWheel,
                    child: const Text(
                      'ម្តង១​ក្រវិល',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for glowing bulbs and border
class WheelBulbPainter extends CustomPainter {
  final int bulbCount;
  final Color bulbColor;
  final Color glowColor;
  final Color borderColor;
  final double borderWidth;

  WheelBulbPainter({
    required this.bulbCount,
    required this.bulbColor,
    required this.glowColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - borderWidth / 2;

    // Draw main border
    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw bulbs
    final bulbRadius = 12.0;
    for (int i = 0; i < bulbCount; i++) {
      final angle = 2 * pi * i / bulbCount - pi / 2;
      final bulbCenter = Offset(
        center.dx + cos(angle) * (radius),
        center.dy + sin(angle) * (radius),
      );
      // Glow: lighter, more modern
      canvas.drawCircle(
        bulbCenter,
        bulbRadius + 2,
        Paint()
          ..color = Colors.white.withOpacity(0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        bulbCenter,
        bulbRadius,
        Paint()
          ..color = Colors.yellowAccent.withOpacity(0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Bulb: more white
      canvas.drawCircle(
        bulbCenter,
        bulbRadius * 0.62,
        Paint()..color = Colors.white,
      );
      // Bulb border
      canvas.drawCircle(
        bulbCenter,
        bulbRadius * 0.62,
        Paint()
          ..color = Colors.amber.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WheelBulbPainter oldDelegate) => false;
}

// Custom pointer painter (triangle)
class WheelPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    final Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawShadow(path, Colors.black, 3, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//Correct with 446 line code changes
