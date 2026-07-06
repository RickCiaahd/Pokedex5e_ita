import 'package:flutter/material.dart';

class PokemonStatusCondition {
  const PokemonStatusCondition({
    required this.key,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    this.assetBaseName,
  });

  final String key;
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final String? assetBaseName;

  String? assetPath({required bool selected}) {
    final baseName = assetBaseName;
    if (baseName == null) {
      return null;
    }
    return 'assets/textures/gui/status/${baseName}_${selected ? 'down' : 'up'}.png';
  }
}

class PokemonStatusConditions {
  const PokemonStatusConditions._();

  static const all = <PokemonStatusCondition>[
    PokemonStatusCondition(
      key: 'burned',
      label: 'BURNED',
      description:
          'Rolls all damage rolls twice and takes the lower result. Until cured or the creature becomes unconscious, it takes damage equal to its proficiency bonus at the end of each of its turns. Fire-type Pokemon are immune to this condition.',
      assetBaseName: 'burn',
      color: Colors.deepOrange,
      icon: Icons.local_fire_department,
    ),
    PokemonStatusCondition(
      key: 'poisoned',
      label: 'POISONED',
      description:
          'Disadvantage on all ability checks and attack rolls. Until cured or the creature becomes unconscious, it takes damage equal to its proficiency bonus at the end of each of its turns. Poison- and Steel-type Pokemon are immune to this condition.',
      assetBaseName: 'poisoned',
      color: Colors.purple,
      icon: Icons.coronavirus,
    ),
    PokemonStatusCondition(
      key: 'paralyzed',
      label: 'PARALYZED',
      description:
          'Disadvantage on STR and DEX saving throws, and moves at half speed. At the start of its turn, roll a d4. On a 1, the creature is incapacitated and restrained until the start of its next turn. Electric-type Pokemon are immune to this condition.',
      assetBaseName: 'paralyze',
      color: Colors.amber,
      icon: Icons.bolt,
    ),
    PokemonStatusCondition(
      key: 'asleep',
      label: 'ASLEEP',
      description:
          'Incapacitated and restrained, and rolls all saving throws with disadvantage. Lasts three rounds. When subject to forced movement and at the end of each of its turns, roll a d20. On 11 or higher, the condition ends.',
      assetBaseName: 'sleep',
      color: Colors.indigo,
      icon: Icons.bedtime,
    ),
    PokemonStatusCondition(
      key: 'frozen',
      label: 'FROZEN',
      description:
          'Incapacitated and restrained. Lasts 1 hour, or until the creature breaks free at the end of one of its turns with a STR save DC 10 + the proficiency of the creature that caused this condition. Ends if the creature takes fire-type damage or damage from a move that can afflict Burned. Ice-type Pokemon are immune to this condition.',
      assetBaseName: 'frozen',
      color: Colors.lightBlue,
      icon: Icons.ac_unit,
    ),
    PokemonStatusCondition(
      key: 'confused',
      label: 'CONFUSED',
      description:
          'Cannot take reactions. Lasts three rounds. At the start of the creature\'s turn, roll a d8: 1 Struggle against itself, 2 Struggle against the nearest Pokemon target, 3 no movement or actions, 4-7 acts normally, 8 the condition ends.',
      assetBaseName: 'confuse',
      color: Colors.pink,
      icon: Icons.psychology,
    ),
    PokemonStatusCondition(
      key: 'flinched',
      label: 'FLINCHED',
      description:
          'Disadvantage on all attack rolls, ability checks, and saving throws until the end of its next turn. If the creature uses an action that requires a saving throw, the targets have advantage on the roll.',
      color: Colors.blueGrey,
      icon: Icons.priority_high,
    ),
  ];

  static PokemonStatusCondition byKey(String key) {
    return all.firstWhere(
      (condition) => condition.key == key,
      orElse: () => PokemonStatusCondition(
        key: key,
        label: key.toUpperCase(),
        description: 'Descrizione non disponibile.',
        color: Colors.grey,
        icon: Icons.help_outline,
      ),
    );
  }
}

class PokemonStatusIcon extends StatelessWidget {
  const PokemonStatusIcon({
    super.key,
    required this.condition,
    this.selected = false,
    this.size = 36,
  });

  final PokemonStatusCondition condition;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = condition.assetPath(selected: selected);
    final fallback = _fallback(context);

    if (assetPath == null) {
      return fallback;
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? condition.color : condition.color.withValues(alpha: 0.22),
        border: Border.all(color: condition.color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        condition.icon,
        color: selected ? Colors.white : condition.color,
        size: size * 0.62,
      ),
    );
  }
}
