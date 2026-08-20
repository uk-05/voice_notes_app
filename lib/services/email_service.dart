import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config/email_config.dart';

/// Sends real emails via Gmail SMTP using the `mailer` package.
/// Used for: OTP verification codes on signup, and login/download
/// notification emails.
///
/// All sends are wrapped in try/catch — a failed email should never crash
/// the app or block the user's flow (e.g. login still succeeds even if the
/// notification email fails to send, say due to no internet).
class EmailService {
  /// Set after every send attempt — null on success, the exception text
  /// on failure, so callers (like the OTP screen) can show *why* an email
  /// didn't arrive instead of just silently falling back.
  static String? lastError;

  static SmtpServer get _server => gmail(
        EmailConfig.senderEmail,
        EmailConfig.senderPassword,
      );

  static Future<bool> _send(String toEmail, String subject, String text) async {
    if (EmailConfig.senderEmail == 'your_email@gmail.com') {
      // Config not filled in yet — don't attempt to send, just log it so
      // signup/login flows still work during development.
      lastError = 'Email not configured yet (lib/config/email_config.dart).';
      debugPrint(
        'EmailService: senderEmail not configured, skipping email. '
        'Would have sent "$subject" to $toEmail.',
      );
      return false;
    }

    final message = Message()
      ..from = const Address(EmailConfig.senderEmail, EmailConfig.senderName)
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = text;

    try {
      await send(message, _server);
      lastError = null;
      debugPrint('EmailService: sent "$subject" to $toEmail successfully.');
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('EmailService: failed to send "$subject" to $toEmail: $e');
      return false;
    }
  }

  static Future<bool> sendOtp({
    required String toEmail,
    required String name,
    required String otp,
  }) {
    return _send(
      toEmail,
      'Your Voice Notes verification code',
      'Hi $name,\n\n'
          'Your verification code is: $otp\n\n'
          'Enter this code in the app to finish creating your account. '
          'This code expires in 10 minutes.\n\n'
          'If you did not request this, you can ignore this email.',
    );
  }

  static Future<bool> sendLoginNotification({
    required String toEmail,
    required String name,
  }) {
    final now = DateTime.now();
    return _send(
      toEmail,
      'New login to your Voice Notes account',
      'Hi $name,\n\n'
          'Your Voice Notes account was just logged into on '
          '${now.toString().split('.').first}.\n\n'
          'If this wasn\'t you, consider changing your password.',
    );
  }

  static Future<bool> sendHistoryDownloadNotification({
    required String toEmail,
    required String name,
    required int noteCount,
  }) {
    final now = DateTime.now();
    return _send(
      toEmail,
      'Your Voice Notes history was downloaded',
      'Hi $name,\n\n'
          'Your notes history ($noteCount notes) was downloaded on '
          '${now.toString().split('.').first}.\n\n'
          'If this wasn\'t you, consider changing your password.',
    );
  }
}
