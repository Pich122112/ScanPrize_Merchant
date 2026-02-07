import 'package:flutter/material.dart';

class AnimatedCallIcon extends StatefulWidget {
  final bool isTablet;
  const AnimatedCallIcon({Key? key, this.isTablet = false}) : super(key: key);

  @override
  State<AnimatedCallIcon> createState() => _AnimatedCallIconState();
}

class _AnimatedCallIconState extends State<AnimatedCallIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          Icons.call,
          size: widget.isTablet ? 50 : 40,
          color: Colors.deepOrange,
        ),
      ),
    );
  }
}
