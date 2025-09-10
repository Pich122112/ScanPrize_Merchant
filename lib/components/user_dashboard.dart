import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gb_merchant/merchant/passcode_cache.dart';
import 'package:gb_merchant/services/user_balance_service.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/transaction_by_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../services/user_server.dart';
import './slider.dart';
import '../services/websocket_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/passcode_service.dart';
import '../utils/balance_refresh_notifier.dart';

class ThreeBoxSection extends StatefulWidget {
  final GlobalKey<ImageSliderState> sliderKey;
  const ThreeBoxSection({super.key, required this.sliderKey});
  @override
  ThreeBoxSectionState createState() => ThreeBoxSectionState();
}

class ThreeBoxSectionState extends State<ThreeBoxSection> {
  int ganzbergPoints = 0;
  int idolPoints = 0;
  int boostrongPoints = 0;
  double diamondAmount = 0.0;
  String? errorMessage;
  int failedAttempts = 0;
  bool _showAmount = false;
  Timer? _eyeAutoLockTimer;
  Timer? _eyeExpireWatcher;
  BalanceRefreshNotifier? _balanceNotifier;
  bool _isEyePressed = false;
  Timer? _eyeColorResetTimer;
  bool _isUnlocked = false;

  // NEW: cooldown timer and flag for the eye icon
  bool _eyeCooldownActive = false;
  Timer? _eyeCooldownTimer;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  StreamSubscription<Map<String, dynamic>>? _balanceSubscription;

  @override
  void dispose() {
    _balanceNotifier?.removeListener(_handleBalanceRefresh);
    _balanceNotifier = null;
    _balanceSubscription?.cancel();
    WebSocketService().disconnect();
    _eyeAutoLockTimer?.cancel();
    _eyeExpireWatcher?.cancel();
    _eyeColorResetTimer?.cancel();
    _eyeCooldownTimer?.cancel(); // <-- cancel new timer

    super.dispose();
  }

  void _handleBalanceRefresh() {
    if (mounted) {
      print('DEBUG: Balance refresh notified in ThreeBoxSection');
      _fetchBalances(useCache: false); // Force refresh from API
    }
  }

