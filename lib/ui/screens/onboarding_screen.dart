import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

/// Onboarding flow matching the provided four-screen design exactly.
///
/// The green-to-blue gradient background, rounded card layout, soft-glow
/// buttons, centered illustrations and pagination dots are all implemented.
/// Horizontal swiping and Next/Get Started behaviour are built in.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'REWORTH',
      description:
          'Revolutionize Your Waste. Turn recyclables into rewards with AI-driven precision.',
      illustrationAsset: 'assets/illustrations/ai_camera.jpeg',
      buttonText: 'Next',
    ),
    _OnboardingData(
      title: 'TRACK YOUR IMPACT',
      description:
          'Visualise your contribution to a greener planet with real-time analytics.',
      illustrationAsset: 'assets/illustrations/impact_globe.jpeg',
      stats: const [
        _Stat(label: 'CO₂ Saved', value: '50kg'),
        _Stat(label: 'Landfill Diverted', value: '200kg'),
        _Stat(label: 'Total Value', value: '₹3500'),
      ],
      buttonText: 'Next',
    ),
    _OnboardingData(
      title: 'SMART COLLECTION',
      description:
          'Schedule intelligent collections with our automated logistics network.',
      illustrationAsset: 'assets/illustrations/smart_collection.jpeg',
      buttonText: 'Next',
    ),
    _OnboardingData(
      title: 'JOIN THE CIRCULAR ECONOMY',
      description:
          'Empower your community. Make waste management smart and profitable.',
      illustrationAsset: 'assets/illustrations/circular_economy.jpeg',
      buttonText: 'GET STARTED',
      secondaryText: 'or login',
    ),
  ];

  void _finishOnboarding() {
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    // Switch to Login screen (which currently handles the redirect to /home)
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _goToLogin() {
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF0091EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (context, idx) {
                    return _OnboardingPage(data: _pages[idx]);
                  },
                ),
              ),
              _Paginator(pageCount: _pages.length, currentPage: _currentIndex),
              const SizedBox(height: 16),
              _ActionButton(
                text: _pages[_currentIndex].buttonText,
                onPressed: () {
                  if (_currentIndex == _pages.length - 1) {
                    _finishOnboarding();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              if (_currentIndex == _pages.length - 1 &&
                  _pages[_currentIndex].secondaryText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: GestureDetector(
                    onTap: _goToLogin,
                    child: Text(
                      _pages[_currentIndex].secondaryText!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String illustrationAsset;
  final List<_Stat>? stats;
  final String buttonText;
  final String? secondaryText;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.illustrationAsset,
    this.stats,
    required this.buttonText,
    this.secondaryText,
  });
}

class _Stat {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xAA00C853), Color(0xAA0091EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      data.illustrationAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              if (data.stats != null) ...[
                const SizedBox(height: 24),
                _StatsRow(stats: data.stats!),
              ],
              const SizedBox(height: 24),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<_Stat> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats
          .map(
            (s) => Column(
              children: [
                Text(
                  s.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.label,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _Paginator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  const _Paginator({required this.pageCount, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == currentPage ? 12 : 8,
          height: i == currentPage ? 12 : 8,
          decoration: BoxDecoration(
            color: i == currentPage ? Colors.white : Colors.white54,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _ActionButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style:
              ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ).copyWith(
                // gradient via decoration
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => Colors.transparent,
                ),
              ),
          onPressed: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF0091EA)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4400C853),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 48),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
