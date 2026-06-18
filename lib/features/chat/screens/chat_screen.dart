import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../../matchmaking/screens/matchmaking_screen.dart';
import '../../../core/constants/app_colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    // Reset typing status on exit
    ref.read(chatRepositoryProvider).updateTypingStatus(widget.roomId, widget.currentUserId, false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final showButton = maxScroll - currentScroll > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
    }
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) {
      if (_isTyping) {
        _setTyping(false);
      }
      return;
    }

    if (!_isTyping) {
      _setTyping(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _setTyping(false);
    });
  }

  void _setTyping(bool typing) {
    if (mounted) {
      setState(() {
        _isTyping = typing;
      });
      ref.read(chatRepositoryProvider).updateTypingStatus(
        widget.roomId,
        widget.currentUserId,
        typing,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _setTyping(false);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
        widget.roomId,
        widget.currentUserId,
        text,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Failed to send message: $e'),
        ),
      );
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

  void _promptDisconnect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Disconnect?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to end this chat session? The stranger will be disconnected.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Disconnect', style: TextStyle(color: AppColors.error)),
            onPressed: () {
              Navigator.pop(context); // close dialog
              ref.read(chatRepositoryProvider).disconnectFromChat(widget.roomId);
              Navigator.pop(context); // close chat screen
            },
          ),
        ],
      ),
    );
  }

  void _blockStranger(String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Block Stranger?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Blocking this stranger will end the conversation and prevent you from matching with them again.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
            onPressed: () {
              Navigator.pop(context); // close dialog
              ref.read(chatRepositoryProvider).disconnectFromChat(roomId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.error,
                  content: Text('Stranger blocked successfully.'),
                ),
              );
              Navigator.pop(context); // close chat screen
            },
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String roomId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Report Stranger', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a reason for reporting:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...['Harassment or Abuse', 'Spam or Advertising', 'Inappropriate Language', 'Other'].map((reason) {
              return ListTile(
                title: Text(reason, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
                onTap: () {
                  Navigator.pop(context); // close dialog
                  ref.read(chatRepositoryProvider).disconnectFromChat(roomId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.online,
                      content: Text('Stranger reported for: $reason. Disconnecting...'),
                    ),
                  );
                  Navigator.pop(context); // close chat screen
                },
              );
            }),
          ],
        ),
      ),
    );
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
    final roomAsync = ref.watch(chatRoomStreamProvider(widget.roomId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        final room = roomAsync.value;
        if (room != null && !room.isActive) {
          Navigator.pop(context);
        } else {
          _promptDisconnect();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () {
              final room = roomAsync.value;
              if (room != null && !room.isActive) {
                Navigator.pop(context);
              } else {
                _promptDisconnect();
              }
            },
          ),
          title: roomAsync.when(
            loading: () => const Text('Connecting...', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            error: (e, s) => const Text('Error', style: TextStyle(color: AppColors.textPrimary)),
            data: (room) {
              if (room == null) return const Text('Chat Room');
              
              final strangerId = room.participants.firstWhere(
                (p) => p != widget.currentUserId,
                orElse: () => '',
              );

              if (strangerId.isEmpty) return const Text('Stranger');

              final strangerAsync = ref.watch(strangerProfileProvider(strangerId));
              return strangerAsync.when(
                loading: () => const Text('Stranger...', style: TextStyle(fontSize: 16)),
                error: (e, s) => const Text('Stranger'),
                data: (stranger) {
                  if (stranger == null) return const Text('Stranger');
                  final strangerColor = Color((stranger.username.hashCode & 0xFFFFFF) | 0xFF000000);
                  
                  return Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(color: strangerColor.withValues(alpha: 0.3), width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.masks_rounded, size: 20, color: strangerColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  stranger.username,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: AppColors.primary, size: 14),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: stranger.isOnline ? AppColors.online : AppColors.offline,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stranger.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: stranger.isOnline ? AppColors.online : AppColors.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          actions: [
            const Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            roomAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (room) {
                if (room == null || !room.isActive) return const SizedBox.shrink();
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    if (value == 'leave') {
                      _promptDisconnect();
                    } else if (value == 'block') {
                      _blockStranger(room.roomId);
                    } else if (value == 'report') {
                      _showReportDialog(room.roomId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report_problem_rounded, color: AppColors.error, size: 18),
                          SizedBox(width: 10),
                          Text('Report Stranger', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block_flipped, color: AppColors.error, size: 18),
                          SizedBox(width: 10),
                          Text('Block Stranger', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app_rounded, color: AppColors.textSecondary, size: 18),
                          SizedBox(width: 10),
                          Text('Leave Chat', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: roomAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, s) => Center(
            child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          ),
          data: (room) {
            if (room == null) {
              return const Center(
                child: Text('Room does not exist.', style: TextStyle(color: AppColors.textSecondary)),
              );
            }

            final isRoomActive = room.isActive;
            final strangerId = room.participants.firstWhere(
              (p) => p != widget.currentUserId,
              orElse: () => '',
            );

            final strangerAsync = ref.watch(strangerProfileProvider(strangerId));
            final strangerName = strangerAsync.value?.username ?? 'Stranger';
            final strangerColor = strangerAsync.value != null
                ? Color((strangerAsync.value!.username.hashCode & 0xFFFFFF) | 0xFF000000)
                : AppColors.secondary;

            // Determine if stranger is typing
            final isStrangerTyping = room.typingStatus[strangerId] == true;

            // Trigger scroll on build if we just entered
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && _scrollController.offset == 0) {
                _scrollToBottom();
              }
            });

            return Stack(
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

                // Chat conversation area
                Column(
                  children: [
                    // Messages list
                    Expanded(
                      child: ref.watch(messagesStreamProvider(widget.roomId)).when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                            error: (e, s) => Center(
                              child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
                            ),
                            data: (messages) {
                              if (messages.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.chat_bubble_outline_rounded,
                                          color: AppColors.textMuted, size: 48),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Connected! Start the conversation.',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  final isMe = msg.senderId == widget.currentUserId;
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Prepend encryption badge and date at the very top of scroll list
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
                                              _buildStrangerAvatar(strangerColor),
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
                                                border: isMe 
                                                    ? null 
                                                    : Border.all(color: AppColors.border, width: 1),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (!isMe) ...[
                                                    Text(
                                                      strangerName,
                                                      style: TextStyle(
                                                        color: strangerColor,
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
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _formatTimestamp(msg.timestamp),
                                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                                                        ),
                                                        if (isMe) ...[
                                                          const SizedBox(width: 4),
                                                          Icon(
                                                            Icons.done_all_rounded,
                                                            color: msg.seen ? AppColors.secondary : AppColors.textMuted,
                                                            size: 13,
                                                          ),
                                                        ],
                                                      ],
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

                    // Typing Indicator (Pulsing text bar)
                    if (isStrangerTyping && isRoomActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, bottom: 8.0, top: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text(
                                '$strangerName is whispering...',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fade(duration: 800.ms, begin: 0.4, end: 1.0),
                            ],
                          ),
                        ),
                      ),

                    // Chat Input text field (Send Only, No Voice mic/recording)
                    Container(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 10.0,
                        bottom: 10.0 + MediaQuery.of(context).padding.bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.border, width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: _onTextChanged,
                              enabled: isRoomActive,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: isRoomActive 
                                    ? 'Type a message...' 
                                    : '$strangerName has left the chat',
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
                          
                          // Send Button
                          InkWell(
                            onTap: isRoomActive ? _sendMessage : null,
                            borderRadius: BorderRadius.circular(50),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isRoomActive ? AppColors.accentGradient : null,
                                color: isRoomActive ? null : AppColors.surfaceGlass,
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

                // Float scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 90 + MediaQuery.of(context).padding.bottom,
                    child: FloatingActionButton.small(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.arrow_downward_rounded),
                    ).animate().scale(),
                  ),

                // Glassmorphic Disconnect Overlay
                if (!isRoomActive)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32.0),
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 25,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(
                                  Icons.heart_broken_rounded,
                                  color: AppColors.error,
                                  size: 56,
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                      duration: 1200.ms,
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1.1, 1.1),
                                    ),
                                const SizedBox(height: 20),
                                Text(
                                  '$strangerName Disconnected',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'The whisper frequency has gone cold. Find another stranger or head back to base.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                
                                // Find New Match Action
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    
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
                                  child: const Text(
                                    'FIND NEW STRANGER',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Go Home Action
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(color: AppColors.border),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'GO HOME',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 400.ms),
              ],
            );
          },
        ),
      ),
    );
  }
}
