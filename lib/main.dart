import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/marketplace_screen.dart';
import 'ui/screens/logistics_screen.dart';
import 'ui/screens/impact_wallet_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/upload_waste_screen.dart';
import 'ui/screens/my_listings_screen.dart';
import 'ui/screens/market_insights_screen.dart';

void main() {
  // wrap the app with ProviderScope for Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reworth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A699)),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        // '/splash': (c) => const SplashScreen(),
        // '/main': (c) => const MainScreen(),
        // '/login': (c) => const LoginScreen(),
        // '/signup': (c) => const SignupScreen(),
        '/home': (c) => const HomeScreen(),
        '/onboarding': (c) => const OnboardingScreen(),
        '/dashboard': (c) => const DashboardScreen(),
        '/marketplace': (c) => const MarketplaceScreen(),
        '/logistics': (c) => const LogisticsScreen(),
        '/impact_wallet': (c) => const ImpactWalletScreen(),
        '/profile': (c) => const ProfileScreen(),
        '/upload_waste': (c) => const UploadWasteScreen(),
        '/my_listings': (c) => const MyListingsScreen(),
        '/market_insights': (c) => const MarketInsightsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
