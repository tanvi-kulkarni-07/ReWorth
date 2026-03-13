import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
// if you generated firebase_options via FlutterFire CLI, uncomment below
// import 'firebase_options.dart';

// provider containing onboarding state
import 'providers/auth_provider.dart';

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
import 'ui/screens/recycler_map_screen.dart';
import 'ui/screens/market_insights_screen.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/my_orders_screen.dart';
import 'ui/screens/pickup_requests_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv.load failed: $e');
  }
  // run the app immediately; Firebase will be initialized within the widget tree
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      '/my_orders': (c) => const MyOrdersScreen(),
      '/pickup_requests': (c) => const PickupRequestsScreen(),
      '/market_insights': (c) => const MarketInsightsScreen(),
      '/recycler_map': (c) => const RecyclerMapScreen(),
      // debugging/chat route
      '/chat': (c) => ChatScreen(),
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

          // Firebase is initialized; choose starting screen based on login state
          final loggedIn = ref.watch(isLoggedInProvider);
          if (!loggedIn) {
            final hasSeen = ref.watch(hasSeenOnboardingProvider);
            if (!hasSeen) {
              return const OnboardingScreen();
            }
            return const LoginScreen();
          }
          // user is authenticated, send them to HomeScreen (which contains PersistentBottomNavBar)
          return const HomeScreen();
        },
      ),
      routes: routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
