import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// if you generated firebase_options via FlutterFire CLI, uncomment below
// import 'firebase_options.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  // run the app immediately; Firebase will be initialized within the widget tree
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // you can flip this constant during development (or load from
    // environment/shared_preferences) to bypass the splash screen.
    const bool skipSplash = true; // <-- set to false to restore splash

    // Define all routes
    final Map<String, WidgetBuilder> routes = {
      '/splash': (c) => const SplashScreen(),
      '/main': (c) => const MainScreen(),
      '/login': (c) => const LoginScreen(),
      '/signup': (c) => const SignupScreen(),
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
    };

    // initialization future for Firebase
    final Future<FirebaseApp> _fbInit = Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );

    return MaterialApp(
      title: 'Reworth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A699)),
        useMaterial3: true,
      ),
      home: FutureBuilder<FirebaseApp>(
        future: _fbInit,
        builder: (context, snapshot) {
          // show a simple loading indicator until Firebase is ready
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            // handle initialization error
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          // Firebase is initialized; return the initial screen
          return skipSplash ? const MainScreen() : const SplashScreen();
        },
      ),
      routes: routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
