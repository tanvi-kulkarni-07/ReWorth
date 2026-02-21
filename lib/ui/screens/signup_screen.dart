import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A699),
        title: const Text('Create Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    ref.read(signupNameProvider.notifier).state = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    ref.read(signupEmailProvider.notifier).state = v,
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    ref.read(signupPasswordProvider.notifier).state = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: ref.watch(signupRoleProvider),
                items: const [
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A699),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final name = ref.read(signupNameProvider);
                  final email = ref.read(signupEmailProvider);
                  final password = ref.read(signupPasswordProvider);
                  final role = ref.read(signupRoleProvider);
                  ref
                      .read(authProvider.notifier)
                      .signUp(name, email, password, role);
                  if (ref.read(isLoggedInProvider)) {
                    // reset local fields
                    ref.read(signupNameProvider.notifier).state = '';
                    ref.read(signupEmailProvider.notifier).state = '';
                    ref.read(signupPasswordProvider.notifier).state = '';
                    ref.read(signupRoleProvider.notifier).state = 'seller';
                    Navigator.pushNamed(context, '/home');
                  }
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
