import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionService {
  static const String KEY_LAST_UPDATE_REMINDER = 'last_update_reminder_date';
  static const String KEY_UPDATE_SKIPPED_VERSION = 'skipped_version';

  // 🔧 FOR TESTING ONLY - Set to true to simulate update without store release
  static bool forceMockUpdate = true; // Change to false for production

  // 🔧 Mock latest version for testing (change this to simulate new update)
  static const String mockLatestVersion = "2.0.0";

  // Store URLs - REPLACE WITH YOUR ACTUAL STORE LINKS
  static const String iOSStoreUrl = "https://apps.apple.com/app/id6758925797";
  static const String androidStoreUrl =
      "https://play.google.com/store/apps/details?id=com.ganzberg.scanprizefront";

  /// Get current app version from pubspec.yaml
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print("Error getting version: $e");
      return "1.0.0";
    }
  }

  /// Check if update is available
  Future<UpdateStatus> checkUpdateAvailability() async {
    final currentVersion = await getCurrentVersion();

    // TESTING MODE: Use mock version
    if (forceMockUpdate) {
      final needsUpdate = _isNewerVersion(mockLatestVersion, currentVersion);
      return UpdateStatus(
        needsUpdate: needsUpdate,
        currentVersion: currentVersion,
        latestVersion: mockLatestVersion,
        isForceUpdate: false, // Set to true for critical updates
      );
    }

    // PRODUCTION MODE: Compare with remote config or API
    // For now, return no update - you'll connect to your backend
    return UpdateStatus(
      needsUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      isForceUpdate: false,
    );
  }

  /// Check if user has already skipped this version
  Future<bool> hasUserSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString(KEY_UPDATE_SKIPPED_VERSION);
    return skippedVersion == version;
  }

  /// Save that user skipped this version
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_UPDATE_SKIPPED_VERSION, version);
  }

  /// Clear skipped version (for testing)
  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_UPDATE_SKIPPED_VERSION);
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      // Fallback to string comparison
      return latest.compareTo(current) > 0;
    }
  }
}

class UpdateStatus {
  final bool needsUpdate;
  final String currentVersion;
  final String latestVersion;
  final bool isForceUpdate;

  UpdateStatus({
    required this.needsUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.isForceUpdate,
  });
}
