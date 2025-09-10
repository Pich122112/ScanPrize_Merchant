// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:gb_merchant/utils/constants.dart';
// import 'package:gb_merchant/utils/wallet_point_tap.dart';
// import 'package:gb_merchant/widgets/custom_segment_controll.dart';
// import '../models/exchange_prize_model.dart';
// import '../services/exchange_prize_service.dart';
// import './Enter_Quantity.dart';
// import '../services/user_balance_service.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'dart:async';

// class ExchangePrizeDialog extends StatefulWidget {
//   final String scannedQr;
//   final String phoneNumber;
//   final String userId;

//   const ExchangePrizeDialog({
//     required this.phoneNumber,
//     required this.scannedQr,
//     required this.userId,
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<ExchangePrizeDialog> createState() => _ExchangePrizeDialogState();
// }

// class _ExchangePrizeDialogState extends State<ExchangePrizeDialog> {
//   late Future<List<ExchangePrize>> futureExchangePrizes;
//   Map<String, dynamic> userBalances = {
//     'ganzberg': 0,
//     'idol': 0,
//     'boostrong': 0,
//     'diamond': 0,
//   };

//   String? receiverPhoneNumber;
//   bool _isLoadingBalances = false;
//   final ExchangePrizeService _service = ExchangePrizeService();
//   bool _noInternet = false;
//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   int selectedIndex = 0; // for segment control
//   final List<String> options = ['exchange'.tr(), 'transfer_direct'.tr()];

//   @override
//   void initState() {
//     super.initState();
//     receiverPhoneNumber = widget.phoneNumber;
//     _checkConnection();
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       results,
//     ) {
//       bool nowOffline =
//           results.isEmpty || results.every((r) => r == ConnectivityResult.none);
//       bool wasOffline = _noInternet;
//       setState(() {
//         _noInternet = nowOffline;
//       });
//       if ((wasOffline && !nowOffline) ||
//           (receiverPhoneNumber == null && !nowOffline)) {
//         _fetchPhoneNumber();
//       }
//       if (!nowOffline && receiverPhoneNumber == null) {
//         _fetchPhoneNumber();
//       }
//       if (!nowOffline) {
//         _fetchBalances();
//       }
//     });

