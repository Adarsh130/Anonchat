import 'package:cloud_firestore/cloud_firestore.dart';

class ConfessionModel {
  final String id;
  final String content;
  final String username;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likes;

  ConfessionModel({
    required this.id,
    required this.content,
    required this.username,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likes = const [],
  });

  ConfessionModel copyWith({
    String? id,
    String? content,
    String? username,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    List<String>? likes,
  }) {
    return ConfessionModel(
      id: id ?? this.id,
      content: content ?? this.content,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likes: likes ?? this.likes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'username': username,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likes': likes,
    };
  }

  factory ConfessionModel.fromMap(Map<String, dynamic> map, String id) {
    return ConfessionModel(
      id: id,
      content: map['content'] ?? '',
      username: map['username'] ?? 'Anonymous',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}
