import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'public_chat_screen.dart';
import '../../../core/constants/app_colors.dart';

final publicRoomActiveCountProvider = StreamProvider.family<int, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('public_rooms')
      .doc(roomId)
      .collection('participants')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

class PublicRoomsScreen extends StatefulWidget {
  const PublicRoomsScreen({super.key});

  @override
  State<PublicRoomsScreen> createState() => _PublicRoomsScreenState();
}

class _PublicRoomsScreenState extends State<PublicRoomsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    'All',
    'Technology',
    'Confessions',
    'Gaming',
    'Relationships',
    'College Life',
  ];

  final List<CategoryRoom> _rooms = [
    CategoryRoom(
      id: 'cyber_whispers',
      name: 'Cyber Whispers',
      category: 'Technology',
      description: 'The future of AI, space travel, coding pipelines, and tech gossips.',
      activeCount: 142,
    ),
    CategoryRoom(
      id: 'midnight_secrets',
      name: 'Midnight Secrets',
      category: 'Confessions',
      description: 'Your darkest thoughts, guilt, and raw confessions. 100% anonymous.',
      activeCount: 310,
    ),
    CategoryRoom(
      id: 'fps_gladiators',
      name: 'FPS Gladiators',
      category: 'Gaming',
      description: 'Find team matches, exchange discord logs, and talk esports.',
      activeCount: 94,
    ),
    CategoryRoom(
      id: 'crush_confidential',
      name: 'Crush Confidential',
      category: 'Relationships',
      description: 'Dating advice, heartbreak, crush gossips, and relationship rules.',
      activeCount: 205,
    ),
    CategoryRoom(
      id: 'campus_rambles',
      name: 'Campus Rambles',
      category: 'College Life',
      description: 'Exams, professors, hostel complaints, and late night study chat.',
      activeCount: 118,
    ),
    CategoryRoom(
      id: 'indie_devs',
      name: 'Indie Devs Zone',
      category: 'Technology',
      description: 'Showcase your prototype, get feedback, and find co-founders.',
      activeCount: 52,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'COMMUNITIES',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            physics: const BouncingScrollPhysics(),
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            tabs: _categories.map((c) => Tab(text: c.toUpperCase())).toList(),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            final filteredRooms = category == 'All'
                ? _rooms
                : _rooms.where((room) => room.category == category).toList();

            if (filteredRooms.isEmpty) {
              return _buildEmptyCategory();
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 100.0), // bottom nav bar spacing
              itemCount: filteredRooms.length,
              itemBuilder: (context, index) {
                final room = filteredRooms[index];
                return _buildRoomCard(room)
                    .animate()
                    .fade(delay: (index * 100).ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0.0, curve: Curves.easeOutCubic);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No Active Channels',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'This community category is empty in the current frequency.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(CategoryRoom room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppColors.glassDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category tag badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  room.category.toUpperCase(),
                  style: TextStyle(
                    color: room.category == 'Technology' || room.category == 'Gaming'
                        ? AppColors.secondary
                        : AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Active count
              Row(
                children: [
                  const Icon(Icons.online_prediction_rounded, color: AppColors.online, size: 14),
                  const SizedBox(width: 6),
                  Consumer(
                    builder: (context, ref, child) {
                      final activeCountAsync = ref.watch(publicRoomActiveCountProvider(room.id));
                      return activeCountAsync.when(
                        data: (activeCount) => Text(
                          '$activeCount online',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text(
                          '... online',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        error: (e, s) => const Text(
                          '0 online',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Room name
          Text(
            room.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            room.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Join Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PublicChatRoomScreen(
                    roomId: room.id,
                    roomName: room.name,
                  ),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'TUNE IN TO CHANNEL',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.wifi_channel_rounded, color: AppColors.secondary, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRoom {
  final String id;
  final String name;
  final String category;
  final String description;
  final int activeCount;

  CategoryRoom({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.activeCount,
  });
}
