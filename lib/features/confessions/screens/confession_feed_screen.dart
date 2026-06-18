import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/confession_model.dart';
import '../../../core/constants/app_colors.dart';

class ConfessionFeedScreen extends ConsumerStatefulWidget {
  const ConfessionFeedScreen({super.key});

  @override
  ConsumerState<ConfessionFeedScreen> createState() => _ConfessionFeedScreenState();
}

class _ConfessionFeedScreenState extends ConsumerState<ConfessionFeedScreen> {
  final TextEditingController _confessionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _confessionController.dispose();
    super.dispose();
  }

  // Stream confessions from Firestore
  Stream<List<ConfessionModel>> _streamConfessions() {
    return _firestore
        .collection('confessions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ConfessionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> _submitConfession() async {
    final text = _confessionController.text.trim();
    if (text.isEmpty || text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Confession must be at least 10 characters long.'),
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      await _firestore.collection('confessions').add({
        'content': text,
        'username': user.username,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'likes': <String>[],
      });

      _confessionController.clear();
      if (mounted) {
        Navigator.pop(context); // close modal sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.online,
            content: Text('Your confession has been cast into the void anonymously.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to post confession: $e'),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(ConfessionModel confession, String currentUserId) async {
    final confessionRef = _firestore.collection('confessions').doc(confession.id);
    final hasLiked = confession.likes.contains(currentUserId);

    try {
      if (hasLiked) {
        await confessionRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        await confessionRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
          'likesCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Failed to toggle like: $e');
    }
  }

  void _showCreateConfessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: const Border(
                top: BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'POST CONFESSION',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Write your confession. It will be posted anonymously, showing only your temporary identity.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                
                // Content text area
                TextField(
                  controller: _confessionController,
                  maxLines: 5,
                  maxLength: 300,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'I confess that...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submitConfession,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: const Text(
                        'CAST INTO VOID',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CONFESSIONS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // prevent bottom shell overlapping
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          onPressed: () {
            if (user != null) {
              _showCreateConfessionSheet();
            }
          },
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ConfessionModel>>(
          stream: _streamConfessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading confessions: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
              );
            }

            final confessions = snapshot.data ?? [];
            if (confessions.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 100.0),
              itemCount: confessions.length,
              itemBuilder: (context, index) {
                final confession = confessions[index];
                final hasLiked = user != null && confession.likes.contains(user.uid);
                
                return _buildConfessionCard(confession, user?.uid ?? '', hasLiked)
                    .animate()
                    .fade(delay: (index * 80).ms, duration: 450.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded, color: AppColors.textMuted, size: 52),
            const SizedBox(height: 16),
            const Text(
              'No Confessions Yet',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to share a confession anonymously in the void. Click the add button to write yours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfessionCard(ConfessionModel confession, String currentUserId, bool hasLiked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppColors.glassDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGlow,
                ),
                child: const Icon(Icons.masks_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    confession.username,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(confession.createdAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content body
          Text(
            confession.content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Interaction buttons (Upvotes, Comments, Share)
          Row(
            children: [
              // Upvotes / Likes
              GestureDetector(
                onTap: currentUserId.isEmpty ? null : () => _toggleLike(confession, currentUserId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasLiked ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasLiked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: hasLiked ? AppColors.primary : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${confession.likesCount}',
                        style: TextStyle(
                          color: hasLiked ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Comments Counter Card (simulated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mode_comment_outlined, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${confession.commentsCount}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),

              // Share button
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.surface,
                      content: Text('Confession frequency link copied to clipboard.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }
}
