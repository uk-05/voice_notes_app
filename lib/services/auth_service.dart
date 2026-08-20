import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'database_service.dart';
import 'email_service.dart';

const _sessionUserIdKey = 'session_user_id';
const _otpValidity = Duration(minutes: 10);

/// Result of an auth attempt.
/// - success + needsVerification=false -> fully logged in
/// - success + needsVerification=true  -> account created/found but an OTP
///   was just sent; the UI should navigate to the OTP screen with `user`
/// - !success -> `error` has a human-readable reason
class AuthResult {
  final bool success;
  final bool needsVerification;
  final AppUser? user;
  final String? error;

  /// The OTP code, included so the UI can show it as a fallback if the
  /// email is slow to arrive (e.g. during a live demo/presentation).
  final String? otpForDemo;

  /// Whether the OTP email actually sent successfully. Only meaningful
  /// when [needsVerification] is true.
  final bool emailSent;

  /// Why the email failed to send, if it did — shown to the user so a
  /// silent failure doesn't just look like "nothing happened".
  final String? emailError;

  AuthResult.success(
    this.user, {
    this.needsVerification = false,
    this.otpForDemo,
    this.emailSent = true,
    this.emailError,
  })  : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        needsVerification = false,
        user = null,
        otpForDemo = null,
        emailSent = false,
        emailError = null;
}

/// Handles account creation, email OTP verification, login, logout, and
/// remembering who's logged in across app restarts.
///
/// NOTE: This is local-only auth (no server) — passwords are hashed with
/// SHA-256 + a static salt before being stored in sqflite. OTP codes and
/// notification emails are sent via Gmail SMTP (see email_service.dart /
/// config/email_config.dart). Good for a coursework/demo project; not
/// production-grade security for a networked app.
class AuthService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  AppUser? _currentUser;
  bool _isRestoringSession = true;
  String? sessionRestoreError;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isRestoringSession => _isRestoringSession;

  String _hashPassword(String password) {
    const salt = 'voice_notes_app_salt';
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  String _generateOtp() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  Future<({String code, bool emailSent, String? emailError})>
      _generateAndSendOtp(AppUser user) async {
    final code = _generateOtp();
    final expiresAt = DateTime.now().add(_otpValidity);

    // Save OTP first
    await _db.saveOtp(user.id!, code, expiresAt);

    // IMPORTANT: wait for email to actually send, and capture whether it
    // worked so the UI can tell the user if it didn't (instead of
    // silently failing).
    final sent = await EmailService.sendOtp(
      toEmail: user.email,
      name: user.name,
      otp: code,
    );

    return (code: code, emailSent: sent, emailError: EmailService.lastError);
  }

  /// Call once at app startup to see if someone's already logged in.
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_sessionUserIdKey);
      if (userId != null) {
        _currentUser = await _db.getUserById(userId);
      }
    } catch (e) {
      sessionRestoreError = e.toString();
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  /// Creates the account (unverified) and sends an OTP to their email.
  /// Does NOT log the user in yet — call [verifyOtp] with the code first.
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (name.trim().isEmpty || cleanEmail.isEmpty || password.isEmpty) {
      return AuthResult.failure('Please fill in all fields.');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return AuthResult.failure('Please enter a valid email.');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters.');
    }

    try {
      final existing = await _db.getUserByEmail(cleanEmail);
      if (existing != null) {
        return AuthResult.failure('An account with this email already exists.');
      }

      final user = AppUser(
        name: name.trim(),
        email: cleanEmail,
        passwordHash: _hashPassword(password),
        isVerified: false,
        createdAt: DateTime.now(),
      );
      final saved = await _db.insertUser(user);
      final otpResult = await _generateAndSendOtp(saved);
      return AuthResult.success(
        saved,
        needsVerification: true,
        otpForDemo: otpResult.code,
        emailSent: otpResult.emailSent,
        emailError: otpResult.emailError,
      );
    } catch (e) {
      return AuthResult.failure('Something went wrong: $e');
    }
  }

  /// Checks the OTP code the user entered. On success, marks the account
  /// verified, logs them in, and saves the session.
  Future<AuthResult> verifyOtp({
    required int userId,
    required String code,
  }) async {
    try {
      final stored = await _db.getOtp(userId);
      if (stored == null) {
        return AuthResult.failure(
            'No verification code found. Request a new one.');
      }
      final expiresAt = DateTime.parse(stored['expiresAt'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        return AuthResult.failure('This code has expired. Request a new one.');
      }
      if (stored['code'] != code.trim()) {
        return AuthResult.failure('Incorrect code. Please try again.');
      }

      await _db.markUserVerified(userId);
      await _db.deleteOtp(userId);

      final user = await _db.getUserById(userId);
      if (user == null) {
        return AuthResult.failure('Account not found.');
      }

      await _setSession(user.id!);
      _currentUser = user;
      notifyListeners();
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Something went wrong: $e');
    }
  }

  /// Sends a fresh OTP code (e.g. user tapped "Resend code").
  Future<AuthResult> resendOtp(AppUser user) async {
    try {
      final otpResult = await _generateAndSendOtp(user);
      return AuthResult.success(
        user,
        needsVerification: true,
        otpForDemo: otpResult.code,
        emailSent: otpResult.emailSent,
        emailError: otpResult.emailError,
      );
    } catch (e) {
      return AuthResult.failure('Could not resend code: $e');
    }
  }

  /// Logs in with email + password. If the account hasn't verified its
  /// email yet, sends a fresh OTP and returns needsVerification=true
  /// instead of logging in. On a normal successful login, also fires off
  /// a "new login" notification email.
  Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    try {
      final user = await _db.getUserByEmail(cleanEmail);

      if (user == null || user.passwordHash != _hashPassword(password)) {
        return AuthResult.failure('Incorrect email or password.');
      }

      if (!user.isVerified) {
        final otpResult = await _generateAndSendOtp(user);
        return AuthResult.success(
          user,
          needsVerification: true,
          otpForDemo: otpResult.code,
          emailSent: otpResult.emailSent,
          emailError: otpResult.emailError,
        );
      }

      await _setSession(user.id!);
      _currentUser = user;
      notifyListeners();

      // Fire-and-forget notification — never blocks login.
      unawaited(EmailService.sendLoginNotification(
        toEmail: user.email,
        name: user.name,
      ));

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Something went wrong: $e');
    }
  }

  Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _setSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionUserIdKey, userId);
  }
}
