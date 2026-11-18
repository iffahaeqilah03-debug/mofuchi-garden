import '../widgets/mofuchi_gradient_surface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/mofuchi_background.dart';
import 'main_scaffold.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  static const _purple = Color(0xFF8062C8);
  static const _ink = Color(0xFF30273B);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      default:
        return 'Could not log in. Please try again.';
    }
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainScaffold()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(_authError(error));
    } catch (_) {
      if (mounted) _message('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _message('Enter your email address first, then tap Forgot password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _message('If this account exists, a reset email will arrive shortly.');
    } on FirebaseAuthException catch (error) {
      if (mounted) _message(_authError(error));
    } catch (_) {
      if (mounted) _message('Could not send the email. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MofuchiBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _Logo()),
                      const SizedBox(height: 18),
                      const Text(
                        'Welcome back 🌸',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Your little garden is waiting for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF756C7D)),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.91),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white),
                          boxShadow: [BoxShadow(color: _purple.withValues(alpha: 0.12), blurRadius: 26, offset: const Offset(0, 12))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Log in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: _ink, fontSize: 15),
                              cursorColor: _purple,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: _decoration('Email address', Icons.mail_outline_rounded),
                              validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())
                                  ? null : 'Enter a valid email address',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: _ink, fontSize: 15),
                              cursorColor: _purple,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _login(),
                              decoration: _decoration('Password', Icons.lock_outline_rounded).copyWith(
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: _purple,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) => (value == null || value.isEmpty) ? 'Enter your password' : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _resetPassword,
                                child: const Text('Forgot password?', style: TextStyle(color: _purple)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 52,
                              child: MofuchiGradientSurface(child: FilledButton(
                                onPressed: _loading ? null : _login,
                                style: (FilledButton.styleFrom(backgroundColor: _purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))).copyWith(backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent), shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent), surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent)),
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
                        child: const Text.rich(
                          TextSpan(
                            style: TextStyle(color: _ink),
                            children: [
                              TextSpan(text: "Don't have an account?  "),
                              TextSpan(text: 'Sign Up', style: TextStyle(color: _purple, fontWeight: FontWeight.w700)),
                            ],
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
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF756C7D)),
        floatingLabelStyle: const TextStyle(color: _purple),
        errorStyle: const TextStyle(color: Color(0xFFB3261E)),
        prefixIcon: Icon(icon, color: _purple),
        filled: true,
        fillColor: const Color(0xFFF8F5FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF8062C8).withValues(alpha: 0.18), blurRadius: 20)],
      ),
      child: Image.asset(
        'assets/images/mofuchi_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.local_florist_rounded, color: Color(0xFF8062C8), size: 43)),
      ),
    );
  }
}
