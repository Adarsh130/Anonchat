import 'package:cloud_firestore/cloud_firestore.dart';

class PublicRoomModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final int activeUsersCount;
  final DateTime createdAt;
  final String lastMessage;
  final String lastMessageSender;
  final DateTime lastMessageTimestamp;

  PublicRoomModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.activeUsersCount,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageSender = '',
    required this.lastMessageTimestamp,
  });

  PublicRoomModel copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    int? activeUsersCount,
    DateTime? createdAt,
    String? lastMessage,
    String? lastMessageSender,
    DateTime? lastMessageTimestamp,
  }) {
    return PublicRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      activeUsersCount: activeUsersCount ?? this.activeUsersCount,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'activeUsersCount': activeUsersCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageSender': lastMessageSender,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
    };
  }

  factory PublicRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return PublicRoomModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      activeUsersCount: map['activeUsersCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSender: map['lastMessageSender'] ?? '',
      lastMessageTimestamp: (map['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
