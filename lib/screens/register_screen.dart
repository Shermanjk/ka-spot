import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kaspot_service.dart';
import '../widgets/kaspot_logo.dart';
import 'sign_in_screen.dart';
import 'verification_pending_screen.dart';

/// Clean, professional Registration screen with structured validation,
/// calm error reporting, and explicit privacy reassurance.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_authError != null) {
      setState(() => _authError = null);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    final trimmed = value.trim();
    if (!trimmed.contains('@')) {
      return 'Email must include "@" (e.g. name@gmail.com).';
    }
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[0].isEmpty) {
      return 'Enter a valid username before the "@".';
    }
    if (!parts[1].contains('.')) {
      return 'Enter a complete domain with extension (e.g. @gmail.com).';
    }
    final domainParts = parts[1].split('.');
    if (domainParts.any((part) => part.isEmpty)) {
      return 'Domain cannot contain empty or trailing dots.';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid, complete email address.';
    }
    return null;
  }

  Future<void> _submit() async {
    _clearError();
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final result = await KaSpotService.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );

      if (!mounted) return;

      if (result.requiresEmailConfirmation) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationPendingScreen(
              email: result.email ?? _email.text.trim(),
            ),
          ),
        );
      } else if (result.isSessionActive) {
        // Pop all pushed auth screens back to root; ValueListenableBuilder renders HomeShell
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      setState(() {
        if (msg.contains('already') || msg.contains('exists')) {
          _authError = 'An account with this email already exists. Please sign in instead.';
        } else {
          _authError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _authError = e.toString().replaceFirst('Exception: ', '');
      });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Keep your circle close, on your terms.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 20),

                        // Calm, Single Authentication Error Banner
                        if (_authError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _authError!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _authError = null),
                                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF991B1B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Full Name Field
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your full name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Email Field
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            helperText: 'Must be at least 8 characters',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter a password.';
                            if (v.length < 8) return 'Password must be at least 8 characters.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPassword,
                          obscureText: _obscureConfirm,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirm your password.';
                            if (v != _password.text) return 'Passwords do not match.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Privacy Reassurance Notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 18, color: Color(0xFF1E60AA)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'We will never share your location without your explicit permission.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Register Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1E60AA),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Path to Sign In
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignInScreen(initialEmail: _email.text.trim()),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E60AA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}
