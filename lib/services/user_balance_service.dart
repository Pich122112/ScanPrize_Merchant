// user_balance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/balance_refresh_notifier.dart';

class UserBalanceService {
  static const _balanceCacheKey = 'wallet_balances';
  static const String appPackage = 'com.ganzberg.scanprizemerchantapp';

  // Get balance from cache (fast, local)
  static Future<Map<String, dynamic>> getBalancesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_balanceCacheKey);
    if (cached != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(cached));
      } catch (_) {}
    }
    // Fallback if cache is empty or corrupt
    return {'ganzberg': 0, 'idol': 0, 'boostrong': 0, 'diamond': 0.0};
  }

  // Add this method for refreshing after transactions
  static Future<void> refreshBalancesAfterTransaction({
    bool isSender = true,
    String? receiverPhone, // Optional: for future push notifications
  }) async {
    try {
      print('DEBUG: Refreshing balances after transaction...');

      // Force fetch fresh balances from API and update cache
      final freshBalances = await fetchUserBalances(updateCache: true);

      // Notify all listeners about the balance update
      BalanceRefreshNotifier().refreshBalances();

      print('DEBUG: Balances refreshed: $freshBalances');

      // If this is a receiver device, we could implement push notifications here
      // For now, we rely on manual refresh or app restart for receivers
    } catch (e) {
      print('Error refreshing balances after transaction: $e');
    }
  }

  // Save balance to cache
  static Future<void> setBalancesToCache(Map<String, dynamic> balances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_balanceCacheKey, jsonEncode(balances));
    await prefs.setInt(
      'balance_last_updated',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // user_balance_service.dart - update the fetchUserBalances method
  // Fetch from API, update cache and return
  static Future<Map<String, dynamic>> fetchUserBalances({
    bool updateCache = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return {'ganzberg': 0, 'idol': 0, 'boostrong': 0, 'diamond': 0.0};
    }

    try {
      final url = Uri.parse(
        'https://api-merchant.sandbox.gzb.app/api/v2/user/profile',
      );
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "X-App-Package": appPackage,
        },
      );

      print(
        'DEBUG: Wallet API status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balances = parseWalletsFromUserDetail(data);
        if (updateCache) {
          await setBalancesToCache(balances);
        }
        return balances;
      } else {
        throw Exception('Failed to fetch balances: ${response.statusCode}');
      }
    } catch (e) {
      print('Balance fetch error: $e');
      throw Exception('Failed to fetch balances: ${e.toString()}');
    }
  }

  // user_balance_service.dart - update the _parseWalletsFromUserDetail method
  static Map<String, dynamic> parseWalletsFromUserDetail(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> balances = {
      'ganzberg': 0,
      'idol': 0,
      'boostrong': 0,
      'diamond': 0.0,
    };

    if (data['success'] == true && data['data'] != null) {
      final userData = data['data'];
      if (userData['wallets'] != null && userData['wallets'] is List) {
        final wallets = userData['wallets'] as List<dynamic>;
        for (final wallet in wallets) {
          final walletName = (wallet['wallet_name'] ?? '').toString();
          final balance = wallet['balance'] ?? 0;
          switch (walletName) {
            case 'GB':
              balances['ganzberg'] = balance;
              break;
            case 'BS':
              balances['boostrong'] = balance;
              break;
            case 'ID':
              balances['idol'] = balance;
              break;
            case 'DM':
              balances['diamond'] = balance.toDouble();
              break;
          }
          print('DEBUG: Processing wallet $walletName = $balance');
        }
      }
      if (balances['ganzberg'] == 0)
        balances['ganzberg'] = (userData['wallet_balance_1'] ?? 0).toInt();
      if (balances['boostrong'] == 0)
        balances['boostrong'] = (userData['wallet_balance_2'] ?? 0).toInt();
      if (balances['idol'] == 0)
        balances['idol'] = (userData['wallet_balance_3'] ?? 0).toInt();
      if (balances['diamond'] == 0)
        balances['diamond'] = (userData['wallet_balance_4'] ?? 0).toDouble();
    }
    print('DEBUG: Final parsed balances - $balances');
    return balances;
  }

  // Use this method for first-time load or when app restarts
  // Use this method for first-time load or when app restarts
  static Future<Map<String, dynamic>> getCachedOrFetchBalances() async {
    final cached = await getBalancesFromCache();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastUpdated = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getInt('balance_last_updated') ?? 0,
    );

    // If cache is stale (older than 5 minutes) or empty, fetch fresh data
    if (now - lastUpdated > 5 * 60 * 1000 ||
        (cached['ganzberg'] ?? 0) == 0 &&
            (cached['idol'] ?? 0) == 0 &&
            (cached['boostrong'] ?? 0) == 0 &&
            (cached['diamond'] ?? 0.0) == 0.0) {
      try {
        return await fetchUserBalances();
      } catch (_) {
        // If API fails, return cached data even if stale
        return cached;
      }
    }

    return cached;
  }

  // Add this method to UserBalanceService for debugging
  static Future<void> debugBalanceFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    print('DEBUG: Token available: ${token.isNotEmpty}');

    if (token.isEmpty) return;

    try {
      final url = Uri.parse(
        'https://api-merchant.sandbox.gzb.app/api/v2/user/profile',
      );
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "X-App-Package": appPackage,
        },
      );

      print('DEBUG: Raw API response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: API success: ${data['success']}');
        print('DEBUG: Data field exists: ${data['data'] != null}');

        if (data['data'] != null && data['data']['wallets'] != null) {
          print('DEBUG: Wallets array: ${data['data']['wallets']}');
        }
      }
    } catch (e) {
      print('DEBUG: Error in debugBalanceFetch: $e');
    }
  }

  // Specific method to fetch points by brand
  static Future<int> fetchPointsByBrand(String brand) async {
    final balances = await fetchUserBalances();
    return (balances[brand.toLowerCase()] ?? 0).toInt();
  }

  // Specific methods for each brand
  static Future<int> fetchGanzbergPoints() => fetchPointsByBrand('ganzberg');
  static Future<int> fetchIdolPoints() => fetchPointsByBrand('idol');
  static Future<int> fetchBoostrongPoints() => fetchPointsByBrand('boostrong');
  static Future<double> fetchDiamondBalance() async {
    final balances = await fetchUserBalances();
    return (balances['diamond'] ?? 0).toDouble();
  }
}

//Correct with 232 line code changes
