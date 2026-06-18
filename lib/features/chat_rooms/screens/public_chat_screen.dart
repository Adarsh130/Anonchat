import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class PublicChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;

  const PublicChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<PublicChatRoomScreen> createState() => _PublicChatRoomScreenState();
}

class _PublicChatRoomScreenState extends ConsumerState<PublicChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  void _joinRoom() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _firestore
          .collection('public_rooms')
          .doc(widget.roomId)
          .collection('participants')
          .doc(uid)
          .set({'joinedAt': FieldValue.serverTimestamp()});
    }
  }

  void _leaveRoom() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _firestore
          .collection('public_rooms')
          .doc(widget.roomId)
          .collection('participants')
          .doc(uid)
          .delete();
    }
  }

  @override
  void dispose() {
    _leaveRoom();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Stream messages in this public room
  Stream<List<PublicMessage>> _streamMessages() {
    return _firestore
        .collection('public_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PublicMessage.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      final messagesRef = _firestore
          .collection('public_rooms')
          .doc(widget.roomId)
          .collection('messages');

      await messagesRef.add({
        'senderId': user.uid,
        'senderName': user.username,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update last message in the room document
      await _firestore.collection('public_rooms').doc(widget.roomId).set({
        'name': widget.roomName,
        'lastMessage': text,
        'lastMessageSender': user.username,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _scrollToBottom();
    } catch (e) {
      debugPrint('Failed to send public message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildStrangerAvatar(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.masks_rounded,
        size: 18,
        color: color,
      ),
    );
  }

  Widget _buildEncryptionBadge() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x0EFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x13FFFFFF), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 14),
            SizedBox(width: 8),
            Text(
              'Messages are end-to-end encrypted.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Public Channel • Encrypted Room',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 20),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle radial glows behind bubbles
            Positioned(
              top: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGlow.withValues(alpha: 0.15),
                  boxShadow: const [
                    BoxShadow(color: AppColors.primaryGlow, blurRadius: 100, spreadRadius: 30),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryGlow.withValues(alpha: 0.1),
                  boxShadow: const [
                    BoxShadow(color: AppColors.secondaryGlow, blurRadius: 100, spreadRadius: 30),
                  ],
                ),
              ),
            ),

            Column(
              children: [
                // Messages Stream
                Expanded(
                  child: StreamBuilder<List<PublicMessage>>(
                    stream: _streamMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Failed to load logs: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                        );
                      }

                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.forum_outlined, color: AppColors.textMuted, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Room is Empty',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Welcome to ${widget.roomName}! Be the first to whisper here.',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      // Trigger scroll on new message
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = currentUser != null && msg.senderId == currentUser.uid;

                          // Generate color for sender name based on hash
                          final nameHash = msg.senderName.hashCode;
                          final senderColor = Color((nameHash & 0xFFFFFF) | 0xFF000000);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (index == 0) ...[
                                _buildEncryptionBadge(),
                                _buildDateSeparator('Today'),
                              ],

                              Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe) ...[
                                      _buildStrangerAvatar(senderColor),
                                      const SizedBox(width: 8),
                                    ],
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isMe ? AppColors.primaryGradient : null,
                                        color: isMe ? null : AppColors.surfaceGlass,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                                          bottomRight: isMe ? Radius.zero : const Radius.circular(18),
                                        ),
                                        border: isMe ? null : Border.all(color: AppColors.border, width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Username header
                                          if (!isMe) ...[
                                            Text(
                                              msg.senderName,
                                              style: TextStyle(
                                                color: senderColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                          Text(
                                            msg.text,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14.5,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Text(
                                              _formatTimestamp(msg.timestamp),
                                              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fade(duration: 250.ms).slideY(begin: 0.1, end: 0);
                        },
                      );
                    },
                  ),
                ),

                // Message Input bar
                Container(
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 10.0,
                    bottom: 10.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Broadcast a whisper...',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
                      InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(50),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.accentGradient,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PublicMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  PublicMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory PublicMessage.fromMap(Map<String, dynamic> map, String id) {
    return PublicMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Anonymous',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
