import 'package:flutter/material.dart';

class AppColors {
  // Primary color used throughout the app
  static const Color primaryColor = Color.fromARGB(255, 251, 96, 0);

  // Additional colors can be added here
  static const Color secondaryColor = Colors.blue;
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black;
  static const Color greyColor = Colors.grey;
  static const Color successCOlor = Color.fromARGB(255, 2, 194, 9);
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

  // Add more styles as needed
}

class AppDimensions {
  // Consistent padding and margin values
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double borderRadius = 50.0;
}
