import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../home/screens/main_shell.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    final authUser = ref.read(authStateProvider).value;
    
    if (authUser != null) {
      // User is already authenticated: skip onboarding/login, go straight to app shell
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      );
    } else {
      // New visitor: go to Onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glows
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryGlow.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryGlow.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Glowing Anonymous Icon & Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Futuristic Anonymous Mask Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.masks_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                )
                .animate()
                .fade(duration: 800.ms)
                .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack)
                .then()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(duration: 1.5.seconds, begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), curve: Curves.easeInOut),

                const SizedBox(height: 32),

                // Brand Name
                Text(
                  'ANONCHAT',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.0,
                    foreground: Paint()
                      ..shader = AppColors.accentGradient.createShader(
                        const Rect.fromLTWH(0.0, 0.0, 250.0, 60.0),
                      ),
                  ),
                )
                .animate()
                .fade(delay: 400.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),

                const SizedBox(height: 8),

                // Mysterious Subtitle
                Text(
                  'TUNE INTO THE VOID',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                  ),
                )
                .animate()
                .fade(delay: 800.ms, duration: 800.ms),
              ],
            ),
          ),

          // Tiny version loader at bottom
          Positioned(
            bottom: 40,
            child: Text(
              'v1.0.0 • SECURED',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            )
            .animate()
            .fade(delay: 1.2.seconds, duration: 800.ms),
          ),
        ],
      ),
    );
  }
}
