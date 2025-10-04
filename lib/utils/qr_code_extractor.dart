import 'dart:convert';
import 'package:crypto/crypto.dart';

class QrCodeExtractor {
  // ⚠️ MUST match your Flask app's SECRET_KEY!
  static const String secretKey =
      'K8r\$1!dJ2x^Lz#Wm9QpVt@7f&uYiHcZsBnOa4Xg5Ej6Rk3Tl';

  /// Check if code is valid based on natural code + signature only
  static bool isValidSignature(String fullCodeOrUrl) {
    try {
      final naturalCode = extractNaturalCode(fullCodeOrUrl);
      final signature = extractSignature(fullCodeOrUrl);

      if (naturalCode.isEmpty || signature.isEmpty) return false;

      final expectedSig = generateSignature(naturalCode);
      return signature == expectedSig;
    } catch (e) {
      return false;
    }
  }

  /// Generate signature for natural code
  static String generateSignature(String naturalCode) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(naturalCode);
    final digest = Hmac(sha256, key).convert(bytes);

    var sig = base64Url
        .encode(digest.bytes)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (sig.length < 7) {
      final extra = digest.bytes.sublist(10, 17);
      sig += base64Url.encode(extra).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    }
    return sig.substring(0, 7);
  }

  /// Extract natural code (first 11 chars) ignoring any domain
  static String extractNaturalCode(String codeOrUrl) {
    try {
      // Strip URL if exists
      var codePart = codeOrUrl;
      if (codeOrUrl.contains('/t/')) {
        codePart = codeOrUrl.split('/t/').last;
      } else if (codeOrUrl.contains('/t=')) {
        codePart = codeOrUrl.split('/t=').last;
      }

      // Remove query params or fragments
      codePart = codePart.split('?').first.split('#').first;

      if (codePart.length < 11) return '';
      return codePart.substring(0, 11); // natural code only
    } catch (e) {
      return '';
    }
  }

  /// Extract signature (chars 11-17) ignoring domain
  static String extractSignature(String codeOrUrl) {
    try {
      var codePart = codeOrUrl;
      if (codeOrUrl.contains('/t/')) {
        codePart = codeOrUrl.split('/t/').last;
      } else if (codeOrUrl.contains('/t=')) {
        codePart = codeOrUrl.split('/t=').last;
      }

      codePart = codePart.split('?').first.split('#').first;

      if (codePart.length < 18) return '';
      return codePart.substring(11, 18); // signature only
    } catch (e) {
      return '';
    }
  }

  /// Returns the full code (natural code + signature)
  static String extractFullCode(String codeOrUrl) {
    final natural = extractNaturalCode(codeOrUrl);
    final signature = extractSignature(codeOrUrl);
    if (natural.isEmpty || signature.isEmpty) return '';
    return '$natural$signature'; // 11 + 7 chars
  }

  /// Check if code looks like URL format (optional, can ignore domain)
  static bool isUrlFormat(String code) {
    return code.contains('/t/');
  }
}

//Correct with 94 line code changes

// class QrCodeExtractor {
//   // ⚠️ MUST match your Flask app's SECRET_KEY!
//   static const String secretKey =
//       'K8r\$1!dJ2x^Lz#Wm9QpVt@7f&uYiHcZsBnOa4Xg5Ej6Rk3Tl';

//   static bool isValidSignature(String fullUrl) {
//     try {
//       final naturalCode = extractNaturalCode(fullUrl);
//       final providedSignature = extractSignature(fullUrl);

//       if (naturalCode.isEmpty || providedSignature.isEmpty) {
//         return false;
//       }

//       // Generate expected signature locally
//       String expectedSignature = generateSignature(naturalCode);
//       return providedSignature == expectedSignature;
//     } catch (e) {
//       return false;
//     }
//   }

//   static String generateSignature(String naturalCode) {
//     // Create HMAC-SHA256 (same as your Flask app)
//     var key = utf8.encode(secretKey);
//     var bytes = utf8.encode(naturalCode);
//     var hmac = Hmac(sha256, key);
//     var digest = hmac.convert(bytes);

