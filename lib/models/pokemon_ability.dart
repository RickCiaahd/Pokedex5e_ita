class PokemonAbility {
  const PokemonAbility({
    required this.id,
    required this.name,
    required this.description,
    required this.deprecated,
  });

  final String id;
  final String name;
  final String description;
  final bool deprecated;

  factory PokemonAbility.fromWebJson(Map<String, dynamic> json) {
    return PokemonAbility(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Abilità sconosciuta',
      description: json['description']?.toString() ?? '',
      deprecated: json['deprecated'] == true,
    );
  }
}
