//Option 3: fetch the exchange prize with no lodaing indicator
import 'package:flutter/material.dart';
import '../models/exchange_prize_model.dart';
import '../services/exchange_prize_service.dart';
import './Enter_Quantity.dart';
import '../services/user_balance_service.dart';

class ExchangePrizeDialog extends StatefulWidget {
  final String phoneNumber;
  final String scannedQr;

  const ExchangePrizeDialog({
    super.key,
    required this.phoneNumber,
    required this.scannedQr,
  });

  @override
  State<ExchangePrizeDialog> createState() => _ExchangePrizeDialogState();
}

class _ExchangePrizeDialogState extends State<ExchangePrizeDialog> {
  late Future<List<ExchangePrize>> futureExchangePrizes;
  Map<String, dynamic> userBalances = {
    'ganzberg': 0,
    'idol': 0,
    'boostrong': 0,
    'money': 0.0,
  };
  bool _isLoadingBalances = false;
  final ExchangePrizeService _service = ExchangePrizeService();

  @override
  void initState() {
    super.initState();
    futureExchangePrizes = _service.fetchExchangePrizes();
    _fetchBalances();
  }

  Future<void> _fetchBalances() async {
    if (!mounted) return;
    setState(() => _isLoadingBalances = true);
    try {
      final balances = await UserBalanceService.fetchUserBalances();
      if (!mounted) return;
      setState(() => userBalances = balances);
    } catch (e) {
      if (!mounted) return;
      // Optionally show error message
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingBalances = false);
    }
  }

  String formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('855')) {
      digits = digits.substring(3);
    }
    if (!digits.startsWith('0')) {
      digits = '0$digits';
    }
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    return digits;
  }

  Widget _buildPrizeItem(BuildContext context, ExchangePrize prize) {
    final basePoints =
        int.tryParse(
          prize.exchangePrizeValue.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final category = prize.companyCategoryName.toLowerCase();
    final userPoints = (userBalances[category] ?? 0).toInt();
    final hasEnoughPoints = userPoints >= basePoints;

    return GestureDetector(
      onTap:
          hasEnoughPoints
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EnterQuantityDialog(
                          prize: prize,
                          phoneNumber: widget.phoneNumber,
                          scannedQr: widget.scannedQr,
                        ),
                  ),
                );
              }
              : null,
      child: Opacity(
        opacity: hasEnoughPoints ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: hasEnoughPoints ? Colors.grey[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child:
                        prize.imageFileName.startsWith('http')
                            ? Image.network(
                              prize.imageFileName,
                              fit: BoxFit.contain,
                            )
                            : Image.network(
                              'http://192.168.1.28:8080/uploads/${prize.imageFileName}',
                              fit: BoxFit.contain,
                            ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        prize.displayText,
                        style: TextStyle(
                          fontSize: 16,
                          color: hasEnoughPoints ? Colors.black54 : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Kantumruy',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!hasEnoughPoints)
                        Text(
                          'សមតុល្យមិនគ្រប់គ្រាន់',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontFamily: 'Kantumruy',
                          ),
                        ),
                    ],
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
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'ផ្ទេរទៅ​ ${formatPhoneNumber(widget.phoneNumber)}',
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 25,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: FutureBuilder<List<ExchangePrize>>(
                      future: futureExchangePrizes,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No prizes available'),
                          );
                        }

                        return GridView.builder(
                          itemCount: snapshot.data!.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                          itemBuilder: (context, index) {
                            return _buildPrizeItem(
                              context,
                              snapshot.data![index],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
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
                    child: const Text(
                      'កំពុងពិនិត្យសមតុល្យ...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//Correct with 285 line code changes


//Option 2 Use with the detech user balance he can exchange enough or not
// import 'package:flutter/material.dart';
// import '../models/exchange_prize_model.dart';
// import '../services/exchange_prize_service.dart';
// import './Enter_Quantity.dart';
// import '../services/user_balance_service.dart';

// // New ExchangePrizeDialog that takes phoneNumber
// class ExchangePrizeDialog extends StatefulWidget {
//   final String phoneNumber;
//   final String scannedQr; 

//   const ExchangePrizeDialog({
//     super.key,
//     required this.phoneNumber,
//     required this.scannedQr,
//   });

//   @override
//   State<ExchangePrizeDialog> createState() => _ExchangePrizeDialogState();
// }

// class _ExchangePrizeDialogState extends State<ExchangePrizeDialog> {
//   late Future<List<ExchangePrize>> futureExchangePrizes;
//   late Future<Map<String, dynamic>> futureUserBalances;
//   final ExchangePrizeService _service = ExchangePrizeService();

//   @override
//   void initState() {
//     super.initState();
//     futureExchangePrizes = _service.fetchExchangePrizes();
//     futureUserBalances = UserBalanceService.fetchUserBalances();
//   }

//   String formatPhoneNumber(String raw) {
//     String digits = raw.replaceAll(RegExp(r'\D'), '');

//     // Remove 855 country code if present at the start
//     if (digits.startsWith('855')) {
//       digits = digits.substring(3);
//     }
//     if (!digits.startsWith('0')) {
//       digits = '0$digits';
//     }
//     // Format 3-3-3 for Cambodian numbers
//     if (digits.length == 9) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     }
//     // fallback
//     return digits;
//   }

//   Widget _buildPrizeItem(
//     BuildContext context,
//     ExchangePrize prize,
//     Map<String, dynamic> balances,
//   ) {
//     final basePoints =
//         int.tryParse(
//           prize.exchangePrizeValue.replaceAll(RegExp(r'[^0-9]'), ''),
//         ) ??
//         0;
//     final category = prize.companyCategoryName.toLowerCase();
//     final userPoints = (balances[category] ?? 0).toInt();
//     final hasEnoughPoints = userPoints >= basePoints;

//     return GestureDetector(
//       onTap:
//           hasEnoughPoints
//               ? () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder:
//                         (context) => EnterQuantityDialog(
//                           prize: prize,
//                           phoneNumber: widget.phoneNumber,
//                           scannedQr: widget.scannedQr,
//                         ),
//                   ),
//                 );
//               }
//               : null,
//       child: Opacity(
//         opacity: hasEnoughPoints ? 1.0 : 0.6,
//         child: Container(
//           decoration: BoxDecoration(
//             color: hasEnoughPoints ? Colors.grey[50] : Colors.grey[200],
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Expanded(
//                 flex: 5,
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(10.0),
//                     child:
//                         prize.imageFileName.startsWith('http')
//                             ? Image.network(prize.imageFileName)
//                             : Image.network(
//                               'http://172.17.4.182:8080/uploads/${prize.imageFileName}',
//                               fit: BoxFit.contain,
//                             ),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 flex: 2,
//                 child: Container(
//                   alignment: Alignment.center,
//                   padding: const EdgeInsets.symmetric(horizontal: 6),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         prize.displayText,
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: hasEnoughPoints ? Colors.black54 : Colors.grey,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'Kantumruy',
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       if (!hasEnoughPoints)
//                         Text(
//                           'សមតុល្យមិនគ្រប់គ្រាន់',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.red,
//                             fontFamily: 'Kantumruy',
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: EdgeInsets.zero,
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.white,
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.only(left: 12, right: 12),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           Icons.arrow_back_ios_new,
//                           color: Colors.black,
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                       ),
//                       const SizedBox(width: 20),
//                       Text(
//                         'ផ្ទេរទៅ​ ${formatPhoneNumber(widget.phoneNumber)}',
//                         style: TextStyle(fontSize: 20),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 30,
//                       vertical: 25,
//                     ),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(24),
//                       ),
//                     ),
//                     child: FutureBuilder(
//                       future: Future.wait([
//                         futureExchangePrizes,
//                         futureUserBalances,
//                       ]),
//                       builder: (
//                         context,
//                         AsyncSnapshot<List<dynamic>> snapshot,
//                       ) {
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         } else if (snapshot.hasError) {
//                           return Center(
//                             child: Text('Error: ${snapshot.error}'),
//                           );
//                         } else if (!snapshot.hasData ||
//                             snapshot.data![0].isEmpty) {
//                           return const Center(
//                             child: Text('No prizes available'),
//                           );
//                         }

//                         final prizes = snapshot.data![0] as List<ExchangePrize>;
//                         final balances =
//                             snapshot.data![1] as Map<String, dynamic>;

//                         return GridView.builder(
//                           itemCount: prizes.length,
//                           gridDelegate:
//                               const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 childAspectRatio: 0.75,
//                                 crossAxisSpacing: 20,
//                                 mainAxisSpacing: 20,
//                               ),
//                           itemBuilder: (context, index) {
//                             return _buildPrizeItem(
//                               context,
//                               prizes[index],
//                               balances,
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//Correct with 262 line code changes

// import 'package:flutter/material.dart';
// import '../models/exchange_prize_model.dart';
// import '../services/exchange_prize_service.dart';
// import './Enter_Quantity.dart';

// // New ExchangePrizeDialog that takes phoneNumber
// class ExchangePrizeDialog extends StatefulWidget {
//   final String phoneNumber;
//   final String scannedQr; // <-- add this

//   const ExchangePrizeDialog({
//     super.key,
//     required this.phoneNumber,
//     required this.scannedQr,
//   });

//   @override
//   State<ExchangePrizeDialog> createState() => _ExchangePrizeDialogState();
// }

// class _ExchangePrizeDialogState extends State<ExchangePrizeDialog> {
//   late Future<List<ExchangePrize>> futureExchangePrizes;
//   final ExchangePrizeService _service = ExchangePrizeService();

//   @override
//   void initState() {
//     super.initState();
//     futureExchangePrizes = _service.fetchExchangePrizes();
//   }

//   String formatPhoneNumber(String raw) {
//     String digits = raw.replaceAll(RegExp(r'\D'), '');

//     // Remove 855 country code if present at the start
//     if (digits.startsWith('855')) {
//       digits = digits.substring(3);
//     }
//     // Add leading zero if not present
//     if (!digits.startsWith('0')) {
//       digits = '0$digits';
//     }
//     // Format 3-3-3 for Cambodian numbers
//     if (digits.length == 9) {
//       return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
//     }
//     // fallback
//     return digits;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: EdgeInsets.zero,
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: Colors.white,
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.only(left: 12, right: 12),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(
//                           Icons.arrow_back_ios_new,
//                           color: Colors.black,
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                       ),
//                       const SizedBox(width: 20),
//                       Text(
//                         'ផ្ទេរទៅ​ ${formatPhoneNumber(widget.phoneNumber)}',
//                         style: TextStyle(fontSize: 20),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 30,
//                       vertical: 25,
//                     ),
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.vertical(
//                         top: Radius.circular(24),
//                       ),
//                     ),
//                     child: FutureBuilder<List<ExchangePrize>>(
//                       future: futureExchangePrizes,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         } else if (snapshot.hasError) {
//                           return Center(
//                             child: Text('Error: ${snapshot.error}'),
//                           );
//                         } else if (!snapshot.hasData ||
//                             snapshot.data!.isEmpty) {
//                           return const Center(
//                             child: Text('No prizes available'),
//                           );
//                         }

//                         return GridView.builder(
//                           itemCount: snapshot.data!.length,
//                           gridDelegate:
//                               const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 childAspectRatio: 0.75,
//                                 crossAxisSpacing: 20,
//                                 mainAxisSpacing: 20,
//                               ),
//                           itemBuilder: (context, index) {
//                             final prize = snapshot.data![index];
//                             return GestureDetector(
//                               onTap: () {
//                                 // In ExchangePrizeDialog, when opening EnterQuantityDialog
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder:
//                                         (context) => EnterQuantityDialog(
//                                           prize: prize,
//                                           phoneNumber: widget.phoneNumber,
//                                           scannedQr:
//                                               widget
//                                                   .scannedQr, // <-- pass scannedQr to next dialog
//                                         ),
//                                   ),
//                                 );
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[50],
//                                   borderRadius: BorderRadius.circular(16),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black12,
//                                       blurRadius: 8,
//                                       offset: const Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     Expanded(
//                                       flex: 5,
//                                       child: ClipRRect(
//                                         borderRadius:
//                                             const BorderRadius.vertical(
//                                               top: Radius.circular(16),
//                                             ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(10.0),
//                                           child:
//                                               prize.imageFileName.startsWith(
//                                                     'http',
//                                                   )
//                                                   ? Image.network(
//                                                     prize.imageFileName,
//                                                   )
//                                                   : Image.network(
//                                                     'http://172.17.4.182:8080/uploads/${prize.imageFileName}',
//                                                     fit: BoxFit.contain,
//                                                   ),
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       flex: 2,
//                                       child: Container(
//                                         alignment: Alignment.center,
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 6,
//                                         ),
//                                         child: Text(
//                                           prize.displayText,
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             color: Colors.black54,
//                                             fontWeight: FontWeight.w600,
//                                             fontFamily: 'Kantumruy',
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//Correct with 220 line code changes
