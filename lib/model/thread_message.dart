// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ThreadMessage {
  final String id;
  final String senderName;
  final String senderProfileImageUrl;
  final String message;
  final DateTime timestamp;
  final List likes;
  final List comments;
  final String imageUrl; // Optional field for image URL

  ThreadMessage({
    required this.id,
    required this.senderName,
    required this.senderProfileImageUrl,
    required this.message,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.imageUrl, // Initialize the optional field
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'senderName': senderName,
      'senderProfileImageUrl': senderProfileImageUrl,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'likes': likes,
      'comments': comments,
      'imageUrl': imageUrl, // Include the image URL in the map
    };
  }

  factory ThreadMessage.fromMap(Map<String, dynamic> map) {
    return ThreadMessage(
      id: map['id'] as String,
      senderName: map['senderName'] as String,
      senderProfileImageUrl: map['senderProfileImageUrl'] as String,
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      likes: List.from((map['likes'] as List)),
      comments: List.from((map['comments'] as List)),
      imageUrl: map['imageUrl'] as String, // Handle optional image URL
    );
  }

  String toJson() => json.encode(toMap());

  factory ThreadMessage.fromJson(String source) =>
      ThreadMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  factory ThreadMessage.empty() {
    return ThreadMessage(
      id: '',
      senderName: '',
      senderProfileImageUrl: '',
      message: '',
      timestamp: DateTime.now(),
      likes: [],
      comments: [],
      imageUrl: '', // Default to null if no image URL is provided
    );
  }
}
