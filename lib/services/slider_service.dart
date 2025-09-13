import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/slider_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api-merchant.sandbox.gzb.app/api/v2';
  static const String _cacheKey = 'slider_cache';
  static const String _cacheTimestampKey = 'slider_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1); // Cache for 1 hour
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';

  Future<List<SliderModel>> getSliders({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we should use cache (not forcing refresh and cache is valid)
    if (!forceRefresh && await _shouldUseCache()) {
      try {
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          final Map<String, dynamic> responseData = json.decode(cached);
          final List<dynamic> data = responseData['data'];
          print('Using cached slider data');
          return data.map((json) => SliderModel.fromJson(json)).toList();
        }
      } catch (e) {
        print('Error parsing cached data: $e');
        // Continue to fetch from API if cache is corrupted
      }
    }

    try {
      print('Fetching sliders from API: $baseUrl/slider');
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/slider'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-App-Package': appPackage,
        },
      );

      print('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          print('Number of sliders fetched: ${data.length}');

          // Save to cache with timestamp
          await prefs.setString(_cacheKey, response.body);
          await prefs.setInt(
            _cacheTimestampKey,
            DateTime.now().millisecondsSinceEpoch,
          );

          return data.map((json) => SliderModel.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load sliders: ${responseData['message']}');
        }
      } else {
        throw Exception(
          'Failed to load sliders. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('API call error: $e');

      // If we have cached data and API fails, return cached data
      if (prefs.containsKey(_cacheKey)) {
        print('API failed, falling back to cached data');
        try {
          final cached = prefs.getString(_cacheKey);
          final Map<String, dynamic> responseData = json.decode(cached!);
          final List<dynamic> data = responseData['data'];
          return data.map((json) => SliderModel.fromJson(json)).toList();
        } catch (e) {
          print('Error using fallback cache: $e');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<bool> _shouldUseCache() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_cacheTimestampKey)) {
      return false;
    }

    final lastCacheTime = prefs.getInt(_cacheTimestampKey);
    if (lastCacheTime == null) {
      return false;
    }

    final cacheAge = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastCacheTime),
    );
    return cacheAge < _cacheDuration;
  }

  // Method to force clear cache (optional)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}

//Correct with 115 line code changes
