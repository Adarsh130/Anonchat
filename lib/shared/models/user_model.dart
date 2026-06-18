import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime lastSeen;
  
  // Custom premium stats & attributes
  final int reputationScore;
  final String avatarSeed;
  final List<String> interests;
  final Map<String, dynamic> chatStats;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.username,
    required this.isOnline,
    required this.createdAt,
    required this.lastSeen,
    this.reputationScore = 100,
    required this.avatarSeed,
    this.interests = const [],
    this.chatStats = const {'totalChats': 0, 'minutesChatted': 0},
    this.blockedUsers = const [],
  });

  UserModel copyWith({
    String? uid,
    String? username,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? lastSeen,
    int? reputationScore,
    String? avatarSeed,
    List<String>? interests,
    Map<String, dynamic>? chatStats,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      reputationScore: reputationScore ?? this.reputationScore,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      interests: interests ?? this.interests,
      chatStats: chatStats ?? this.chatStats,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'reputationScore': reputationScore,
      'avatarSeed': avatarSeed,
      'interests': interests,
      'chatStats': chatStats,
      'blockedUsers': blockedUsers,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? 'Anonymous',
      isOnline: map['isOnline'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reputationScore: map['reputationScore'] ?? 100,
      avatarSeed: map['avatarSeed'] ?? map['username'] ?? 'anon',
      interests: List<String>.from(map['interests'] ?? []),
      chatStats: Map<String, dynamic>.from(map['chatStats'] ?? {'totalChats': 0, 'minutesChatted': 0}),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
    );
  }
}
