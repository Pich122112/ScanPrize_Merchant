// Change the return type to Future<List<Map<String, dynamic>>> and decode as a List

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './scanqr_prize.dart';

class UserTransactionService {
  static Future<List<Map<String, dynamic>>> fetchUserTransactions(
    String account,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('userId') ?? '';
    final userId = int.tryParse(userIdStr) ?? 0;

    if (userId == 0) {
      return [];
    }

    final url = '${Constants.apiUrl}/transaction/user/$userId?account=$account';
    final response = await http.get(
      Uri.parse(url),
      headers: {"x-app-secret": Constants.appSecret},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to fetch user transactions: ${response.statusCode}',
      );
    }
  }
}
