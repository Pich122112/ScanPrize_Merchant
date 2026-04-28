import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/exchange_prize_model.dart';
import '../models/user_transfer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class ExchangePrizeService {
  static const String prizeListUrl =
      'https://api-merchant.sandbox.gzb.app/api/v2/redeem/prizes';
  static const String cacheKey = 'exchange_prize_cache_v2';
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';

  final SecureStorageService _secureStorage = SecureStorageService();

  Future<String?> getToken() async {
    try {
      // ✅ Use secure storage instead of SharedPreferences
      final token = await _secureStorage.getToken();
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting token");
      }
      return null;
    }
  }

  Future<UserModel?> fetchUserById(String userId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('https://api-merchant.sandbox.gzb.app/api/v2/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-App-Package': appPackage,
        },
      );

      if (kDebugMode) {
        print("🔍 User Info Response Status: ${response.statusCode}");
      }
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserModel.fromJson(jsonData);
      } else {
        if (kDebugMode) {
          print("❌ Error fetching user: ${response.statusCode}");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("🔥 Exception in fetchUserById: $e");
      }
      return null;
    }
  }

  Future<List<ExchangePrize>> fetchExchangePrizes({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getToken();

    if (token == null) {
      throw Exception('Authentication required');
    }

    try {
      // ✅ 1. Try cache first (unless force refresh)
      if (!forceRefresh && prefs.containsKey(cacheKey)) {
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final Map<String, dynamic> jsonData = json.decode(cached);
          return (jsonData['data']['prizes'] as List)
              .map((item) => ExchangePrize.fromJson(item))
              .toList();
        }
      }

      // ✅ 2. Fetch from API with authentication
      final response = await http.get(
        Uri.parse(prizeListUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-App-Package': appPackage,
        },
      );

      if (kDebugMode) {
        print('📡 Prize List API status: ${response.statusCode}');
      }
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          // Save response to cache
          prefs.setString(cacheKey, response.body);

          return (jsonData['data']['prizes'] as List)
              .map((item) => ExchangePrize.fromJson(item))
              .toList();
        } else {
          throw HttpException("API returned error: ${jsonData['message']}");
        }
      } else {
        throw HttpException("Failed to load prizes: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Error fetching prizes");
      }
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        if (kDebugMode) {
          print("📦 Loaded prizes from cache (offline mode)");
        }
        final Map<String, dynamic> jsonData = json.decode(cached);
        return (jsonData['data']['prizes'] as List)
            .map((item) => ExchangePrize.fromJson(item))
            .toList();
      }

      // No cache available
      rethrow;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    if (kDebugMode) {
      print("🗑️ Cleared prize cache");
    }
  }
}

// Correct with 147 line code changes
