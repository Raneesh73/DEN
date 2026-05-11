import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final List<String> joinedDenIds;
  final String? activeDenId;
  final String status; // 'online', 'offline', 'sos'
  final String? bio;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.joinedDenIds,
    this.activeDenId,
    required this.status,
    this.bio,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'joinedDenIds': joinedDenIds,
      'activeDenId': activeDenId,
      'status': status,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? map['name'] ?? '', // Fallback to 'name' if existing data
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      joinedDenIds: List<String>.from(map['joinedDenIds'] ?? []),
      activeDenId: map['activeDenId'] ?? map['denId'], // Fallback to 'denId' if existing data
      status: map['status'] ?? 'online',
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  // Deprecated field getter for backward compatibility during migration
  String get name => username;
  String? get denId => activeDenId;
}
