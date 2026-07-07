class PcPokemon {
  PcPokemon({
    required this.id,
    required this.pokemonId,
    DateTime? capturedAt,
    this.nickname,
    this.isShiny = false,
    this.gender,
    this.nature = 'No Nature',
    this.notes = '',
  }) : capturedAt = capturedAt ?? DateTime.now();

  final String id;
  final int pokemonId;
  final DateTime capturedAt;
  final String? nickname;
  final bool isShiny;
  final String? gender;
  final String nature;
  final String notes;

  String get displayName {
    final trimmed = nickname?.trim() ?? '';

    return trimmed.isEmpty ? '' : trimmed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pokemonId': pokemonId,
      'capturedAt': capturedAt.toIso8601String(),
      'nickname': nickname,
      'isShiny': isShiny,
      'gender': gender,
      'nature': nature,
      'notes': notes,
    };
  }

  factory PcPokemon.fromJson(Map<String, dynamic> json) {
    return PcPokemon(
      id: json['id'] as String,
      pokemonId: json['pokemonId'] as int,
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.now(),
      nickname: json['nickname'] as String?,
      isShiny: json['isShiny'] as bool? ?? false,
      gender: json['gender'] as String?,
      nature: json['nature'] as String? ?? 'No Nature',
      notes: json['notes'] as String? ?? '',
    );
  }
}
