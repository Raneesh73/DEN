class DenModel {
  final String denId;
  final String denName;
  final String inviteCode;
  final String ownerId;
  final List<String> members;

  DenModel({
    required this.denId,
    required this.denName,
    required this.inviteCode,
    required this.ownerId,
    required this.members,
  });

  Map<String, dynamic> toMap() {
    return {
      'denId': denId,
      'denName': denName,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'members': members,
    };
  }

  factory DenModel.fromMap(Map<String, dynamic> map) {
    return DenModel(
      denId: map['denId'] ?? '',
      denName: map['denName'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      ownerId: map['ownerId'] ?? '',
      members: List<String>.from(map['members'] ?? []),
    );
  }
}
