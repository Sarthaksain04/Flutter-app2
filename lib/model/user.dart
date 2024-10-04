import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final String? link;
  final String? resumeUrl; // New field for resume URL
  final List following;
  final List followers;
  final GeoPoint? position; // GeoPoint field for user location

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.followers,
    required this.following,
    this.profileImageUrl,
    this.bio,
    this.link,
    this.resumeUrl, // Added field for resume URL
    this.position, // Position field
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'link': link,
      'resumeUrl': resumeUrl, // Add resumeUrl to map
      'following': following,
      'followers': followers,
      'position': position != null
          ? {
              'latitude': position!.latitude,
              'longitude': position!.longitude,
            }
          : null, // Handling GeoPoint
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String,
      profileImageUrl: map['profileImageUrl'] != null ? map['profileImageUrl'] as String : null,
      bio: map['bio'] != null ? map['bio'] as String : null,
      link: map['link'] != null ? map['link'] as String : null,
      resumeUrl: map['resumeUrl'] != null ? map['resumeUrl'] as String : null, // Add resumeUrl
      followers: List.from((map['followers'] as List)),
      following: List.from((map['following'] as List)),
      position: map['position'] != null
          ? GeoPoint(
              (map['position'] as Map<String, dynamic>)['latitude'],
              (map['position'] as Map<String, dynamic>)['longitude'],
            )
          : null, // Handling GeoPoint from Firestore
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
