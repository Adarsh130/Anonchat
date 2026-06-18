import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String roomId;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTimestamp;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, bool> typingStatus; // Map of uid -> isTyping

  ChatRoomModel({
    required this.roomId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTimestamp,
    required this.createdAt,
    required this.isActive,
    required this.typingStatus,
  });

  ChatRoomModel copyWith({
    String? roomId,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTimestamp,
    DateTime? createdAt,
    bool? isActive,
    Map<String, bool>? typingStatus,
  }) {
    return ChatRoomModel(
      roomId: roomId ?? this.roomId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      typingStatus: typingStatus ?? this.typingStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTimestamp': lastMessageTimestamp != null 
          ? Timestamp.fromDate(lastMessageTimestamp!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'typingStatus': typingStatus,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    // Handle parsing the typingStatus map safely
    final rawTyping = map['typingStatus'] as Map<dynamic, dynamic>? ?? {};
    final Map<String, bool> typedTyping = {};
    rawTyping.forEach((key, value) {
      typedTyping[key.toString()] = value == true;
    });

    return ChatRoomModel(
      roomId: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTimestamp: (map['lastMessageTimestamp'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      typingStatus: typedTyping,
    );
  }
}
