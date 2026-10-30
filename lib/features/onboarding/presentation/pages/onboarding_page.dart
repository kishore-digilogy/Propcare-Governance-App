import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';

/// Data model for each onboarding story page.
class _StoryData {
  final String imagePath;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _StoryData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}

final List<_StoryData> _stories = [
  const _StoryData(
    imagePath: AppAssets.onboarding1,
    title: 'Smart Property\nManagement',
    subtitle:
        'Get a complete overview of all your properties, tenants, and maintenance — all in one powerful dashboard.',
    accentColor: Color(0xFF1B6CA8),
  ),
  const _StoryData(
    imagePath: AppAssets.onboarding2,
    title: 'Governance &\nCompliance',
    subtitle:
        'Stay audit-ready with automated compliance tracking, real-time reports, and governance workflows.',
    accentColor: Color(0xFF1A73E8),
  ),
  const _StoryData(
    imagePath: AppAssets.onboarding3,
    title: 'Peace of Mind,\nDelivered.',
    subtitle:
        'Your residents enjoy seamless communication, quick maintenance, and 24/7 smart monitoring — effortlessly.',
    accentColor: Color(0xFF27AE60),
  ),
];

/// Animated 3-page onboarding / story screen with white background.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _progressController.forward(from: 0);
  }

  Future<void> _finish() async {
    await HiveStorage.markOnboardingSeen();
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_currentPage < _stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_currentPage];
    final size = MediaQuery.of(context).size;
    final isLast = _currentPage == _stories.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full-screen page view ────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _stories.length,
            itemBuilder: (context, index) =>
                _StoryPageContent(story: _stories[index], size: size),
          ),

          // ── Top bar: skip + progress ──────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  // Story progress bars
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _stories.length,
                        (i) => Expanded(
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            height: 3.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: i < _currentPage
                                  ? story.accentColor
                                  : const Color(0xFFE2E8F0),
                            ),
                            child: i == _currentPage
                                ? AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (_, __) => FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          color: story.accentColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Skip button
                  GestureDetector(
                    onTap: _finish,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.outfit(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom content card ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCard(
              story: story,
              currentPage: _currentPage,
              totalPages: _stories.length,
              isLast: isLast,
              onNext: _next,
              onDotTap: (i) => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Full-screen illustration page with white background
// ─────────────────────────────────────────────────────────────────────────────

class _StoryPageContent extends StatelessWidget {
  final _StoryData story;
  final Size size;

  const _StoryPageContent({required this.story, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Clean white background with subtle ambient tint
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                story.accentColor.withValues(alpha: 0.08),
                Colors.white,
                Colors.white,
              ],
            ),
          ),
        ),

        // Decorative background circle
        Positioned(
          top: size.height * 0.08,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: size.width * 0.85,
              height: size.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: story.accentColor.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),

        // Illustration image
        Positioned(
          top: size.height * 0.07,
          left: 0,
          right: 0,
          child: Center(
            child: Hero(
              tag: story.imagePath,
              child: Container(
                width: size.width * 0.78,
                height: size.width * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: story.accentColor.withValues(alpha: 0.2),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    story.imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                  begin: const Offset(0.85, 0.85),
                  duration: 600.ms,
                  curve: Curves.easeOutBack),
        ),

        // Bottom gradient fade to white
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: size.height * 0.5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom content card with title, subtitle, dots, CTA on white
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCard extends StatelessWidget {
  final _StoryData story;
  final int currentPage;
  final int totalPages;
  final bool isLast;
  final VoidCallback onNext;
  final void Function(int) onDotTap;

  const _BottomCard({
    required this.story,
    required this.currentPage,
    required this.totalPages,
    required this.isLast,
    required this.onNext,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator dots
          Row(
            children: List.generate(
              totalPages,
              (i) => GestureDetector(
                onTap: () => onDotTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 6),
                  width: i == currentPage ? 24 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == currentPage
                        ? story.accentColor
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            story.title,
            style: GoogleFonts.outfit(
              color: AppColors.secondary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          )
              .animate(key: ValueKey('title_$currentPage'))
              .fadeIn(duration: 400.ms)
              .slideX(
                  begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            story.subtitle,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          )
              .animate(key: ValueKey('sub_$currentPage'))
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(
                  begin: -0.15,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut),

          const SizedBox(height: 32),

          // CTA button
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    story.accentColor,
                    story.accentColor.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: story.accentColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast ? 'Get Started' : 'Next',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate(key: ValueKey('btn_$currentPage'))
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 400.ms),
        ],
      ),
    );
  }
}
