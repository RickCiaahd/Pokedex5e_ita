class PokemonMoves {
  const PokemonMoves({
    required this.startingMoves,
    required this.levelMoves,
    required this.tmMoves,
    this.eggMoves = const [],
  });

  final List<String> startingMoves;
  final Map<int, List<String>> levelMoves;
  final List<int> tmMoves;
  final List<String> eggMoves;

  factory PokemonMoves.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []);
    }

    final levelJson = Map<String, dynamic>.from(json['Level'] ?? {});

    return PokemonMoves(
      startingMoves: List<String>.from(json['Starting Moves'] ?? []),
      levelMoves: levelJson.map(
        (key, value) => MapEntry(int.parse(key), List<String>.from(value)),
      ),
      tmMoves: _readIntList(json['TM']),
      eggMoves: _readStringList(json['egg'] ?? json['Egg Moves']),
    );
  }

  factory PokemonMoves.fromWebJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []);
    }

    final levelMoves = <int, List<String>>{};
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase().trim();
      if (!key.startsWith('level')) continue;

      final level = int.tryParse(key.replaceFirst('level', ''));
      if (level == null) continue;

      levelMoves[level] = _readStringList(entry.value);
    }

    return PokemonMoves(
      startingMoves: _readStringList(json['start']),
      levelMoves: levelMoves,
      tmMoves: _readIntList(json['tm']),
      eggMoves: _readStringList(json['egg'] ?? json['eggMoves']),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return const [];
  }

  static List<int> _readIntList(dynamic value) {
    if (value is List) {
      return value
          .map((item) {
            if (item is int) return item;
            if (item is num) return item.toInt();
            return int.tryParse(item.toString());
          })
          .whereType<int>()
          .toList(growable: false);
    }

    return const [];
  }
}
