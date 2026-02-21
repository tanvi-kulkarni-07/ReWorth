import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to Reworth',
      'subtitle': 'Buy and sell waste materials easily from your phone.',
      'icon': '🌿',
    },
    {
      'title': 'Track Your Impact',
      'subtitle': 'See how much carbon you save and earn rewards.',
      'icon': '📊',
    },
    {
      'title': 'Smart Logistics',
      'subtitle': 'Book trucks or bikes with real-time tracking.',
      'icon': '🚚',
    },
  ];

  void _finishOnboarding() {
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (idx) {
              setState(() => _currentIndex = idx);
            },
            itemBuilder: (context, idx) {
              final page = _pages[idx];
              return Container(
                color: const Color(0xFF00A699),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(page['icon']!, style: const TextStyle(fontSize: 80)),
                    const SizedBox(height: 24),
                    Text(
                      page['title']!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        page['subtitle']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == i ? 12 : 8,
                      height: _currentIndex == i ? 12 : 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          _currentIndex == i ? 1 : 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_currentIndex == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00A699),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _currentIndex == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
