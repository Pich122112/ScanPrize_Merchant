import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

class SecretKeyApiService {
  static const String _baseUrl = 'https://api-merchant.sandbox.gzb.app/api/v2';
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';
  final SecureStorageService _storage = SecureStorageService();

  Future<Map<String, dynamic>> fetchSecretKey() async {
    try {
      final accessToken = await _storage.getToken();

      if (accessToken == null) {
        return {'success': false, 'message': 'No access token found'};
      }

      final url = Uri.parse('$_baseUrl/redeem/secret-key');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
              'X-App-Package': appPackage,
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (kDebugMode) {
          print('📦 Secret Key API Response: $data');
        }

        final String? secretKey =
            data['secret_key'] ?? data['key'] ?? data['data'];

        if (secretKey != null && secretKey.isNotEmpty) {
          await _storage.setSecretKey(secretKey);

          if (kDebugMode) {
            print(
              '✅ Secret key stored successfully (length: ${secretKey.length})',
            );
          }

          return {
            'success': true,
            'message': 'Secret key fetched and stored successfully',
            'secret_key': secretKey,
          };
        } else {
          if (kDebugMode) {
            print(
              '❌ No secret key found in response. Available keys: ${data.keys}',
            );
          }
          return {
            'success': false,
            'message': 'Secret key not found in response',
          };
        }
      } else {
        if (kDebugMode) {
          print('❌ API Error: ${response.statusCode} - ${response.body}');
        }
        return {
          'success': false,
          'message': 'Failed to fetch secret key: ${response.statusCode}',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching secret key: $e');
      }
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Convenience method that returns just the key (for backward compatibility)
  Future<String?> fetchAndStoreSecretKey() async {
    final result = await fetchSecretKey();
    if (result['success'] == true) {
      return result['secret_key'] as String?;
    }
    return null;
  }
}

// Correct with 94 line code changes
