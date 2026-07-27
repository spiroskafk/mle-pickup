import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Sign-in failed.');
    } catch (_) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    await _run(() => auth.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        ));
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthService>();
    await _run(auth.signInWithGoogle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.pitchGreen, AppColors.darkGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MLE',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Mas Leipei Enas",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                validator: (v) => (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter your password'
                                    : null,
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _busy ? null : _signInWithEmail,
                                child: _busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _signInWithGoogle,
                                icon: const Icon(Icons.g_mobiledata, size: 24),
                                label: const Text('Continue with Google'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onSurface,
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        ),
                                child: const Text("New here? Create an account"),
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
    );
  }
}
