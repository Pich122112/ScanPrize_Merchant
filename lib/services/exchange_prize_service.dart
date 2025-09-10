// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import '../models/exchange_prize_model.dart';
// import '../models/user_transfer.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ExchangePrizeService {
//   static const String prizeListUrl =
//       'https://redeemapi-merchant.piikmall.com/api/v2/redeem/prizes';
//   static const String cacheKey = 'exchange_prize_cache_v2';

//   Future<String?> getToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');
//       print("🔐 Retrieved token from storage: $token");
//       return token;
//     } catch (e) {
//       print("❌ Error getting token: $e");
//       return null;
//     }
//   }

//   Future<UserModel?> fetchUserById(String userId) async {
//     try {
//       final token = await getToken();
//       if (token == null) throw Exception('No token available');

//       final response = await http.get(
//         Uri.parse('https://redeemapi-merchant.piikmall.com/api/v2/transfer'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       print("🔍 User Info Response: ${response.statusCode} - ${response.body}");

//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         return UserModel.fromJson(jsonData);
//       } else {
//         print("❌ Error fetching user: ${response.statusCode}");
//         return null;
//       }
//     } catch (e) {
//       print("🔥 Exception in fetchUserById: $e");
//       return null;
//     }
//   }

//   Future<List<ExchangePrize>> fetchExchangePrizes({
//     bool forceRefresh = false,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = await getToken();

//     if (token == null) {
//       throw Exception('Authentication required');
//     }

//     try {
//       // ✅ 1. Try cache first (unless force refresh)
//       if (!forceRefresh && prefs.containsKey(cacheKey)) {
//         final cached = prefs.getString(cacheKey);
//         if (cached != null) {
//           final Map<String, dynamic> jsonData = json.decode(cached);
//           return (jsonData['data']['prizes'] as List)
//               .map((item) => ExchangePrize.fromJson(item))
//               .toList();
//         }
//       }

//       // ✅ 2. Fetch from API with authentication
//       final response = await http.get(
//         Uri.parse(prizeListUrl),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       print('📡 Prize List API status: ${response.statusCode}');
//       print('📡 Prize List API response: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonData = json.decode(response.body);

//         if (jsonData['success'] == true) {
//           // Save response to cache
//           prefs.setString(cacheKey, response.body);

//           return (jsonData['data']['prizes'] as List)
//               .map((item) => ExchangePrize.fromJson(item))
//               .toList();
//         } else {
//           throw HttpException("API returned error: ${jsonData['message']}");
//         }
//       } else {
//         throw HttpException("Failed to load prizes: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("⚠️ Error fetching prizes: $e");

//       // ✅ 3. Fallback to cache if available
//       final cached = prefs.getString(cacheKey);
//       if (cached != null) {
//         print("📦 Loaded prizes from cache (offline mode)");
//         final Map<String, dynamic> jsonData = json.decode(cached);
//         return (jsonData['data']['prizes'] as List)
//             .map((item) => ExchangePrize.fromJson(item))
//             .toList();
//       }

//       // No cache available
//       rethrow;
//     }
//   }
// }

// //Correct with 124 line code change

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/exchange_prize_model.dart';
import '../models/user_transfer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExchangePrizeService {
  static const String prizeListUrl =
      'https://redeemapi-merchant.piikmall.com/api/v2/redeem/prizes';
  static const String cacheKey = 'exchange_prize_cache_v2';

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print("🔐 Retrieved token from storage: $token");
      return token;
    } catch (e) {
      print("❌ Error getting token: $e");
      return null;
    }
  }

  Future<UserModel?> fetchUserById(String userId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('No token available');

      final response = await http.get(
        Uri.parse('https://redeemapi-merchant.piikmall.com/api/v2/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("🔍 User Info Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserModel.fromJson(jsonData);
      } else {
        print("❌ Error fetching user: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🔥 Exception in fetchUserById: $e");
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
        },
      );

      print('📡 Prize List API status: ${response.statusCode}');
      print('📡 Prize List API response: ${response.body}');

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
      print("⚠️ Error fetching prizes: $e");

      // ✅ 3. Fallback to cache if available
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        print("📦 Loaded prizes from cache (offline mode)");
        final Map<String, dynamic> jsonData = json.decode(cached);
        return (jsonData['data']['prizes'] as List)
            .map((item) => ExchangePrize.fromJson(item))
            .toList();
      }

      // No cache available
      rethrow;
    }
  }

  // Add this method to clear cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    print("🗑️ Cleared prize cache");
  }
}

//Correct with 256 line code changes
