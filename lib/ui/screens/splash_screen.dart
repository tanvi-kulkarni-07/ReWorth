import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // wait for 5 seconds then navigate to appropriate screen
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final seen = ref.read(hasSeenOnboardingProvider);
      if (!seen) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else if (ref.read(isLoggedInProvider)) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF00A699)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.recycling, size: 120, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
