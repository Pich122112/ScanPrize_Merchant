// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

// class DeviceUUID {
//   static const String _key = 'device_uuid_uniqfeb14twosousandandtwentyonehaha';
//   static String? _cachedUUID; // Add this line

//   // Simple regex to validate UUID v4 format
//   static final RegExp _uuidRegex = RegExp(
//     r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
//     caseSensitive: false,
//   );

//   static Future<String> getUUID() async {
//     // ✅ FIRST check if we have a valid cached UUID
//     if (_cachedUUID != null && _uuidRegex.hasMatch(_cachedUUID!)) {
//       print('📱 Using cached UUID: $_cachedUUID');
//       return _cachedUUID!;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     String? uuid = prefs.getString(_key);

//     // ✅ Check if we have a valid stored UUID
//     if (uuid != null && uuid.isNotEmpty && _uuidRegex.hasMatch(uuid)) {
//       print('📱 Restoring UUID from storage: $uuid');
//       _cachedUUID = uuid; // ✅ RESTORE THE CACHE
//       return uuid;
//     }

//     // ✅ If no valid UUID exists, generate a new one
//     if (uuid == null || uuid.isEmpty || !_uuidRegex.hasMatch(uuid)) {
//       return await _regenerateUUID();
//     } else {
//       print('📱 Retrieved stored UUID: $uuid');
//       _cachedUUID = uuid;
//       return uuid;
//     }
//   }

//   static Future<String> _regenerateUUID() async {
//     final prefs = await SharedPreferences.getInstance();
//     final newUuid = const Uuid().v4();
//     await prefs.setString(_key, newUuid);
//     _cachedUUID = newUuid; // ✅ Ensure cache is always set
//     print('📱 Generated new UUID: $newUuid');
//     return newUuid;
//   }

//   static Future<String> regenerateUUID() async {
//     return await _regenerateUUID();
//   }

//   static Future<void> clearUUID() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_key);
//     _cachedUUID = null;
//     print('📱 Cleared UUID from storage');
//   }

//   static Future<bool> hasUUID() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.containsKey(_key);
//   }

//   static Future<String?> getExistingUUID() async {
//     if (_cachedUUID != null) return _cachedUUID;
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_key);
//   }
// }

// //Correct with 78 line code changes

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceUUID {
  static const String _fileName = 'device_uuid.txt';
  static String? _cachedUUID;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static Future<String> getUUID() async {
    // Return cached UUID if valid
    if (_cachedUUID != null && _isValidUUID(_cachedUUID!)) {
      print('📱 Using cached UUID: $_cachedUUID');
      return _cachedUUID!;
    }

    // Try to read from file storage (more reliable than SharedPreferences)
    try {
      final file = await _getUUIDFile();
      if (await file.exists()) {
        final storedUUID = await file.readAsString();
        if (_isValidUUID(storedUUID)) {
          print('📱 Using stored file UUID: $storedUUID');
          _cachedUUID = storedUUID;
          return storedUUID;
        }
      }
    } catch (e) {
      print('⚠️ Error reading UUID file: $e');
    }

    // Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedUUID = prefs.getString('device_uuid_backup');
      if (storedUUID != null && _isValidUUID(storedUUID)) {
        print('📱 Using SharedPreferences backup UUID: $storedUUID');
        _cachedUUID = storedUUID;
        return storedUUID;
      }
    } catch (e) {
      print('⚠️ Error reading SharedPreferences: $e');
    }

    // Generate new UUID if none exists
    return await _regenerateUUID();
  }

  static Future<String> _regenerateUUID() async {
    final newUuid = const Uuid().v4();
    _cachedUUID = newUuid;

    // Save to both file and SharedPreferences for redundancy
    try {
      final file = await _getUUIDFile();
      await file.writeAsString(newUuid);
      print('📱 Saved new UUID to file: $newUuid');
    } catch (e) {
      print('⚠️ Error saving UUID to file: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_uuid_backup', newUuid);
      print('📱 Saved new UUID to SharedPreferences: $newUuid');
    } catch (e) {
      print('⚠️ Error saving UUID to SharedPreferences: $e');
    }

    print('📱 Generated new UUID: $newUuid');
    return newUuid;
  }

  static Future<File> _getUUIDFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static bool _isValidUUID(String? uuid) {
    return uuid != null && uuid.isNotEmpty && _uuidRegex.hasMatch(uuid);
  }

  static Future<String> regenerateUUID() async {
    return await _regenerateUUID();
  }

  static Future<void> clearUUID() async {
    _cachedUUID = null;

    try {
      final file = await _getUUIDFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('⚠️ Error deleting UUID file: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_uuid_backup');
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences UUID: $e');
    }

    print('📱 Cleared UUID from storage');
  }

  static Future<bool> hasUUID() async {
    try {
      final file = await _getUUIDFile();
      return await file.exists();
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('device_uuid_backup');
    }
  }

  static Future<String?> getExistingUUID() async {
    if (_cachedUUID != null) return _cachedUUID;

    try {
      final file = await _getUUIDFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('⚠️ Error reading existing UUID from file: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('device_uuid_backup');
    } catch (e) {
      print('⚠️ Error reading existing UUID from SharedPreferences: $e');
      return null;
    }
  }
}
