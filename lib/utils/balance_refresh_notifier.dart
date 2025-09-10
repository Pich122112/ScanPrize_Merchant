// lib/utils/balance_refresh_notifier.dart
import 'package:flutter/foundation.dart';

class BalanceRefreshNotifier with ChangeNotifier {
  static final BalanceRefreshNotifier _instance =
      BalanceRefreshNotifier._internal();

  factory BalanceRefreshNotifier() => _instance;

  BalanceRefreshNotifier._internal();

  void refreshBalances() {
    notifyListeners();
  }
}

//Correct with 16 line code changes
