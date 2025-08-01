import 'dart:async';

import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:scanprize_frontend/components/Enter_Quantity.dart';
import 'package:scanprize_frontend/utils/constants.dart';
import 'package:scanprize_frontend/utils/transaction_by_account.dart';
import './transfer_prize_qr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/scanqr_prize.dart';
import '../components/passcode.dart';
import '../widgets/attemp_time.dart';
import 'package:scanprize_frontend/components/user_qr_code_component.dart';
import '../widgets/Dialog_Success.dart';
import 'package:shimmer/shimmer.dart';
import './slider.dart';
import '../services/websocket_service.dart';

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
  double moneyAmount = 0.0;
  String? errorMessage;
  int failedAttempts = 0;
  bool _showAmount = false;
  Timer? _eyeAutoLockTimer;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  StreamSubscription<Map<String, dynamic>>? _balanceSubscription;

  // 2. Dispose timer in dispose():
  @override
  void dispose() {
    _balanceSubscription?.cancel();
    WebSocketService().disconnect();
    _eyeAutoLockTimer?.cancel();
    super.dispose();
  }

  // 3. Helper to handle 20s auto-lock logic:
  void _startEyeAutoLockTimer() async {
    _eyeAutoLockTimer?.cancel(); // Cancel any previous timer
    final prefs = await SharedPreferences.getInstance();
    final expires =
        DateTime.now().add(const Duration(seconds: 50)).millisecondsSinceEpoch;
    await prefs.setInt('eye_window_expires_at', expires);

    _eyeAutoLockTimer = Timer(const Duration(seconds: 50), () async {
      setState(() {
        _showAmount = false;
      });
      // Optionally, clear the eye_window_expires_at or keep for next check
      // await prefs.remove('eye_window_expires_at');
    });
  }

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _fetchBalances();
    // Add listener for app state changes
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(resumeCallBack: () => _handleAppResumed()),
    );
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
              moneyAmount = (data['money'] ?? 0).toDouble();
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

  // refresh balance methos
  Future<void> refreshBalances() async {
    await _fetchBalances();
  }

  // Update the _fetchPrizeSummary method to use the new endpoint
  Future<void> _fetchBalances() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('userId') ?? '';
    final userId = int.tryParse(userIdStr) ?? 0;
    if (userId == 0) return;

    final url = '${Constants.apiUrl}/user-balances/$userId';
    final response = await http.get(
      Uri.parse(url),
      headers: {"x-app-secret": Constants.appSecret},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        ganzbergPoints = (data['ganzberg'] ?? 0).toInt();
        idolPoints = (data['idol'] ?? 0).toInt();
        boostrongPoints = (data['boostrong'] ?? 0).toInt();
        moneyAmount = (data['money'] ?? 0).toDouble();
      });
    } else {
      // Handle error or set default values
      setState(() {
        ganzbergPoints = 0;
        idolPoints = 0;
        boostrongPoints = 0;
        moneyAmount = 0.0;
      });
    }
  }

  String formatMoney(double moneyAmount) {
    if (moneyAmount % 1 == 0) {
      // Whole number, no decimals
      return moneyAmount.toInt().toString();
    } else {
      // Has decimals, show up to 2 digits
      return moneyAmount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // TextButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       barrierColor:
            //           Colors
            //               .white, // Makes the background white instead of semi-transparent
            //       builder: (context) => const ExchangePrizeDialog(),
            //     );
            //   },
            //   child: const Text('Click'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       barrierColor:
            //           Colors
            //               .white, // Makes the background white instead of semi-transparent
            //       builder: (context) => const EnterQuantityDialog(),
            //     );
            //   },
            //   child: Text('Click me'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       barrierColor:
            //           Colors
            //               .white, // Makes the background white instead of semi-transparent
            //       builder: (context) => TransactionDetail(),
            //     );
            //   },
            //   child: Text('Click me'),
            // ),
            // TextButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       barrierColor:
            //           Colors
            //               .white, // Makes the background white instead of semi-transparent
            //       builder: (context) => TransactionByAccount(),
            //     );
            //   },
            //   child: Text('Click me'),
            // ),
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
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userIdStr = prefs.getString('userId') ?? '';
                        final userId = int.tryParse(userIdStr) ?? 0;

                        final nowMillis = DateTime.now().millisecondsSinceEpoch;
                        final unlockAtMillis =
                            prefs.getInt('passcode_unlock_at') ?? 0;
                        final eyeWindowExpiresAt =
                            prefs.getInt('eye_window_expires_at') ?? 0;

                        // If _showAmount is true, and inside 20s window, allow toggle hide/show freely
                        if (_showAmount && eyeWindowExpiresAt > nowMillis) {
                          setState(() {
                            _showAmount = false;
                          });
                          _eyeAutoLockTimer?.cancel();
                          return;
                        }

                        // If 20s window expired, require passcode again
                        if (eyeWindowExpiresAt > nowMillis) {
                          // Still inside window, allow show without passcode
                          setState(() {
                            _showAmount = true;
                          });
                          _startEyeAutoLockTimer();
                          return;
                        }

                        // If passcode lockout active, show timer dialog
                        if (unlockAtMillis > nowMillis) {
                          final secondsLeft =
                              ((unlockAtMillis - nowMillis) / 1000).ceil();
                          await showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder:
                                (context) => LockTimerDialog(
                                  initialSeconds: secondsLeft,
                                ),
                          );
                          return;
                        }

                        // 1. Check if passcode is set
                        final checkResp = await http.post(
                          Uri.parse('${Constants.apiUrl}/user-passcode/check'),
                          headers: {
                            "x-app-secret": Constants.appSecret,
                            "Content-Type": "application/json",
                          },
                          body: json.encode({"userId": userId}),
                        );
                        final isSet =
                            json.decode(checkResp.body)['isSet'] == true;

                        if (!isSet) {
                          // 2. Create passcode (input twice)
                          final code1 = await showDialog<String>(
                            context: context,
                            builder:
                                (context) => CustomPasscodeDialog(
                                  subtitle:
                                      'សូមធ្វើការបង្កើតលេខសម្ងាត់របស់អ្នក',
                                ),
                          );
                          if (code1 == null || code1.length != 4) return;

                          final code2 = await showDialog<String>(
                            context: context,
                            builder:
                                (context) => CustomPasscodeDialog(
                                  subtitle:
                                      'សូមផ្ទៀងផ្ទាត់លេខសម្ងាត់អ្នកម្តងទៀត',
                                ),
                          );
                          if (code2 == null || code2.length != 4) return;

                          if (code1 != code2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'លេខសម្ងាត់ដែលអ្នកបញ្ចូលមិនដូចគ្នា សូមបង្កើតម្តងទៀត',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final createResp = await http.post(
                            Uri.parse(
                              '${Constants.apiUrl}/user-passcode/create',
                            ),
                            headers: {
                              "x-app-secret": Constants.appSecret,
                              "Content-Type": "application/json",
                            },
                            body: json.encode({
                              "userId": userId,
                              "passcode": code1,
                              "passcodeConfirm": code2,
                            }),
                          );
                          if (createResp.statusCode == 200) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (dialogContext) => const SuccessDialog(
                                    message:
                                        "លេខសម្ងាត់របស់អ្នកបង្កើតបានជោគជ័យ!",
                                  ),
                            );

                            // Auto close after 5 seconds
                            Future.delayed(const Duration(seconds: 5), () {
                              Navigator.of(context, rootNavigator: true).pop();
                            });

                            setState(() {
                              _showAmount = true;
                            });
                            _startEyeAutoLockTimer();
                            return;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'បង្កើតលេខសម្ងាត់បរាជ័យ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                        // 3. Verify passcode (with lockout)
                        for (;;) {
                          final code = await showDialog<String>(
                            context: context,
                            builder:
                                (context) => CustomPasscodeDialog(
                                  subtitle:
                                      'សូមបញ្ចូលលេខសម្ងាត់ របស់អ្នកដើម្បីចូល',
                                  errorMessage:
                                      errorMessage != null && failedAttempts > 0
                                          ? 'លេខសម្ងាត់មិនត្រឹមត្រូវ​ (អាចព្យាយាម​ ${(3 - failedAttempts)} ដងទៀត)'
                                          : null,
                                ),
                          );
                          if (code == null || code.length != 4) return;

                          final verifyResp = await http.post(
                            Uri.parse(
                              '${Constants.apiUrl}/user-passcode/verify',
                            ),
                            headers: {
                              "x-app-secret": Constants.appSecret,
                              "Content-Type": "application/json",
                            },
                            body: json.encode({
                              "userId": userId,
                              "passcode": code,
                            }),
                          );
                          if (verifyResp.statusCode == 200) {
                            setState(() {
                              errorMessage = null;
                              failedAttempts = 0;
                              _showAmount = true;
                            });
                            _startEyeAutoLockTimer();
                            break;
                          } else if (verifyResp.statusCode == 423) {
                            final waitSeconds =
                                json.decode(verifyResp.body)['waitSeconds'] ??
                                0;
                            final unlockAt = DateTime.now().add(
                              Duration(seconds: waitSeconds),
                            );
                            await prefs.setInt(
                              'passcode_unlock_at',
                              unlockAt.millisecondsSinceEpoch,
                            );

                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder:
                                  (context) => LockTimerDialog(
                                    initialSeconds: waitSeconds,
                                  ),
                            );
                            break;
                          } else {
                            final respBody = json.decode(verifyResp.body);
                            failedAttempts = respBody['failedAttempts'] ?? 0;
                            int maxAttempts = 3;
                            int leftAttempts = maxAttempts - failedAttempts;
                            errorMessage =
                                'លេខសម្ងាត់មិនត្រឹមត្រូវ​ (អាចព្យាយាម​ $leftAttempts ដងទៀត)';
                          }
                        }
                      },
                    ),
                  ),
                  GestureDetector(
                    // For Money
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => TransactionByAccount(
                              account: 'money',
                              logoPath: 'assets/images/diamond.png',
                              balance: moneyAmount.toInt(),
                            ),
                      );
                    },
                    child: Center(
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _showAmount
                                ? Text(
                                  formatMoney(moneyAmount),
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
                                    width: 80,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.70),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                height: 115,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Example usage in ThreeBoxSection
                    _buildInfoBox(
                      imagePath: 'assets/images/ganzberg.png',
                      value: _showAmount ? '$ganzbergPoints' : null,
                      label: 'ពិន្ទុ',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => TransactionByAccount(
                                account: 'ganzberg',
                                logoPath: 'assets/images/ganzberg.png',
                                balance: ganzbergPoints,
                              ),
                        );
                      },
                    ),
                    _verticalDivider(),
                    _buildInfoBox(
                      imagePath: 'assets/images/idollogo.png',
                      value: _showAmount ? '$idolPoints' : null,
                      label: 'ពិន្ទុ',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => TransactionByAccount(
                                account: 'idol',
                                logoPath: 'assets/images/idollogo.png',
                                balance: idolPoints,
                              ),
                        );
                      },
                    ),
                    _verticalDivider(),
                    _buildInfoBox(
                      imagePath: 'assets/images/boostrong.png',
                      value: _showAmount ? '$boostrongPoints' : null,
                      label: 'ពិន្ទុ',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => TransactionByAccount(
                                account: 'boostrong',
                                logoPath: 'assets/images/boostrong.png',
                                balance: boostrongPoints,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      // Open transfer without need to input or create passcode
                      onTap: () async {
                        await showTransferPrizeScanDialog(context);
                      },
                      // Open transfer with need to input or create passcode
                      // onTap: () async {
                      //   final prefs = await SharedPreferences.getInstance();
                      //   final userIdStr = prefs.getString('userId') ?? '';
                      //   final userId = int.tryParse(userIdStr) ?? 0;

                      //   // NEW: Check lockout time before any passcode input
                      //   final nowMillis = DateTime.now().millisecondsSinceEpoch;
                      //   final unlockAtMillis =
                      //       prefs.getInt('passcode_unlock_at') ?? 0;
                      //   if (unlockAtMillis > nowMillis) {
                      //     final secondsLeft =
                      //         ((unlockAtMillis - nowMillis) / 1000).ceil();
                      //     await showDialog(
                      //       context: context,
                      //       barrierDismissible: true,
                      //       builder:
                      //           (context) =>
                      //               LockTimerDialog(initialSeconds: secondsLeft),
                      //     );
                      //     // Do NOT allow passcode input yet
                      //     return;
                      //   }
                      //   // 1. Check if passcode is set
                      //   final checkResp = await http.post(
                      //     Uri.parse('${Constants.apiUrl}/user-passcode/check'),
                      //     headers: {
                      //       "x-app-secret": Constants.appSecret,
                      //       "Content-Type": "application/json",
                      //     },
                      //     body: json.encode({"userId": userId}),
                      //   );
                      //   final isSet = json.decode(checkResp.body)['isSet'] == true;

                      //   if (!isSet) {
                      //     // 2. Create passcode (input twice)
                      //     final code1 = await showDialog<String>(
                      //       context: context,
                      //       builder:
                      //           (context) => CustomPasscodeDialog(
                      //             subtitle: 'សូមធ្វើការបង្កើតលេខសម្ងាត់របស់អ្នក',
                      //           ),
                      //     );
                      //     if (code1 == null || code1.length != 4) return;

                      //     final code2 = await showDialog<String>(
                      //       context: context,
                      //       builder:
                      //           (context) => CustomPasscodeDialog(
                      //             subtitle: 'សូមបញ្ចូលលេខសម្ងាត់អ្នកម្តងទៀត',
                      //           ),
                      //     );
                      //     if (code2 == null || code2.length != 4) return;

                      //     if (code1 != code2) {
                      //       // Show error, let user try again
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //           content: Text(
                      //             'លេខសម្ងាត់ដែលអ្នកបញ្ចូលមិនដូចគ្នា សូមបង្កើតម្តងទៀត',
                      //             style: TextStyle(
                      //               color: Colors.white,
                      //               fontSize: 16,
                      //               fontWeight: FontWeight.w500,
                      //             ),
                      //           ),
                      //           backgroundColor: AppColors.secondaryColor,
                      //         ),
                      //       );
                      //       return;
                      //     }

                      //     final createResp = await http.post(
                      //       Uri.parse('${Constants.apiUrl}/user-passcode/create'),
                      //       headers: {
                      //         "x-app-secret": Constants.appSecret,
                      //         "Content-Type": "application/json",
                      //       },
                      //       body: json.encode({
                      //         "userId": userId,
                      //         "passcode": code1,
                      //         "passcodeConfirm": code2,
                      //       }),
                      //     );
                      //     if (createResp.statusCode == 200) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //           backgroundColor: Colors.green,
                      //           content: Text(
                      //             'បង្កើតលេខសម្ងាត់ជោគជ័យ',
                      //             style: TextStyle(
                      //               fontSize: 16,
                      //               color: Colors.white,
                      //               fontWeight: FontWeight.w500,
                      //             ),
                      //           ),
                      //         ),
                      //       );
                      //       //For auto open after create
                      //       // Ready for transfer
                      //       // showDialog(
                      //       //   context: context,
                      //       //   barrierColor: Colors.black87,
                      //       //   builder: (context) => const TransferPrizeScan(),
                      //       // );
                      //       // Do NOT open scan dialog, just return (let user tap again to enter passcode and scan)
                      //       return;
                      //     } else {
                      //       // Show error
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(
                      //           content: Text(
                      //             'បង្កើតលេខសម្ងាត់បរាជ័យ',
                      //             style: TextStyle(
                      //               color: Colors.white,
                      //               fontSize: 16,
                      //               fontWeight: FontWeight.w500,
                      //             ),
                      //           ),
                      //           backgroundColor: Colors.red,
                      //         ),
                      //       );
                      //     }
                      //   } else {
                      //     // 3. Verify passcode (with lockout)
                      //     for (;;) {
                      //       final code = await showDialog<String>(
                      //         context: context,
                      //         builder:
                      //             (context) => CustomPasscodeDialog(
                      //               subtitle:
                      //                   'សូមបញ្ចូលលេខសម្ងាត់របស់អ្នកដើម្បីបន្ត',
                      //               errorMessage:
                      //                   errorMessage != null && failedAttempts > 0
                      //                       ? 'លេខសម្ងាត់មិនត្រឹមត្រូវ $failedAttempts/5'
                      //                       : null,
                      //             ),
                      //       );
                      //       if (code == null || code.length != 4) return;

                      //       final verifyResp = await http.post(
                      //         Uri.parse('${Constants.apiUrl}/user-passcode/verify'),
                      //         headers: {
                      //           "x-app-secret": Constants.appSecret,
                      //           "Content-Type": "application/json",
                      //         },
                      //         body: json.encode({
                      //           "userId": userId,
                      //           "passcode": code,
                      //         }),
                      //       );
                      //       if (verifyResp.statusCode == 200) {
                      //         // Success, reset error and attempts!
                      //         errorMessage = null;
                      //         failedAttempts = 0;

                      //         showDialog(
                      //           context: context,
                      //           barrierColor: Colors.black87,
                      //           builder: (context) => const TransferPrizeScan(),
                      //         );
                      //         break;
                      //       } else if (verifyResp.statusCode == 423) {
                      //         final waitSeconds =
                      //             json.decode(verifyResp.body)['waitSeconds'] ?? 0;
                      //         // Save lockout end time in local storage
                      //         final prefs = await SharedPreferences.getInstance();
                      //         final unlockAt = DateTime.now().add(
                      //           Duration(seconds: waitSeconds),
                      //         );
                      //         await prefs.setInt(
                      //           'passcode_unlock_at',
                      //           unlockAt.millisecondsSinceEpoch,
                      //         );

                      //         await showDialog(
                      //           context: context,
                      //           barrierDismissible: true,
                      //           builder:
                      //               (context) => LockTimerDialog(
                      //                 initialSeconds: waitSeconds,
                      //               ),
                      //         );
                      //         // After dialog closes (wait over or closed manually), user must tap again to retry, logic will check unlock time again.
                      //         break;
                      //       } else {
                      //         // Incorrect, get failedAttempts from backend response
                      //         final respBody = json.decode(verifyResp.body);
                      //         failedAttempts = respBody['failedAttempts'] ?? 0;
                      //         errorMessage =
                      //             'លេខសម្ងាត់មិនត្រឹមត្រូវ $failedAttempts/5';
                      //         // Loop to allow retry (dialog will show errorMessage)
                      //       }
                      //     }
                      //   }
                      // },
                      child: _buildActionButton(
                        Icons.arrow_circle_up_sharp,
                        "ផ្ទេរចេញ",
                        Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final qrPayload = prefs.getString('qrPayload');
                        final phoneNumber = prefs.getString('phoneNumber');

                        if (qrPayload != null && phoneNumber != null) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => UserQrCodeComponent(
                                  qrPayload: qrPayload,
                                  phoneNumber: phoneNumber,
                                ),
                          );
                          return;
                        }

                        // Fetch from backend if not cached
                        if (phoneNumber != null && phoneNumber.isNotEmpty) {
                          try {
                            final response = await http.get(
                              // Same endpoint but without type parameter
                              Uri.parse(
                                '${Constants.apiUrl}/auth/me/qr?phoneNumber=$phoneNumber',
                              ),
                              headers: {'Content-Type': 'application/json'},
                            );

                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              await prefs.setString(
                                'qrPayload',
                                data['qrPayload'],
                              );
                              showDialog(
                                context: context,
                                builder:
                                    (context) => UserQrCodeComponent(
                                      qrPayload: data['qrPayload'],
                                      phoneNumber: phoneNumber,
                                    ),
                              );
                            } else {
                              throw Exception(
                                'Failed to fetch QR code: ${response.statusCode}',
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to fetch QR code: ${e.toString()}',
                                ),
                              ),
                            );
                            debugPrint('QR fetch error: ${e.toString()}');
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please login again')),
                          );
                        }
                      },
                      child: _buildActionButton(
                        Icons.arrow_circle_down,
                        "ទទួលចូល",
                        Colors.lightBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String imagePath,
    String? value,
    required String label,
    VoidCallback? onTap,
  }) {
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
              fit: BoxFit.fill,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
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

  Widget _buildActionButton(IconData icon, String label, Color iconColor) {
    return Container(
      width: 180,
      height: 130,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(icon, color: iconColor, size: 40),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

//Correct with 981 line code changes
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
