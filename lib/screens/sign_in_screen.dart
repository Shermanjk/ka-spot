import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kaspot_service.dart';
import '../widgets/kaspot_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Clean, professional Sign-In screen with calm error reporting and accessible navigation.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_authError != null) {
      setState(() => _authError = null);
    }
  }

  Future<void> _submit() async {
    _clearError();
    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await KaSpotService.signIn(_email.text.trim(), _password.text);
      // On success, KaSpotService.authStateNotifier updates,
      // which automatically navigates to HomeShell via main.dart ValueListenableBuilder.
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      setState(() {
        if (msg.contains('invalid login credentials') || msg.contains('invalid') || msg.contains('not found')) {
          _authError = 'Incorrect email or password. Please check your credentials or create an account.';
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
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to stay connected with your circle.',
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
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter your email address.';
                            if (!v.contains('@') || !v.contains('.')) return 'Enter a complete email address.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your password.';
                            return null;
                          },
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim()),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Sign In Submit Button
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
                                    'Sign In',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Path to Create Account
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterScreen(initialEmail: _email.text.trim()),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                                children: [
                                  TextSpan(text: 'New to KaSpot? '),
                                  TextSpan(
                                    text: 'Create an account',
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
