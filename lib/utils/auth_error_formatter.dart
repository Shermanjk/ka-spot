import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized utility to transform backend auth exceptions into clean,
/// professional, human-readable user error messages.
///
/// Prevents raw developer exceptions (e.g. AuthApiException, statusCode: 429, PlatformException)
/// from leaking into the user interface.
class AuthErrorFormatter {
  AuthErrorFormatter._();

  /// Guidance shown when Supabase rejects a password sign-in. It never claims
  /// the account is missing — Google-only accounts legitimately have no KaSpot
  /// password, and enumerating accounts is avoided on purpose.
  static const String invalidCredentialsMessage =
      'Incorrect email or password. If you created this account with Google, use "Continue with Google" instead — or tap "Forgot password?" to set a KaSpot password.';

  /// Converts any exception or error object into a user-friendly message.
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final rawString = error.toString();
    final lower = rawString.toLowerCase();

    // 0. Google Sign-In PlatformException handling. Cancellation is checked
    // first: a cancelled picker may embed arbitrary digits (including "10")
    // in its raw text and must never be misread as a configuration error.
    if (error is PlatformException || lower.contains('platformexception')) {
      if (lower.contains('sign_in_canceled') ||
          lower.contains('sign_in_cancelled') ||
          lower.contains('12501') ||
          lower.contains('canceled') ||
          lower.contains('cancelled')) {
        return 'Google sign-in was cancelled.';
      }
      if (lower.contains('developer_error') || _containsStandaloneNumber(lower, 10)) {
        // Developer detail stays in the console — SHA-1 fingerprints and
        // Cloud Console instructions must never reach the UI.
        debugPrint(
          '[AuthErrorFormatter] Google Sign-In DEVELOPER_ERROR (Code 10): the Android OAuth client is likely misconfigured. Verify the app SHA-1 fingerprint in Google Cloud Console. Raw error: $rawString',
        );
        return 'Google sign-in could not be completed right now. Please try again in a moment, or use email sign-in instead.';
      }
      if (lower.contains('network_error') || _containsStandaloneNumber(lower, 7)) {
        return 'Network error connecting to Google. Please check your internet connection.';
      }
      return 'Google sign-in failed. Please verify your Google account and try again.';
    }

    // 1. Rate Limiting (HTTP 429 / over_email_send_rate_limit)
    if (lower.contains('over_email_send_rate_limit') ||
        lower.contains('rate limit') ||
        lower.contains('security purposes') ||
        lower.contains('statuscode: 429') ||
        lower.contains('429')) {
      // Extract remaining seconds if mentioned in the message
      final secondsMatch = RegExp(r'after\s+(\d+)\s+seconds', caseSensitive: false).firstMatch(rawString);
      if (secondsMatch != null) {
        final sec = secondsMatch.group(1);
        return 'For security, please wait $sec seconds before requesting another email.';
      }
      return 'For security, please wait a minute before trying again.';
    }

    // 2. Invalid Credentials / Wrong password / Google-only account
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid_grant') ||
        lower.contains('user not found') ||
        lower.contains('not found')) {
      return invalidCredentialsMessage;
    }

    // 3. Email Not Confirmed
    if (lower.contains('email not confirmed')) {
      return 'This email address has not been confirmed yet. Please verify your inbox to continue.';
    }

    // 4. Duplicate / Existing Account
    if (lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('user already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    // 5. Password Complexity / Length
    if (lower.contains('password should be at least') || lower.contains('weak password')) {
      return 'Password must be at least 8 characters long.';
    }

    // 6. Network & Connectivity
    if (lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('connection refused') ||
        lower.contains('timed out') ||
        lower.contains('clientexception')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }

    // 7. Supabase AuthException fallback
    if (error is AuthException && error.message.isNotEmpty) {
      final msg = error.message.trim();
      // If message is technical, sanitize it
      if (msg.contains('AuthApiException') || msg.contains('statusCode')) {
        return 'Authentication failed. Please verify your credentials and try again.';
      }
      return msg;
    }

    // Clean any 'Exception: ' or 'AuthException: ' prefixes
    String cleaned = rawString
        .replaceFirst(RegExp(r'^(Exception|AuthException|AuthApiException):\s*', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty || cleaned.contains('statusCode:') || cleaned.contains('AuthApiException(')) {
      return 'Authentication request could not be completed. Please try again.';
    }

    return cleaned;
  }

  /// True when [number] appears as a standalone token — not embedded inside a
  /// larger number such as "1000" or "12501". Platform exception codes are
  /// bare numbers, so a plain substring check produced false positives.
  static bool _containsStandaloneNumber(String lower, int number) {
    return RegExp(r'(^|[^0-9])' '$number' r'([^0-9]|$)').hasMatch(lower);
  }
}
