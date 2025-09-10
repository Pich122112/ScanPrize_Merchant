// import 'package:flutter/material.dart';
// import 'package:gb_merchant/widgets/attemp_time.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../components/passcode.dart';
// import '../widgets/Dialog_Success.dart';
// import '../utils/encryption.dart';
// import '../services/user_server.dart';

// class PasscodeService {
//   static int failedAttempts = 0;
//   static String? errorMessage;

//   static Future<bool> requireUnlock(
//     BuildContext context, {
//     bool setExpiration = true,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final nowMillis = DateTime.now().millisecondsSinceEpoch;
//     final token = prefs.getString('token') ?? '';

//     // Check for lockout first
//     final lockoutUntil = prefs.getInt('passcode_lockout_until') ?? 0;
//     if (lockoutUntil > nowMillis) {
//       final secondsLeft = ((lockoutUntil - nowMillis) / 1000).ceil();
//       await showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => LockTimerDialog(initialSeconds: secondsLeft),
//       );
//       return false;
//     }

//     // Always get latest profile to check passcode status
//     try {
//       final userProfile = await ApiService.getUserProfile(token);
//       // ignore: unnecessary_null_comparison
//       if (userProfile != null && userProfile['success'] == true) {
//         final userData = userProfile['data'];
//         // This will work for both int 0 and string "0"
//         // In your requireUnlock method, add debug logging first:
//         print('🔐 DEBUG: User profile data: $userData');

//         // Check both possible fields until we know which one is used
//         final passcodeValue = userData['passcode'] ?? userData['passcode_hash'];
//         final hasPasscode =
//             (passcodeValue != null &&
//                 passcodeValue.toString() != '0' &&
//                 passcodeValue.toString().isNotEmpty);

//         print(
//           '🔐 DEBUG: Passcode status - value: $passcodeValue, hasPasscode: $hasPasscode',
//         );

//         // Update shared preferences
//         await prefs.setBool('hasPasscode', hasPasscode);

//         if (!hasPasscode) {
//           // Force create passcode if not set (passcode==0)
//           return await _createPasscodeFlow(
//             context,
//             prefs,
//             token,
//             setExpiration,
//           );
//         } else {
//           // Usual verify flow
//           return await _verifyPasscodeFlow(
//             context,
//             prefs,
//             token,
//             setExpiration,
//           );
//         }
//       }
//     } catch (e) {
//       // Fallback to stored preference
//       final hasPasscodePref = prefs.getBool('hasPasscode') ?? false;
//       if (!hasPasscodePref) {
//         return await _createPasscodeFlow(context, prefs, token, setExpiration);
//       } else {
//         return await _verifyPasscodeFlow(context, prefs, token, setExpiration);
//       }
//     }

//     return false;
//   }

//   static Future<bool> _createPasscodeFlow(
//     BuildContext context,
//     SharedPreferences prefs,
//     String token,
//     bool setExpiration,
//   ) async {
//     final code1 = await showDialog<String>(
//       context: context,
//       builder:
//           (_) => const CustomPasscodeDialog(
//             subtitle: 'សូមធ្វើការបង្កើតលេខសម្ងាត់របស់អ្នក',
//           ),
//     );
//     if (code1 == null || code1.length != 4) return false;

//     final code2 = await showDialog<String>(
//       context: context,
//       builder:
//           (_) => const CustomPasscodeDialog(
//             subtitle: 'សូមផ្ទៀងផ្ទាត់លេខសម្ងាត់អ្នកម្តងទៀត',
//           ),
//     );
//     if (code2 == null || code2.length != 4) return false;

//     if (code1 != code2) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('លេខសម្ងាត់ដែលអ្នកបញ្ចូលមិនដូចគ្នា សូមបង្កើតម្តងទៀត'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//       return false;
//     }

//     try {
//       // Encrypt passcode using the same method as in your API
//       final userId = prefs.getString('userId') ?? '';
//       final encryptedPasscode = await encryptPasscodeForVerification(
//         code1,
//         userId,
//       );

//       debugPrint('🔐 DEBUG: User entered passcode for creation: "$code1"');
//       debugPrint('🔐 DEBUG: Encrypting passcode for creation...');
//       debugPrint('🔐 DEBUG: Encrypted passcode hash: "$encryptedPasscode"');
//       debugPrint(
//         '🔐 DEBUG: Hash length: ${encryptedPasscode.length} characters',
//       );
//       debugPrint('🌐 DEBUG: Starting passcode creation API call');
//       debugPrint(
//         '🌐 DEBUG: Token preview: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
//       );
//       debugPrint('🌐 DEBUG: Encrypted passcode to send: "$encryptedPasscode"');
//       debugPrint('🌐 DEBUG: Passcode length: ${encryptedPasscode.length}');
//       // Use the new API endpoint from your Postman collection

