// services/transfer_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransferService {
  //=========Transfer with confirm dialog============
  // static Future<http.Response> transferPoints({
  //   required int points,
  //   required String walletId,
  //   required String receiverPhone,
  //   String? signature,
  //   required String prizeId,
  //   required int prizePoint,
  //   required int qty,
  // }) async {
  //   try {
  //     // Get token from shared preferences
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token');

  //     if (token == null) {
  //       throw TransferException('Authentication required. Please login again.');
  //     }

  //     // ✅ Use the correct API format
  //     final url = Uri.parse('https://redeemapi-merchant.piikmall.com/api/v2/transfer');

  //     // ✅ UPDATED request body format - include new fields
  //     final requestBody = {
  //       'reciever_phone': receiverPhone,
  //       'wallet_id': walletId,
  //       'amount': points.toString(),
  //       'prize_id': prizeId,
  //       'prize_point': prizePoint.toString(),
  //       'qty': qty.toString(),
  //     };

  //     // ✅ COMPREHENSIVE DEBUG PRINT
  //     // print('🔄 ======= TRANSFER REQUEST DETAILS =======');
  //     // print('🔄 Receiver Phone: $receiverPhone');
  //     // print('🔄 Wallet ID: $walletId');
  //     // print('🔄 Points Amount: $points');
  //     // print('🔄 Prize ID: $prizeId (type: ${prizeId.runtimeType})');
  //     // print('🔄 Prize Point: $prizePoint (type: ${prizePoint.runtimeType})');
  //     // print('🔄 Quantity: $qty (type: ${qty.runtimeType})');
  //     // print('🔄 Signature: $signature');
  //     // print('🔄 Full Request Body: $requestBody');
  //     // print('🔄 ========================================');

  //     final response = await http
  //         .post(
  //           url,
  //           headers: {
  //             "Content-Type": "application/x-www-form-urlencoded",
  //             "Authorization": "Bearer $token",
  //             "Accept": "application/json",
  //           },
  //           body: requestBody,
  //         )
  //         .timeout(const Duration(seconds: 30));

  //     // print('📨 ======= TRANSFER RESPONSE =======');
  //     // print('📨 Status Code: ${response.statusCode}');
  //     // print('📨 Response Body: ${response.body}');
  //     // print('📨 ================================');

  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);

  //       if (responseData['success'] == true) {
  //         return response;
  //       } else {
  //         throw TransferException(
  //           responseData['message'] ?? 'Transfer failed',
  //           details: responseData['error'] ?? response.body,
  //           statusCode: response.statusCode,
  //         );
  //       }
  //     } else {
  //       final error = json.decode(response.body);
  //       throw TransferException(
  //         error['message'] ?? 'Transfer failed (${response.statusCode})',
  //         details: error['error'] ?? error['details'] ?? response.body,
  //         statusCode: response.statusCode,
  //       );
  //     }
  //   } on SocketException {
  //     throw TransferException('No internet connection');
  //   } on TimeoutException {
  //     throw TransferException('Request timed out');
  //   } on http.ClientException catch (e) {
  //     throw TransferException('Network error: ${e.message}');
  //   } catch (e) {
  //     throw TransferException('Transfer failed: ${e.toString()}');
  //   }
  // }

  //Transfer without confirm dialog
  // services/transfer_service.dart
  // Update the transferPoints method to handle wallet transfers without prize_id
  static Future<http.Response> transferPoints({
    required int points,
    required String walletId,
    required String receiverId,
    required String receiverPhone,
    String? signature,
    String? prizeId, // ✅ Make prize_id optional
    int? prizePoint, // ✅ Make prize_point optional
    int? qty, // ✅ Make qty optional
  }) async {
    try {
      // Get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw TransferException('Authentication required. Please login again.');
      }

      final url = Uri.parse(
        'https://redeemapi-merchant.piikmall.com/api/v2/transfer',
      );

      // ✅ UPDATED: Only include prize-related fields if they're provided
      final requestBody = {
        'reciever_id': receiverId,
        'reciever_phone': receiverPhone,
        'wallet_id': walletId,
        'amount': points.toString(),
      };

      // ✅ Add optional fields only if they have values
      if (prizeId != null && prizeId.isNotEmpty && prizeId != '0') {
        requestBody['prize_id'] = prizeId;
      }

      if (prizePoint != null && prizePoint > 0) {
        requestBody['prize_point'] = prizePoint.toString();
      }

      if (qty != null && qty > 0) {
        requestBody['qty'] = qty.toString();
      }

      print('🔄 ======= TRANSFER REQUEST DETAILS =======');
      print('🔄 Receiver ID: $receiverId');
      print('🔄 Receiver Phone: $receiverPhone');
      print('🔄 Wallet ID: $walletId');
      print('🔄 Points Amount: $points');
      print('🔄 Prize ID: $prizeId');
      print('🔄 Prize Point: $prizePoint');
      print('🔄 Quantity: $qty');
      print('🔄 Full Request Body: $requestBody');
      print('🔄 ========================================');

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              "Authorization": "Bearer $token",
              "Accept": "application/json",
              "X-App-Package": "com.ganzberg.scanprizemerchantapp",
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      print('📨 ======= TRANSFER RESPONSE =======');
      print('📨 Status Code: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');
      print('📨 ================================');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return response;
        } else {
          throw TransferException(
            responseData['message'] ?? 'Transfer failed',
            details: responseData['error'] ?? response.body,
            statusCode: response.statusCode,
          );
        }
      } else {
        final error = json.decode(response.body);
        throw TransferException(
          error['message'] ?? 'Transfer failed (${response.statusCode})',
          details: error['error'] ?? error['details'] ?? response.body,
          statusCode: response.statusCode,
        );
      }
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

  static Future<Map<String, dynamic>?> verifyReceiver(
    String phoneNumber,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication required');
      }

      // Clean phone number (remove spaces, ensure proper format)
      String cleanPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

      // ✅ CRITICAL: Validate phone number before API call
      if (cleanPhone == 'Unknown' || cleanPhone.isEmpty) {
        throw Exception('Invalid phone number: $cleanPhone');
      }

      // If it's in local format (0XXX), convert to international (855XXX)
      if (cleanPhone.startsWith('0') && cleanPhone.length == 9) {
        cleanPhone = '855${cleanPhone.substring(1)}';
      }

      // ✅ UPDATED: Validate it's a proper Cambodian phone number (11 or 12 digits)
      if (!cleanPhone.startsWith('855') ||
          (cleanPhone.length != 11 && cleanPhone.length != 12)) {
        throw Exception('Invalid Cambodian phone format: $cleanPhone');
      }

      final url = Uri.parse(
        'https://redeemapi-merchant.piikmall.com/api/v2/transfer/receiver-check?phone_number=$cleanPhone',
      );

      print('🔍 Verify receiver - URL: $url');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "X-App-Package": "com.ganzberg.scanprizemerchantapp",
        },
      );

      print('✅ Verify receiver response - Status: ${response.statusCode}');
      print('✅ Verify receiver response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(
            responseData['message'] ?? 'Receiver verification failed',
          );
        }
      } else if (response.statusCode == 422) {
        // Handle the case where no user is found
        final responseData = json.decode(response.body);
        throw Exception(
          responseData['message'] ?? 'No user found with this phone number',
        );
      } else {
        throw Exception('Failed to verify receiver: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Receiver verification failed: $e');
      rethrow;
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

//Correct with 294 line code changes
