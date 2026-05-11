import 'package:cloud_firestore/cloud_firestore.dart';

class DenModel {
  final String denId;
  final String denName;
  final String inviteCode;
  final String ownerId;
  final List<String> members;
  final DateTime createdAt;
  final String? description;
  final bool sosActive;

  DenModel({
    required this.denId,
    required this.denName,
    required this.inviteCode,
    required this.ownerId,
    required this.members,
    required this.createdAt,
    this.description,
    this.sosActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'denId': denId,
      'denName': denName,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'sosActive': sosActive,
    };
  }

  factory DenModel.fromMap(Map<String, dynamic> map) {
    return DenModel(
      denId: map['denId'] ?? '',
      denName: map['denName'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      ownerId: map['ownerId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'],
      sosActive: map['sosActive'] ?? false,
    );
  }
}
