import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A699),
        title: const Text('Welcome Back!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => ref.read(loginEmailProvider.notifier).state = v,
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  ref.read(loginPasswordProvider.notifier).state = v,
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
                final email = ref.read(loginEmailProvider);
                final password = ref.read(loginPasswordProvider);
                ref.read(authProvider.notifier).login(email, password);
                if (ref.read(isLoggedInProvider)) {
                  // flush form
                  ref.read(loginEmailProvider.notifier).state = '';
                  ref.read(loginPasswordProvider.notifier).state = '';
                  Navigator.pushNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid credentials')),
                  );
                }
              },
              child: const Text('Login'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // navigate to a reset password page or show dialog
              },
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }
}
