class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.armorClass,
    required this.hitPoints,
  });

  final int id;
  final String name;
  final List<String> types;
  final int armorClass;
  final int hitPoints;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      types: List<String>.from(json['types']),
      armorClass: json['armorClass'],
      hitPoints: json['hitPoints'],
    );
  }
}