//       final createResult = await ApiService.createPasscode(
//         token,
//         encryptedPasscode,
//         encryptedPasscode,
//       );
//       // Add this debug log to see what the API returns
//       debugPrint('🌐 DEBUG: Create passcode API response: $createResult');

//       if (createResult['success'] == true) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder:
//               (_) => const SuccessDialog(
//                 message: "លេខសម្ងាត់របស់អ្នកបង្កើតបានជោគជ័យ!",
//               ),
//         );
//         Future.delayed(const Duration(seconds: 2), () {
//           Navigator.of(context, rootNavigator: true).pop();
//         });
//         if (setExpiration) {
//           final expires =
//               DateTime.now()
//                   .add(const Duration(minutes: 5))
//                   .millisecondsSinceEpoch;
//           await prefs.setInt('eye_window_expires_at', expires);
//         }
//         return true;
//       } else {
//         // Add detailed error logging
//         debugPrint(
//           '❌ DEBUG: Passcode creation failed: ${createResult['message']}',
//         );
//         debugPrint('❌ DEBUG: Full response: $createResult');
//         // FIX: Handle the case where passcode already exists more robustly
//         final errorMessage = (createResult['message'] ?? '').toLowerCase();

//         if (errorMessage.contains('already setup') ||
//             errorMessage.contains('already set up') ||
//             errorMessage.contains('already exists')) {
//           // Show informative message to user
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'លេខសម្ងាត់មានរួចហើយ សូមបញ្ចូលលេខសម្ងាត់ដើម្បីចូល',
//               ),
//               backgroundColor: Colors.orange,
//             ),
//           );

//           // Close the create dialog and immediately show verify dialog
//           Navigator.of(context, rootNavigator: true).pop();

