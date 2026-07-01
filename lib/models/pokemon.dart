class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.armorClass,
    required this.hitPoints,
    required this.size,
  });

  final int id;
  final String name;
  final List<String> types;
  final int armorClass;
  final int hitPoints;
  final String size;

  factory Pokemon.fromJson(String name, Map<String, dynamic> json) {
    return Pokemon(
      id: json['index'],
      name: name,
      types: List<String>.from(json['Type'] ?? []),
      armorClass: json['AC'] ?? 0,
      hitPoints: json['HP'] ?? 0,
      size: json['size'] ?? 'Unknown',
    );
  }
}