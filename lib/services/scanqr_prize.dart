import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Constants {
  static const String apiUrl = "https://redeemapi-merchant.piikmall.com/api/v2";
  static const String appSecret = "MySuperSecretKey123!@*";
  static const String wsUrl = 'scan-app-m1fx.onrender.com:8081';
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';
}

Future<Map<String, dynamic>> fetchPrizeByCode(String code) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) {
    return {
      "success": false,
      "error": "Authentication required. Please login again.",
    };
  }

  final url = "https://redeemapi-merchant.piikmall.com/api/v2/redeem/scan";
  print('Scanning code: $code');

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "X-App-Package": Constants.appPackage,
      },
      body: {"code": code},
    );

    print('Scan API response status: ${response.statusCode}');
    print('Scan API response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        // Success format from new API
        final responseData = data['data'] ?? {};
        return {
          "success": true,
          "issuer": responseData["issuer"] ?? "",
          "amount": responseData["amount"] ?? 0,
          "wallet_id": responseData["wallet_id"] ?? 0,
          "wallet_name": responseData["wallet_name"] ?? "",
          "new_amount": responseData["new_amount"] ?? 0,
          "message": data["message"] ?? "Code redeemed successfully.",
        };
      } else {
        // Check if this is definitely a transfer QR (not a prize QR)
        if (_isDefinitelyTransferQr(code)) {
          return {
            "success": false,
            "isTransferQr": true,
            "error": data["message"] ?? "Invalid code",
          };
        } else {
          // This is a prize QR that failed (already redeemed or invalid)
          return {
            "success": false,
            "error": data["message"] ?? "Invalid or already redeemed code",
          };
        }
      }
    } else {
      String? message;
      try {
        final body = json.decode(response.body);
        message = body['message'] ?? body['error'];
      } catch (_) {
        message = "Server error: ${response.statusCode}";
      }

      // Check if this is definitely a transfer QR
      if (_isDefinitelyTransferQr(code)) {
        return {
          "success": false,
          "isTransferQr": true,
          "error": message ?? "Invalid code",
        };
      } else {
        return {"success": false, "error": message ?? "Invalid or used code"};
      }
    }
  } catch (e) {
    print('Scan API error: $e');

    // Check if this is definitely a transfer QR
    if (_isDefinitelyTransferQr(code)) {
      return {
        "success": false,
        "isTransferQr": true,
        "error": "Network error: ${e.toString()}",
      };
    } else {
      return {"success": false, "error": "Network error: ${e.toString()}"};
    }
  }
}

// Helper function to detect if QR code is DEFINITELY a transfer QR (not prize QR)
bool _isDefinitelyTransferQr(String code) {
  // Check for JSON format transfer QR (exact structure)
  try {
    final jsonData = json.decode(code) as Map<String, dynamic>;
    if (jsonData.containsKey('userId') &&
        jsonData.containsKey('phoneNumber') &&
        jsonData.containsKey('name') &&
        jsonData.containsKey('signature')) {
      return true;
    }
  } catch (e) {
    // Not JSON format
  }

  // Check for specific ABA TLV format with proper structure
  // Format: 59[length][phone]99[length][name][signature][crc]
  if (code.startsWith('59') && code.length >= 4) {
    try {
      final phoneLengthStr = code.substring(2, 4);
      final phoneLength = int.tryParse(phoneLengthStr) ?? 0;

      if (phoneLength > 0 && code.length >= 4 + phoneLength) {
        final remaining = code.substring(4 + phoneLength);

        // Check if remaining part has name tag (99)
        if (remaining.startsWith('99') && remaining.length >= 4) {
          final nameLengthStr = remaining.substring(2, 4);
          final nameLength = int.tryParse(nameLengthStr) ?? 0;

          if (nameLength > 0 && remaining.length >= 4 + nameLength) {
            // Valid transfer QR structure found
            return true;
          }
        }
      }
    } catch (e) {
      // Not valid TLV format
    }
  }

  // Check for your specific transfer format: 59128559620011469912Default Name6304D1F0
  if (code.startsWith('5912') &&
      code.contains('Default Name') &&
      code.length >= 30) {
    return true;
  }

  // Check for very specific patterns that only transfer QR codes would have
  final transferSpecificPatterns = [
    RegExp(r'^59\d{2}855\d{8,9}99'), // TLV format with phone and name tags
    RegExp(r'Default Name'), // Contains "Default Name"
    RegExp(
      r'userId.*phoneNumber.*name.*signature',
      caseSensitive: false,
    ), // JSON keys
  ];

  for (final pattern in transferSpecificPatterns) {
    if (pattern.hasMatch(code)) {
      return true;
    }
  }

  // Prize QR codes typically don't have these patterns
  // They are usually simple codes like "B000194023", "GB123456", etc.
  final prizeQrPatterns = [
    RegExp(r'^[A-Z]{1,2}\d{6,9}$'), // Like B000194023, GB123456
    RegExp(r'^[A-Z]{2,3}\d+$'), // Like BS123, ID4567
  ];

  for (final pattern in prizeQrPatterns) {
    if (pattern.hasMatch(code)) {
      return false; // This is likely a prize QR, not transfer
    }
  }

  return false;
}

//Correct with 186 line code changes
