import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../shared_ui.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ReWorthUI.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.recycling,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'REWORTH',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // Login Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: ReWorthUI.cardDecoration,
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (v) =>
                              ref.read(loginEmailProvider.notifier).state = v,
                          decoration: ReWorthUI.inputDecoration(
                            'Email',
                            Icons.email_outlined,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (v) =>
                              ref.read(loginPasswordProvider.notifier).state =
                                  v,
                          decoration: ReWorthUI.inputDecoration(
                            'Password',
                            Icons.lock_outline,
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Color(0xFF0091EA)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Button
                  ElevatedButton(
                    style: ReWorthUI.actionButtonStyle,
                    onPressed: () {
                      final email = ref.read(loginEmailProvider);
                      final password = ref.read(loginPasswordProvider);
                      ref.read(authProvider.notifier).login(email, password);

                      if (ref.read(isLoggedInProvider)) {
                        ref.read(loginEmailProvider.notifier).state = '';
                        ref.read(loginPasswordProvider.notifier).state = '';
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid credentials')),
                        );
                      }
                    },
                    child: const Text('LOGIN'),
                  ),

                  const SizedBox(height: 16),

                  // Google Login Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .signInWithGoogle();
                        if (ref.read(isLoggedInProvider)) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google Sign-In failed: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 32),
                    label: const Text('Sign in with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      minimumSize: const Size(280, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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
