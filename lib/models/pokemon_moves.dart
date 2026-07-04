class PokemonMoves {
  const PokemonMoves({
    required this.startingMoves,
    required this.levelMoves,
    required this.tmMoves,
  });

  final List<String> startingMoves;
  final Map<int, List<String>> levelMoves;
  final List<int> tmMoves;

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
      tmMoves: List<int>.from(json['TM'] ?? []),
    );
  }
}
