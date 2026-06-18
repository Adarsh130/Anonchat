import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/matchmaking_repository.dart';
import '../../../shared/models/chat_room_model.dart';

// Matchmaking states
enum MatchmakingStatus { idle, searching, matched }

class MatchmakingState {
  final MatchmakingStatus status;
  final String? roomId;
  final String? error;

  MatchmakingState({
    required this.status,
    this.roomId,
    this.error,
  });

  factory MatchmakingState.idle() => MatchmakingState(status: MatchmakingStatus.idle);
  factory MatchmakingState.searching() => MatchmakingState(status: MatchmakingStatus.searching);
  factory MatchmakingState.matched(String id) => MatchmakingState(status: MatchmakingStatus.matched, roomId: id);
  factory MatchmakingState.error(String err) => MatchmakingState(status: MatchmakingStatus.idle, error: err);
}

// Provides matchmaking repository
final matchmakingRepositoryProvider = Provider<MatchmakingRepository>((ref) {
  return MatchmakingRepository();
});

// Streams active matching rooms for a user
final activeMatchStreamProvider = StreamProvider.family<ChatRoomModel?, String>((ref, uid) {
  final repository = ref.watch(matchmakingRepositoryProvider);
  return repository.listenForMatch(uid);
});

// Modern Notifier for Matchmaking
final matchmakingControllerProvider = NotifierProvider<MatchmakingNotifier, MatchmakingState>(() {
  return MatchmakingNotifier();
});

class MatchmakingNotifier extends Notifier<MatchmakingState> {
  late final MatchmakingRepository _repository;
  StreamSubscription<ChatRoomModel?>? _streamSubscription;

  @override
  MatchmakingState build() {
    _repository = ref.watch(matchmakingRepositoryProvider);
    ref.onDispose(() {
      _streamSubscription?.cancel();
    });
    return MatchmakingState.idle();
  }

  Future<void> startMatchmaking(String uid, String username) async {
    state = MatchmakingState.searching();
    
    try {
      // 1. Attempt transaction matchmaking
      final resultRoomId = await _repository.findMatch(uid, username);
      if (resultRoomId != null) {
        state = MatchmakingState.matched(resultRoomId);
        return;
      }
      
      // 2. If no immediate match, listen to active room changes
      _listenToMatchStream(uid);
    } catch (e) {
      state = MatchmakingState.error(e.toString());
    }
  }

  void _listenToMatchStream(String uid) {
    _streamSubscription?.cancel();
    _streamSubscription = _repository.listenForMatch(uid).listen(
      (room) {
        if (state.status == MatchmakingStatus.searching && room != null) {
          state = MatchmakingState.matched(room.roomId);
          _streamSubscription?.cancel();
          _streamSubscription = null;
        }
      },
      onError: (err) {
        state = MatchmakingState.error(err.toString());
      },
    );
  }

  Future<void> cancelMatchmaking(String uid) async {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    state = MatchmakingState.idle();
    await _repository.cancelMatch(uid);
  }

  void resetToIdle() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    state = MatchmakingState.idle();
  }
}
