import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:gb_merchant/services/secure_storage_service.dart';

class QrCodeExtractor {
  static final SecureStorageService _storage = SecureStorageService();
  static String? _cachedSecretKey;

  /// Get secret key from secure storage
  static Future<String?> getSecretKey() async {
    if (_cachedSecretKey != null) {
      return _cachedSecretKey;
    }

    _cachedSecretKey = await _storage.getSecretKey();
    return _cachedSecretKey;
  }

  /// Check if code is valid based on natural code + signature only
  static Future<bool> isValidSignature(String fullCodeOrUrl) async {
    try {
      final secretKey = await getSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        if (kDebugMode) print('❌ Secret key is missing!');
        return false;
      }

      final naturalCode = extractNaturalCode(fullCodeOrUrl);
      final signature = extractSignature(fullCodeOrUrl);

      if (naturalCode.isEmpty || signature.isEmpty) return false;

      final expectedSig = generateSignature(naturalCode, secretKey);

      if (kDebugMode) {
        print('📝 Natural code: $naturalCode');
        print('🔖 Extracted signature: $signature');
        print('🎯 Expected signature: $expectedSig');
        print('✅ Match: ${signature == expectedSig}');
      }

      return signature == expectedSig;
    } catch (e) {
      if (kDebugMode) print('❌ Validation error: $e');
      return false;
    }
  }

  /// Generate signature for natural code - EXACT MATCH with Flask backend
  static String generateSignature(String naturalCode, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(naturalCode);
    final digest = Hmac(sha256, key).convert(bytes);

    // Step 1: Convert to URL-safe base64
    String signature = base64Url.encode(digest.bytes);

    // Step 2: Take first 7 characters (like Flask's [:7])
    signature = signature.substring(
      0,
      signature.length >= 7 ? 7 : signature.length,
    );

    // Step 3: Remove any non-alphanumeric characters
    signature = signature.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Step 4: Ensure exactly 7 chars (pad if shorter)
    if (signature.length < 7) {
      // Use bytes from position 10 to end (like Flask's hmac_digest[10:])
      final startIndex = 10;
      final endIndex = digest.bytes.length;
      final extraBytes = digest.bytes.sublist(
        startIndex,
        endIndex > startIndex + 17 ? startIndex + 17 : endIndex,
      );
      String extraSig = base64Url.encode(extraBytes);
      extraSig = extraSig.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      signature += extraSig.substring(
        0,
        (7 - signature.length).clamp(0, extraSig.length),
      );
    }

    // Step 5: Ensure exactly 7 characters
    if (signature.length > 7) {
      signature = signature.substring(0, 7);
    }

    return signature;
  }

  /// Extract natural code (first 11 chars) ignoring any domain
  static String extractNaturalCode(String codeOrUrl) {
    try {
      var codePart = codeOrUrl;
      if (codeOrUrl.contains('/t/')) {
        codePart = codeOrUrl.split('/t/').last;
      } else if (codeOrUrl.contains('/t=')) {
        codePart = codeOrUrl.split('/t=').last;
      }

      // Remove query params or fragments and ThankYou suffix
      codePart = codePart.split('?').first.split('#').first;

      // Remove ThankYou suffix if present (comma separator)
      if (codePart.contains(',')) {
        codePart = codePart.split(',').first;
      }

      if (codePart.length < 11) return '';
      return codePart.substring(0, 11);
    } catch (e) {
      return '';
    }
  }

  /// Extract signature (chars 11-18) ignoring domain
  static String extractSignature(String codeOrUrl) {
    try {
      var codePart = codeOrUrl;
      if (codeOrUrl.contains('/t/')) {
        codePart = codeOrUrl.split('/t/').last;
      } else if (codeOrUrl.contains('/t=')) {
        codePart = codeOrUrl.split('/t=').last;
      }

      // Remove query params or fragments and ThankYou suffix
      codePart = codePart.split('?').first.split('#').first;

      // Remove ThankYou suffix if present (comma separator)
      if (codePart.contains(',')) {
        codePart = codePart.split(',').first;
      }

      if (codePart.length < 18) return '';
      return codePart.substring(11, 18);
    } catch (e) {
      return '';
    }
  }

  /// Returns the full code (natural code + signature)
  static String extractFullCode(String codeOrUrl) {
    final natural = extractNaturalCode(codeOrUrl);
    final signature = extractSignature(codeOrUrl);
    if (natural.isEmpty || signature.isEmpty) return '';
    return '$natural$signature';
  }

  /// Check if code looks like URL format
  static bool isUrlFormat(String code) {
    return code.contains('/t/') || code.contains('/t=');
  }
}

// Correct with 157 line code changes
