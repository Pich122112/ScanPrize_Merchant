// import 'package:flutter/material.dart';
// import 'package:gb_merchant/components/All_Exchange_PrizeList.dart';
// import 'package:gb_merchant/components/Enter_Quantity.dart';
// import 'package:gb_merchant/components/transfer_prize_qr.dart';
// import 'package:gb_merchant/utils/qr_code_parser.dart';
// import '../components/slider.dart';
// import '../components/user_dashboard.dart';
// import '../models/exchange_prize_model.dart';
// import '../services/user_balance_service.dart';
// import '../utils/balance_refresh_notifier.dart';

// class HomePage extends StatefulWidget {
//   final GlobalKey<ThreeBoxSectionState> dashboardKey;
//   const HomePage({required this.dashboardKey, super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final GlobalKey<ImageSliderState> sliderKey = GlobalKey<ImageSliderState>();
//   Map<String, dynamic> userBalances = {
//     'ganzberg': 0,
//     'idol': 0,
//     'boostrong': 0,
//     'diamond': 0,
//   };
//   bool _isLoadingBalances = false;
//   bool _isRefreshing = false;
//   // ignore: unused_field
//   bool _isInitialLoad = true;

//   BalanceRefreshNotifier? _balanceNotifier;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//     _balanceNotifier = BalanceRefreshNotifier();
//     _balanceNotifier?.addListener(_handleBalanceRefresh);
//   }

//   @override
//   void dispose() {
//     _balanceNotifier?.removeListener(_handleBalanceRefresh);
//     _balanceNotifier = null;
//     super.dispose();
//   }

//   Future<void> _loadInitialData() async {
//     // Load balances
//     await _fetchBalances();

//     // Load slider data immediately on app start - use the public method
//     if (sliderKey.currentState != null) {
//       await sliderKey.currentState!.fetchSliders();
//     }

//     setState(() {
//       _isInitialLoad = false;
//     });
//   }

//   void _handleBalanceRefresh() {
//     if (mounted) {
//       print('DEBUG: HomePage received balance refresh notification');
//       _fetchBalances();
//     }
//   }

//   // Enhance _fetchBalances with error handling
//   Future<void> _fetchBalances() async {
//     if (!mounted) return;
//     setState(() => _isLoadingBalances = true);
//     try {
//       final balances = await UserBalanceService.fetchUserBalances();
//       if (!mounted) return;
//       setState(() => userBalances = balances);
//     } catch (e) {
//       if (!mounted) return;
//       print('Error fetching balances in HomePage: $e');
//       // Keep the old balances instead of resetting to zero
//     } finally {
//       if (!mounted) return;
//       setState(() => _isLoadingBalances = false);
//     }
//   }

//   // In HomePage - Update the QR handling
//   void _handlePrizeSelected(ExchangePrize prize) async {
//     String? scannedQr;

