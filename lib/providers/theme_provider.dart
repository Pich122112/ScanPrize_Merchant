// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = AppColors.blueColor;
  bool _isDarkMode = false;
  
  ThemeProvider() {
    loadPreferences(); 
  }
  
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _isDarkMode;
  
  // Made this public
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load primary color preference
    final savedColor = prefs.getString('primaryColor');
    if (savedColor == 'orange') {
      _primaryColor = AppColors.orangeColor;
    } else {
      _primaryColor = AppColors.blueColor;
    }
    
    // Load dark mode preference
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    // Update AppColors static variable
    AppColors.setPrimaryColor(_primaryColor);
    
    notifyListeners();
  }
  
  Future<void> setPrimaryColor(Color color, String colorKey) async {
    _primaryColor = color;
    AppColors.setPrimaryColor(color);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primaryColor', colorKey);
    
    notifyListeners();
  }
  
  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    AppColors.setPrimaryColor(_primaryColor); // Ensure color updates with dark mode
    notifyListeners();
  }
}
