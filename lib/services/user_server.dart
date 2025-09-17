// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiService {
//   static const String baseUrl = 'https://api-merchant.sandbox.gzb.app/api/v2';

//   static Future<Map<String, dynamic>> signUp({
//     required String name,
//     required String phone,
//     required String otp,
//     required String provinceId, // Now accepts numeric ID directly
//     required String district,
//     required String commune,
//     required String village,
//   }) async {
//     try {
//       final url = Uri.parse(
//         'https://api-merchant.sandbox.gzb.app/api/v2/auth/signup',
//       );

//       // Debug the request data
//       print('🔐 SIGNUP REQUEST DATA:');
//       print('Name: $name');
//       print('Phone: $phone');
//       print('OTP: $otp');
//       print('Province: $provinceId');
//       print('District: $district');
//       print('Commune: $commune');
//       print('Village: $village');

//       final response = await http.post(
//         url,
//         headers: {'Accept': 'application/json'},
//         body: {
//           'name': name,
//           'phone': phone,
//           'otp': otp,
//           'province': provinceId, // Send numeric ID directly
//           'district': district,
//           'commune': commune,
//           'village': village,
//         },
//       );

//       print('🔐 SIGNUP API RESPONSE:');
//       print('Status: ${response.statusCode}');
//       print('Body: ${response.body}');

//       return json.decode(response.body);
//     } catch (e) {
//       print('❌ SIGNUP ERROR: $e');
//       return {'success': false, 'message': 'Network error: $e'};
//     }
//   }

//   static Future<Map<String, dynamic>> requestOtpV2(String phone) async {
//     final url = Uri.parse('$baseUrl/auth/request-otp');
//     final response = await http.post(
//       url,
//       headers: {'Accept': 'application/json'},
//       body: {'phone': phone},
//     );
//     return json.decode(response.body);
//   }

//   static Future<Map<String, dynamic>> verifyOtpV2(
//     String phone,
//     String otp,
//     String userType,
//   ) async {
//     final url = Uri.parse('$baseUrl/auth/verify-otp');
//     final response = await http.post(
//       url,
//       headers: {'Accept': 'application/json'},
//       body: {'phone': phone, 'otp': otp, 'user_type': userType},
//     );
//     return json.decode(response.body);
//   }

//   static Future<Map<String, dynamic>> getUserProfile(String token) async {
//     try {
//       final url = Uri.parse(
//         'https://api-merchant.sandbox.gzb.app/api/v2/user/profile?force=1',
//       );

//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final result = json.decode(response.body);

//         // ✅ DEBUG: Check what fields actually exist in the response
//         if (result['data'] != null) {
//           print('🔐 USER PROFILE FIELDS: ${result['data'].keys.toList()}');
//           print('🔐 STATUS FIELD: ${result['data']['status']}'); // Add this
//           print('🔐 PASSCODE FIELD: ${result['data']['passcode']}');
//           print('🔐 PASSCODE_HASH FIELD: ${result['data']['passcode_hash']}');

//           // Handle the status field
//           final status = result['data']['status'];
//           print('🔐 USER STATUS: $status');

//           // You might want to add status to the returned data
//           result['user_status'] = status;
//         }

//         return result;
//       } else {
//         return {'success': false, 'message': 'Failed to get user profile'};
//       }
//     } catch (e) {
//       return {'success': false, 'message': 'Network error'};
//     }
//   }

//   static Future<Map<String, dynamic>> createPasscode(
//     String token,
//     String passcode,
//     String passcodeConfirmation,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('https://api-merchant.sandbox.gzb.app/api/v2/user/passcode'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//         body: {
//           'passcode': passcode,
//           'passcode_confirmation': passcodeConfirmation,
//         },
//       );

//       // ✅ DEBUG: Check the actual response
//       print('🔐 CREATE PASSCODE API RESPONSE:');
//       print('Status: ${response.statusCode}');
//       print('Body: ${response.body}');

//       return json.decode(response.body);
//     } catch (e) {
//       print('❌ CREATE PASSCODE ERROR: $e');
//       return {'success': false, 'message': 'Network error: $e'};
//     }
//   }

//   static Future<Map<String, dynamic>> verifyPasscode(
//     String token,
//     String passcode,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('https://api-merchant.sandbox.gzb.app/api/v2/user/passcode/verify'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//         },
//         body: {'passcode': passcode},
//       );

//       // ✅ Add debug logging
//       print('🔐 VERIFY PASSCODE API RESPONSE:');
//       print('Status: ${response.statusCode}');
//       print('Body: ${response.body}');

//       return json.decode(response.body);
//     } catch (e) {
//       print('❌ VERIFY PASSCODE ERROR: $e');
//       return {'success': false, 'message': 'Network error: $e'};
//     }
//   }

