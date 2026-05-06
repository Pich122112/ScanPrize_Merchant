import 'package:flutter/material.dart';

class AppColors {
  // Primary color - now dynamic
  static Color primaryColor = const Color(0xFF0D55A8); // Default blue

  // Define your color options
  static const Color blueColor = Color(0xFF0D55A8);
  static const Color orangeColor = Color.fromARGB(255, 235, 79, 7); //this one
  // static const Color orangeColor = Color.fromARGB(255, 251, 96, 0);

  // Additional colors
  static const Color secondaryColor = Colors.blue;
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;
  static const Color greyColor = Colors.grey;
  static const Color successColor = Color.fromARGB(255, 2, 194, 9);

  // Method to update primary color
  static void setPrimaryColor(Color color) {
    primaryColor = color;
  }
}

class AppStyles {
  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    color: Colors.black,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );
}

class AppDimensions {
  // Consistent padding and margin values
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double borderRadius = 50.0;
}
