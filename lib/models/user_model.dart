import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? denId;
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.denId,
    this.latitude,
    this.longitude,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'denId': denId,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      denId: map['denId'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}
