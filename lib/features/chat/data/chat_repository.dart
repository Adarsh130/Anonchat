import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/chat_room_model.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/user_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream room details (isActive, typingStatus, lastMessage)
  Stream<ChatRoomModel?> getChatRoom(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return ChatRoomModel.fromMap(snapshot.data()!, snapshot.id);
        });
  }

  // Stream messages in a room, sorted by oldest first for scrolling view
  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Send a message
  Future<void> sendMessage(String roomId, String senderId, String text) async {
    try {
      final messagesRef = _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages');

      // Create batched write to ensure both documents are updated atomically
      final batch = _firestore.batch();
      
      final newMessageRef = messagesRef.doc();
      batch.set(newMessageRef, {
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });

      final roomRef = _firestore.collection('chat_rooms').doc(roomId);
      batch.update(roomRef, {
        'lastMessage': text,
        'lastMessageSenderId': senderId,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Update typing status for current user in the room
  Future<void> updateTypingStatus(String roomId, String userId, bool isTyping) async {
    try {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'typingStatus.$userId': isTyping,
      });
    } catch (e) {
      debugPrint('Failed to update typing status: $e');
    }
  }

  // Mark room as inactive (Stranger leaves)
  Future<void> disconnectFromChat(String roomId) async {
    try {
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Failed to disconnect from room: $e');
    }
  }

  // Stream the stranger's user profile (to show their online status)
  Stream<UserModel?> getStrangerProfile(String strangerId) {
    return _firestore
        .collection('users')
        .doc(strangerId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return UserModel.fromMap(snapshot.data()!);
        });
  }
}
