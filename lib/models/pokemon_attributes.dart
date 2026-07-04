class PokemonAttributes {
  const PokemonAttributes({
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
  });

  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  factory PokemonAttributes.fromJson(Map<String, dynamic> json) {
    return PokemonAttributes(
      strength: json['STR'] ?? 0,
      dexterity: json['DEX'] ?? 0,
      constitution: json['CON'] ?? 0,
      intelligence: json['INT'] ?? 0,
      wisdom: json['WIS'] ?? 0,
      charisma: json['CHA'] ?? 0,
    );
  }
}
