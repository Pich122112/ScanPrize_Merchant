import 'package:http/http.dart' as http;
import 'dart:convert';

class Constants {
  static const String apiUrl = "http://192.168.1.28:8080/api";
  static const String appSecret = "MySuperSecretKey123!@*";
  static const String wsUrl = '192.168.1.28:8081'; // WebSocket server
}

Future<Map<String, dynamic>> fetchPrizeByCode(
  String code,
  String userId,
) async {
  final url = "${Constants.apiUrl}/scan";
  print('userId used for scan: $userId');
  final response = await http.post(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "x-app-secret": Constants.appSecret,
    },
    body: json.encode({"code": code, "userId": userId}),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    String? message;
    try {
      final body = json.decode(response.body);
      message = body['error'] ?? body['message'];
    } catch (_) {
      message = null;
    }
    return {"success": false, "error": message ?? "Invalid or used code"};
  }
}

//Correct with 37 line code changes
