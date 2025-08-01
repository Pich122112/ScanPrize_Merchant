import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './scanqr_prize.dart';

class TransferService {
  static const String baseUrl = 'http://192.168.1.28:8080/api';

  static Future<http.Response> transferPoints({
    required int points,
    required int productCategoryId,
    required String recipientPhone,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    try {
      final response = await http
          .post(
            Uri.parse(
              '${Constants.apiUrl}/transfer/transfer-points-by-category',
            ), // Updated endpoint
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              "x-app-secret": Constants.appSecret,
            },
            body: json.encode({
              "points": points,
              "productCategoryId": productCategoryId,
              "recipientPhone": recipientPhone,
              "userId": userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw TransferException(
          error['message'] ?? 'Transfer failed (${response.statusCode})',
          details: error['error'] ?? error['details'] ?? response.body,
          statusCode: response.statusCode,
        );
      }
      return response;
    } on SocketException {
      throw TransferException('No internet connection');
    } on TimeoutException {
      throw TransferException('Request timed out');
    } on http.ClientException catch (e) {
      throw TransferException('Network error: ${e.message}');
    } catch (e) {
      throw TransferException('Transfer failed: ${e.toString()}');
    }
  }
}

class TransferException implements Exception {
  final String message;
  final dynamic details;
  final int? statusCode;

  TransferException(this.message, {this.details, this.statusCode});

  @override
  String toString() => message;
}

//Correct with 72 line code
