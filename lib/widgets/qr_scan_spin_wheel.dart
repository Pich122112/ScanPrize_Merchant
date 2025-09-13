import 'dart:async';
// ignore: unused_import
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:gb_merchant/utils/constants.dart';

class QrScanSpinWheelDialog extends StatefulWidget {
  final String prize;
  final List<String> defaultItems;
  final VoidCallback onClose;
  final String prizeLogo; // Add this parameter

  const QrScanSpinWheelDialog({
    required this.prize,
    required this.defaultItems,
    required this.onClose,
    this.prizeLogo = 'assets/images/default.png', // Default value
    super.key,
  });

  @override
  State<QrScanSpinWheelDialog> createState() => _QrScanSpinWheelDialogState();
}

class _QrScanSpinWheelDialogState extends State<QrScanSpinWheelDialog> {
  late List<String> items;
  final StreamController<int> selected = StreamController<int>();
  late ConfettiController _confettiController;
  bool isSpinning = true;
  int selectedIndex = 0;
  bool showResult = false;

  List<FortuneItem> _buildWheelItems() {
    return items.map((item) {
      final index = items.indexOf(item);
      final color = index.isEven ? AppColors.primaryColor : Colors.black;
      final borderColor = Colors.white;

      if (item.toLowerCase().contains('motor')) {
        return FortuneItem(
          style: FortuneItemStyle(
            color: color,
            borderColor: borderColor,
            borderWidth: 2,
          ),
          child: Transform.rotate(
            angle: 3.1416,
            child: Image.asset(
              'assets/images/Yamaha.png',
              width: 60,
              height: 60,
            ),
          ),
        );
      } else if (item.toLowerCase().contains('car')) {
        return FortuneItem(
          style: FortuneItemStyle(
            color: color,
            borderColor: borderColor,
            borderWidth: 2,
          ),
          child: Transform.rotate(
            angle: 3.1416,
            child: Image.asset(
              'assets/images/fordranger.png',
              width: 60,
              height: 60,
            ),
          ),
        );
      } else {
        return FortuneItem(
          style: FortuneItemStyle(
            color: color,
            borderColor: borderColor,
            borderWidth: 2,
          ),
          child: Transform.rotate(
            angle: 3.1416,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // If ends with D (and has number in front), show number + diamond
                  if (RegExp(r'^\d+\s*D$').hasMatch(item)) ...[
                    Text(
                      item.replaceAll(RegExp(r'D$'), ''),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    diamondIcon(size: 22, color: Colors.white),
                  ] else
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'KhmerFont'
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Combine default items with the scanned prize
    items = List.from(widget.defaultItems);

    if (!items.contains(widget.prize)) {
      items.add(widget.prize);
    }

    // Start spinning automatically
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSpin());
  }

  void _startSpin() async {
    // Always include the scanned prize in the wheel
    if (!items.contains(widget.prize)) {
      setState(() {
        items.add(widget.prize);
      });
    }

    // Find index of the prize (it will be there now)
    selectedIndex = items.indexOf(widget.prize);

    selected.add(selectedIndex);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        isSpinning = false;
        showResult = true;
      });
      _showCongratulation();
    }
  }

  void _showCongratulation() {
    _confettiController.play();
  }

  @override
  void dispose() {
    selected.close();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        // Changed from Container to Stack
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSpinning ? 'spinning'.tr() : 'completed'.tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  width: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle:
                            3.1416, // Rotate the whole wheel by 180 degrees (in radians)
                        child: FortuneWheel(
                          selected: selected.stream,
                          animateFirst: false,
                          duration: const Duration(seconds: 1),
                          physics: CircularPanPhysics(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.decelerate,
                          ),
                          indicators: [
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: TriangleIndicator(color: Colors.blue),
                            ),
                          ],
                          items: _buildWheelItems(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (showResult) ...[
                  _buildCongratulationDialog(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryColor.withOpacity(0.3),
                    ),
                    onPressed: () {
                      widget.onClose();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'ok'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        fontFamily: 'KhmerFont'
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Confetti positioned at the top of the dialog
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              minimumSize: const Size(10, 10),
              maximumSize: const Size(20, 20),
              numberOfParticles: 30,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.pink,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCongratulationDialog() {
    final localeCode = context.locale.languageCode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textColor.withOpacity(0),
                  blurRadius: 25,
                  spreadRadius: 4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              widget.prizeLogo,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'congratulation'.tr(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (RegExp(r'^\d+\s*D$').hasMatch(items[selectedIndex])) ...[
                Text(
                  'you_received'.tr(
                    args: [items[selectedIndex].replaceAll(RegExp(r'D$'), '')],
                  ),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B4957),
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  ),
                ),
                const SizedBox(width: 6),
                diamondIcon(size: 22, color: Colors.black),
              ] else
                Text(
                  'you_received'.tr(args: [items[selectedIndex]]),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B4957),
                    fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget diamondIcon({double size = 30, Color color = Colors.yellow}) {
  return Icon(Icons.diamond, size: size, color: color);
}

class TriangleIndicator extends StatelessWidget {
  final Color color;

  const TriangleIndicator({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 3.1416, // Rotate the triangle 180 degrees to point upwards
      child: ClipPath(
        clipper: _TriangleClipper(),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

//Correct with 442 line code changes
