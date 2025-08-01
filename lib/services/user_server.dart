import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.28:8080/api'; // Change this to your server IP

  // Get user info by phone number
  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/users?phoneNumber=$phone'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['users'] != null && data['users'].isNotEmpty) {
        return {
          'userId': data['users'][0]['UserID'],
          'fullName': data['users'][0]['UserName'],
          'phoneNumber': data['users'][0]['PhoneNumber'],
        };
      }
    }
    return null;
  }

  // Add this method to ApiService
  Future<Map<String, dynamic>?> signupWithPhone(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phone}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    }
    return null;
  }

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<Map<String, dynamic>> signUp(Users user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }
}

//Correct with 81 line code changes
