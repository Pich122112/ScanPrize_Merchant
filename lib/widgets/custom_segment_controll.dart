import 'package:flutter/material.dart';

class KhmerSegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<String> options;
  final ValueChanged<int> onChanged;

  const KhmerSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.options,
    required this.onChanged,
  }) : assert(options.length == 2);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(2, (index) {
          final bool isSelected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFFF6B00) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KhmerFont',
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
