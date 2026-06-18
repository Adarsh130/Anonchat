import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/matchmaking_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../../../core/constants/app_colors.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  final String uid;
  final String username;

  const MatchmakingScreen({
    super.key,
    required this.uid,
    required this.username,
  });

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  late Timer _textTimer;
  int _textIndex = 0;

  final List<String> _loadingTexts = [
    'Searching the void...',
    'Tuning frequencies...',
    'Listening for whispers...',
    'Scanning cyber space...',
    'Decrypting noise...',
    'Connecting relays...',
  ];

  @override
  void initState() {
    super.initState();
    // Start matchmaking process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchmakingControllerProvider.notifier).resetToIdle();
      ref.read(matchmakingControllerProvider.notifier).startMatchmaking(widget.uid, widget.username);
    });

    // Rotate loading texts every 2.5 seconds
    _textTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _textTimer.cancel();
    super.dispose();
  }

  void _cancelMatchmaking() {
    ref.read(matchmakingControllerProvider.notifier).cancelMatchmaking(widget.uid);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to matchmaking state to perform navigation
    ref.listen<MatchmakingState>(matchmakingControllerProvider, (previous, next) {
      if (next.status == MatchmakingStatus.matched && next.roomId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              roomId: next.roomId!,
              currentUserId: widget.uid,
            ),
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _cancelMatchmaking();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated Radar Core
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Radar Ripple 1
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4), width: 1.5),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(duration: 2.seconds, begin: const Offset(0.3, 0.3), end: const Offset(1.3, 1.3), curve: Curves.easeOut)
                        .fade(duration: 2.seconds, begin: 0.8, end: 0.0),

                        // Outer Radar Ripple 2
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(delay: 600.ms, duration: 2.seconds, begin: const Offset(0.3, 0.3), end: const Offset(1.3, 1.3), curve: Curves.easeOut)
                        .fade(delay: 600.ms, duration: 2.seconds, begin: 0.8, end: 0.0),

                        // Outer Radar Ripple 3
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(delay: 1200.ms, duration: 2.seconds, begin: const Offset(0.3, 0.3), end: const Offset(1.3, 1.3), curve: Curves.easeOut)
                        .fade(delay: 1200.ms, duration: 2.seconds, begin: 0.8, end: 0.0),

                        // Glowing Radar Center Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.secondary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.radar_rounded,
                            color: AppColors.secondary,
                            size: 36,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Transitioning Scanning State Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeOutCubic)),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _loadingTexts[_textIndex],
                    key: ValueKey<int>(_textIndex),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Static Subtext
                const Text(
                  'Matching you with a stranger, please stand by.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                // Cancel Button
                OutlinedButton(
                  onPressed: _cancelMatchmaking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                  ),
                  child: const Text(
                    'CANCEL SEARCH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
