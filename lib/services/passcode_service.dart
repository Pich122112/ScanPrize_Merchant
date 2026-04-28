import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/widgets/attemp_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/passcode.dart';
import '../utils/encryption.dart';
import '../services/user_server.dart';
import 'secure_storage_service.dart';
import 'package:flutter/foundation.dart';

class PasscodeService {
  static int failedAttempts = 0;
  static String? errorMessage;

  static Future<bool> requireUnlock(
    BuildContext context, {
    bool setExpiration = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = SecureStorageService();
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final token = await secureStorage.getToken() ?? '';

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

        final passcodeValue = userData['passcode'] ?? userData['passcode_hash'];
        final hasPasscode =
            (passcodeValue != null &&
                passcodeValue.toString() != '0' &&
                passcodeValue.toString().isNotEmpty);

        if (kDebugMode) {
          print('🔐 DEBUG: User profile retrieved');
          print('🔐 DEBUG: Passcode status checked');
        }

        await prefs.setBool('hasPasscode', hasPasscode);

        if (!hasPasscode) {
          return await _createPasscodeFlow(
            context,
            prefs,
            token,
            setExpiration,
          );
        } else {
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
    final secureStorage = SecureStorageService();

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
      final userId = await secureStorage.getUserId() ?? '';
      final encryptedPasscode = await encryptPasscodeForVerification(
        code1,
        userId,
      );

      if (kDebugMode) {
        debugPrint('🔐 Creating passcode...');
        debugPrint('🌐 API call started');
        debugPrint('📡 Response received');
      }

      final createResult = await ApiService.createPasscode(
        token,
        encryptedPasscode,
        encryptedPasscode,
      );

      if (createResult['success'] == true) {
        // Do NOT show dialog. Proceed immediately.
        if (setExpiration) {
          final expires =
              DateTime.now()
                  .add(const Duration(minutes: 10))
                  .millisecondsSinceEpoch;
          await prefs.setInt('eye_window_expires_at', expires);
        }
        // Return to unlock flow, caller will show transfer animation immediately
        return true;
      } else {
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
      if (kDebugMode) {
        debugPrint('❌ Passcode creation error');
      }
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
    final secureStorage = SecureStorageService(); 

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
            final userId = await secureStorage.getUserId() ?? '';
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
                          .add(const Duration(minutes: 10))
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
      unlocked = true;
      await prefs.setBool('was_locked_out', false);
      await prefs.setInt('passcode_lockout_level', 0);
    }

    return unlocked;
  }
}

//Correct with 354 line code changes
