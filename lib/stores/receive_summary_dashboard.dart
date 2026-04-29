import 'package:flutter/material.dart';
import 'package:gb_merchant/services/user_transaction_service.dart';

class TransactionSummaryService {
  /// Calculate total points and diamonds for today's RECEIVED transactions only
  /// Diamonds are counted based on DIAMOND wallet (amount) or unit indicating diamonds.
  static Future<Map<String, int>> getTodayTotals({String? walletType}) async {
    final transactions = await UserTransactionService.fetchAllUserTransactions();

    final today = DateTime.now();
    int totalPoints = 0;
    int totalDiamonds = 0;

    for (var tx in transactions) {
      final createdAtStr = tx['created_at'] ?? '';
      if (createdAtStr.isEmpty) continue;

      DateTime txDate;
      try {
        txDate = DateTime.parse(createdAtStr).toLocal();
      } catch (_) {
        continue;
      }

      // Only today's transactions
      if (txDate.year != today.year ||
          txDate.month != today.month ||
          txDate.day != today.day) continue;

      // Optional wallet filter (gb, id, bs, etc.)
      if (walletType != null &&
          (tx['wallet_type'] ?? '').toString().toLowerCase() !=
              walletType.toLowerCase()) continue;

      final txType = (tx['transaction_type'] ?? '').toString().toLowerCase();
      if (txType != 'transfer_in') continue;

      // Parse amount and qty safely
      final rawAmount = tx['Amount'];
      final rawQty = tx['qty'];
      final unit = (tx['unit'] ?? '').toString().toLowerCase();
      final txWallet = (tx['wallet_type'] ?? '').toString().toLowerCase();

      final int amount = rawAmount is int
          ? rawAmount
          : int.tryParse(rawAmount?.toString() ?? '0') ?? 0;

      final int? qty = rawQty is int
          ? rawQty
          : (rawQty is String && rawQty.isNotEmpty)
              ? int.tryParse(rawQty)
              : null;

      totalPoints += amount;

      int diamondsThisTx = 0;
      if (txWallet.contains('dm') || txWallet.contains('diamond')) {
        diamondsThisTx = amount;
      } else if (unit.contains('diamond')) {
        diamondsThisTx = qty ?? 0;
      } else {
        diamondsThisTx = 0;
      }

      totalDiamonds += diamondsThisTx;
    }

    return {'points': totalPoints, 'diamonds': totalDiamonds};
  }

  /// Calculate total points and diamonds with date filtering
  static Future<Map<String, int>> getFilteredTotals({
    String? walletType,
    required String dateFilter,
    DateTimeRange? customDateRange,
  }) async {
    final transactions = await UserTransactionService.fetchAllUserTransactions();

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    // Calculate date range based on filter
    switch (dateFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
        endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      case 'Custom':
        if (customDateRange != null) {
          startDate = DateTime(customDateRange.start.year, customDateRange.start.month, customDateRange.start.day);
          endDate = DateTime(customDateRange.end.year, customDateRange.end.month, customDateRange.end.day, 23, 59, 59, 999);
        } else {
          // Fallback to today if no custom range
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    }

    int totalPoints = 0;
    int totalDiamonds = 0;

    for (var tx in transactions) {
      final createdAtStr = tx['created_at'] ?? '';
      if (createdAtStr.isEmpty) continue;

      DateTime txDate;
      try {
        txDate = DateTime.parse(createdAtStr).toLocal();
      } catch (_) {
        continue;
      }

      // Check if transaction is within date range
      if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) continue;

      // Optional wallet filter (gb, id, bs, etc.)
      if (walletType != null &&
          (tx['wallet_type'] ?? '').toString().toLowerCase() !=
              walletType.toLowerCase()) continue;

      final txType = (tx['transaction_type'] ?? '').toString().toLowerCase();
      if (txType != 'transfer_in') continue;

      // Parse amount and qty safely
      final rawAmount = tx['Amount'];
      final rawQty = tx['qty'];
      final unit = (tx['unit'] ?? '').toString().toLowerCase();
      final txWallet = (tx['wallet_type'] ?? '').toString().toLowerCase();

      final int amount = rawAmount is int
          ? rawAmount
          : int.tryParse(rawAmount?.toString() ?? '0') ?? 0;

      final int? qty = rawQty is int
          ? rawQty
          : (rawQty is String && rawQty.isNotEmpty)
              ? int.tryParse(rawQty)
              : null;

      totalPoints += amount;

      int diamondsThisTx = 0;
      if (txWallet.contains('dm') || txWallet.contains('diamond')) {
        diamondsThisTx = amount;
      } else if (unit.contains('diamond')) {
        diamondsThisTx = qty ?? 0;
      } else {
        diamondsThisTx = 0;
      }

      totalDiamonds += diamondsThisTx;
    }

    print('Transfer In Today Filter: $dateFilter, Points: $totalPoints, Diamonds: $totalDiamonds, Date Range: $startDate to $endDate');
    
    return {'points': totalPoints, 'diamonds': totalDiamonds};
  }
}