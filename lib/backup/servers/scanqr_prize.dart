import 'package:http/http.dart' as http;
import 'dart:convert';

class Constants {
  static const String apiUrl = "http://172.17.5.5:8080/api";
  static const String appSecret = "MySuperSecretKey123!@*";
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
