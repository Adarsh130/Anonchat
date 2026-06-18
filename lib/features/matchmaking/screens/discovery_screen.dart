import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import 'matchmaking_screen.dart';
import '../../../core/constants/app_colors.dart';

class MatchDiscoveryScreen extends ConsumerStatefulWidget {
  const MatchDiscoveryScreen({super.key});

  @override
  ConsumerState<MatchDiscoveryScreen> createState() => _MatchDiscoveryScreenState();
}

class _MatchDiscoveryScreenState extends ConsumerState<MatchDiscoveryScreen> {
  // Mock data of candidate cards
  final List<DiscoveryProfile> _profiles = [
    DiscoveryProfile(
      username: 'Neon_Whisper_44',
      reputation: 98,
      isOnline: true,
      interests: ['Coding', 'Synthwave', 'Philosophy', 'Sci-Fi'],
      avatarColor: AppColors.secondary,
      bio: 'Lurking in the terminal. Code by day, write confessions by night. Let\'s talk about anything.',
    ),
    DiscoveryProfile(
      username: 'Silent_Specter_91',
      reputation: 85,
      isOnline: false,
      interests: ['Confessions', 'Gaming', 'Anime', 'Metal'],
      avatarColor: AppColors.primary,
      bio: 'Here to read wild secrets and talk about gaming setups. Addicted to FPS games.',
    ),
    DiscoveryProfile(
      username: 'Ghost_Protocol_09',
      reputation: 92,
      isOnline: true,
      interests: ['Relationships', 'D&D', 'Memes', 'Art'],
      avatarColor: AppColors.online,
      bio: 'Looking for deep late-night talks. If you like dark humor, we will match instantly.',
    ),
    DiscoveryProfile(
      username: 'Shadow_Runner_22',
      reputation: 89,
      isOnline: true,
      interests: ['Tech', 'Crypto', 'Books', 'Music'],
      avatarColor: AppColors.error,
      bio: 'Let\'s exchange developer horror stories or discuss futuristic tech. No small talks.',
    ),
  ];

  int _currentIndex = 0;
  double _swipeOffset = 0.0;
  bool _isSwiping = false;

  void _onSwipe(bool isLike) {
    if (_currentIndex >= _profiles.length) return;

    setState(() {
      _isSwiping = true;
      _swipeOffset = isLike ? 400.0 : -400.0;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _swipeOffset = 0.0;
          _isSwiping = false;
        });

        // Trigger matched celebration if liked
        if (isLike && _currentIndex <= _profiles.length) {
          _showMatchCelebration();
        }
      }
    });
  }

  void _showMatchCelebration() {
    final matchedProfile = _profiles[_currentIndex - 1];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: AppColors.glassDecoration(
              borderRadius: 28,
              fillColor: AppColors.background.withValues(alpha: 0.95),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.error, size: 56)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 800.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                
                const SizedBox(height: 18),
                
                const Text(
                  'MATCH FOUND!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'You and ${matchedProfile.username} aligned on the same frequency.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
                ),
                
                const SizedBox(height: 28),
                
                // Action Buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    final myProfile = ref.read(currentUserProvider).value;
                    if (myProfile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchmakingScreen(
                            uid: myProfile.uid,
                            username: myProfile.username,
                          ),
                        ),
                      );
                    }
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: const Text('OPEN SECURE CHAT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('KEEP DISCOVERING', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isQueueEmpty = _currentIndex >= _profiles.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'DISCOVERY',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 100.0), // nav bar padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro header
              const Text(
                'SWIPE AND CONNECT',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Swipe Area Card Stack
              Expanded(
                child: isQueueEmpty
                    ? _buildEmptyQueueCard()
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background card (next one)
                          if (_currentIndex < _profiles.length - 1)
                            Transform.scale(
                              scale: 0.95,
                              child: Transform.translate(
                                offset: const Offset(0, 15),
                                child: _buildDiscoveryCard(_profiles[_currentIndex + 1], isBehind: true),
                              ),
                            ),

                          // Active sliding card
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              if (_isSwiping) return;
                              setState(() {
                                _swipeOffset = details.delta.dx * 1.5 + _swipeOffset;
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              if (_isSwiping) return;
                              if (_swipeOffset.abs() > size.width * 0.3) {
                                _onSwipe(_swipeOffset > 0);
                              } else {
                                setState(() {
                                  _swipeOffset = 0.0;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: _isSwiping ? 300 : 100),
                              transform: Matrix4.translationValues(_swipeOffset, _swipeOffset.abs() * 0.15, 0)
                                ..rotateZ(_swipeOffset * 0.001),
                              child: _buildDiscoveryCard(_profiles[_currentIndex]),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Action buttons row (Dismiss vs Match)
              if (!isQueueEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Swipe Left (Dismiss)
                    _buildActionButton(
                      icon: Icons.close_rounded,
                      color: AppColors.error,
                      onPressed: () => _onSwipe(false),
                    ),
                    const SizedBox(width: 40),
                    // Swipe Right (Match)
                    _buildActionButton(
                      icon: Icons.favorite_rounded,
                      color: AppColors.online,
                      onPressed: () => _onSwipe(true),
                    ),
                  ],
                ).animate().fade(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyQueueCard() {
    return Container(
      decoration: AppColors.glassDecoration(borderRadius: 24),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: AppColors.secondary, size: 56)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
          const SizedBox(height: 20),
          const Text(
            'The Grid is Empty',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'You\'ve viewed all active discovery profiles. Check back in a few minutes or join the matching radar!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
            child: const Text('RELOAD PROFILES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(DiscoveryProfile profile, {bool isBehind = false}) {
    return Container(
      decoration: AppColors.glassDecoration(
        borderRadius: 24,
        fillColor: isBehind ? AppColors.surface : AppColors.surface.withValues(alpha: 0.9),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar silhouette with neon outline
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: profile.avatarColor.withValues(alpha: 0.3), width: 1.5),
                gradient: LinearGradient(
                  colors: [
                    profile.avatarColor.withValues(alpha: 0.15),
                    profile.avatarColor.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 80,
                    color: profile.avatarColor.withValues(alpha: 0.8),
                  ),
                  
                  // Online indicator tag
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: profile.isOnline ? AppColors.online : AppColors.offline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: profile.isOnline ? AppColors.online : AppColors.offline,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.isOnline ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              color: profile.isOnline ? AppColors.online : AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // User details (Name and Reputation)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                profile.username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Reputation Score
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.reputation}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bio text
          Text(
            profile.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // Interests Tags row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

class DiscoveryProfile {
  final String username;
  final int reputation;
  final bool isOnline;
  final List<String> interests;
  final Color avatarColor;
  final String bio;

  DiscoveryProfile({
    required this.username,
    required this.reputation,
    required this.isOnline,
    required this.interests,
    required this.avatarColor,
    required this.bio,
  });
}
