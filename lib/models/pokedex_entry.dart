class PokedexEntry {
  const PokedexEntry({
    required this.pokemonId,
    this.seen = false,
    this.caught = false,
  });

  final int pokemonId;
  final bool seen;
  final bool caught;

  PokedexEntry copyWith({
    bool? seen,
    bool? caught,
  }) {
    return PokedexEntry(
      pokemonId: pokemonId,
      seen: seen ?? this.seen,
      caught: caught ?? this.caught,
    );
  }
}