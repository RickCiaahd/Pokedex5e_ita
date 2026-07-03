enum MarkMode {
  none,
  seen,
  caught,
}

class PokedexEntry {
  final int pokemonId;
  final MarkMode markMode;
  final DateTime updatedAt;

  PokedexEntry({
    required this.pokemonId,
    required this.markMode,
    required this.updatedAt,
  });

  factory PokedexEntry.empty(int pokemonId) {
    return PokedexEntry(
      pokemonId: pokemonId,
      markMode: MarkMode.none,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pokemonId': pokemonId,
      'markMode': markMode.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PokedexEntry.fromJson(Map<String, dynamic> json) {
    return PokedexEntry(
      pokemonId: json['pokemonId'],
      markMode: MarkMode.values.firstWhere(
        (mode) => mode.name == json['markMode'],
        orElse: () => MarkMode.none,
      ),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}