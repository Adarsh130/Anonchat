import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/main_shell.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isConnecting = false;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Enter Stealth Mode',
      description: 'Communicate freely with fully generated identities. No real names, no email tracking, absolute secrets.',
      icon: Icons.masks_outlined,
      glowColor: AppColors.primary,
    ),
    OnboardingSlide(
      title: 'Privacy By Design',
      description: 'Chats are secure, temporary, and self-cleaning. Your tracks melt away as soon as the session terminates.',
      icon: Icons.shield_outlined,
      glowColor: AppColors.secondary,
    ),
    OnboardingSlide(
      title: 'Vibrant Communities',
      description: 'Discuss confessions, technology, gaming, or relationships inside encrypted public anonymous channels.',
      icon: Icons.forum_outlined,
      glowColor: AppColors.primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _connectAnonymously() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).signInAnonymously();
      
      if (mounted) {
        final authState = ref.read(authControllerProvider);
        if (authState is AsyncError) {
          throw Exception(authState.error);
        }
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to connect to the void: $e'),
          ),
        );
      }
    }
  }

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _connectAnonymously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dynamic Background Aura according to slide
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            top: _currentIndex % 2 == 0 ? -120 : -50,
            left: _currentIndex % 2 == 0 ? -120 : 100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _slides[_currentIndex].glowColor.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: _slides[_currentIndex].glowColor.withValues(alpha: 0.12),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main Page Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Skip Action
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isConnecting ? null : _connectAnonymously,
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Sliding Onboarding Cards
                  SizedBox(
                    height: 420,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                          padding: const EdgeInsets.all(28.0),
                          decoration: AppColors.glassDecoration(borderRadius: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon container with neon ring
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: slide.glowColor.withValues(alpha: 0.3), width: 1.5),
                                  gradient: LinearGradient(
                                    colors: [
                                      slide.glowColor.withValues(alpha: 0.15),
                                      slide.glowColor.withValues(alpha: 0.05),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  slide.icon,
                                  size: 44,
                                  color: slide.glowColor,
                                ),
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                              const SizedBox(height: 36),

                              // Slide Title
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Description
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Indicators & Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dots Indicators
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: index == _currentIndex ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: index == _currentIndex
                                  ? _slides[_currentIndex].glowColor
                                  : AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),

                      // Next / Enter Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isConnecting ? null : _onNext,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            child: Row(
                              children: [
                                Text(
                                  _currentIndex == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Glassmorphic Connection Loader Overlay
          if (_isConnecting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: AppColors.glassDecoration(borderRadius: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                            strokeWidth: 3,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1))
                        .fade(begin: 0.7, end: 1.0),
                        const SizedBox(height: 24),
                        const Text(
                          'TUNING FREQUENCY',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Generating anonymous signature...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color glowColor;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.glowColor,
  });
}