//   static Future<Map<String, dynamic>> scanQrCode(
//     String code,
//     String token,
//   ) async {
//     try {
//       final response = await http.post(
//         Uri.parse('https://api-merchant.sandbox.gzb.app/api/v2/redeem/scan'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//           'Content-Type': 'application/x-www-form-urlencoded',
//         },
//         body: {'code': code},
//       );

//       return json.decode(response.body);
//     } catch (e) {
//       return {'success': false, 'message': 'Network error'};
//     }
//   }
// }

// //Correct with 187 line code changes

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
    required String deviceUuid, // Add device_uuid parameter
    required String fcmToken, // Add fcm_token parameter
  }) async {
    // try {
    final url = Uri.parse(
      'https://api-merchant.sandbox.gzb.app/api/v2/auth/signup',
    );

    // Debug the request data
    print('🔐 SIGNUP REQUEST DATA:');
    print('Name: $name');
    print('Phone: $phone');
    print('OTP: $otp');
    print('Province: $provinceId');
    print('District: $district');
    print('Commune: $commune');
    print('Village: $village');
    print('Device UUID: $deviceUuid'); // Add debug for device UUID
    print('FCM Token: $fcmToken'); // Add debug for FCM token

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'X-App-Package': appPackage, // Add X-App-Package header
      },
      body: {
        'name': name,
        'phone': phone,
        'otp': otp,
        'province': provinceId,
        'district': district,
        'commune': commune,
        'village': village,
        'device_uuid': deviceUuid, // Add device_uuid to request body
        'fcm_token': fcmToken, // Add fcm_token to request body
      },
    );

    print('🔐 SIGNUP API RESPONSE:');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    return json.decode(response.body);
    // } catch (e) {
    //   print('❌ SIGNUP ERROR: $e');
    //   return {'success': false, 'message': 'Network error: $e'};
    // }
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

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.headers['X-App-Package'] = appPackage;

      // Add form fields
      request.fields['upload_type'] = uploadType;

      // Add front image
      request.files.add(
        await http.MultipartFile.fromPath(
          'national_id_front',
          nationalIdFront.path,
          filename: 'front_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Add back image
      request.files.add(
        await http.MultipartFile.fromPath(
          'national_id_back',
          nationalIdBack.path,
          filename: 'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📸 UPLOAD RESPONSE: ${response.statusCode}');
      print('📸 UPLOAD BODY: $responseBody');

      return json.decode(responseBody);
    } catch (e) {
      print('❌ UPLOAD ERROR: $e');
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

  // static Future<Map<String, dynamic>> requestOtpV2(String phone) async {
  //   final url = Uri.parse('$baseUrl/auth/request-otp');
  //   final response = await http.post(
  //     url,
  //     headers: {
  //       'Accept': 'application/json',
  //       'X-App-Package': appPackage, // Add X-App-Package header
  //     },
  //     body: {'phone': phone},
  //   );
  //   return json.decode(response.body);
  // }

  static Future<Map<String, dynamic>> verifyOtpV2(
    String phone,
    String otp,
    String deviceUuid, // Add device_uuid parameter
    String fcmToken, // Add fcm_token parameter
  ) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'X-App-Package': appPackage, // Add X-App-Package header
      },
      body: {
        'phone': phone,
        'otp': otp,
        'device_uuid': deviceUuid,
        'fcm_token': fcmToken,
      },
    );
    // Debug the request
    print('🔐 SIGNIN REQUEST DATA:');
    print('Phone: $phone');
    print('OTP: $otp');
    print('Device UUID: $deviceUuid');
    print('FCM Token: $fcmToken');
    print('🔐 SIGNIN API RESPONSE:');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

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
          'X-App-Package': appPackage, // Add X-App-Package header
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['data'] != null) {
          print('🔐 USER PROFILE FIELDS: ${result['data'].keys.toList()}');
          print('🔐 STATUS FIELD: ${result['data']['status']}');
          print('🔐 PASSCODE FIELD: ${result['data']['passcode']}');
          print('🔐 PASSCODE_HASH FIELD: ${result['data']['passcode_hash']}');

          final status = result['data']['status'];
          print('🔐 USER STATUS: $status');

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
          'X-App-Package': appPackage, // Add X-App-Package header
        },
        body: {
          'passcode': passcode,
          'passcode_confirmation': passcodeConfirmation,
        },
      );

      print('🔐 CREATE PASSCODE API RESPONSE:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('❌ CREATE PASSCODE ERROR: $e');
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
          'X-App-Package': appPackage, // Add X-App-Package header
        },
        body: {'passcode': passcode},
      );

      print('🔐 VERIFY PASSCODE API RESPONSE:');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('❌ VERIFY PASSCODE ERROR: $e');
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
          'X-App-Package': appPackage, // Add X-App-Package header
        },
        body: {'code': code},
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}

//Correct with 537 line code changes
