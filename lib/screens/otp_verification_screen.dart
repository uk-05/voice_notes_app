import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notes_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final AppUser user;
  final String? initialDemoCode;
  final bool emailSent;
  final String? emailError;

  const OtpVerificationScreen({
    super.key,
    required this.user,
    this.initialDemoCode,
    this.emailSent = true,
    this.emailError,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;
  int _resendCooldown = 30;
  Timer? _timer;
  bool _emailSent = true;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailSent = widget.emailSent;
    _emailError = widget.emailError;
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showSnackBar('Enter the 6-digit code from your email.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthService>();
      final result = await auth.verifyOtp(userId: widget.user.id!, code: code);

      if (!mounted) return;

      if (result.success) {
        await context.read<NotesProvider>().setUser(result.user!.id);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(result.error ?? 'Verification failed.');
      }
    } catch (e) {
      _showSnackBar('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      final auth = context.read<AuthService>();
      final result = await auth.resendOtp(widget.user);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _emailSent = result.emailSent;
          _emailError = result.emailError;
        });
        _showSnackBar(
          result.emailSent
              ? 'A new code was sent to ${widget.user.email}.'
              : 'Could not email the code — use the one shown below.',
        );
        _startCooldown();
      } else {
        _showSnackBar(result.error ?? 'Could not resend code.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                'We sent a 6-digit code to\n${widget.user.email}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              if (!_emailSent) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.danger, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Could not send the email',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      if (_emailError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _emailError!,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _verify,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    (_resendCooldown > 0 || _isResending) ? null : _resend,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend code in ${_resendCooldown}s'
                      : (_isResending ? 'Sending...' : 'Resend code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
