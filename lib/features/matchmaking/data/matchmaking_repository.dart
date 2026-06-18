import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/chat_room_model.dart';

class MatchmakingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream active chat rooms for the current user
  Stream<ChatRoomModel?> listenForMatch(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          // Sort in-memory by createdAt descending
          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.docs);
          docs.sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          final doc = docs.first;
          return ChatRoomModel.fromMap(doc.data(), doc.id);
        });
  }

  // Atomically check the queue and match or join queue
  Future<String?> findMatch(String currentUserId, String currentUsername) async {
    final queueRef = _firestore.collection('waiting_users');
    final roomsRef = _firestore.collection('chat_rooms');

    try {
      // Run Firestore Transaction
      return await _firestore.runTransaction<String?>((transaction) async {
        // Query candidates outside or inside. Since query read is async,
        // we can fetch the candidate first.
        // Wait, Firestore transactions require all reads before writes.
        // So we query the queue.
        final querySnapshot = await queueRef
            .orderBy('createdAt', descending: false)
            .limit(10)
            .get();

        DocumentSnapshot? candidateDoc;
        for (var doc in querySnapshot.docs) {
          if (doc.id != currentUserId) {
            candidateDoc = doc;
            break;
          }
        }

        if (candidateDoc != null) {
          // Verify candidate is still in queue using the transaction lock
          final candidateRef = queueRef.doc(candidateDoc.id);
          final freshSnapshot = await transaction.get(candidateRef);

          if (freshSnapshot.exists) {
            // Match found! Delete candidate from queue
            transaction.delete(candidateRef);

            // Also clean up current user from queue in case they were in it
            transaction.delete(queueRef.doc(currentUserId));

            // Create new Chat Room
            final newRoomRef = roomsRef.doc();
            transaction.set(newRoomRef, {
              'roomId': newRoomRef.id,
              'participants': [candidateDoc.id, currentUserId],
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'lastMessage': '',
              'lastMessageSenderId': '',
              'lastMessageTimestamp': FieldValue.serverTimestamp(),
              'typingStatus': {
                candidateDoc.id: false,
                currentUserId: false,
              },
            });

            return newRoomRef.id;
          }
        }

        // No match found: Add current user to waiting_users queue
        final myQueueRef = queueRef.doc(currentUserId);
        transaction.set(myQueueRef, {
          'uid': currentUserId,
          'username': currentUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return null;
      });
    } catch (e) {
      debugPrint('Matchmaking transaction failed: $e');
      // If transaction failed, attempt to add user to queue directly
      try {
        await queueRef.doc(currentUserId).set({
          'uid': currentUserId,
          'username': currentUsername,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (err) {
        debugPrint('Direct queue fallback failed: $err');
      }
      return null;
    }
  }

  // Cancel matchmaking by removing user from queue
  Future<void> cancelMatch(String currentUserId) async {
    try {
      await _firestore.collection('waiting_users').doc(currentUserId).delete();
    } catch (e) {
      debugPrint('Failed to cancel matchmaking: $e');
    }
  }
}
