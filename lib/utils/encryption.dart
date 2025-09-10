import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

String deriveKeyFromUserID(String userId) {
  final hash = sha256.convert(utf8.encode(userId));
  return base64UrlEncode(hash.bytes.sublist(0, 16)); // 16 bytes = 128 bits
}

String deriveIVFromUserID(String userId) {
  // Use a different part of the hash or a different derivation method for IV
  final hash = sha256.convert(utf8.encode(userId));
  return base64UrlEncode(hash.bytes.sublist(16, 32)); // Use bytes 16-31 for IV
}

Future<String> encryptPasscodeForVerification(
  String passcode,
  String userId,
) async {
  debugPrint('🔐 DEBUG: Encrypting passcode for user ID: $userId');
  debugPrint('🔐 DEBUG: Plain passcode: $passcode');

  final derivedKey = deriveKeyFromUserID(userId);
  final derivedIV = deriveIVFromUserID(userId); // Get deterministic IV

  final key = encrypt.Key(base64Url.decode(derivedKey));
  final iv = encrypt.IV(base64Url.decode(derivedIV)); // Use the derived IV

  final encrypter = encrypt.Encrypter(
    encrypt.AES(key, mode: encrypt.AESMode.cbc),
  );
  final encrypted = encrypter.encrypt(passcode, iv: iv);

  return base64Encode(encrypted.bytes);
}

//Correct with 38 line code changes
