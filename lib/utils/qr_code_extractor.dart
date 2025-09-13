import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrCodeExtractor {
  // ⚠️ MUST match your Flask app's SECRET_KEY!
  static const String secretKey =
      'K8r\$1!dJ2x^Lz#Wm9QpVt@7f&uYiHcZsBnOa4Xg5Ej6Rk3Tl';

  static bool isValidSignature(String fullUrl) {
    try {
      final naturalCode = extractNaturalCode(fullUrl);
      final providedSignature = extractSignature(fullUrl);

      if (naturalCode.isEmpty || providedSignature.isEmpty) {
        return false;
      }

      // Generate expected signature locally
      String expectedSignature = generateSignature(naturalCode);
      return providedSignature == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  static String generateSignature(String naturalCode) {
    // Create HMAC-SHA256 (same as your Flask app)
    var key = utf8.encode(secretKey);
    var bytes = utf8.encode(naturalCode);
    var hmac = Hmac(sha256, key);
    var digest = hmac.convert(bytes);

    // Convert to base64Url and take first 7 characters (same as Flask)
    String base64Sig = base64Url.encode(digest.bytes);
    String signature = base64Sig.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Padding logic (same as Flask)
    if (signature.length < 7) {
      var extraBytes = digest.bytes.sublist(10, 17);
      String extraSig = base64Url
          .encode(extraBytes)
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      signature += extraSig;
    }

    return signature.substring(0, 7);
  }

  // Extract natural code from URL format: https://gbz.app/t/GAC000D232A08heEiW
  static String extractNaturalCode(String fullUrl) {
    try {
      // Handle different URL formats
      String codePart;

      if (fullUrl.contains('https://gbz.app/t/')) {
        codePart = fullUrl.split('https://gbz.app/t/').last;
      } else if (fullUrl.contains('https://gbz.app/t=')) {
        codePart = fullUrl.split('https://gbz.app/t=').last;
      } else {
        // If it's not a URL, assume it's already the code part
        codePart = fullUrl;
      }

      // Remove any query parameters or fragments
      codePart = codePart.split('?').first;
      codePart = codePart.split('#').first;

      // Split by comma to separate code from ThankYou/spaces
      final parts = codePart.split(',');
      if (parts.isEmpty) return '';

      final actualCode = parts[0];
      if (actualCode.length < 11) return '';

      return actualCode.substring(
        0,
        11,
      ); // Return first 11 chars (natural code)
    } catch (e) {
      return '';
    }
  }

  static String extractFullCode(String fullUrl) {
    try {
      String codePart;
      if (fullUrl.contains('https://gbz.app/t/')) {
        codePart = fullUrl.split('https://gbz.app/t/').last;
      } else if (fullUrl.contains('https://gbz.app/t=')) {
        codePart = fullUrl.split('https://gbz.app/t=').last;
      } else {
        codePart = fullUrl;
      }
      codePart = codePart.split('?').first;
      codePart = codePart.split('#').first;
      final parts = codePart.split(',');
      if (parts.isEmpty) return '';
      final actualCode = parts[0];
      return actualCode.trim(); // This returns code+signature
    } catch (e) {
      return '';
    }
  }

  // Extract signature from URL format
  static String extractSignature(String fullUrl) {
    try {
      String codePart;

      if (fullUrl.contains('https://gbz.app/t/')) {
        codePart = fullUrl.split('https://gbz.app/t/').last;
      } else if (fullUrl.contains('https://gbz.app/t=')) {
        codePart = fullUrl.split('https://gbz.app/t=').last;
      } else {
        codePart = fullUrl;
      }

      // Remove any query parameters or fragments
      codePart = codePart.split('?').first;
      codePart = codePart.split('#').first;

      // Split by comma to separate code from ThankYou/spaces
      final parts = codePart.split(',');
      if (parts.isEmpty) return '';

      final actualCode = parts[0];
      if (actualCode.length < 18) return '';

      return actualCode.substring(11, 18); // Return chars 11-17 (signature)
    } catch (e) {
      return '';
    }
  }

  // Check if the scanned code is in the new URL format
  static bool isUrlFormat(String code) {
    return code.contains('https://gbz.app/t/') ||
        code.contains('https://gbz.app/t=');
  }
}

//Correct with 142 line code changes
