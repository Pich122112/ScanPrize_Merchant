// user_balance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './scanqr_prize.dart';

class UserBalanceService {
  static Future<Map<String, dynamic>> fetchUserBalances() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('userId') ?? '';
    final userId = int.tryParse(userIdStr) ?? 0;

    if (userId == 0) {
      return {'ganzberg': 0, 'idol': 0, 'boostrong': 0, 'money': 0.0};
    }

    try {
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/user-balances/$userId'),
        headers: {"x-app-secret": Constants.appSecret},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch balances: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch balances: ${e.toString()}');
    }
  }

  // Specific method to fetch points by brand
  static Future<int> fetchPointsByBrand(String brand) async {
    final balances = await fetchUserBalances();
    return (balances[brand.toLowerCase()] ?? 0).toInt();
  }

  // Specific methods for each brand
  static Future<int> fetchGanzbergPoints() => fetchPointsByBrand('ganzberg');
  static Future<int> fetchIdolPoints() => fetchPointsByBrand('idol');
  static Future<int> fetchBoostrongPoints() => fetchPointsByBrand('boostrong');
  static Future<double> fetchMoneyBalance() async {
    final balances = await fetchUserBalances();
    return (balances['money'] ?? 0).toDouble();
  }
}

//Correct with 49 line code changes
