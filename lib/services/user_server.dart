import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'https://api-merchant.sandbox.gzb.app/api/v2';
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';

  static Future<Map<String, dynamic>> uploadFcmToken({
    required String apiToken,
    required String fcmToken,
  }) async {
    final url = Uri.parse('$baseUrl/user/save-fcm-token');

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiToken",
        "Accept": "application/json",
        'X-App-Package': appPackage,
      },
      body: {"fcm_token": fcmToken},
    );
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {"result": decoded};
      }
    } catch (e) {
      return {
        "error": "Failed to decode response",
        "status": response.statusCode,
      };
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String phone,
    required String otp,
    required String provinceId,
    required String district,
    required String commune,
    required String village,
    required String deviceUuid,
    required String fcmToken,
  }) async {
    final url = Uri.parse(
      'https://api-merchant.sandbox.gzb.app/api/v2/auth/signup',
    );

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'X-App-Package': appPackage},
      body: {
        'name': name,
        'phone': phone,
        'otp': otp,
        'province': provinceId,
        'district': district,
        'commune': commune,
        'village': village,
        'device_uuid': deviceUuid,
        'fcm_token': fcmToken,
      },
    );

    if (kDebugMode) {
      print('🔐 SIGNUP request sent');
      print('Status: ${response.statusCode}');
    }
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> uploadIdentityDocuments({
    required String token,
    required File nationalIdFront,
    required File nationalIdBack,
    String uploadType = 'nid',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/uploads');

      var request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.headers['X-App-Package'] = appPackage;
      request.fields['upload_type'] = uploadType;

      request.files.add(
        await http.MultipartFile.fromPath(
          'national_id_front',
          nationalIdFront.path,
          filename: 'front_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'national_id_back',
          nationalIdBack.path,
          filename: 'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('📸 UPLOAD Status: ${response.statusCode}');
      }

      return json.decode(responseBody);
    } catch (e) {
      if (kDebugMode) {
        print('❌ UPLOAD ERROR');
      }
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> requestSignUpOtp(String phone) async {
    final url = Uri.parse('$baseUrl/auth/request-signup-otp');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'X-App-Package': appPackage},
      body: {'phone': phone},
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> requestSignInOtp(String phone) async {
    final url = Uri.parse('$baseUrl/auth/request-otp');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'X-App-Package': appPackage},
      body: {'phone': phone},
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtpV2(
    String phone,
    String otp,
    String deviceUuid,
    String fcmToken,
  ) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'X-App-Package': appPackage},
      body: {
        'phone': phone,
        'otp': otp,
        'device_uuid': deviceUuid,
        'fcm_token': fcmToken,
      },
    );

    if (kDebugMode) {
      print('🔐 SIGNIN request sent');
      print('Status: ${response.statusCode}');
    }
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final url = Uri.parse(
        'https://api-merchant.sandbox.gzb.app/api/v2/user/profile?force=1',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-App-Package': appPackage,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['data'] != null) {
          final status = result['data']['status'];
          if (kDebugMode) {
            print('🔐 User profile retrieved');
          }
          result['user_status'] = status;
        }

        return result;
      } else {
        return {'success': false, 'message': 'Failed to get user profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<String?> getTokenFromSecureStorage() async {
    final secureStorage = SecureStorageService();
    return await secureStorage.getToken();
  }

  static Future<Map<String, dynamic>> createPasscode(
    String token,
    String passcode,
    String passcodeConfirmation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-merchant.sandbox.gzb.app/api/v2/user/passcode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-App-Package': appPackage,
        },
        body: {
          'passcode': passcode,
          'passcode_confirmation': passcodeConfirmation,
        },
      );

      if (kDebugMode) {
        print('🔐 Create passcode API called');
        print('Status: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      if (kDebugMode) {
        print('❌ CREATE PASSCODE ERROR');
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyPasscode(
    String token,
    String passcode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://api-merchant.sandbox.gzb.app/api/v2/user/passcode/verify',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-App-Package': appPackage,
        },
        body: {'passcode': passcode},
      );
      if (kDebugMode) {
        print('🔐 Verify passcode API called');
        print('Status: ${response.statusCode}');
      }
      return json.decode(response.body);
    } catch (e) {
      if (kDebugMode) {
        print('❌ VERIFY PASSCODE ERROR');
      }
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> scanQrCode(
    String code,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://api-merchant.sandbox.gzb.app/api/v2/redeem/scan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-App-Package': appPackage,
        },
        body: {'code': code},
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}

//Correct with 297 line code changes
