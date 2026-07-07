class UserProfile {
  static const defaultProfileId = 'default';

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trainerLevel;
  final int money;

  UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.trainerLevel = 1,
    this.money = 0,
  });

  factory UserProfile.create(String name) {
    final now = DateTime.now();

    return UserProfile(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      updatedAt: now,
      trainerLevel: 1,
      money: 0,
    );
  }

  factory UserProfile.defaultProfile() {
    final now = DateTime.now();

    return UserProfile(
      id: defaultProfileId,
      name: 'Allenatore',
      createdAt: now,
      updatedAt: now,
      trainerLevel: 1,
      money: 0,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trainerLevel,
    int? money,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      trainerLevel: trainerLevel ?? this.trainerLevel,
      money: money ?? this.money,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'trainerLevel': trainerLevel,
      'money': money,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      trainerLevel: json['trainerLevel'] ?? 1,
      money: json['money'] ?? 0,
    );
  }
}
