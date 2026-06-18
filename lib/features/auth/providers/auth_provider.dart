import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../shared/models/user_model.dart';

// Provides the auth repository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Streams Firebase User state changes
final authStateProvider = StreamProvider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Streams the current user model from Firestore
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.streamCurrentUser();
});

// Modern AsyncNotifier for Auth state
final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserModel?> {
  late final AuthRepository _repository;

  @override
  FutureOr<UserModel?> build() {
    _repository = ref.watch(authRepositoryProvider);
    return null;
  }

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _repository.signInAnonymously();
    });
  }

  Future<void> createProfileIfMissing() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await _repository.createProfileIfMissing();
    });
  }

  Future<void> regenerateUsername() async {
    try {
      await _repository.regenerateUsername();
    } catch (e) {
      debugPrint("Failed to regenerate username: $e");
    }
  }

  Future<void> updateAvatarSeed(String seed) async {
    try {
      await _repository.updateAvatarSeed(seed);
    } catch (e) {
      debugPrint("Failed to update avatar seed: $e");
    }
  }

  Future<void> updateInterests(List<String> interests) async {
    try {
      await _repository.updateInterests(interests);
    } catch (e) {
      debugPrint("Failed to update interests: $e");
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
      return null;
    });
  }
}
