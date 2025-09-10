import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_server.dart';

class PasscodeCache {
  static const String _hasPasscodeKey = 'hasPasscode';
  static const String _lastUpdatedKey = 'passcode_last_updated';
  static const Duration _cacheDuration = Duration(hours: 1); // Cache for 1 hour

  static Future<bool> hasPasscodeCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdated = prefs.getInt(_lastUpdatedKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if cache is still valid
      if (now - lastUpdated > _cacheDuration.inMilliseconds) {
        return false; // Cache expired
      }

      return prefs.getBool(_hasPasscodeKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> cachePasscodeStatus(bool hasPasscode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasPasscodeKey, hasPasscode);
      await prefs.setInt(
        _lastUpdatedKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error caching passcode status: $e');
    }
  }

  static Future<void> clearPasscodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasPasscodeKey);
      await prefs.remove(_lastUpdatedKey);
    } catch (e) {
      print('Error clearing passcode cache: $e');
    }
  }

  // Force refresh the cache from API
  static Future<bool> refreshPasscodeStatus(String token) async {
    try {
      final userProfile = await ApiService.getUserProfile(token);
      // ignore: unnecessary_null_comparison
      if (userProfile != null && userProfile['success'] == true) {
        final userData = userProfile['data'];
        final passcodeValue = userData['passcode'] ?? userData['passcode_hash'];
        final hasPasscode =
            (passcodeValue != null &&
                passcodeValue.toString() != '0' &&
                passcodeValue.toString().isNotEmpty);

        await cachePasscodeStatus(hasPasscode);
        return hasPasscode;
      }
    } catch (e) {
      print('Error refreshing passcode status: $e');
    }
    return false;
  }
}