//     // Show scan dialog and get QR result
//     scannedQr = await showGeneralDialog<String>(
//       context: context,
//       barrierDismissible: true,
//       barrierColor: Colors.black87,
//       barrierLabel: "TransferPrizeScan",
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (context, animation, secondaryAnimation) {
//         return Scaffold(
//           backgroundColor: Colors.black,
//           body: TransferPrizeScan(
//             onScanned: (qrCode) {
//               Navigator.of(context).pop(qrCode);
//             },
//           ),
//         );
//       },
//     );

//     // If no QR scanned or dialog dismissed
//     if (scannedQr == null || scannedQr.isEmpty) return;

//     // Parse QR data with proper error handling
//     Map<String, dynamic> qrData;
//     try {
//       qrData = QrCodeParser.parseTransferQr(scannedQr);
//       print("🔍 Parsed QR Data:");
//       print("   - Raw QR: ${qrData['raw']}");
//       print("   - Parsed Phone: ${qrData['phoneNumber']}");
//       print("   - Parsed Name: ${qrData['name']}");
//       print("   - Signature: ${qrData['signature']}");
//     } catch (e) {
//       print("Error parsing QR data: $e");
//       // Show error and return
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Invalid QR code format: $e')));
//       return;
//     }

//     final phoneNumber = qrData['phoneNumber'] ?? 'Unknown';
//     final signature = qrData['signature'] ?? scannedQr;

//     // ✅ Validate phone number before proceeding
//     if (phoneNumber == 'Unknown' || !phoneNumber.contains('855')) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid phone number in QR code')),
//       );
//       return;
//     }

//     // Determine wallet ID based on prize type
//     String walletId;
//     switch (prize.walletName.toLowerCase()) {
//       case 'gb':
//         walletId = '1';
//         break;
//       case 'bs':
//         walletId = '2';
//         break;
//       case 'id':
//         walletId = '3';
//         break;
//       case 'dm':
//         walletId = '4';
//         break;
//       default:
//         walletId = '1';
//     }

//     // Show EnterQuantityDialog
//     await Future.delayed(const Duration(milliseconds: 100));
//     if (!mounted) return;

//     await showGeneralDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: "EnterQuantityDialog",
//       barrierColor: Colors.black.withOpacity(0.5),
//       transitionDuration: const Duration(milliseconds: 200),
//       pageBuilder: (context, animation, secondaryAnimation) {
//         return WillPopScope(
//           onWillPop: () {
//             Navigator.of(context);
//             return Future.value(false);
//           },
//           child: Center(
//             child: EnterQuantityDialog(
//               prize: prize,
//               phoneNumber: phoneNumber,
//               scannedQr: signature,
//               receiverId: '0',
//               walletId: walletId,
//               routeSource: 'homePage',
//               onTransferSuccess: () {
//                 // Callback for successful transfer
//                 _refreshData(); // Refresh all data
//                 BalanceRefreshNotifier().refreshBalances(); // Notify others
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _refreshData() async {
//     if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

//     setState(() {
//       _isRefreshing = true;
//     });

//     print('DEBUG: Pull-to-refresh triggered');

//     try {
//       // Refresh dashboard balances (force API call)
//       await widget.dashboardKey.currentState?.refreshBalances();

//       // Refresh slider
//       await sliderKey.currentState?.refreshSlider();

//       // Refresh home page balances
//       await _fetchBalances();
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isRefreshing = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: RefreshIndicator(
//         onRefresh: _refreshData,
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
//                 SingleChildScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(
//                       minHeight: constraints.maxHeight,
//                     ),
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 30),
//                         ThreeBoxSection(
//                           key: widget.dashboardKey,
//                           sliderKey: sliderKey,
//                         ),
//                         ImageSlider(key: sliderKey),
//                         const SizedBox(height: 10),
//                         // Show prize list immediately, balances will update when loaded
//                         AllExchangePrizeList(
//                           userBalances: userBalances,
//                           onPrizeSelected: _handlePrizeSelected,
//                           isLoadingBalances: _isLoadingBalances,
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// //Correct with 272 line code changes

import 'package:flutter/material.dart';
import 'package:gb_merchant/components/All_Exchange_PrizeList.dart';
import 'package:gb_merchant/components/Enter_Quantity.dart';
import 'package:gb_merchant/components/transfer_prize_qr.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/qr_code_parser.dart';
import '../components/slider.dart';
import '../components/user_dashboard.dart';
import '../models/exchange_prize_model.dart';
import '../services/user_balance_service.dart';
import '../utils/balance_refresh_notifier.dart';

class HomePage extends StatefulWidget {
  final GlobalKey<ThreeBoxSectionState> dashboardKey;
  const HomePage({required this.dashboardKey, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ImageSliderState> sliderKey = GlobalKey<ImageSliderState>();
  final GlobalKey<AllExchangePrizeListState> _prizeListKey =
      GlobalKey<AllExchangePrizeListState>();

  Map<String, dynamic> userBalances = {
    'ganzberg': 0,
    'idol': 0,
    'boostrong': 0,
    'diamond': 0,
  };
  bool _isLoadingBalances = false;
  bool _isRefreshing = false;
  // ignore: unused_field
  bool _isInitialLoad = true;

  BalanceRefreshNotifier? _balanceNotifier;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _balanceNotifier = BalanceRefreshNotifier();
    _balanceNotifier?.addListener(_handleBalanceRefresh);
  }

  @override
  void dispose() {
    _balanceNotifier?.removeListener(_handleBalanceRefresh);
    _balanceNotifier = null;
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Load balances
    await _fetchBalances();

    // Load slider data immediately on app start - use the public method
    if (sliderKey.currentState != null) {
      await sliderKey.currentState!.fetchSliders();
    }

    setState(() {
      _isInitialLoad = false;
    });
  }

  void _handleBalanceRefresh() {
    if (mounted) {
      print('DEBUG: HomePage received balance refresh notification');
      _fetchBalances();
    }
  }

  // Enhance _fetchBalances with error handling
  Future<void> _fetchBalances() async {
    if (!mounted) return;
    setState(() => _isLoadingBalances = true);
    try {
      final balances = await UserBalanceService.fetchUserBalances();
      if (!mounted) return;
      setState(() => userBalances = balances);
    } catch (e) {
      if (!mounted) return;
      print('Error fetching balances in HomePage: $e');
      // Keep the old balances instead of resetting to zero
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingBalances = false);
    }
  }

  // In HomePage - Update the QR handling
  void _handlePrizeSelected(ExchangePrize prize) async {
    String? scannedQr;

    // Show scan dialog and get QR result
    scannedQr = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      barrierLabel: "TransferPrizeScan",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: TransferPrizeScan(
            onScanned: (qrCode) {
              Navigator.of(context).pop(qrCode);
            },
          ),
        );
      },
    );

    // If no QR scanned or dialog dismissed
    if (scannedQr == null || scannedQr.isEmpty) return;

    // Parse QR data with proper error handling
    Map<String, dynamic> qrData;
    try {
      qrData = QrCodeParser.parseTransferQr(scannedQr);
      print("🔍 Parsed QR Data:");
      print("   - Raw QR: ${qrData['raw']}");
      print("   - Parsed Phone: ${qrData['phoneNumber']}");
      print("   - Parsed Name: ${qrData['name']}");
      print("   - Signature: ${qrData['signature']}");
    } catch (e) {
      print("Error parsing QR data: $e");
      // Show error and return
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid QR code format: $e')));
      return;
    }

    final phoneNumber = qrData['phoneNumber'] ?? 'Unknown';
    final signature = qrData['signature'] ?? scannedQr;

    // ✅ Validate phone number before proceeding
    if (phoneNumber == 'Unknown' || !phoneNumber.contains('855')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid phone number in QR code')),
      );
      return;
    }

    // Determine wallet ID based on prize type
    String walletId;
    switch (prize.walletName.toLowerCase()) {
      case 'gb':
        walletId = '1';
        break;
      case 'bs':
        walletId = '2';
        break;
      case 'id':
        walletId = '3';
        break;
      case 'dm':
        walletId = '4';
        break;
      default:
        walletId = '1';
    }

    // Show EnterQuantityDialog
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EnterQuantityDialog",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
          onWillPop: () {
            Navigator.of(context);
            return Future.value(false);
          },
          child: Center(
            child: EnterQuantityDialog(
              prize: prize,
              phoneNumber: phoneNumber,
              scannedQr: signature,
              receiverId: '0',
              walletId: walletId,
              routeSource: 'homePage',
              onTransferSuccess: () {
                // Callback for successful transfer
                _refreshData(); // Refresh all data
                BalanceRefreshNotifier().refreshBalances(); // Notify others
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isRefreshing = true;
    });

    print('DEBUG: Pull-to-refresh triggered');

    try {
      // Refresh dashboard balances (force API call)
      await widget.dashboardKey.currentState?.refreshBalances();

      // Refresh slider
      await sliderKey.currentState?.refreshSlider();

      // Refresh home page balances
      await _fetchBalances();

      // Refresh prize list
      if (_prizeListKey.currentState != null) {
        _prizeListKey.currentState!.refreshPrizes(forceRefresh: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ), // ~30px on a 1000px height screen
                        ThreeBoxSection(
                          key: widget.dashboardKey,
                          sliderKey: sliderKey,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.006,
                        ), // ~6px
                        ImageSlider(key: sliderKey),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ), // ~10px
                        // Show prize list immediately, balances will update when loaded
                        AllExchangePrizeList(
                          key: _prizeListKey,
                          userBalances: userBalances,
                          onPrizeSelected: _handlePrizeSelected,
                          isLoadingBalances: _isLoadingBalances,
                          onRefresh: _refreshData,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ), // ~20px
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

//Correct with 553 line code changes
