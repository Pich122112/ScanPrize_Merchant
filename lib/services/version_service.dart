import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


class VersionService {
  static const String KEY_SKIPPED_VERSION = 'skipped_version';

  // Store URLs for Merchant App
  static const String iOSStoreUrl = "https://apps.apple.com/app/id6759018661";
  static const String androidStoreUrl =
      "https://play.google.com/store/apps/details?id=com.ganzberg.scanprizemerchantapp";

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // ✅ Updated: Merchant-specific Remote Config Keys
  static const String RC_IOS_LATEST_VERSION = 'merchant_ios_latest_version';
  static const String RC_IOS_MINIMUM_VERSION = 'merchant_ios_minimum_version';
  static const String RC_IOS_FORCE_UPDATE = 'merchant_ios_force_update';

  static const String RC_ANDROID_LATEST_VERSION =
      'merchant_android_latest_version';
  static const String RC_ANDROID_MINIMUM_VERSION =
      'merchant_android_minimum_version';
  static const String RC_ANDROID_FORCE_UPDATE = 'merchant_android_force_update';

  Future<void> initRemoteConfig() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 0),
        ),
      );

      await _remoteConfig.setDefaults({
        RC_IOS_LATEST_VERSION: '1.0.0',
        RC_IOS_MINIMUM_VERSION: '1.0.0',
        RC_IOS_FORCE_UPDATE: false,
        RC_ANDROID_LATEST_VERSION: '1.0.0',
        RC_ANDROID_MINIMUM_VERSION: '1.0.0',
        RC_ANDROID_FORCE_UPDATE: false,
      });

      await _remoteConfig.fetch();
      await _remoteConfig.activate();

      print('📱 === MERCHANT APP FETCHED VALUES ===');
      print(
        '📱 merchant_ios_latest_version: "${_remoteConfig.getString(RC_IOS_LATEST_VERSION)}"',
      );
      print(
        '📱 merchant_ios_minimum_version: "${_remoteConfig.getString(RC_IOS_MINIMUM_VERSION)}"',
      );
      print(
        '📱 merchant_ios_force_update: ${_remoteConfig.getBool(RC_IOS_FORCE_UPDATE)}',
      );
      print(
        '📱 merchant_android_latest_version: "${_remoteConfig.getString(RC_ANDROID_LATEST_VERSION)}"',
      );
      print(
        '📱 merchant_android_minimum_version: "${_remoteConfig.getString(RC_ANDROID_MINIMUM_VERSION)}"',
      );
      print(
        '📱 merchant_android_force_update: ${_remoteConfig.getBool(RC_ANDROID_FORCE_UPDATE)}',
      );
      print('📱 =====================================');
    } catch (e) {
      print('❌ Remote Config init error: $e');
    }
  }

  /// Get latest version based on platform
  String getLatestVersion() {
    if (Platform.isIOS) {
      return _remoteConfig.getString(RC_IOS_LATEST_VERSION);
    } else {
      return _remoteConfig.getString(RC_ANDROID_LATEST_VERSION);
    }
  }

  /// Get minimum version based on platform
  String getMinimumVersion() {
    if (Platform.isIOS) {
      return _remoteConfig.getString(RC_IOS_MINIMUM_VERSION);
    } else {
      return _remoteConfig.getString(RC_ANDROID_MINIMUM_VERSION);
    }
  }

  /// Get force update status based on platform
  bool getForceUpdate() {
    if (Platform.isIOS) {
      return _remoteConfig.getBool(RC_IOS_FORCE_UPDATE);
    } else {
      return _remoteConfig.getBool(RC_ANDROID_FORCE_UPDATE);
    }
  }

  /// Get current app version
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      print('📱 PackageInfo appName: ${packageInfo.appName}');
      print('📱 PackageInfo packageName: ${packageInfo.packageName}');
      print('📱 PackageInfo version: ${packageInfo.version}');
      print('📱 PackageInfo buildNumber: ${packageInfo.buildNumber}');

      return packageInfo.version;
    } catch (e) {
      print("Error getting version: $e");
      return "1.0.0";
    }
  }

  /// Check if update is available
  Future<UpdateStatus> checkUpdateAvailability() async {
    final currentVersion = await getCurrentVersion();

    try {
      await initRemoteConfig();

      final latestVersion = getLatestVersion();
      final minimumVersion = getMinimumVersion();
      final forceUpdateFlag = getForceUpdate();

      final platform = Platform.isIOS ? "iOS" : "Android";

      print('📱 Platform: $platform');
      print('📱 Current version: $currentVersion');
      print('📱 Latest version from Firebase: $latestVersion');
      print('📱 Minimum version: $minimumVersion');
      print('📱 Force update flag from Firebase: $forceUpdateFlag');

      // Check if update is needed
      final needsUpdate = _isNewerVersion(latestVersion, currentVersion);

      if (!needsUpdate) {
        print("✅ No update needed");
        return UpdateStatus(
          needsUpdate: false,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          isForceUpdate: false,
        );
      }

      final shouldForceUpdate = forceUpdateFlag;

      print('📊 shouldForceUpdate: $shouldForceUpdate');

      return UpdateStatus(
        needsUpdate: true,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        isForceUpdate: shouldForceUpdate,
      );
    } catch (e) {
      print('❌ Error checking update: $e');
      return UpdateStatus(
        needsUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        isForceUpdate: false,
      );
    }
  }

  /// Check if user has already skipped this version
  Future<bool> hasUserSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString(KEY_SKIPPED_VERSION);
    return skippedVersion == version;
  }

  /// Save that user skipped this version
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_SKIPPED_VERSION, version);
  }

  /// Clear skipped version (for testing)
  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_SKIPPED_VERSION);
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      // 🔥 FIX: Extract only the version part (remove build number)
      String extractVersion(String version) {
        return version.split('+').first;
      }

      final cleanLatest = extractVersion(latest);
      final cleanCurrent = extractVersion(current);

      // If versions are identical, no update needed
      if (cleanLatest == cleanCurrent) {
        print(
          '📊 Same version detected: $cleanLatest == $cleanCurrent → No update',
        );
        return false;
      }

      List<int> parseVersion(String version) {
        return version.split('.').map(int.parse).toList();
      }

      final latestParts = parseVersion(cleanLatest);
      final currentParts = parseVersion(cleanCurrent);

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      print('📊 Version parsing error: $e');
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
