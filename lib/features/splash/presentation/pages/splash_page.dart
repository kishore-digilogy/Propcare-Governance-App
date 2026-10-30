import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_theme.dart';

/// Animated splash screen.
/// Navigates to: dashboard (if token) → onboarding (first time) → login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Allow animations to complete
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final isLoggedIn = HiveStorage.isLoggedIn;
    final seenOnboarding = HiveStorage.isOnboardingSeen;

    if (isLoggedIn) {
      context.go(AppRoutes.dashboard);
    } else if (!seenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle soft decorative accents
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Center full logo (properly scaled, no cropping)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/gov_icon.png',
                    width: size.width * 0.72,
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                      ),
                  const SizedBox(height: 48),

                  // Elegant progress bar
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFFF1F5F9),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 3.5,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),
                ],
              ),
            ),
          ),

          // Bottom version tag
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 800.ms),
          ),
        ],
      ),
    );
  }
}
