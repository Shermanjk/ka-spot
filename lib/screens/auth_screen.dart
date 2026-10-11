import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kaspot_service.dart';
import '../widgets/kaspot_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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

  void _clearErrors() {
    if (_nameError != null || _emailError != null || _passwordError != null) {
      setState(() {
        _nameError = null;
        _emailError = null;
        _passwordError = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    if (!_form.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      if (_register) {
        await KaSpotService.register(_name.text, _email.text, _password.text);
      } else {
        await KaSpotService.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      if (KaSpotService.isConfigured) {
        final session = KaSpotService.client?.auth.currentSession;
        if (session == null && _register) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Check your email to confirm your account, then sign in.'),
          ));
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (!_register && (msg.contains('invalid login credentials') || msg.contains('invalid') || msg.contains('not found'))) {
        setState(() {
          _emailError = 'Account not found or password incorrect.';
          _passwordError = 'Check your password or create a new account.';
        });
        _form.currentState?.validate();
        await _showAccountNotFoundDialog(_email.text.trim());
      } else if (_register && (msg.contains('already registered') || msg.contains('already exists'))) {
        setState(() {
          _emailError = 'An account with this email already exists.';
        });
        _form.currentState?.validate();
        await _showAccountAlreadyRegisteredDialog(_email.text.trim());
      } else {
        setState(() {
          _emailError = e.message;
        });
        _form.currentState?.validate();
        _message(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      final lower = errorMsg.toLowerCase();
      if (lower.contains('email')) {
        setState(() => _emailError = errorMsg);
      } else if (lower.contains('password')) {
        setState(() => _passwordError = errorMsg);
      }
      _form.currentState?.validate();
      _message(errorMsg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showAccountNotFoundDialog(String email) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_off_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Account Not Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.45),
                children: [
                  const TextSpan(text: 'We couldn\'t find a KaSpot account for '),
                  TextSpan(
                    text: email.isNotEmpty ? email : 'this email',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const TextSpan(text: ', or the password was incorrect.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If you haven\'t registered yet, create an account to start sharing locations with your circle.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _register = true;
                _emailError = null;
                _passwordError = null;
              });
              _form.currentState?.reset();
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Create Account'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E60AA),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountAlreadyRegisteredDialog(String email) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_circle_rounded, color: Color(0xFF1E60AA), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Account Already Exists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.45),
                children: [
                  const TextSpan(text: 'An account is already registered for '),
                  TextSpan(
                    text: email.isNotEmpty ? email : 'this email',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const TextSpan(text: '. Please sign in with your password.'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _register = false;
                _emailError = null;
                _passwordError = null;
              });
              _form.currentState?.reset();
            },
            child: const Text('Switch to Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _recover() async {
    final emailValidation = _validateEmail(_email.text);
    if (emailValidation != null) {
      setState(() => _emailError = emailValidation);
      _form.currentState?.validate();
      return;
    }
    try {
      await KaSpotService.recoverPassword(_email.text.trim());
      if (mounted) _message('If the account exists, a recovery email is on its way.');
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(
        prefixIcon,
        color: hasError ? const Color(0xFFEF4444) : const Color(0xFF64748B),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: hasError ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFF1E60AA),
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFEF4444),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KaSpotLogo(
                    fontSize: 38,
                    showTagline: true,
                    tagline: 'Stay connected. Wherever life takes you.',
                  ),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 1,
                    shadowColor: const Color(0x0A000000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _form,
                        child: Column(
                          children: [
                            if (_register) ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => _clearErrors(),
                                decoration: _inputDecoration(
                                  labelText: 'Your name',
                                  prefixIcon: Icons.person_outline,
                                  hasError: _nameError != null,
                                ),
                                validator: (v) {
                                  if (_nameError != null) return _nameError;
                                  return (v == null || v.trim().isEmpty) ? 'Enter your name.' : null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => _clearErrors(),
                              decoration: _inputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icons.mail_outline,
                                suffixIcon: _emailError != null
                                    ? const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444))
                                    : null,
                                hasError: _emailError != null,
                              ),
                              validator: (v) {
                                if (_emailError != null) return _emailError;
                                return _validateEmail(v);
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              onChanged: (_) => _clearErrors(),
                              decoration: _inputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_passwordError != null)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
                                      ),
                                    IconButton(
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    ),
                                  ],
                                ),
                                hasError: _passwordError != null,
                              ),
                              validator: (v) {
                                if (_passwordError != null) return _passwordError;
                                return (v == null || v.length < 8) ? 'Use at least 8 characters.' : null;
                              },
                            ),
                            if (!_register)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _recover,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _busy ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E60AA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        _register ? 'Create account' : 'Sign in',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      setState(() {
                                        _register = !_register;
                                        _clearErrors();
                                      });
                                      _form.currentState?.reset();
                                    },
                              child: Text(
                                _register
                                    ? 'Already have an account? Sign in'
                                    : 'New to KaSpot? Create an account',
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}
