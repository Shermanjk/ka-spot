import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kaspot_service.dart';
import '../utils/auth_error_formatter.dart';
import '../utils/email_validator.dart';
import '../widgets/google_sign_in_button.dart';
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

/// Which action is currently in flight on the Sign In screen. Exactly one
/// control renders its progress indicator; every other action is disabled but
/// keeps its label.
enum _BusyAction { none, password, google, resend }

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();
  _BusyAction _busyAction = _BusyAction.none;
  bool get _busy => _busyAction != _BusyAction.none;
  bool _obscure = true;
  String? _authError;
  String? _emailError;
  String? _passwordError;
  String? _resendSuccess;
  bool _isUnconfirmed = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

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
    if (_authError != null ||
        _emailError != null ||
        _passwordError != null ||
        _resendSuccess != null ||
        _isUnconfirmed) {
      setState(() {
        _authError = null;
        _emailError = null;
        _passwordError = null;
        _resendSuccess = null;
        _isUnconfirmed = false;
      });
    }
  }

  Future<void> _submit() async {
    _clearError();
    setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
    if (!_form.currentState!.validate()) return;

    setState(() => _busyAction = _BusyAction.password);
    try {
      await KaSpotService.signIn(_email.text.trim(), _password.text);
      if (!mounted) return;
      // Pop all pushed auth screens back to root; ValueListenableBuilder renders HomeShell
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      setState(() {
        // Account-level errors belong to the single banner only: duplicated
        // per-field variants would misattribute network or Google issues to
        // the email field.
        _emailError = null;
        _passwordError = null;
        if (msg.contains('email not confirmed')) {
          _isUnconfirmed = true;
          _authError = 'Your email address has not been confirmed yet. Please verify your inbox to continue.';
        } else if (msg.contains('invalid login credentials') ||
            msg.contains('invalid credentials') ||
            msg.contains('invalid') ||
            msg.contains('not found')) {
          // Never claim the account is missing: it may exist with a Google
          // credential that simply has no KaSpot password yet.
          _isUnconfirmed = false;
          _authError = AuthErrorFormatter.invalidCredentialsMessage;
        } else {
          _isUnconfirmed = false;
          _authError = AuthErrorFormatter.format(e);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUnconfirmed = false;
        _emailError = null;
        _passwordError = null;
        _authError = AuthErrorFormatter.format(e);
      });
    } finally {
      if (mounted) setState(() => _busyAction = _BusyAction.none);
    }
  }

  Future<void> _resendVerification() async {
    final cleanEmail = _email.text.trim();
    if (cleanEmail.isEmpty) return;
    setState(() {
      _busyAction = _BusyAction.resend;
      _resendSuccess = null;
    });
    try {
      await KaSpotService.resendVerificationEmail(cleanEmail);
      if (mounted) {
        setState(() {
          _resendSuccess = 'Confirmation email sent to $cleanEmail! Please check your inbox.';
          _authError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authError = AuthErrorFormatter.format(e);
        });
      }
    } finally {
      if (mounted) setState(() => _busyAction = _BusyAction.none);
    }
  }

  Future<void> _signInWithGoogle() async {
    _clearError();
    setState(() => _busyAction = _BusyAction.google);
    try {
      await KaSpotService.signInWithGoogle();
      if (!mounted) return;
      if (KaSpotService.isAuthenticated) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _authError = AuthErrorFormatter.format(e));
      }
    } finally {
      if (mounted) setState(() => _busyAction = _BusyAction.none);
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
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: KaSpotWordmark(fontSize: 32),
                          ),
                        ),
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

                        // 1-Tap Google Sign-In Shortcut
                        GoogleSignInButton(
                          onPressed: _busy ? null : _signInWithGoogle,
                          busy: _busyAction == _BusyAction.google,
                          label: 'Continue with Google',
                          busyLabel: 'Signing in…',
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Resend Success Banner
                        if (_resendSuccess != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _resendSuccess!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF065F46),
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Calm, Single Authentication Error Banner
                        if (_authError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
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
                                      onTap: () => setState(() {
                                        _authError = null;
                                        _emailError = null;
                                        _passwordError = null;
                                        _isUnconfirmed = false;
                                      }),
                                      child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF991B1B)),
                                    ),
                                  ],
                                ),
                                if (_isUnconfirmed) ...[
                                  const SizedBox(height: 10),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: _busy ? null : _resendVerification,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFFCA5A5)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.mark_email_read_outlined, size: 16, color: Color(0xFFDC2626)),
                                          const SizedBox(width: 6),
                                          Text(
                                            _busyAction == _BusyAction.resend ? 'Sending link...' : 'Resend Confirmation Email Now',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                          autovalidateMode: _autoValidateMode,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Email address',
                            errorText: _emailError,
                            errorMaxLines: 3,
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                              color: _emailError != null ? const Color(0xFFDC2626) : null,
                            ),
                            filled: true,
                            fillColor: _emailError != null ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _emailError != null ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                                width: _emailError != null ? 1.6 : 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _emailError != null ? const Color(0xFFDC2626) : const Color(0xFF1E60AA),
                                width: 1.8,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
                            ),
                          ),
                          validator: (v) => EmailValidator.validate(v),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autovalidateMode: _autoValidateMode,
                          onChanged: (_) => _clearError(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            errorText: _passwordError,
                            errorMaxLines: 2,
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: _passwordError != null ? const Color(0xFFDC2626) : null,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                            filled: true,
                            fillColor: _passwordError != null ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _passwordError != null ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                                width: _passwordError != null ? 1.6 : 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _passwordError != null ? const Color(0xFFDC2626) : const Color(0xFF1E60AA),
                                width: 1.8,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
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
                            child: _busyAction == _BusyAction.password
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
