// exchange_prize_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exchange_prize_model.dart';
import '../models/user_transfer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExchangePrizeService {
  static const String baseUrl =
      'http://192.168.1.28:8080/api/exchange-prize-list';

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

      if (token == null || token.isEmpty) {
        print("⚠️ No token available");
        return null;
      }

      print("🔑 Using token: $token");

      final response = await http.get(
        Uri.parse('http://192.168.1.28:8080/api/transfer/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization':
              'Bearer $token', // Ensure this matches backend expectation
        },
      );

      print("🔁 GET /api/transfer/$userId - Status: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        print("❌ Error response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("🔥 Exception in fetchUserById: $e");
      return null;
    }
  }

  Future<List<ExchangePrize>> fetchExchangePrizes() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => ExchangePrize.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to load exchange prizes. Status: ${response.statusCode}. Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error in fetchExchangePrizes: $e');
      throw Exception('Failed to load exchange prizes: $e');
    }
  }
}

//Correct with 88 line code changes
