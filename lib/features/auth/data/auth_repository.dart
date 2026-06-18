import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/utils/username_generator.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of FirebaseAuth user state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream current user data from Firestore
  Stream<UserModel?> streamCurrentUser() {
    final uid = currentUserId;
    if (uid == null) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return UserModel.fromMap(snapshot.data()!);
        });
  }

  // Sign in anonymously and register in Firestore
  Future<UserModel> signInAnonymously() async {
    try {
      // 1. Sign in with Firebase Anonymous Auth
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Anonymous authentication failed. User is null.');
      }

      // 2. Check if user document already exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        // User already exists, update status to online
        final existingUser = UserModel.fromMap(userDoc.data()!);
        await updateOnlineStatus(true);
        return existingUser.copyWith(isOnline: true);
      } else {
        // 3. New user: generate username and save to Firestore
        final generatedUsername = UsernameGenerator.generate();
        final newUser = UserModel(
          uid: user.uid,
          username: generatedUsername,
          isOnline: true,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          avatarSeed: generatedUsername,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());

        return newUser;
      }
    } catch (e) {
      throw Exception('Failed to sign in anonymously: $e');
    }
  }

  // Automatically create a user profile document if it is missing in Firestore
  Future<UserModel?> createProfileIfMissing() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data() == null) {
        final generatedUsername = UsernameGenerator.generate();
        final newUser = UserModel(
          uid: user.uid,
          username: generatedUsername,
          isOnline: true,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          avatarSeed: generatedUsername,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
        
        return newUser;
      } else {
        final existingUser = UserModel.fromMap(userDoc.data()!);
        await updateOnlineStatus(true);
        return existingUser.copyWith(isOnline: true);
      }
    } catch (e) {
      debugPrint('Failed to create profile if missing: $e');
      return null;
    }
  }

  // Update online presence status in Firestore
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If the document doesn't exist yet, we catch the error silently
      debugPrint('Error updating online status: $e');
    }
  }

  // Generate a new username for the user
  Future<void> regenerateUsername() async {
    final uid = currentUserId;
    if (uid == null) return;

    final newUsername = UsernameGenerator.generate();
    await _firestore.collection('users').doc(uid).update({
      'username': newUsername,
    });
  }

  // Update avatar customization seed in Firestore
  Future<void> updateAvatarSeed(String seed) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'avatarSeed': seed,
    });
  }

  // Update interests list in Firestore
  Future<void> updateInterests(List<String> interests) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'interests': interests,
    });
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
