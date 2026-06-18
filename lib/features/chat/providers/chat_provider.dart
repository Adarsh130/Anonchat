import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../../../shared/models/chat_room_model.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/user_model.dart';

// Provides the chat repository instance
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

// Streams chat room metadata (active state, typing maps)
final chatRoomStreamProvider = StreamProvider.family<ChatRoomModel?, String>((ref, roomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getChatRoom(roomId);
});

// Streams list of messages within the chat room
final messagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, roomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(roomId);
});

// Streams the stranger's presence profile
final strangerProfileProvider = StreamProvider.family<UserModel?, String>((ref, strangerId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getStrangerProfile(strangerId);
});