  void _handleEyeIconPress() async {
    // If cooldown active, ignore subsequent taps
    if (_eyeCooldownActive) {
      // Optional: give user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryColor,
            content: Text(
              'please_wait'.tr(),
              style: TextStyle(fontFamily: 'KhmerFont', fontSize: 16),
            ), // add translation key if you want
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
      return;
    }

    // Activate cooldown for 3 seconds
    _eyeCooldownActive = true;
    _eyeCooldownTimer?.cancel();
    _eyeCooldownTimer = Timer(const Duration(seconds: 3), () {
      _eyeCooldownActive = false;
    });

    // Check user status first
    final userStatus = await _getUserStatus();
    if (userStatus == 2) {
      _showApprovalRequiredDialog(context);
      return; // Stop here for pending approval users
    }

    // Set pressed state to true (black color)
    setState(() {
      _isEyePressed = true;
    });

    // Cancel any existing timer
    _eyeColorResetTimer?.cancel();

    // Set timer to revert back to white after 200ms
    _eyeColorResetTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isEyePressed = false;
        });
      }
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) _showNoInternetDialog(context);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final eyeWindowExpiresAt = prefs.getInt('eye_window_expires_at') ?? 0;

      if (_isUnlocked && eyeWindowExpiresAt > nowMillis) {
        setState(() {
          _showAmount = !_showAmount;
        });
        _startEyeAutoLockTimer();
        return;
      }

      bool unlocked = await PasscodeService.requireUnlock(context);
      if (!unlocked) return;

      final expires =
          DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await prefs.setInt('eye_window_expires_at', expires);
      setState(() {
        _isUnlocked = true;
        _showAmount = true;
      });
      _startEyeAutoLockTimer();
    } catch (e) {
      if (mounted) _showNoInternetDialog(context);
    }
  }

  // Create a wrapper method for wallet tap actions
  Future<void> _handleWalletTap(Function() action) async {
    // Check user status first
    final userStatus = await _getUserStatus();
    if (userStatus == 2) {
      _showApprovalRequiredDialog(context);
      return; // Stop here for pending approval users
    }

    // If status is 1 or other, proceed with the action
    action();
  }

  void _startEyeAutoLockTimer() {
    _eyeAutoLockTimer?.cancel();
    _eyeAutoLockTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _showAmount = false;
          _isUnlocked = false;
        });
      }
    });
  }

  // NEW: periodically check if unlock has expired, and auto-lock
  void _startEyeExpireWatcher() {
    _eyeExpireWatcher?.cancel();
    _eyeExpireWatcher = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final eyeWindowExpiresAt = prefs.getInt('eye_window_expires_at') ?? 0;
      if (_isUnlocked && eyeWindowExpiresAt <= nowMillis) {
        if (mounted) {
          setState(() {
            _isUnlocked = false;
            _showAmount = false;
          });
        }
        timer.cancel(); // stop checking after lock
      }
    });
  }

  void _showNoInternetDialog(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 20),
                  Text(
                    'no_internet'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិតរបស់អ្នក ហើយសាកល្បងម្តងទៀត។',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontFamily: 'KhmerFont',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'បិទ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.redAccent,
                            fontFamily: 'KhmerFont',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: បន្ថែមលទ្ធភាពសាកល្បងឡើងវិញ
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'សាកល្បងឡើងវិញ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'KhmerFont',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _fetchBalances(useCache: true); // Use cache on start
    checkUnlockState();
    _startEyeExpireWatcher();

    // Add for fast passcode show also will delete
    // Initialize passcode cache
    _initializePasscodeCache();
    // Listen for balance refresh events
    _balanceNotifier = BalanceRefreshNotifier();
    _balanceNotifier?.addListener(_handleBalanceRefresh);

    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () {
          _handleAppResumed();
          checkUnlockState();
        },
      ),
    );
  }

  // Add for fast passcode show will delete
  Future<void> _initializePasscodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        // Pre-load passcode status in background
        await PasscodeCache.refreshPasscodeStatus(token);
      }
    } catch (e) {
      print('Error initializing passcode cache: $e');
    }
  }

  void _handleAppResumed() async {
    print('App resumed - reconnecting WebSocket...');
    await WebSocketService().disconnect();
    _initWebSocket();
    _fetchBalances();
  }

  Future<void> _initWebSocket() async {
    try {
      print('Initializing WebSocket connection...');
      await WebSocketService().connect();

      _balanceSubscription?.cancel();
      _balanceSubscription = WebSocketService().balanceStream.listen(
        (data) {
          print('WebSocket balance update received: $data');
          if (mounted) {
            setState(() {
              ganzbergPoints = (data['ganzberg'] ?? 0).toInt();
              idolPoints = (data['idol'] ?? 0).toInt();
              boostrongPoints = (data['boostrong'] ?? 0).toInt();
              diamondAmount = (data['diamond'] ?? 0).toDouble();
            });
          }
        },
        onError: (error) {
          print('WebSocket stream error: $error');
          _reconnectWebSocket();
        },
      );
    } catch (e) {
      print('WebSocket initialization error: $e');
      _reconnectWebSocket();
    }
  }

  void _reconnectWebSocket() {
    if (!mounted) return;

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        print('Attempting WebSocket reconnection...');
        _initWebSocket();
      }
    });
  }

  void updateWalletAmount(String issuer, int newAmount) async {
    setState(() {
      switch (issuer) {
        case 'BS':
          boostrongPoints = newAmount;
          break;
        case 'GB':
          ganzbergPoints = newAmount;
          break;
        case 'ID':
          idolPoints = newAmount;
          break;
        case 'DM':
          diamondAmount = newAmount.toDouble();
          break;
      }
    });
    // Save to cache
    await UserBalanceService.setBalancesToCache({
      'ganzberg': ganzbergPoints,
      'idol': idolPoints,
      'boostrong': boostrongPoints,
      'diamond': diamondAmount,
    });
  }

  // Add this method to refresh user data and check status
  Future<void> _refreshUserDataAndCheckStatus() async {
    try {
      // Refresh user data from API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        final userProfile = await ApiService.getUserProfile(token);
        // ignore: unnecessary_null_comparison
        if (userProfile != null && userProfile['success'] == true) {
          // Save updated user data
          await prefs.setString('user_data', jsonEncode(userProfile));

          // Check if status changed from 2 to 1
          final newStatus = userProfile['data']['status'] as int?;
          if (newStatus == 1) {
            print('DEBUG: User status updated from 2 to 1 - approval granted');
          }
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  // refresh balance methos
  // Modify the refreshBalances method to also refresh user data
  Future<void> refreshBalances() async {
    print('DEBUG: Calling refreshBalances()');
    await _fetchBalances(useCache: false); // Force update and cache

    // Also refresh user data to get latest status
    await _refreshUserDataAndCheckStatus();

    if (mounted) setState(() {}); // Ensures UI refresh
  }

  // --- NEW: Parse balances from new API structure ---
  // In ThreeBoxSectionState class
  // In ThreeBoxSectionState class
  // Add retry logic to _fetchBalances
  Future<void> _fetchBalances({
    bool useCache = true,
    int retryCount = 0,
  }) async {
    try {
      Map<String, dynamic> balances;

      if (useCache) {
        balances = await UserBalanceService.getCachedOrFetchBalances();
      } else {
        balances = await UserBalanceService.fetchUserBalances();
      }

      if (mounted) {
        setState(() {
          ganzbergPoints = (balances['ganzberg'] ?? 0).toInt();
          boostrongPoints = (balances['boostrong'] ?? 0).toInt();
          idolPoints = (balances['idol'] ?? 0).toInt();
          diamondAmount = (balances['diamond'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print('Error fetching balances: $e');

      // Retry logic
      if (retryCount < 3 && mounted) {
        await Future.delayed(Duration(seconds: 1 + retryCount));
        _fetchBalances(useCache: useCache, retryCount: retryCount + 1);
      } else if (mounted) {
        setState(() {
          ganzbergPoints = 0;
          idolPoints = 0;
          boostrongPoints = 0;
          diamondAmount = 0.0;
        });
      }
    }
  }

  // Add this method to check user status from SharedPreferences
  Future<int?> _getUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        return userData['data']['status'] as int?;
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }
    return null;
  }

  // Add this method to show approval dialog
  void _showApprovalRequiredDialog(BuildContext context) {
    final localeCode = context.locale.languageCode;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 60, color: Colors.orange),
                  const SizedBox(height: 20),
                  Text(
                    'សូមអភ័យទោស អ្នកមិនអាចដំណើរការមុខងារនេះបានទេ!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'សូមរង់ចាំការអនុញ្ញាតពីក្រុមហ៊ុនជាមុនសិន',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'យល់ព្រម',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String formatDiamond(double diamondAmount) {
    if (diamondAmount % 1 == 0) {
      // Whole number, no decimals
      return diamondAmount.toInt().toString();
    } else {
      // Has decimals, show up to 2 digits
      return diamondAmount.toStringAsFixed(2);
    }
  }

  Future<void> checkUnlockState() async {
    final prefs = await SharedPreferences.getInstance();
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final eyeWindowExpiresAt = prefs.getInt('eye_window_expires_at') ?? 0;
    final stillUnlocked = eyeWindowExpiresAt > nowMillis;
    setState(() {
      _isUnlocked = stillUnlocked;
      _showAmount = stillUnlocked;
    });
    if (stillUnlocked) {
      _startEyeAutoLockTimer();
      _startEyeExpireWatcher(); // <-- restart watcher if still unlocked
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // --- AUTO LOCK ON TIMEOUT ---
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      final eyeWindowExpiresAt = prefs.getInt('eye_window_expires_at') ?? 0;
      if (_isUnlocked && eyeWindowExpiresAt <= nowMillis) {
        setState(() {
          _isUnlocked = false;
          _showAmount = false;
        });
      }
    });

    return RefreshIndicator(
      key: refreshIndicatorKey,
      onRefresh: () async {
        await refreshBalances();
        if (widget.sliderKey.currentState != null) {
          await widget.sliderKey.currentState!.refreshSlider();
        }
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40.0,
      edgeOffset: 20.0,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -15,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      _showAmount
                          ? Icons.visibility_outlined
                          : Icons.visibility_off,
                      color: _isEyePressed ? Colors.black : Colors.white,
                    ),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: _handleEyeIconPress,
                  ),
                ),
                GestureDetector(
                  // For diamond
                  // For Diamond tap:
                  onTap: () async {
                    await _handleWalletTap(() async {
                      try {
                        final connectivityResult =
                            await Connectivity().checkConnectivity();
                        if (connectivityResult == ConnectivityResult.none) {
                          if (mounted) _showNoInternetDialog(context);
                          return;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        final nowMillis = DateTime.now().millisecondsSinceEpoch;
                        final eyeWindowExpiresAt =
                            prefs.getInt('eye_window_expires_at') ?? 0;

                        if (_isUnlocked && eyeWindowExpiresAt > nowMillis) {
                          _startEyeAutoLockTimer();
                          if (mounted) {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: "TransactionByAccountDiamond",
                              barrierColor: Colors.black.withOpacity(0.5),
                              transitionDuration: Duration.zero,
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) {
                                return Scaffold(
                                  backgroundColor: Colors.white,
                                  body: TransactionByAccount(
                                    account: 'DM',
                                    logoPath: 'assets/images/diamond.png',
                                    balance: diamondAmount.toInt(),
                                  ),
                                );
                              },
                            );
                          }
                          return;
                        }

                        bool unlocked = await PasscodeService.requireUnlock(
                          context,
                        );
                        if (!unlocked) return;

                        final expires =
                            DateTime.now()
                                .add(const Duration(minutes: 5))
                                .millisecondsSinceEpoch;
                        await prefs.setInt('eye_window_expires_at', expires);
                        setState(() {
                          _isUnlocked = true;
                          _showAmount = true;
                        });
                        _startEyeAutoLockTimer();

                        if (mounted) {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: "TransactionByAccountDiamond",
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: Duration.zero,
                            pageBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                            ) {
                              return Scaffold(
                                backgroundColor: Colors.white,
                                body: TransactionByAccount(
                                  account: 'DM',
                                  logoPath: 'assets/images/diamond.png',
                                  balance: diamondAmount.toInt(),
                                ),
                              );
                            },
                          );
                        }
                      } catch (e) {
                        if (mounted) _showNoInternetDialog(context);
                      }
                    });
                  },
                  child: Center(
                    child: SizedBox(
                      height: screenHeight * 0.05,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _showAmount
                              ? Text(
                                formatDiamond(diamondAmount),
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              )
                              : Shimmer.fromColors(
                                baseColor: Colors.white.withOpacity(0.2),
                                highlightColor: Colors.white.withOpacity(0.5),
                                child: Container(
                                  width: screenWidth * 0.2,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.70),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      4,
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.diamond_outlined,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Example usage in ThreeBoxSection
                  _buildInfoBox(
                    imagePath: 'assets/images/ganzberg.png',
                    value: _showAmount ? '$ganzbergPoints' : null,
                    label: 'score',
                    onTap: () async {
                      await _handleWalletTap(() async {
                        try {
                          final connectivityResult =
                              await Connectivity().checkConnectivity();
                          if (connectivityResult == ConnectivityResult.none) {
                            if (mounted) _showNoInternetDialog(context);
                            return;
                          }

                          final prefs = await SharedPreferences.getInstance();
                          final nowMillis =
                              DateTime.now().millisecondsSinceEpoch;
                          final eyeWindowExpiresAt =
                              prefs.getInt('eye_window_expires_at') ?? 0;

                          if (_isUnlocked && eyeWindowExpiresAt > nowMillis) {
                            _startEyeAutoLockTimer();
                            if (mounted) {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: "TransactionByAccountGanzberg",
                                barrierColor: Colors.black.withOpacity(0.5),
                                transitionDuration: Duration.zero,
                                pageBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                ) {
                                  return Scaffold(
                                    backgroundColor: Colors.white,
                                    body: TransactionByAccount(
                                      account: 'GB',
                                      logoPath: 'assets/images/ganzberg.png',
                                      balance: ganzbergPoints,
                                    ),
                                  );
                                },
                              );
                            }
                            return;
                          }

                          bool unlocked = await PasscodeService.requireUnlock(
                            context,
                          );
                          if (!unlocked) return;

                          final expires =
                              DateTime.now()
                                  .add(const Duration(minutes: 5))
                                  .millisecondsSinceEpoch;
                          await prefs.setInt('eye_window_expires_at', expires);
                          setState(() {
                            _isUnlocked = true;
                            _showAmount = true;
                          });
                          _startEyeAutoLockTimer();

                          if (mounted) {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: "TransactionByAccountGanzberg",
                              barrierColor: Colors.black.withOpacity(0.5),
                              transitionDuration: Duration.zero,
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) {
                                return Scaffold(
                                  backgroundColor: Colors.white,
                                  body: TransactionByAccount(
                                    account: 'GB',
                                    logoPath: 'assets/images/ganzberg.png',
                                    balance: ganzbergPoints,
                                  ),
                                );
                              },
                            );
                          }
                        } catch (e) {
                          if (mounted) _showNoInternetDialog(context);
                        }
                      });
                    },
                  ),
                  _verticalDivider(),
                  _buildInfoBox(
                    imagePath: 'assets/images/idollogo.png',
                    value: _showAmount ? '$idolPoints' : null,
                    label: 'score',
                    onTap: () async {
                      await _handleWalletTap(() async {
                        try {
                          final connectivityResult =
                              await Connectivity().checkConnectivity();
                          if (connectivityResult == ConnectivityResult.none) {
                            if (mounted) _showNoInternetDialog(context);
                            return;
                          }

                          final prefs = await SharedPreferences.getInstance();
                          final nowMillis =
                              DateTime.now().millisecondsSinceEpoch;
                          final eyeWindowExpiresAt =
                              prefs.getInt('eye_window_expires_at') ?? 0;

                          if (_isUnlocked && eyeWindowExpiresAt > nowMillis) {
                            _startEyeAutoLockTimer();
                            if (mounted) {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: "TransactionByAccountIdol",
                                barrierColor: Colors.black.withOpacity(0.5),
                                transitionDuration: Duration.zero,
                                pageBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                ) {
                                  return Scaffold(
                                    backgroundColor: Colors.white,
                                    body: TransactionByAccount(
                                      account: 'ID', // Use 'ID' consistently
                                      logoPath: 'assets/images/idollogo.png',
                                      balance: idolPoints,
                                    ),
                                  );
                                },
                              );
                            }
                            return;
                          }

                          bool unlocked = await PasscodeService.requireUnlock(
                            context,
                          );
                          if (!unlocked) return;

                          final expires =
                              DateTime.now()
                                  .add(const Duration(minutes: 5))
                                  .millisecondsSinceEpoch;
                          await prefs.setInt('eye_window_expires_at', expires);
                          setState(() {
                            _isUnlocked = true;
                            _showAmount = true;
                          });
                          _startEyeAutoLockTimer();

                          if (mounted) {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: "TransactionByAccountIdol",
                              barrierColor: Colors.black.withOpacity(0.5),
                              transitionDuration: Duration.zero,
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) {
                                return Scaffold(
                                  backgroundColor: Colors.white,
                                  body: TransactionByAccount(
                                    account: 'ID',
                                    logoPath: 'assets/images/idollogo.png',
                                    balance: idolPoints,
                                  ),
                                );
                              },
                            );
                          }
                        } catch (e) {
                          if (mounted) _showNoInternetDialog(context);
                        }
                      });
                    },
                  ),
                  _verticalDivider(),
                  _buildInfoBox(
                    imagePath: 'assets/images/newbslogo.png',
                    value: _showAmount ? '$boostrongPoints' : null,
                    label: 'score',
                    onTap: () async {
                      await _handleWalletTap(() async {
                        try {
                          final connectivityResult =
                              await Connectivity().checkConnectivity();
                          if (connectivityResult == ConnectivityResult.none) {
                            if (mounted) _showNoInternetDialog(context);
                            return;
                          }

                          final prefs = await SharedPreferences.getInstance();
                          final nowMillis =
                              DateTime.now().millisecondsSinceEpoch;
                          final eyeWindowExpiresAt =
                              prefs.getInt('eye_window_expires_at') ?? 0;

                          if (_isUnlocked && eyeWindowExpiresAt > nowMillis) {
                            _startEyeAutoLockTimer();
                            if (mounted) {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: "TransactionByAccountBoostrong",
                                barrierColor: Colors.black.withOpacity(0.5),
                                transitionDuration: Duration.zero,
                                pageBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                ) {
                                  return Scaffold(
                                    backgroundColor: Colors.white,
                                    body: TransactionByAccount(
                                      account: 'BS', // Use 'BS' consistently
                                      logoPath: 'assets/images/boostrong.png',
                                      balance: boostrongPoints,
                                    ),
                                  );
                                },
                              );
                            }
                            return;
                          }

                          bool unlocked = await PasscodeService.requireUnlock(
                            context,
                          );
                          if (!unlocked) return;

                          final expires =
                              DateTime.now()
                                  .add(const Duration(minutes: 5))
                                  .millisecondsSinceEpoch;
                          await prefs.setInt('eye_window_expires_at', expires);
                          setState(() {
                            _isUnlocked = true;
                            _showAmount = true;
                          });
                          _startEyeAutoLockTimer();

                          if (mounted) {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: "TransactionByAccountBoostrong",
                              barrierColor: Colors.black.withOpacity(0.5),
                              transitionDuration: Duration.zero,
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) {
                                return Scaffold(
                                  backgroundColor: Colors.white,
                                  body: TransactionByAccount(
                                    account: 'BS',
                                    logoPath: 'assets/images/boostrong.png',
                                    balance: boostrongPoints,
                                  ),
                                );
                              },
                            );
                          }
                        } catch (e) {
                          if (mounted) _showNoInternetDialog(context);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String imagePath,
    String? value,
    required String label,
    VoidCallback? onTap,
  }) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.asset(
              imagePath,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 22),
        value != null
            ? Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
            : Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        SizedBox(height: 14),
        Text(
          label.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
          ),
        ),
      ],
    );

    // Wrap in InkWell if onTap provided
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      );
    } else {
      return content;
    }
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 45, color: Colors.white);
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final VoidCallback resumeCallBack;

  LifecycleEventHandler({required this.resumeCallBack});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resumeCallBack();
    }
  }
}

//Correct with 1169 line code changes
