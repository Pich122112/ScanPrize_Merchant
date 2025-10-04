import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';

class RemarkInput extends StatefulWidget {
  final TextEditingController controller;
  final String localeCode;

  const RemarkInput({
    super.key,
    required this.controller,
    required this.localeCode,
  });

  @override
  State<RemarkInput> createState() => _RemarkInputState();
}

class _RemarkInputState extends State<RemarkInput>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Ping-pong animation (center → left → center → right → center)
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
        if (_isEditing) {
          _animationController.repeat(reverse: true); // infinite ping-pong
        } else {
          _animationController.stop();
          _animationController.reset();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    if (widget.controller.text.isEmpty) {
      // If no text, close input
      _focusNode.unfocus();
    } else {
      // If there is text, clear it
      setState(() {
        widget.controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder:
              (child, animation) =>
                  SizeTransition(sizeFactor: animation, child: child),
          child:
              _isEditing
                  ? Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey("remarkInput"),
                              controller: widget.controller,
                              focusNode: _focusNode,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily:
                                    widget.localeCode == 'km'
                                        ? 'KhmerFont'
                                        : null,
                              ),
                              decoration: InputDecoration(
                                hintText: 'remarks'.tr(),
                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.backgroundColor,
                                  fontSize: 15,
                                  fontFamily:
                                      widget.localeCode == 'km'
                                          ? 'KhmerFont'
                                          : null,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                filled: false,
                              ),
                              maxLines: 1,
                              onSubmitted: (_) => _focusNode.unfocus(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              widget.controller.text.isEmpty
                                  ? Icons.close
                                  : Icons.clear,
                              color: Colors.white,
                            ),
                            onPressed: _handleCancel,
                          ),
                        ],
                      ),
                      // Animated gradient underline
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final widthFactor = 0.4; // 40% of full width
                            final center = 0.5;
                            final shift =
                                (_animation.value - 0.5) * 2; // -1 to 1
                            final startAlign =
                                center - widthFactor / 2 + shift * 0.5;
                            final endAlign =
                                center + widthFactor / 2 + shift * 0.5;

                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1.0,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purpleAccent,
                                      Colors.pinkAccent,
                                      Colors.cyanAccent,
                                    ],
                                    begin: Alignment(startAlign * 2 - 1, 0),
                                    end: Alignment(endAlign * 2 - 1, 0),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                  : GestureDetector(
                    key: const ValueKey("remarkLabel"),
                    onTap:
                        () => FocusScope.of(context).requestFocus(_focusNode),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.text_fields_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.controller.text.isEmpty
                              ? (widget.localeCode == 'km' ? "ចំណាំ" : "Remark")
                              : widget.controller.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily:
                                widget.localeCode == 'km' ? 'KhmerFont' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
