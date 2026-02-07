import 'package:flutter/material.dart';

class DashboardSegmentControll extends StatelessWidget {
  final int selectedIndex;
  final List<String> options;
  final ValueChanged<int> onChanged;

  const DashboardSegmentControll({
    super.key,
    required this.selectedIndex,
    required this.options,
    required this.onChanged,
  }) : assert(options.length == 3);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: List.generate(3, (index) {
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
                    fontSize: 15,
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
