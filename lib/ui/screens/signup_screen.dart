import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../shared_ui.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

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
                      Icons.person_add_outlined,
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
                    'Create an Account',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),

                  // Signup Card
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
                                ref.read(signupNameProvider.notifier).state = v,
                            decoration:
                                ReWorthUI.inputDecoration(
                                  'Full Name',
                                  Icons.person_outline,
                                ).copyWith(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientOutline(
                          child: TextField(
                            onChanged: (v) =>
                                ref.read(signupEmailProvider.notifier).state =
                                    v,
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
                                ref
                                        .read(signupPasswordProvider.notifier)
                                        .state =
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
                        const SizedBox(height: 16),
                        GradientOutline(
                          child: TextField(
                            onChanged: (v) =>
                                ref.read(signupPhoneProvider.notifier).state =
                                    v,
                            decoration:
                                ReWorthUI.inputDecoration(
                                  'Phone',
                                  Icons.phone_outlined,
                                ).copyWith(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientOutline(
                          child: TextField(
                            onChanged: (v) =>
                                ref
                                        .read(signupLocationProvider.notifier)
                                        .state =
                                    v,
                            decoration:
                                ReWorthUI.inputDecoration(
                                  'Location',
                                  Icons.location_on_outlined,
                                ).copyWith(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GradientOutline(
                          child: DropdownButtonFormField<String>(
                            value: ref.watch(signupRoleProvider),
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
                            onChanged: (v) {
                              if (v != null)
                                ref.read(signupRoleProvider.notifier).state = v;
                            },
                            decoration:
                                ReWorthUI.inputDecoration(
                                  'Role',
                                  Icons.work_outline,
                                ).copyWith(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
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
                    onPressed: () async {
                      final name = ref.read(signupNameProvider);
                      final email = ref.read(signupEmailProvider);
                      final password = ref.read(signupPasswordProvider);
                      final role = ref.read(signupRoleProvider);
                      final phone = ref.read(signupPhoneProvider);
                      final location = ref.read(signupLocationProvider);

                      if (name.isEmpty ||
                          email.isEmpty ||
                          password.isEmpty ||
                          phone.isEmpty ||
                          location.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await ref
                            .read(authProvider.notifier)
                            .signUp(
                              name,
                              email,
                              password,
                              role,
                              phone,
                              location,
                            );

                        if (context.mounted) Navigator.of(context).pop();

                        if (ref.read(isLoggedInProvider)) {
                          ref.read(signupNameProvider.notifier).state = '';
                          ref.read(signupEmailProvider.notifier).state = '';
                          ref.read(signupPasswordProvider.notifier).state = '';
                          ref.read(signupPhoneProvider.notifier).state = '';
                          ref.read(signupLocationProvider.notifier).state = '';
                          ref.read(signupRoleProvider.notifier).state =
                              'seller';
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false);
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.of(context).pop();
                        String msg = e.toString().replaceAll('Exception: ', '');
                        if (e is FirebaseAuthException) {
                          msg = e.message ?? e.code;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    child: const Text('SIGN UP'),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
