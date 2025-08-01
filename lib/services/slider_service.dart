import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/slider_model.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.28:8080/api'; // Change this to your server IP

  Future<List<SliderModel>> getSliders() async {
    final response = await http.get(Uri.parse('$baseUrl/sliders'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SliderModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sliders');
    }
  }
} // services/api_service.dart

//Correct with 21 line code changes
