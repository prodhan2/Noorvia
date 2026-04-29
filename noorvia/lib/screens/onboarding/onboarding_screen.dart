import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../main_shell.dart';

class OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;

  OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      emoji: '🕌',
      title: 'নামাজের সময়সূচি',
      subtitle: 'প্রতিদিনের নামাজের সময় জানুন\nআযানের নোটিফিকেশন পান',
      color: AppColors.primary,
      bgColor: const Color(0xFFE8F5E9),
    ),
    OnboardingPage(
      emoji: '📖',
      title: 'পবিত্র কুরআন',
      subtitle: 'বাংলা অনুবাদসহ কুরআন পড়ুন\nতাফসীর ও তিলাওয়াত শুনুন',
      color: const Color(0xFF1565C0),
      bgColor: const Color(0xFFE3F2FD),
    ),
    OnboardingPage(
      emoji: '🤲',
      title: 'দু\'আ ও যিকির',
      subtitle: 'দৈনন্দিন দু\'আ ও যিকির শিখুন\nতাসবীহ কাউন্টার ব্যবহার করুন',
      color: const Color(0xFF6A1B9A),
      bgColor: const Color(0xFFF3E5F5),
    ),
    OnboardingPage(
      emoji: '🌙',
      title: 'ইসলামিক ক্যালেন্ডার',
      subtitle: 'হিজরি তারিখ ও ইসলামিক\nগুরুত্বপূর্ণ দিনগুলো জানুন',
      color: const Color(0xFFE65100),
      bgColor: const Color(0xFFFFF3E0),
    ),
  ];

  void _goToNext() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return _buildPage(page);
            },
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: pages[_currentPage].color,
                      dotColor: pages[_currentPage].color.withOpacity(0.3),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'এড়িয়ে যান',
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToNext,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: pages[_currentPage].color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: pages[_currentPage].color.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentPage == pages.length - 1
                                ? Icons.check
                                : Icons.arrow_forward,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(page.emoji, style: const TextStyle(fontSize: 90)),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                page.title,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: page.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