//     // Initialize with the new API call
//     futureExchangePrizes = _service.fetchExchangePrizes(forceRefresh: true);
//     if (!_noInternet) {
//       _fetchBalances();
//     }
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> _fetchPhoneNumber() async {
//     try {
//       final parts = widget.scannedQr.split(':');
//       if (parts.length > 2) {
//         final rest = parts[2];
//         final userId = rest.split('|')[1];
//         final response = await ExchangePrizeService().fetchUserById(userId);
//         setState(() {
//           receiverPhoneNumber = response?.phoneNumber ?? 'Unknown';
//         });
//       }
//     } catch (_) {
//       setState(() {
//         receiverPhoneNumber = 'Unknown';
//       });
//     }
//   }

//   Future<void> _checkConnection() async {
//     var results = await Connectivity().checkConnectivity();
//     bool nowOffline =
//         results.isEmpty || results.every((r) => r == ConnectivityResult.none);
//     setState(() {
//       _noInternet = nowOffline;
//     });
//     if (!nowOffline) {
//       _fetchBalances();
//     }
//   }

//   Future<void> _fetchBalances() async {
//     if (!mounted || _noInternet) return;
//     setState(() => _isLoadingBalances = true);
//     try {
//       final balances = await UserBalanceService.fetchUserBalances();
//       if (!mounted) return;
//       setState(() => userBalances = balances);
//     } catch (e) {
//       if (!mounted) return;
//     } finally {
//       if (!mounted) return;
//       setState(() => _isLoadingBalances = false);
//     }
//   }

//   // Add this helper method to map prize wallet names to balance keys
//   String _mapWalletNameToBalanceKey(String walletName) {
//     switch (walletName.toLowerCase()) {
//       case 'gb':
//         return 'ganzberg';
//       case 'bs':
//         return 'boostrong';
//       case 'id':
//         return 'idol';
//       case 'dm':
//         return 'diamond';
//       default:
//         return walletName.toLowerCase();
//     }
//   }

//   String formatPhoneNumber(String raw) {
//     // Ensure we have a non-null string to work with
//     String digits = raw.replaceAll(RegExp(r'\D'), '');
//     if (digits.startsWith('855')) {
//       digits = digits.substring(3);
//     }
//     if (!digits.startsWith('0') && digits.isNotEmpty) {
//       digits = '0$digits';
//     }
//     if (digits.length == 9) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     } else if (digits.length == 10) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     }
//     return digits;
//   }

//   String getPrizeImage(ExchangePrize prize) {
//     // Updated to match new wallet names from API
//     switch (prize.walletName.toLowerCase()) {
//       case 'gb':
//         return 'assets/images/snow.png';
//       case 'bs':
//         return 'assets/images/bscan.png';
//       case 'id':
//         return 'assets/images/CanIdol.png';
//       case 'dm':
//         return 'assets/images/dollas.png';
//       default:
//         return 'assets/images/default.png';
//     }
//   }

//   // Add this helper method to translate units
//   String _translateUnit(String unit, BuildContext context) {
//     final localeCode = context.locale.languageCode;
//     if (localeCode == 'km' && unit.toLowerCase() == 'can') {
//       return 'កំប៉ុង';
//     }
//     return unit;
//   }

//   Widget _buildPrizeItem(BuildContext context, ExchangePrize prize) {
//     // Convert wallet name to lowercase to match the keys in userBalances
//     final walletKey = _mapWalletNameToBalanceKey(prize.walletName);
//     final userBalance = userBalances[walletKey] ?? 0;
//     final canExchange = userBalance >= prize.point;
//     final localeCode = context.locale.languageCode; // 'km' or 'en'
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isTablet = screenWidth > 600;

//     // Calculate how many items user can exchange
//     final maxExchangeable = (userBalance / prize.point).floor();
//     return GestureDetector(
//       onTap: () {
//         if (_noInternet) {
//           // Show no internet dialog when user taps on any prize
//           showDialog(
//             context: context,
//             builder: (context) {
//               return AlertDialog(
//                 backgroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
//                 contentPadding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
//                 title: Row(
//                   children: [
//                     const Icon(Icons.wifi_off, color: Colors.red, size: 28),
//                     const SizedBox(width: 10),
//                     Text(
//                       "no_internet".tr(),
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: Text(
//                   "check_connection".tr(),
//                   style: const TextStyle(fontSize: 15, color: Colors.black87),
//                 ),
//                 actionsAlignment: MainAxisAlignment.center,
//                 actions: [
//                   ElevatedButton.icon(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close, size: 18),
//                     label: Text("close".tr()),
//                     style: ElevatedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       backgroundColor: Colors.redAccent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           );
//           return;
//         }

//         if (canExchange) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => EnterQuantityDialog(
//                     prize: prize,
//                     phoneNumber: widget.phoneNumber,
//                     scannedQr: widget.scannedQr,
//                     receiverId: widget.userId,
//                     walletId: prize.walletType,
//                   ),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 'insufficient_balance'.tr(
//                   namedArgs: {'walletName': prize.walletName},
//                 ),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                   fontSize: 18,
//                 ),
//                 textAlign: isTablet ? TextAlign.left : TextAlign.center,
//               ),
//               backgroundColor: Colors.grey,
//             ),
//           );
//         }
//       },
//       child: Opacity(
//         opacity: canExchange ? 1.0 : 0.5,
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           color: canExchange ? Colors.white : Colors.grey[10],
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     // Image
//                     // Replace the image container with this:
//                     Container(
//                       alignment: Alignment.center,
//                       height: screenHeight * 0.15,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: const EdgeInsets.all(8),
//                       child: Image.network(
//                         prize.imageUrl,
//                         fit: BoxFit.contain,
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Center(
//                             child: CircularProgressIndicator(
//                               value:
//                                   loadingProgress.expectedTotalBytes != null
//                                       ? loadingProgress.cumulativeBytesLoaded /
//                                           loadingProgress.expectedTotalBytes!
//                                       : null,
//                             ),
//                           );
//                         },
//                         errorBuilder: (context, error, stackTrace) {
//                           print(
//                             "❌ Image load error: ${prize.imageUrl}, error: $error",
//                           );
//                           return Image.asset(
//                             getPrizeImage(prize),
//                             fit: BoxFit.contain,
//                           );
//                         },
//                       ),
//                     ),

//                     const SizedBox(height: 6),

//                     Text(
//                       "${prize.point} ${prize.walletName}",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w500,
//                         fontFamily: 'KhmerFont',
//                         color:
//                             canExchange
//                                 ? Colors.blueGrey[900]
//                                 : Colors.red[400],
//                       ),
//                     ),

//                     // Insufficient balance warning
//                     if (!canExchange) ...[
//                       Text(
//                         "notenoughbalance".tr(),
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               // Show how many items user can exchange
//               if (canExchange && maxExchangeable > 0)
//                 Positioned(
//                   top: 12,
//                   right: 8,
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: screenWidth * 0.02,
//                       vertical: screenHeight * 0.005,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryColor,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       "${(userBalance / prize.point).floor()} ${_translateUnit(prize.unit, context)}",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: isTablet ? 14 : 12,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'KhmerFont',
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localeCode = context.locale.languageCode; // 'km' or 'en'

//     return Dialog(
//       insetPadding: EdgeInsets.zero,
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: AppColors.primaryColor,
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 const SizedBox(height: 60),
//                 Container(
//                   padding: const EdgeInsets.only(left: 12, right: 12),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(
//                           Icons.arrow_back_ios_new,
//                           color: Colors.white,
//                         ),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const SizedBox(width: 20),
//                       Text(
//                         receiverPhoneNumber != null
//                             ? 'transfer_to'.tr(
//                               namedArgs: {
//                                 'phoneNumber': formatPhoneNumber(
//                                   receiverPhoneNumber!,
//                                 ),
//                               },
//                             )
//                             : _noInternet
//                             ? 'connecting_internet'.tr()
//                             : 'fetching_phone'.tr(),
//                         style: TextStyle(
//                           fontSize: 20,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   child: KhmerSegmentedControl(
//                     selectedIndex: selectedIndex,
//                     options: options,
//                     onChanged: (idx) => setState(() => selectedIndex = idx),
//                   ),
//                 ),
//                 // In the build method, replace the WalletPointsTab usage:
//                 Expanded(
//                   child:
//                       selectedIndex == 0
//                           ? _buildExchangePrizeList(
//                             context,
//                           ) // First tab: Exchange prize list
//                           : WalletPointsTab(
//                             userBalances: userBalances,
//                             phoneNumber: widget.phoneNumber,
//                             scannedQr: widget.scannedQr,
//                             userId: widget.userId,
//                           ), // Second tab: Wallet points
//                 ),
//                 const SizedBox(height: 30),
//               ],
//             ),
//             // No internet connection banner - STICKY BOTTOM
//             if (_noInternet)
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.only(bottom: 30, top: 20),
//                   color: const Color.fromARGB(255, 255, 255, 255),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.wifi_off, color: Colors.red),
//                       const SizedBox(width: 10),
//                       Text(
//                         "no_internet".tr(),
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),

//             if (_isLoadingBalances)
//               Positioned(
//                 bottom: 20,
//                 left: 0,
//                 right: 0,
//                 child: Center(
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       'checking_balance'.tr(),
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExchangePrizeList(BuildContext context) {
//     final localeCode = context.locale.languageCode;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 15),
//       child: FutureBuilder<List<ExchangePrize>>(
//         future: futureExchangePrizes,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(
//               child: Text(
//                 'No prizes available'.tr(),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
//                 ),
//               ),
//             );
//           }

//           return GridView.builder(
//             itemCount: snapshot.data!.length,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.70,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemBuilder: (context, index) {
//               return _buildPrizeItem(context, snapshot.data![index]);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// //Correct with 585 line code changes

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import 'package:gb_merchant/utils/wallet_point_tap.dart';
import 'package:gb_merchant/widgets/custom_segment_controll.dart';
import '../models/exchange_prize_model.dart';
import '../services/exchange_prize_service.dart';
import './Enter_Quantity.dart';
import '../services/user_balance_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ExchangePrizeDialog extends StatefulWidget {
  final String scannedQr;
  final String phoneNumber;
  final String userId;

  const ExchangePrizeDialog({
    required this.phoneNumber,
    required this.scannedQr,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<ExchangePrizeDialog> createState() => _ExchangePrizeDialogState();
}

class _ExchangePrizeDialogState extends State<ExchangePrizeDialog> {
  late Future<List<ExchangePrize>> futureExchangePrizes;
  Map<String, dynamic> userBalances = {
    'ganzberg': 0,
    'idol': 0,
    'boostrong': 0,
    'diamond': 0,
  };

  String? receiverPhoneNumber;
  bool _isLoadingBalances = false;
  final ExchangePrizeService _service = ExchangePrizeService();
  bool _noInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int selectedIndex = 0; // for segment control
  final List<String> options = ['exchange'.tr(), 'transfer_direct'.tr()];

  @override
  void initState() {
    super.initState();
    receiverPhoneNumber = widget.phoneNumber;
    _checkConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      bool nowOffline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      bool wasOffline = _noInternet;
      setState(() {
        _noInternet = nowOffline;
      });
      if ((wasOffline && !nowOffline) ||
          (receiverPhoneNumber == null && !nowOffline)) {
        _fetchPhoneNumber();
      }
      if (!nowOffline && receiverPhoneNumber == null) {
        _fetchPhoneNumber();
      }
      if (!nowOffline) {
        _fetchBalances();
      }
    });

    // Initialize with cached data first, then refresh if online
    futureExchangePrizes = _service.fetchExchangePrizes(forceRefresh: false);
    if (!_noInternet) {
      _fetchBalances();
    }
  }

  void refreshPrizes({bool forceRefresh = false}) {
    setState(() {
      futureExchangePrizes = _service.fetchExchangePrizes(
        forceRefresh: forceRefresh,
      );
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchPhoneNumber() async {
    try {
      final parts = widget.scannedQr.split(':');
      if (parts.length > 2) {
        final rest = parts[2];
        final userId = rest.split('|')[1];
        final response = await ExchangePrizeService().fetchUserById(userId);
        setState(() {
          receiverPhoneNumber = response?.phoneNumber ?? 'Unknown';
        });
      }
    } catch (_) {
      setState(() {
        receiverPhoneNumber = 'Unknown';
      });
    }
  }

  Future<void> _checkConnection() async {
    var results = await Connectivity().checkConnectivity();
    bool nowOffline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    setState(() {
      _noInternet = nowOffline;
    });
    if (!nowOffline) {
      _fetchBalances();
    }
  }

  Future<void> _fetchBalances() async {
    if (!mounted || _noInternet) return;
    setState(() => _isLoadingBalances = true);
    try {
      final balances = await UserBalanceService.fetchUserBalances();
      if (!mounted) return;
      setState(() => userBalances = balances);
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingBalances = false);
    }
  }

  // Add this helper method to map prize wallet names to balance keys
  String _mapWalletNameToBalanceKey(String walletName) {
    switch (walletName.toLowerCase()) {
      case 'gb':
        return 'ganzberg';
      case 'bs':
        return 'boostrong';
      case 'id':
        return 'idol';
      case 'dm':
        return 'diamond';
      default:
        return walletName.toLowerCase();
    }
  }

  String formatPhoneNumber(String raw) {
    // Ensure we have a non-null string to work with
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    if (!digits.startsWith('0') && digits.isNotEmpty) {
      digits = '0$digits';
    }
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return digits;
  }

  String getPrizeImage(ExchangePrize prize) {
    // Updated to match new wallet names from API
    switch (prize.walletName.toLowerCase()) {
      case 'gb':
        return 'assets/images/snow.png';
      case 'bs':
        return 'assets/images/bscan.png';
      case 'id':
        return 'assets/images/CanIdol.png';
      case 'dm':
        return 'assets/images/dollas.png';
      default:
        return 'assets/images/default.png';
    }
  }

  // Add this helper method to translate units
  String _translateUnit(String unit, BuildContext context) {
    final localeCode = context.locale.languageCode;
    if (localeCode == 'km' && unit.toLowerCase() == 'can') {
      return 'កំប៉ុង';
    }
    return unit;
  }

  Widget _buildPrizeItem(BuildContext context, ExchangePrize prize) {
    // Convert wallet name to lowercase to match the keys in userBalances
    final walletKey = _mapWalletNameToBalanceKey(prize.walletName);
    final userBalance = userBalances[walletKey] ?? 0;
    final canExchange = userBalance >= prize.point;
    final localeCode = context.locale.languageCode; // 'km' or 'en'
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    // Calculate how many items user can exchange
    final maxExchangeable = (userBalance / prize.point).floor();
    return GestureDetector(
      onTap: () {
        if (_noInternet) {
          // Show no internet dialog when user taps on any prize
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                contentPadding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
                title: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.red, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "no_internet".tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerFont'
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "check_connection".tr(),
                  style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerFont'),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text("close".tr()),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          return;
        }

        if (canExchange) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EnterQuantityDialog(
                    prize: prize,
                    phoneNumber: widget.phoneNumber,
                    scannedQr: widget.scannedQr,
                    receiverId: widget.userId,
                    walletId: prize.walletType,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'insufficient_balance'.tr(
                  namedArgs: {'walletName': prize.walletName},
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                  fontSize: 18,
                   fontWeight: FontWeight.bold,
                ),
                textAlign: isTablet ? TextAlign.left : TextAlign.center,
              ),
              backgroundColor: Colors.grey,
            ),
          );
        }
      },
      child: Opacity(
        opacity: canExchange ? 1.0 : 0.5,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: canExchange ? Colors.white : Colors.grey[10],
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image
                    // Replace the image container with this:
                    Container(
                      alignment: Alignment.center,
                      height: screenHeight * 0.15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: CachedNetworkImage(
                        imageUrl: prize.imageUrl,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) =>
                                Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) {
                          print(
                            "❌ Cached image load error: ${prize.imageUrl}, error: $error",
                          );
                          return Image.asset(
                            getPrizeImage(prize),
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "${prize.point} ${prize.walletName}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'KhmerFont',
                        color:
                            canExchange
                                ? Colors.blueGrey[900]
                                : Colors.red[400],
                      ),
                    ),

                    // Insufficient balance warning
                    if (!canExchange) ...[
                      Text(
                        "notenoughbalance".tr(),
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Show how many items user can exchange
              if (canExchange && maxExchangeable > 0)
                Positioned(
                  top: 12,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${(userBalance / prize.point).floor()} ${_translateUnit(prize.unit, context)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'KhmerFont',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode; // 'km' or 'en'

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primaryColor,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                receiverPhoneNumber != null
                                    ? 'transfer_to'.tr(
                                      namedArgs: {
                                        'phoneNumber': formatPhoneNumber(
                                          receiverPhoneNumber!,
                                        ),
                                      },
                                    )
                                    : _noInternet
                                    ? 'connecting_internet'.tr()
                                    : 'fetching_phone'.tr(),
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily:
                                      localeCode == 'km' ? 'KhmerFont' : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: KhmerSegmentedControl(
                    selectedIndex: selectedIndex,
                    options: options,
                    onChanged: (idx) => setState(() => selectedIndex = idx),
                  ),
                ),
                // In the build method, replace the WalletPointsTab usage:
                Expanded(
                  child:
                      selectedIndex == 0
                          ? _buildExchangePrizeList(
                            context,
                          ) // First tab: Exchange prize list
                          : WalletPointsTab(
                            userBalances: userBalances,
                            phoneNumber: widget.phoneNumber,
                            scannedQr: widget.scannedQr,
                            userId: widget.userId,
                          ), // Second tab: Wallet points
                ),
                const SizedBox(height: 30),
              ],
            ),
            // No internet connection banner - STICKY BOTTOM
            if (_noInternet)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30, top: 20),
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.red),
                      const SizedBox(width: 10),
                      Text(
                        "no_internet".tr(),
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

            if (_isLoadingBalances)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'checking_balance'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangePrizeList(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: FutureBuilder<List<ExchangePrize>>(
        future: futureExchangePrizes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No prizes available'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
            );
          }

          return GridView.builder(
            itemCount: snapshot.data!.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return _buildPrizeItem(context, snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}

//Correct with 1179 line code changes