//     // Convert to base64Url and take first 7 characters (same as Flask)
//     String base64Sig = base64Url.encode(digest.bytes);
//     String signature = base64Sig.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

//     // Padding logic (same as Flask)
//     if (signature.length < 7) {
//       var extraBytes = digest.bytes.sublist(10, 17);
//       String extraSig = base64Url
//           .encode(extraBytes)
//           .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
//       signature += extraSig;
//     }

//     return signature.substring(0, 7);
//   }

//   // Extract natural code from URL format: https://web.sandbox.gzb.app/t/GAC000D232A08heEiW
//   static String extractNaturalCode(String fullUrl) {
//     try {
//       // Handle different URL formats
//       String codePart;

//       // new code scan format:  https://web.sandbox.gzb.app/t
//       if (fullUrl.contains('https://web.sandbox.gzb.app/t/')) {
//         codePart = fullUrl.split('https://web.sandbox.gzb.app/t/').last;
//       } else if (fullUrl.contains('https://web.sandbox.gzb.app/t=')) {
//         codePart = fullUrl.split('https://web.sandbox.gzb.app/t=').last;
//       } else {
//         // If it's not a URL, assume it's already the code part
//         codePart = fullUrl;
//       }

//       // Remove any query parameters or fragments
//       codePart = codePart.split('?').first;
//       codePart = codePart.split('#').first;

//       // Split by comma to separate code from ThankYou/spaces
//       final parts = codePart.split(',');
//       if (parts.isEmpty) return '';

//       final actualCode = parts[0];
//       if (actualCode.length < 11) return '';

//       return actualCode.substring(
//         0,
//         11,
//       ); // Return first 11 chars (natural code)
//     } catch (e) {
//       return '';
//     }
//   }

//   static String extractFullCode(String fullUrl) {
//     try {
//       String codePart;
//       if (fullUrl.contains('https://web.sandbox.gzb.app/t/')) {
//         codePart = fullUrl.split('https://web.sandbox.gzb.app/t/').last;
//       } else if (fullUrl.contains('https://web.sandbox.gzb.app/t=')) {
//         codePart = fullUrl.split('https://web.sandbox.gzb.app/t=').last;
//       } else {
//         codePart = fullUrl;
//       }
//       codePart = codePart.split('?').first;
//       codePart = codePart.split('#').first;
//       final parts = codePart.split(',');
//       if (parts.isEmpty) return '';
//       final actualCode = parts[0];
//       return actualCode.trim(); // This returns code+signature
//     } catch (e) {
//       return '';
//     }
//   }

//   // Extract signature from URL format
//   static String extractSignature(String fullUrl) {
//     try {
//       String codePart;

//       if (fullUrl.contains('https://web.sandbox.gzb.app/t/')) {
//         codePart = fullUrl.split('https://web.sandbox.gzb.app/t/').last;
//       } else if (fullUrl.contains('https://web.sandbox.gzb.app/t=')) {
//         codePart = fullUrl.split('https://web.sandbox.gzb.app/t=').last;
//       } else {
//         codePart = fullUrl;
//       }

//       // Remove any query parameters or fragments
//       codePart = codePart.split('?').first;
//       codePart = codePart.split('#').first;

//       // Split by comma to separate code from ThankYou/spaces
//       final parts = codePart.split(',');
//       if (parts.isEmpty) return '';

//       final actualCode = parts[0];
//       if (actualCode.length < 18) return '';

//       return actualCode.substring(11, 18); // Return chars 11-17 (signature)
//     } catch (e) {
//       return '';
//     }
//   }

//   // Check if the scanned code is in the new URL format
//   static bool isUrlFormat(String code) {
//     return code.contains('https://web.sandbox.gzb.app/t/') ||
//         code.contains('https://web.sandbox.gzb.app/t=');
//   }
// }

//Correct with 142 line code changes
