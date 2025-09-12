// user_transaction_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserTransactionService {
  static const String baseUrl = 'https://redeemapi.piikmall.com/api/v2';
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';

  static Future<List<Map<String, dynamic>>> fetchAllUserTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('user_token') ??
          prefs.getString('access_token');

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Fetch ALL transactions
      final response = await http.get(
        Uri.parse('$baseUrl/user/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-App-Package': appPackage,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> allTransactions = responseData['data'];

          // Filter to only include transfer transactions
          final List<Map<String, dynamic>> transferTransactions = [];

          for (var transaction in allTransactions) {
            final String transactionType =
                transaction['transaction_type'] ?? '';

            // Only include transfer transactions for notifications
            if (transactionType == 'transfer_in' ||
                transactionType == 'transfer_out') {
              final dynamic qtyValue = transaction['qty'];
              final int? parsedQty; // Change to nullable int

              if (qtyValue == null) {
                parsedQty = null; // Keep it as null instead of defaulting to 1
                print('DEBUG: Qty is null, preserving null');
              } else if (qtyValue is int) {
                parsedQty = qtyValue;
                print('DEBUG: Qty is int: $parsedQty');
              } else if (qtyValue is String) {
                // Handle empty string case
                if (qtyValue.isEmpty) {
                  parsedQty = null; // Also set to null for empty strings
                  print('DEBUG: Qty is empty string, setting to null');
                } else {
                  parsedQty = int.tryParse(qtyValue);
                  print('DEBUG: Qty is String "$qtyValue", parsed: $parsedQty');
                }
              } else {
                parsedQty = null;
                print(
                  'DEBUG: Qty is unknown type ${qtyValue.runtimeType}, setting to null',
                );
              }

              final Map<String, dynamic> formattedTransaction = {
                'id': transaction['id'],
                'Amount': transaction['amount'],
                'is_credit': transaction['is_credit'],
                'created_at': transaction['created_at'],
                'Type': _mapTransactionType(transactionType),
                'FromUserName': transaction['from_user_name'] ?? 'N/A',
                'FromPhoneNumber': transaction['from_user_phone_number'] ?? '',
                'ToUserName': transaction['to_user_name'] ?? 'N/A',
                'ToPhoneNumber': transaction['to_user_phone_number'] ?? '',
                'transaction_type': transactionType,
                'qty':
                    parsedQty, // This will now be null when backend returns null
                'wallet_type': transaction['wallet_type'] ?? '',
              };

              transferTransactions.add(formattedTransaction);
            }
          }

          // Sort by date (newest first)
          transferTransactions.sort((a, b) {
            final dateA = DateTime.parse(a['created_at']);
            final dateB = DateTime.parse(b['created_at']);
            return dateB.compareTo(dateA);
          });

          return transferTransactions;
        } else {
          throw Exception(
            'Failed to fetch transactions: ${responseData['message']}',
          );
        }
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all transactions: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserTransactions(
    String walletCode,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString('auth_token') ??
          prefs.getString('token') ??
          prefs.getString('user_token') ??
          prefs.getString('access_token');

      print('DEBUG: Token found: ${token != null ? "Yes" : "No"}');
      if (token == null) {
        final keys = prefs.getKeys();
        print('DEBUG: Available keys in SharedPreferences: $keys');
        keys.forEach((key) {
          final value = prefs.get(key);
          print('DEBUG: $key = $value');
        });
        throw Exception('No authentication token found. Please login again.');
      }

      // Fetch ALL transactions first
      final response = await http.get(
        Uri.parse('$baseUrl/user/transactions'), // Remove wallet_id parameter
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'X-App-Package': appPackage,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('DEBUG: API Response: ${response.body}'); // Print full response

        if (responseData['success'] == true) {
          final List<dynamic> allTransactions = responseData['data'];
          print('DEBUG: Found ${allTransactions.length} total transactions');

          // Filter transactions by wallet_type
          final List<dynamic> filteredTransactions =
              allTransactions
                  .where(
                    (transaction) =>
                        transaction['wallet_type'] == walletCode.toUpperCase(),
                  )
                  .toList();

          print(
            'DEBUG: Found ${filteredTransactions.length} transactions for $walletCode',
          );

          if (filteredTransactions.isEmpty) {
            return []; // Return empty list if no transactions for this wallet
          }

          // Group filtered transactions by date
          final Map<String, List<Map<String, dynamic>>> groupedByDate = {};

          for (var transaction in filteredTransactions) {
            final String createdAt = transaction['created_at'];
            final String date = createdAt.split(' ')[0]; // Extract date part

            if (!groupedByDate.containsKey(date)) {
              groupedByDate[date] = [];
            }

            // DEBUG: Print transaction details including qty
            print('DEBUG: Transaction details:');
            print('DEBUG: - ID: ${transaction['id']}');
            print('DEBUG: - Amount: ${transaction['amount']}');
            print('DEBUG: - Qty: ${transaction['qty']}');
            print('DEBUG: - Qty type: ${transaction['qty']?.runtimeType}');
            print('DEBUG: - Wallet type: ${transaction['wallet_type']}');
            print(
              'DEBUG: - Transaction type: ${transaction['transaction_type']}',
            );
            print('DEBUG: - Created at: $createdAt');
            print('DEBUG: ------------------------------------');

            final dynamic qtyValue = transaction['qty'];
            final int? parsedQty; // Change to nullable int

            if (qtyValue == null) {
              parsedQty = null; // Keep it as null instead of defaulting to 1
              print('DEBUG: Qty is null, preserving null');
            } else if (qtyValue is int) {
              parsedQty = qtyValue;
              print('DEBUG: Qty is int: $parsedQty');
            } else if (qtyValue is String) {
              // Handle empty string case
              if (qtyValue.isEmpty) {
                parsedQty = null; // Also set to null for empty strings
                print('DEBUG: Qty is empty string, setting to null');
              } else {
                parsedQty = int.tryParse(qtyValue);
                print('DEBUG: Qty is String "$qtyValue", parsed: $parsedQty');
              }
            } else {
              parsedQty = null;
              print(
                'DEBUG: Qty is unknown type ${qtyValue.runtimeType}, setting to null',
              );
            }

            final Map<String, dynamic> formattedTransaction = {
              'id': transaction['id'],
              'Amount': transaction['amount'],
              'is_credit': transaction['is_credit'],
              'created_at': createdAt,
              'Type': _mapTransactionType(transaction['transaction_type']),
              'FromUserName': transaction['from_user_name'] ?? 'N/A',
              'FromPhoneNumber': transaction['from_user_phone_number'] ?? '',
              'ToUserName': transaction['to_user_name'] ?? 'N/A',
              'ToPhoneNumber': transaction['to_user_phone_number'] ?? '',
              'transaction_type': transaction['transaction_type'],
              'qty': parsedQty,
            };

            groupedByDate[date]!.add(formattedTransaction);
          }

          // Convert to list format expected by your UI
          final List<Map<String, dynamic>> result = [];
          groupedByDate.forEach((date, transactions) {
            final List<Map<String, dynamic>> allTransactions = [
              ...transactions,
            ];

            allTransactions.sort((a, b) {
              final dateA = DateTime.parse(a['created_at']);
              final dateB = DateTime.parse(b['created_at']);
              return dateB.compareTo(dateA);
            });

            result.add({
              'date': _formatDate(date),
              'transactions': allTransactions,
            });
          });

          result.sort((a, b) {
            final dateA = _parseDateString(a['date']);
            final dateB = _parseDateString(b['date']);
            return dateB.compareTo(dateA);
          });

          return result;
        } else {
          throw Exception(
            'Failed to fetch transactions: ${responseData['message']}',
          );
        }
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      rethrow;
    }
  }

  // Add this helper method to parse date strings in "dd/MM/yyyy" format
  static DateTime _parseDateString(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $dateString, error: $e');
    }

    // Fallback to current date if parsing fails
    return DateTime.now();
  }

  // Helper method to map transaction types
  static String _mapTransactionType(String apiType) {
    switch (apiType) {
      case 'transfer_in':
        return 'Transfer In';
      case 'transfer_out':
        return 'Transfer Out';
      case 'deposit':
        return 'Deposit';
      case 'redeem':
        return 'Redeem';
      default:
        return apiType;
    }
  }

  static String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

//Correct with 323 line code changes
