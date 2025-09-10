import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

Future<void> uploadFcmToken(
  String userId,
  String token,
  String apiToken,
) async {
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  final url = Uri.parse(
    'https://redeemapi.piikmall.com/api/v2/user/update-fcm-token',
  );
  await http.post(
    url,
    headers: {
      "Authorization": "Bearer $apiToken",
      "Accept": "application/json",
    },
    body: {"user_id": userId, "fcm_token": fcmToken},
  );
}

//Correct with 23 line code changes
