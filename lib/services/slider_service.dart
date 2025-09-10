import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/slider_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://redeemapi-merchant.piikmall.com/api/v1';

  Future<List<SliderModel>> getSliders({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // Try to load from cache if not force refresh
    if (!forceRefresh && prefs.containsKey('slider_cache')) {
      final cached = prefs.getString('slider_cache');
      if (cached != null) {
        final Map<String, dynamic> responseData = json.decode(cached);
        final List<dynamic> data = responseData['data'];
        return data.map((json) => SliderModel.fromJson(json)).toList();
      }
    }

    // If not cached or force refresh, fetch from network
    final response = await http.get(Uri.parse('$baseUrl/sliders'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        final List<dynamic> data = responseData['data'];

        // Save to cache
        prefs.setString('slider_cache', response.body);

        return data.map((json) => SliderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sliders: ${responseData['message']}');
      }
    } else {
      throw Exception(
        'Failed to load sliders. Status code: ${response.statusCode}',
      );
    }
  }
}

//Correct with 46 line code changes
