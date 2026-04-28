import 'package:flutter/material.dart';

class AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool disabled; // optional: grey out when disabled

  const AnimatedGradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.disabled = false,
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // infinite loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return TextButton(
            onPressed: widget.disabled ? null : widget.onPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(120, 45),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient:
                    widget.disabled
                        ? null
                        : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Color(0xFF8A2BE2),
                            Color(0xFFFF8CFF),
                            Color(0xFF40E0D0),
                          ],
                          stops: [0.0, _controller.value, 2.0],
                        ),
                color: widget.disabled ? Colors.grey[400] : null,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minWidth: 120, minHeight: 45),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.disabled ? Colors.grey[200] : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KhmerFont',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
