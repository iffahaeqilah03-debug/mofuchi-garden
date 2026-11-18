import '../widgets/mofuchi_gradient_surface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/mofuchi_background.dart';
import 'main_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _registering = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _register() async {
    if (_registering) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text;
    final confirmation = _confirmPassController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmation.isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }
    if (!email.contains('@') || !email.split('@').last.contains('.')) {
      _showMessage('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must contain at least 6 characters.');
      return;
    }
    if (password != confirmation) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _registering = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firebase signs in the newly created user automatically.
      // A display name is optional metadata, not a separate registration step.
      try {
        await credential.user?.updateDisplayName(name);
      } catch (error) {
        debugPrint('Account created, but display name update failed: $error');
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScaffold()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      final message = switch (error.code) {
        'email-already-in-use' => 'This email already has an account. Please log in.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Please use a stronger password.',
        'operation-not-allowed' => 'Email/password sign-up is not enabled in Firebase Authentication.',
        'network-request-failed' => 'Network error. Check your internet connection.',
        _ => error.message ?? 'Unable to create your account. Please try again.',
      };
      _showMessage(message);
      debugPrint('Firebase sign-up failed (${error.code}): ${error.message}');
    } catch (error) {
      debugPrint('Unexpected sign-up error: $error');
      _showMessage('Could not create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MofuchiBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2430),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _field(_nameController, 'Full name', Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_emailController, 'Email address', Icons.mail_outline),
                      const SizedBox(height: 12),
                      _field(_passController, 'Password', Icons.lock_outline, obscure: true),
                      const SizedBox(height: 12),
                      _field(_confirmPassController, 'Confirm password', Icons.lock_outline, obscure: true),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C84F4), Color(0xFF6D3AC3)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: MofuchiGradientSurface(child: ElevatedButton(
                          onPressed: _registering ? null : _register,
                          style: (ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          )).copyWith(backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent), shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent), surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent)),
                          child: _registering
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign Up',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _registering ? null : () => Navigator.pop(context),
                  child: const Text('Already have an account? Log In', style: TextStyle(color: Color(0xFF9C84F4))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: hint == 'Email address' ? TextInputType.emailAddress : TextInputType.text,
        textCapitalization: hint == 'Full name' ? TextCapitalization.words : TextCapitalization.none,
        autocorrect: !obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9C94A0)),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9C94A0)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
