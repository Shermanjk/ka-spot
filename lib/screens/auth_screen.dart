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

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recover() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      _message('Enter your account email first.');
      return;
    }
    try {
      await KaSpotService.recoverPassword(_email.text);
      if (mounted) _message('If the account exists, a recovery email is on its way.');
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const KaSpotLogo(
                  fontSize: 38,
                  showTagline: true,
                  tagline: 'Stay connected. Wherever life takes you.',
                ),
                const SizedBox(height: 28),
                Card(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(key: _form, child: Column(children: [
                    if (_register) ...[
                      TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name.' : null),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email address.' : null),
                    const SizedBox(height: 14),
                    TextFormField(controller: _password, obscureText: _obscure,
                      decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                      validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters.' : null),
                    if (!_register) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _recover, child: const Text('Forgot password?'))),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, height: 52, child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'Create account' : 'Sign in'),
                    )),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _busy ? null : () => setState(() => _register = !_register),
                      child: Text(_register ? 'Already have an account? Sign in' : 'New to KaSpot? Create an account')),
                  ])),
                )),
                const SizedBox(height: 18),
                const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.shield_outlined, size: 19, color: Color(0xFF2879C7)),
                  SizedBox(width: 9),
                  Expanded(child: Text('Location sharing is always your choice. Creating a connection never turns it on automatically.',
                    style: TextStyle(color: Color(0xFF60758A), height: 1.45))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
