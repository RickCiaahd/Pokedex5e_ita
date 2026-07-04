class PokedexEntry {
  final int pokemonId;
  final bool seen;
  final bool caught;
  final DateTime updatedAt;

  PokedexEntry({
    required this.pokemonId,
    this.seen = false,
    this.caught = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  PokedexEntry copyWith({
    int? pokemonId,
    bool? seen,
    bool? caught,
    DateTime? updatedAt,
  }) {
    return PokedexEntry(
      pokemonId: pokemonId ?? this.pokemonId,
      seen: seen ?? this.seen,
      caught: caught ?? this.caught,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PokedexEntry.empty(int pokemonId) {
    return PokedexEntry(pokemonId: pokemonId);
  }

  Map<String, dynamic> toJson() {
    return {
      'pokemonId': pokemonId,
      'seen': seen,
      'caught': caught,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PokedexEntry.fromJson(Map<String, dynamic> json) {
    final markMode = json['markMode'] as String?;
    final updatedAt = json['updatedAt'] as String?;
    final seen =
        (json['seen'] as bool?) ?? (markMode == 'seen' || markMode == 'caught');
    final caught = (json['caught'] as bool?) ?? markMode == 'caught';

    return PokedexEntry(
      pokemonId: json['pokemonId'] as int,
      seen: seen,
      caught: caught,
      updatedAt: DateTime.tryParse(updatedAt ?? '') ?? DateTime.now(),
    );
  }
}
