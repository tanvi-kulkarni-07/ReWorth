import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.recycling, size: 84, color: Color(0xFF00A699)),
              const SizedBox(height: 16),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A699),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            ref.read(signupNameProvider.notifier).state = v,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            ref.read(signupEmailProvider.notifier).state = v,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock),
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) =>
                            ref.read(signupPasswordProvider.notifier).state = v,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: ref.watch(signupRoleProvider),
                        items: const [
                          DropdownMenuItem(
                            value: 'seller',
                            child: Text('Seller'),
                          ),
                          DropdownMenuItem(
                            value: 'buyer',
                            child: Text('Buyer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(signupRoleProvider.notifier).state = value;
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A699),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            final name = ref.read(signupNameProvider);
                            final email = ref.read(signupEmailProvider);
                            final password = ref.read(signupPasswordProvider);
                            final role = ref.read(signupRoleProvider);
                            try {
                              await ref
                                  .read(authProvider.notifier)
                                  .signUp(name, email, password, role);
                              if (ref.read(isLoggedInProvider)) {
                                ref.read(signupNameProvider.notifier).state =
                                    '';
                                ref.read(signupEmailProvider.notifier).state =
                                    '';
                                ref
                                        .read(signupPasswordProvider.notifier)
                                        .state =
                                    '';
                                ref.read(signupRoleProvider.notifier).state =
                                    'seller';
                                Navigator.pushNamed(context, '/home');
                              }
                            } catch (e) {
                              String msg;
                              if (e is FirebaseAuthException) {
                                if (e.code == 'email-already-in-use') {
                                  msg =
                                      'An account with this email already exists. Please login.';
                                } else {
                                  msg = e.message ?? e.code;
                                }
                              } else if (e is FirebaseException) {
                                msg = e.message ?? 'An error occurred';
                              } else {
                                msg = e.toString();
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sign up failed: $msg')),
                              );
                            }
                          },
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
