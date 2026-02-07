import 'package:flutter/material.dart';
import 'package:gb_merchant/services/user_transaction_service.dart';

class TransferToCompanyService {
  static Future<Map<String, int>> getAllTimeTotals({String? walletCode}) async {
    final transactions =
        await UserTransactionService.fetchAllUserTransactions();

    // 🎯 Target company information
    const targetName = 'hhh kk';
    const targetPhone = '85599666555';

    int totalPoints = 0;
    int totalDiamonds = 0;

    for (var tx in transactions) {
      final receiverName = (tx['ToUserName'] ?? '').toString().toLowerCase();
      final receiverPhone = (tx['ToPhoneNumber'] ?? '').toString();
      final walletType = (tx['wallet_type'] ?? '').toString().toLowerCase();
      final unit = (tx['unit'] ?? '').toString().toLowerCase();

      // ✅ Filter by target account and optional wallet type
      if (receiverName.contains(targetName.toLowerCase()) &&
          receiverPhone.contains(targetPhone) &&
          (walletCode == null || walletType == walletCode.toLowerCase())) {
        // Parse Amount safely
        final rawAmount = tx['Amount'];
        final int amount =
            rawAmount is int
                ? rawAmount
                : int.tryParse(rawAmount?.toString() ?? '0') ?? 0;

        // Parse Qty safely
        final rawQty = tx['qty'];
        final int? qty =
            rawQty is int
                ? rawQty
                : (rawQty is String && rawQty.isNotEmpty)
                ? int.tryParse(rawQty)
                : null;

        // ✅ Points always counted from amount
        totalPoints += amount;

        // ✅ Diamonds counted only if from diamond wallet or diamond unit
        int diamondsThisTx = 0;
        if (walletType.contains('dm') || walletType.contains('diamond')) {
          diamondsThisTx = amount;
        } else if (unit.contains('diamond')) {
          diamondsThisTx = qty ?? 0;
        }

        totalDiamonds += diamondsThisTx;
      }
    }

    print(
      'Transfer To Company - ALL TIME: Points: $totalPoints, Diamonds: $totalDiamonds',
    );

    return {'points': totalPoints, 'diamonds': totalDiamonds};
  }

  static Future<Map<String, int>> getTransferTotals({
    String? walletCode,
  }) async {
    final transactions =
        await UserTransactionService.fetchAllUserTransactions();

    // 🎯 Target company information
    const targetName = 'hhh kk';
    const targetPhone = '85599666555';

    int totalPoints = 0;
    int totalDiamonds = 0;

    for (var tx in transactions) {
      final receiverName = (tx['ToUserName'] ?? '').toString().toLowerCase();
      final receiverPhone = (tx['ToPhoneNumber'] ?? '').toString();
      final walletType = (tx['wallet_type'] ?? '').toString().toLowerCase();
      final unit = (tx['unit'] ?? '').toString().toLowerCase();

      // ✅ Filter by target account and optional wallet type
      if (receiverName.contains(targetName.toLowerCase()) &&
          receiverPhone.contains(targetPhone) &&
          (walletCode == null || walletType == walletCode.toLowerCase())) {
        // Parse Amount safely
        final rawAmount = tx['Amount'];
        final int amount =
            rawAmount is int
                ? rawAmount
                : int.tryParse(rawAmount?.toString() ?? '0') ?? 0;

        // Parse Qty safely
        final rawQty = tx['qty'];
        final int? qty =
            rawQty is int
                ? rawQty
                : (rawQty is String && rawQty.isNotEmpty)
                ? int.tryParse(rawQty)
                : null;

        // ✅ Points always counted from amount
        totalPoints += amount;

        // ✅ Diamonds counted only if from diamond wallet or diamond unit
        int diamondsThisTx = 0;
        if (walletType.contains('dm') || walletType.contains('diamond')) {
          diamondsThisTx = amount;
        } else if (unit.contains('diamond')) {
          diamondsThisTx = qty ?? 0;
        }

        totalDiamonds += diamondsThisTx;
      }
    }

    return {'points': totalPoints, 'diamonds': totalDiamonds};
  }

  /// Calculate total points and diamonds with date filtering for transfers to company
  static Future<Map<String, int>> getFilteredTransferTotals({
    String? walletCode,
    required String dateFilter,
    DateTimeRange? customDateRange,
  }) async {
    final transactions =
        await UserTransactionService.fetchAllUserTransactions();

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
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
          999,
        );
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      case 'Custom':
        if (customDateRange != null) {
          startDate = DateTime(
            customDateRange.start.year,
            customDateRange.start.month,
            customDateRange.start.day,
          );
          endDate = DateTime(
            customDateRange.end.year,
            customDateRange.end.month,
            customDateRange.end.day,
            23,
            59,
            59,
            999,
          );
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

    // 🎯 Target company information
    const targetName = 'hhh kk';
    const targetPhone = '85599666555';

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

      final receiverName = (tx['ToUserName'] ?? '').toString().toLowerCase();
      final receiverPhone = (tx['ToPhoneNumber'] ?? '').toString();
      final walletType = (tx['wallet_type'] ?? '').toString().toLowerCase();
      final unit = (tx['unit'] ?? '').toString().toLowerCase();

      // ✅ Filter by target account and optional wallet type
      if (receiverName.contains(targetName.toLowerCase()) &&
          receiverPhone.contains(targetPhone) &&
          (walletCode == null || walletType == walletCode.toLowerCase())) {
        // Parse Amount safely
        final rawAmount = tx['Amount'];
        final int amount =
            rawAmount is int
                ? rawAmount
                : int.tryParse(rawAmount?.toString() ?? '0') ?? 0;

        // Parse Qty safely
        final rawQty = tx['qty'];
        final int? qty =
            rawQty is int
                ? rawQty
                : (rawQty is String && rawQty.isNotEmpty)
                ? int.tryParse(rawQty)
                : null;

        // ✅ Points always counted from amount
        totalPoints += amount;

        // ✅ Diamonds counted only if from diamond wallet or diamond unit
        int diamondsThisTx = 0;
        if (walletType.contains('dm') || walletType.contains('diamond')) {
          diamondsThisTx = amount;
        } else if (unit.contains('diamond')) {
          diamondsThisTx = qty ?? 0;
        }

        totalDiamonds += diamondsThisTx;
      }
    }

    print(
      'Transfer To Company Filter: $dateFilter, Points: $totalPoints, Diamonds: $totalDiamonds, Date Range: $startDate to $endDate',
    );

    return {'points': totalPoints, 'diamonds': totalDiamonds};
  }
}
