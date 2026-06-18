import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import 'matchmaking_screen.dart';
import '../../../core/constants/app_colors.dart';

// Streams the count of online users
final onlineUsersCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final onlineCountAsync = ref.watch(onlineUsersCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ANONCHAT',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 3,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading profile: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (user) {
          if (user == null) {
            // Automatically recreate the missing profile document
            Future.microtask(() {
              ref.read(authControllerProvider.notifier).createProfileIfMissing();
            });
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 100.0), // Padding to prevent nav overlap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Identity Glass Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: AppColors.glassDecoration(borderRadius: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.online,
                                shape: BoxShape.circle,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(duration: 800.ms, begin: 0.3, end: 1.0),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR TEMP IDENTITY',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.username,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Regenerate button
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
                          onPressed: () => ref.read(authControllerProvider.notifier).regenerateUsername(),
                        ),
                      ],
                    ),
                  ).animate().fade().scale(duration: 400.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 36),

                  // Giant matchmaking glow radar
                  Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchmakingScreen(
                              uid: user.uid,
                              username: user.username,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Radar glowing pulses
                            ...List.generate(3, (index) {
                              final delay = (index * 600).ms;
                              return Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (index % 2 == 0 ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(delay: delay, duration: 2.seconds, begin: const Offset(0.4, 0.4), end: const Offset(1.2, 1.2), curve: Curves.easeOut)
                              .fade(delay: delay, duration: 2.seconds, begin: 0.8, end: 0.0);
                            }),

                            // Core Button
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.accentGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.radar_rounded, size: 44, color: Colors.white),
                                  SizedBox(height: 6),
                                  Text(
                                    'START MATCH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(duration: 1.5.seconds, begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Online Counter Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: AppColors.glassDecoration(borderRadius: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_rounded, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 10),
                        onlineCountAsync.when(
                          loading: () => const Text('Querying the void...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          error: (e, s) => const Text('Connection status offline', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          data: (activeCount) => Text(
                            '$activeCount user${activeCount == 1 ? "" : "s"} active in the cyber void',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave the Shadows?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Signing out will discard your current temporary identity.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
