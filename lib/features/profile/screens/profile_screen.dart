import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final List<String> _availableInterests = [
    'Coding',
    'Gaming',
    'Relationships',
    'Confessions',
    'Technology',
    'D&D',
    'Philosophy',
    'Memes',
    'Anime',
    'Music',
    'Books',
    'Art',
  ];

  void _rollAvatar(String currentSeed) {
    // Generate a random seed
    final random = Random();
    final newSeed = 'user_${random.nextInt(8999) + 1000}';
    ref.read(authControllerProvider.notifier).updateAvatarSeed(newSeed);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.online,
        content: Text('Avatar identity frequency rolled!'),
      ),
    );
  }

  void _toggleInterest(String interest, List<String> currentInterests) {
    final updatedList = List<String>.from(currentInterests);
    if (updatedList.contains(interest)) {
      updatedList.remove(interest);
    } else {
      updatedList.add(interest);
    }
    ref.read(authControllerProvider.notifier).updateInterests(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'IDENTITY CARD',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, s) => Center(
          child: Text('Error loading profile: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No user profile loaded', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          // Generate a deterministic color based on seed
          final seedHash = user.avatarSeed.hashCode;
          final avatarColor = Color((seedHash & 0xFFFFFF) | 0xFF000000);

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 100.0), // nav bar padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Customization Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppColors.glassDecoration(borderRadius: 24),
                    child: Column(
                      children: [
                        // Custom Avatar Ring
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: avatarColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: avatarColor.withValues(alpha: 0.25),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 48,
                              color: avatarColor,
                            ),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 18),

                        // Username
                        Text(
                          user.username,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        const SizedBox(height: 4),

                        Text(
                          'Identity Seed: ${user.avatarSeed}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Roll Avatar Action
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _rollAvatar(user.avatarSeed),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Container(
                              height: 44,
                              width: 160,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'ROLL IDENTITY',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.refresh_rounded, color: AppColors.secondary, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reputation Score Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppColors.glassDecoration(borderRadius: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'REPUTATION SCORE',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '${user.reputationScore}%',
                              style: const TextStyle(
                                color: AppColors.online,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Linear progress indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.reputationScore / 100,
                            backgroundColor: AppColors.background,
                            color: AppColors.online,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Maintain high reputation score by having positive conversation. Scores drop when strangers block or disconnect immediately.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Chats',
                          '${user.chatStats['totalChats'] ?? 0}',
                          Icons.forum_outlined,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Lurking Duration',
                          '${user.chatStats['minutesChatted'] ?? 0}m',
                          Icons.hourglass_empty_rounded,
                          AppColors.secondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Interests Configuration Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppColors.glassDecoration(borderRadius: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHOOSE INTERESTS',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select your topics to help the cyber void align you with similar anonymous minds.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        
                        // Selectable wrap list
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableInterests.map((interest) {
                            final isSelected = user.interests.contains(interest);
                            return GestureDetector(
                              onTap: () => _toggleInterest(interest, user.interests),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.background.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.secondary.withValues(alpha: 0.5) : AppColors.border,
                                    width: 1.2,
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppColors.glassDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
