class UserProfile {
  static const defaultProfileId = 'default';

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.create(String name) {
    final now = DateTime.now();

    return UserProfile(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProfile.defaultProfile() {
    final now = DateTime.now();

    return UserProfile(
      id: defaultProfileId,
      name: 'Allenatore',
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
