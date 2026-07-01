import 'pokemon_attributes.dart';
import 'pokemon_moves.dart';

class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.armorClass,
    required this.hitPoints,
    required this.size,
    required this.speed,
    required this.attributes,
    required this.abilities,
    required this.hiddenAbility,
    required this.skills,
    required this.savingThrows,
    required this.moves,
    required this.hitDice,
    required this.sr,
    required this.minLevelFound,
  });

  final int id;
  final String name;
  final List<String> types;
  final int armorClass;
  final int hitPoints;
  final String size;
  final int speed;
  final PokemonAttributes attributes;
  final List<String> abilities;
  final String? hiddenAbility;
  final List<String> skills;
  final List<String> savingThrows;
  final PokemonMoves moves;
  final int hitDice;
  final double sr;
  final int minLevelFound;

  factory Pokemon.fromJson(String name, Map<String, dynamic> json) {
    return Pokemon(
      id: json['index'] ?? 0,
      name: name,
      types: List<String>.from(json['Type'] ?? []),
      armorClass: json['AC'] ?? 0,
      hitPoints: json['HP'] ?? 0,
      size: json['size'] ?? 'Unknown',
      speed: json['WSp'] ?? 0,
      attributes: PokemonAttributes.fromJson(
        Map<String, dynamic>.from(json['attributes'] ?? {}),
      ),
      abilities: List<String>.from(json['Abilities'] ?? []),
      hiddenAbility: json['Hidden Ability'],
      skills: List<String>.from(json['Skill'] ?? []),
      savingThrows: List<String>.from(json['saving_throws'] ?? []),
      moves: PokemonMoves.fromJson(json['Moves']),
      hitDice: json['Hit Dice'] ?? 0,
      sr: (json['SR'] ?? 0).toDouble(),
      minLevelFound: json['MIN LVL FD'] ?? 0,
    );
  }
}