//           // Directly call verify flow
//           return await _verifyPasscodeFlow(
//             context,
//             prefs,
//             token,
//             setExpiration,
//           );
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(createResult['message'] ?? 'បង្កើតលេខសម្ងាត់បរាជ័យ'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return false;
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('កំហុសក្នុងការបង្កើតលេខសម្ងាត់'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return false;
//     }
//   }

//   static Future<bool> _verifyPasscodeFlow(
//     BuildContext context,
//     SharedPreferences prefs,
//     String token,
//     bool setExpiration,
//   ) async {
//     while (true) {
//       final code = await showDialog<String>(
//         context: context,
//         builder:
//             (_) => CustomPasscodeDialog(
//               subtitle: 'សូមបញ្ចូលលេខសម្ងាត់ របស់អ្នកដើម្បីចូល',
//               errorMessage: errorMessage,
//             ),
//       );

//       if (code == null || code.length != 4) return false;

//       try {
//         final userId = prefs.getString('userId') ?? '';
//         final encryptedPasscode = await encryptPasscodeForVerification(
//           code,
//           userId,
//         ); // ✅ DEBUG LOGS
//         debugPrint('🔐 DEBUG: User entered passcode: "$code"');
//         debugPrint('🔐 DEBUG: Encrypting passcode for verification...');
//         debugPrint('🔐 DEBUG: Encrypted passcode hash: "$encryptedPasscode"');
//         debugPrint(
//           '🔐 DEBUG: Hash length: ${encryptedPasscode.length} characters',
//         );
//         debugPrint('🌐 DEBUG: Starting passcode verification API call');
//         debugPrint(
//           '🌐 DEBUG: Token preview: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
//         );
//         debugPrint(
//           '🌐 DEBUG: Encrypted passcode to send: "$encryptedPasscode"',
//         );
//         debugPrint('🌐 DEBUG: Passcode length: ${encryptedPasscode.length}');

//         final verifyResult = await ApiService.verifyPasscode(
//           token,
//           encryptedPasscode,
//         );

//         if (verifyResult['success'] == true) {
//           failedAttempts = 0;
//           errorMessage = null;

//           if (setExpiration) {
//             final expires =
//                 DateTime.now()
//                     .add(const Duration(minutes: 5))
//                     .millisecondsSinceEpoch;
//             await prefs.setInt('passcode_unlock_at', expires);
//             await prefs.setInt('eye_window_expires_at', expires);
//           }
//           return true;
//         } else {
//           failedAttempts++;
//           errorMessage =
//               'លេខសម្ងាត់មិនត្រឹមត្រូវ។ អាចព្យាយាម​ ${3 - failedAttempts} ដងទៀត';

//           if (failedAttempts >= 3) {
//             // Set lockout period (10 second)
//             final lockoutUntil =
//                 DateTime.now()
//                     .add(const Duration(seconds: 10))
//                     .millisecondsSinceEpoch;
//             await prefs.setInt('passcode_lockout_until', lockoutUntil);

//             return false;
//           }
//         }
//       } catch (e) {
//         failedAttempts++;
//         errorMessage =
//             'លេខសម្ងាត់មិនត្រឹមត្រូវ។ អាចព្យាយាម​ ${3 - failedAttempts} ដងទៀត';
//       }
//     }
//   }
// }

// //Correct with 307 line code changes

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/widgets/attemp_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/passcode.dart';
import '../widgets/Dialog_Success.dart';
import '../utils/encryption.dart';
import '../services/user_server.dart';

class PasscodeService {
  static int failedAttempts = 0;
  static String? errorMessage;

  static Future<bool> requireUnlock(
    BuildContext context, {
    bool setExpiration = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final token = prefs.getString('token') ?? '';

    // Check for lockout first
    final lockoutUntil = prefs.getInt('passcode_lockout_until') ?? 0;
    if (lockoutUntil > nowMillis) {
      final secondsLeft = ((lockoutUntil - nowMillis) / 1000).ceil();
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LockTimerDialog(initialSeconds: secondsLeft),
      );
      return false;
    }

    // Get current failed attempts
    final currentAttempts = prefs.getInt('passcode_failed_attempts') ?? 0;

    // Check if this is after a lockout - if so, user gets only 1 attempt
    final wasLockedOut = prefs.getBool('was_locked_out') ?? false;

    // Always get latest profile to check passcode status
    try {
      final userProfile = await ApiService.getUserProfile(token);
      // ignore: unnecessary_null_comparison
      if (userProfile != null && userProfile['success'] == true) {
        final userData = userProfile['data'];
        print('🔐 DEBUG: User profile data: $userData');

        // Check both possible fields until we know which one is used
        final passcodeValue = userData['passcode'] ?? userData['passcode_hash'];
        final hasPasscode =
            (passcodeValue != null &&
                passcodeValue.toString() != '0' &&
                passcodeValue.toString().isNotEmpty);

        print(
          '🔐 DEBUG: Passcode status - value: $passcodeValue, hasPasscode: $hasPasscode',
        );

        // Update shared preferences
        await prefs.setBool('hasPasscode', hasPasscode);

        if (!hasPasscode) {
          return await _createPasscodeFlow(
            context,
            prefs,
            token,
            setExpiration,
          );
        } else {
          // Usual verify flow with current attempts
          bool unlocked = await _verifyPasscodeFlow(
            context,
            prefs,
            token,
            setExpiration,
            currentAttempts: currentAttempts,
            wasLockedOut: wasLockedOut,
          );

          return unlocked;
        }
      }
    } catch (e) {
      // Fallback to stored preference
      final hasPasscodePref = prefs.getBool('hasPasscode') ?? false;
      if (!hasPasscodePref) {
        return await _createPasscodeFlow(context, prefs, token, setExpiration);
      } else {
        return await _verifyPasscodeFlow(
          context,
          prefs,
          token,
          setExpiration,
          currentAttempts: currentAttempts,
          wasLockedOut: wasLockedOut,
        );
      }
    }

    return false;
  }

  static Future<bool> _createPasscodeFlow(
    BuildContext context,
    SharedPreferences prefs,
    String token,
    bool setExpiration,
  ) async {
    final localeCode = context.locale.languageCode;

    final code1 = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "PasscodeDialog",
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomPasscodeDialog(subtitle: "passcode.create".tr());
      },
    );

    if (code1 == null || code1.length != 4) return false;

    final code2 = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "PasscodeConfirmDialog",
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomPasscodeDialog(subtitle: "passcode.confirm".tr());
      },
    );

    if (code2 == null || code2.length != 4) return false;

    if (code1 != code2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("passcode.mismatch".tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    try {
      // Encrypt passcode using the same method as in your API
      final userId = prefs.getString('userId') ?? '';
      final encryptedPasscode = await encryptPasscodeForVerification(
        code1,
        userId,
      );

      debugPrint('🔐 DEBUG: User entered passcode for creation: "$code1"');
      debugPrint('🔐 DEBUG: Encrypting passcode for creation...');
      debugPrint('🔐 DEBUG: Encrypted passcode hash: "$encryptedPasscode"');
      debugPrint(
        '🔐 DEBUG: Hash length: ${encryptedPasscode.length} characters',
      );
      debugPrint('🌐 DEBUG: Starting passcode creation API call');
      debugPrint(
        '🌐 DEBUG: Token preview: ${token.substring(0, token.length > 10 ? 10 : token.length)}...',
      );
      debugPrint('🌐 DEBUG: Encrypted passcode to send: "$encryptedPasscode"');
      debugPrint('🌐 DEBUG: Passcode length: ${encryptedPasscode.length}');
      // Use the new API endpoint from your Postman collection

      final createResult = await ApiService.createPasscode(
        token,
        encryptedPasscode,
        encryptedPasscode,
      );
      // Add this debug log to see what the API returns
      debugPrint('🌐 DEBUG: Create passcode API response: $createResult');

      if (createResult['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => const SuccessDialog(
                message: "លេខសម្ងាត់របស់អ្នកបង្កើតបានជោគជ័យ!",
              ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context, rootNavigator: true).pop();
        });
        if (setExpiration) {
          final expires =
              DateTime.now()
                  .add(const Duration(minutes: 5))
                  .millisecondsSinceEpoch;
          await prefs.setInt('eye_window_expires_at', expires);
        }
        return true;
      } else {
        // Add detailed error logging
        debugPrint(
          '❌ DEBUG: Passcode creation failed: ${createResult['message']}',
        );
        debugPrint('❌ DEBUG: Full response: $createResult');
        // FIX: Handle the case where passcode already exists more robustly
        final errorMessage = (createResult['message'] ?? '').toLowerCase();

        if (errorMessage.contains('already setup') ||
            errorMessage.contains('already set up') ||
            errorMessage.contains('already exists')) {
          // Show informative message to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'passcode_already_set'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                ),
              ),
              backgroundColor: Colors.orange,
            ),
          );

          // Close the create dialog and immediately show verify dialog
          Navigator.of(context, rootNavigator: true).pop();

          // Directly call verify flow
          return await _verifyPasscodeFlow(
            context,
            prefs,
            token,
            setExpiration,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createResult['message'] ?? 'បង្កើតលេខសម្ងាត់បរាជ័យ'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("passcode.create_failed".tr()),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  static Future<bool> _verifyPasscodeFlow(
    BuildContext context,
    SharedPreferences prefs,
    String token,
    bool setExpiration, {
    int currentAttempts = 0,
    bool wasLockedOut = false,
  }) async {
    int maxAttempts = 3;
    bool unlocked = false;

    // Get current lockout level (0 = no lockout, 1 = 1 min, 2 = 2 min, etc.)
    int lockoutLevel = prefs.getInt('passcode_lockout_level') ?? 0;

    // Calculate lockout duration based on level
    Duration getLockoutDuration(int level) {
      switch (level) {
        case 1:
          return const Duration(minutes: 1);
        case 2:
          return const Duration(minutes: 2);
        case 3:
          return const Duration(minutes: 5);
        case 4:
          return const Duration(minutes: 10);
        case 5:
          return const Duration(minutes: 30);
        case 6:
          return const Duration(days: 1);
        default:
          return const Duration(minutes: 1);
      }
    }

    // If user was previously locked out, they only get 1 attempt now
    final remainingAttempts = wasLockedOut ? 1 : maxAttempts - currentAttempts;

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierLabel: "PasscodeVerify",
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (_, __, ___) {
        return CustomPasscodeDialog(
          subtitle: "passcode.verify".tr(),
          maxAttempts: maxAttempts,
          remainingAttempts: remainingAttempts,
          onValidate: (String code) async {
            final userId = prefs.getString('userId') ?? '';
            final encryptedPasscode = await encryptPasscodeForVerification(
              code,
              userId,
            );

            try {
              final verifyResult = await ApiService.verifyPasscode(
                token,
                encryptedPasscode,
              );
              if (verifyResult['success'] == true) {
                if (setExpiration) {
                  final expires =
                      DateTime.now()
                          .add(const Duration(minutes: 5))
                          .millisecondsSinceEpoch;
                  await prefs.setInt('passcode_unlock_at', expires);
                  await prefs.setInt('eye_window_expires_at', expires);
                }
                // Reset failed attempts and lockout flag on success
                await prefs.setInt('passcode_failed_attempts', 0);
                await prefs.setBool('was_locked_out', false);
                await prefs.setInt(
                  'passcode_lockout_level',
                  0,
                ); // Reset lockout level

                return true;
              }
            } catch (e) {
              // Optionally log error
            }

            // Increment failed attempts on failure
            final newAttempts =
                (prefs.getInt('passcode_failed_attempts') ?? 0) + 1;
            await prefs.setInt('passcode_failed_attempts', newAttempts);

            return false;
          },
        );
      },
    );

    // Check if dialog was closed due to max attempts reached
    if (result == 'max_attempts_reached') {
      // Increase lockout level
      lockoutLevel++;
      await prefs.setInt('passcode_lockout_level', lockoutLevel);

      // Calculate lockout duration based on level
      final lockoutDuration = getLockoutDuration(lockoutLevel);
      final lockoutUntil =
          DateTime.now().add(lockoutDuration).millisecondsSinceEpoch;

      await prefs.setInt('passcode_lockout_until', lockoutUntil);
      // Set lockout flag so user only gets 1 attempt next time
      await prefs.setBool('was_locked_out', true);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) =>
                LockTimerDialog(initialSeconds: lockoutDuration.inSeconds),
      );
      return false;
    } else if (result != null) {
      // Success case - result contains the passcode
      unlocked = true;
      // Reset lockout flags on success
      await prefs.setBool('was_locked_out', false);
      await prefs.setInt('passcode_lockout_level', 0); // Reset lockout level
    }

    return unlocked;
  }
  // static Future<bool> _verifyPasscodeFlow(
  //   BuildContext context,
  //   SharedPreferences prefs,
  //   String token,
  //   bool setExpiration, {
  //   int currentAttempts = 0,
  //   bool wasLockedOut = false,
  // }) async {
  //   int maxAttempts = 3;
  //   bool unlocked = false;

  //   // If user was previously locked out, they only get 1 attempt now
  //   final remainingAttempts = wasLockedOut ? 1 : maxAttempts - currentAttempts;

  //   final result = await showGeneralDialog<String>(
  //     context: context,
  //     barrierDismissible: false,
  //     barrierLabel: "PasscodeVerify",
  //     barrierColor: Colors.black.withOpacity(0.5),
  //     pageBuilder: (_, __, ___) {
  //       return CustomPasscodeDialog(
  //         subtitle: "passcode.verify".tr(),
  //         maxAttempts: maxAttempts,
  //         remainingAttempts: remainingAttempts,
  //         onValidate: (String code) async {
  //           final userId = prefs.getString('userId') ?? '';
  //           final encryptedPasscode = await encryptPasscodeForVerification(
  //             code,
  //             userId,
  //           );

  //           try {
  //             final verifyResult = await ApiService.verifyPasscode(
  //               token,
  //               encryptedPasscode,
  //             );
  //             if (verifyResult['success'] == true) {
  //               if (setExpiration) {
  //                 final expires =
  //                     DateTime.now()
  //                         .add(const Duration(minutes: 5))
  //                         .millisecondsSinceEpoch;
  //                 await prefs.setInt('passcode_unlock_at', expires);
  //                 await prefs.setInt('eye_window_expires_at', expires);
  //               }
  //               // Reset failed attempts and lockout flag on success
  //               await prefs.setInt('passcode_failed_attempts', 0);
  //               await prefs.setBool('was_locked_out', false);
  //               return true;
  //             }
  //           } catch (e) {
  //             // Optionally log error
  //           }

  //           // Increment failed attempts on failure
  //           final newAttempts =
  //               (prefs.getInt('passcode_failed_attempts') ?? 0) + 1;
  //           await prefs.setInt('passcode_failed_attempts', newAttempts);

  //           return false;
  //         },
  //       );
  //     },
  //   );

  //   // Check if dialog was closed due to max attempts reached
  //   if (result == 'max_attempts_reached') {
  //     // Lock user out for 10 seconds
  //     final lockoutUntil =
  //         DateTime.now()
  //             .add(const Duration(seconds: 10))
  //             .millisecondsSinceEpoch;
  //     await prefs.setInt('passcode_lockout_until', lockoutUntil);
  //     // Set lockout flag so user only gets 1 attempt next time
  //     await prefs.setBool('was_locked_out', true);

  //     await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => LockTimerDialog(initialSeconds: 10),
  //     );
  //     return false;
  //   } else if (result != null) {
  //     // Success case - result contains the passcode
  //     unlocked = true;
  //     // Reset lockout flag on success
  //     await prefs.setBool('was_locked_out', false);
  //   }

  //   return unlocked;
  // }
}

//Correct with 656 line code changes
