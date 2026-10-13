import 'dart:async';
import 'package:flutter/material.dart';
import '../services/kaspot_service.dart';
import '../utils/auth_error_formatter.dart';
import '../widgets/kaspot_logo.dart';
import 'sign_in_screen.dart';

/// Screen displayed when registration requires email verification before access.
class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key, required this.email});

  final String email;

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  int _cooldownSeconds = 0;
  Timer? _timer;
  bool _busy = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0 || _busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      await KaSpotService.resendVerificationEmail(widget.email);
      _startCooldown();
      if (mounted) {
        setState(() {
          _statusMessage = 'A new confirmation email has been sent to ${widget.email}.';
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = AuthErrorFormatter.format(e);
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const KaSpotWordmark(fontSize: 20),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF5FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mail_outline_rounded, color: Color(0xFF1E60AA), size: 38),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Confirm Your Email',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                          children: [
                            const TextSpan(text: 'We sent a verification link to\n'),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                            const TextSpan(text: '.\nPlease tap the link in the email to activate your account.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_statusMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isError ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _isError ? const Color(0xFFDC2626) : const Color(0xFF065F46),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: (_cooldownSeconds > 0 || _busy) ? null : _resend,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E60AA),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E60AA)),
                                )
                              : Text(
                                  _cooldownSeconds > 0
                                      ? 'Resend in ${_cooldownSeconds}s'
                                      : 'Resend Verification Email',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const SignInScreen()),
                              (route) => route.isFirst,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E60AA),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Back to Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
