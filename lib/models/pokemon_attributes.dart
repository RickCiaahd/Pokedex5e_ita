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
      strength: _readInt(json['STR'] ?? json['str']),
      dexterity: _readInt(json['DEX'] ?? json['dex']),
      constitution: _readInt(json['CON'] ?? json['con']),
      intelligence: _readInt(json['INT'] ?? json['int']),
      wisdom: _readInt(json['WIS'] ?? json['wis']),
      charisma: _readInt(json['CHA'] ?? json['cha']),
    );
  }

  factory PokemonAttributes.fromWebJson(Map<String, dynamic> json) {
    return PokemonAttributes.fromJson(json);
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
