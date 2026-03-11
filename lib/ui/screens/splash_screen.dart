import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<OnboardingData> onboardingPages;

  @override
  void initState() {
    super.initState();
    onboardingPages = [
      OnboardingData(
        title: 'REWORTH',
        description: 'Revolutionize Your Waste. Turn recyclables into rewards with AI-driven precision.',
        graphicBuilder: _buildReworthGraphic,
      ),
      OnboardingData(
        title: 'TRACK YOUR IMPACT',
        description: 'Visualise your contribution to a greener planet with real-time analytics.',
        graphicBuilder: _buildTrackImpactGraphic,
      ),
      OnboardingData(
        title: 'SMART COLLECTION',
        description: 'Schedule intelligent collections with our automated logistics network.',
        graphicBuilder: _buildSmartCollectionGraphic,
      ),
      OnboardingData(
        title: 'JOIN THE CIRCULAR ECONOMY',
        description: 'Empower your community. Make waste management smart and profitable.',
        graphicBuilder: _buildCircularEconomyGraphic,
      ),
    ];
  }

  void _navigateNext() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _skipToEnd() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: onboardingPages.length,
        itemBuilder: (context, i) {
          final data = onboardingPages[i];
          return OnboardingCard(
            graphic: data.graphicBuilder(),
            title: data.title,
            description: data.description,
            currentPage: i,
            totalPages: onboardingPages.length,
            showLogin: i == onboardingPages.length - 1,
            onNext: _navigateNext,
            onLogin: _skipToEnd,
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Widget Function() graphicBuilder;

  OnboardingData({
    required this.title,
    required this.description,
    required this.graphicBuilder,
  });
}

class OnboardingCard extends StatelessWidget {
  final Widget graphic;
  final String title;
  final String description;
  final int currentPage;
  final int totalPages;
  final bool showLogin;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  const OnboardingCard({
    Key? key,
    required this.graphic,
    required this.title,
    required this.description,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onLogin,
    this.showLogin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1DB89F), Color(0xFF00746C)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Expanded(flex: 3, child: Center(child: graphic)),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalPages,
                      (idx) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: currentPage == idx ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: currentPage == idx
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      showLogin ? 'GET STARTED' : 'Next',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1DB89F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showLogin) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onLogin,
                      child: Text(
                        'or login',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// detailed graphics matching the target onboarding screens

Widget _buildReworthGraphic() {
  // card with gradient background, phone in hand and app logo
  return Stack(
    alignment: Alignment.center,
    children: [
      // gradient circular backdrop
      Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1DB89F), Color(0xFF00A699)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
      ),
      // phone outline
      Container(
        width: 140,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recycling, size: 60, color: const Color(0xFF1DB89F)),
            const SizedBox(height: 16),
            Text(
              'REWORTH',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1DB89F),
              ),
            ),
          ],
        ),
      ),
      // subtle hand silhouette at bottom
      Positioned(
        bottom: -20,
        child: Icon(
          Icons.handshake,
          size: 60,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    ],
  );
}

Widget _buildTrackImpactGraphic() {
  // simple analytics icon on a contrasting circle
  return Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Icon(
        Icons.bar_chart,
        size: 100,
        color: Colors.white,
      ),
    ),
  );
}

Widget _buildSmartCollectionGraphic() {
  return Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Icon(
        Icons.local_shipping,
        size: 100,
        color: Colors.white,
      ),
    ),
  );
}

Widget _buildCircularEconomyGraphic() {
  return Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Icon(
        Icons.loop,
        size: 100,
        color: Colors.white,
      ),
    ),
  );
}

