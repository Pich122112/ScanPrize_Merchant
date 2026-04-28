import 'dart:ui';
import 'package:flutter/material.dart';

class DateFilterDialog {
  static Future<dynamic> show(
    BuildContext context, {
    String currentFilter = 'Default', // Update default
    DateTimeRange? currentDateRange,
  }) async {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.purpleAccent.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '📅 Filter by Date',
                        style: TextStyle(
                          fontFamily: 'KhmerFont',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(blurRadius: 20, color: Colors.white),
                            Shadow(blurRadius: 30, color: Colors.pinkAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _filterButton(
                        context,
                        'Default',
                        Colors.greenAccent,
                        isSelected: currentFilter == 'Default',
                      ), // Add this
                      _filterButton(
                        context,
                        'On Today',
                        Colors.pinkAccent,
                        isSelected: currentFilter == 'On Today',
                      ),
                      _filterButton(
                        context,
                        'This Week',
                        Colors.purpleAccent,
                        isSelected: currentFilter == 'This Week',
                      ),
                      _filterButton(
                        context,
                        'This Month',
                        Colors.blueAccent,
                        isSelected: currentFilter == 'This Month',
                      ),
                      _filterButton(
                        context,
                        'Custom',
                        Colors.cyanAccent,
                        isCustom: true,
                        isSelected: currentFilter == 'Custom',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  static Widget _filterButton(
    BuildContext context,
    String title,
    Color glowColor, {
    bool isCustom = false,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: glowColor.withOpacity(0.2),
        onTap: () async {
          if (isCustom) {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: Colors.cyanAccent,
                      surface: Colors.blueGrey.shade900,
                      onSurface: Colors.white,
                      error: Colors.redAccent,
                    ),
                    textTheme: const TextTheme(
                      titleLarge: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.cyanAccent,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.pinkAccent),
                        ],
                      ),
                      labelLarge: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.pinkAccent,
                        letterSpacing: 0.2,
                      ),
                      bodyLarge: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.cyanAccent,
                      ),
                      bodyMedium: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      headlineSmall: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.pinkAccent,
                      ),
                      labelSmall: TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: ButtonStyle(
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(
                            fontFamily: 'KhmerFont',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: const TextStyle(
                        fontFamily: 'KhmerFont',
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                      hintStyle: const TextStyle(
                        fontFamily: 'KhmerFont',
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.blueGrey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.blueGrey.shade800),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              Navigator.pop(context, picked);
            }
          } else {
            Navigator.pop(context, title);
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isSelected
                      ? [
                        glowColor.withOpacity(0.3),
                        glowColor.withOpacity(0.15),
                      ]
                      : [
                        glowColor.withOpacity(0.15),
                        glowColor.withOpacity(0.05),
                      ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? glowColor : glowColor.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(isSelected ? 0.6 : 0.4),
                blurRadius: isSelected ? 16 : 12,
                spreadRadius: isSelected ? 2 : 1,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'KhmerFont',
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Correct with 271 line code change
