import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../shared_ui.dart';

class SellerLoginScreen extends ConsumerWidget {
  const SellerLoginScreen({super.key});

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
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store_outlined,
                      size: 60,
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
                    'Seller Login',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

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
                        GradientOutline(
                          child: TextField(
                            onChanged: (v) =>
                                ref.read(loginEmailProvider.notifier).state = v,
                            decoration:
                                ReWorthUI.inputDecoration(
                                  'Email',
                                  Icons.email_outlined,
                                ).copyWith(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientOutline(
                          child: TextField(
                            onChanged: (v) =>
                                ref.read(loginPasswordProvider.notifier).state =
                                    v,
                            decoration:
                                ReWorthUI.inputDecoration(
                                  'Password',
                                  Icons.lock_outline,
                                ).copyWith(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Button
                  ElevatedButton(
                    style: ReWorthUI.actionButtonStyle,
                    onPressed: () async {
                      final email = ref.read(loginEmailProvider);
                      final password = ref.read(loginPasswordProvider);

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await ref
                            .read(authProvider.notifier)
                            .login(email, password);

                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close loading
                        }

                        final role = ref.read(authProvider).role;
                        if (role == 'seller') {
                          ref.read(loginEmailProvider.notifier).state = '';
                          ref.read(loginPasswordProvider.notifier).state = '';
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/seller_home',
                            (route) => false,
                          );
                        } else {
                          await ref.read(authProvider.notifier).logout();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'This account is not registered as a seller',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close loading
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text('LOGIN AS SELLER'),
                  ),

                  const SizedBox(height: 16),

                  // Google Login Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .signInWithGoogle();
                        final role = ref.read(authProvider).role;
                        if (role == 'seller') {
                          Navigator.pushReplacementNamed(
                            context,
                            '/seller_home',
                          );
                        } else {
                          await ref.read(authProvider.notifier).logout();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'This account is not registered as a seller',
                              ),
                            ),
                          );
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

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(color: Colors.white70),
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
