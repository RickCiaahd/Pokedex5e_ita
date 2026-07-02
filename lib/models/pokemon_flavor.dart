class PokemonFlavor {
  const PokemonFlavor({
    required this.flavor,
    required this.height,
    required this.weight,
    required this.genus,
  });

  final String flavor;
  final int height;
  final int weight;
  final String genus;

  double get heightMeters => height / 10;
  double get weightKg => weight / 10;

  factory PokemonFlavor.fromJson(Map<String, dynamic> json) {
    return PokemonFlavor(
      flavor: json['flavor'] as String? ?? '',
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      genus: json['genus'] as String? ?? '',
    );
  }
}