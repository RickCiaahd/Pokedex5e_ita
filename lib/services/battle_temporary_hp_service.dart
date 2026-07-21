import '../models/pokemon.dart';
import '../models/team_slot.dart';

class BattleTemporaryHpRule {
  const BattleTemporaryHpRule({
    required this.id,
    required this.label,
    required this.abilityAliases,
    required this.levelMultiplier,
    required this.description,
    this.brokenFormName,
  });

  final String id;
  final String label;
  final Set<String> abilityAliases;
  final int levelMultiplier;
  final String description;
  final String? brokenFormName;

  int maximumForLevel(int level) {
    return (level.clamp(1, 20) * levelMultiplier).toInt();
  }
}

class BattleTemporaryHpService {
  const BattleTemporaryHpService._();

  static const List<BattleTemporaryHpRule> rules = [
    BattleTemporaryHpRule(
      id: 'disguise',
      label: 'Fantasmanto',
      abilityAliases: {'disguise', 'fantasmanto'},
      levelMultiplier: 2,
      description:
          'Concede PF temporanei pari al doppio del livello. Quando vengono '
          'esauriti, il Fantasmanto si rompe e Mimikyu assume la Forma '
          'Smascherata.',
      brokenFormName: 'Busted',
    ),
  ];

  static BattleTemporaryHpRule? ruleFor(Pokemon pokemon, TeamSlot slot) {
    final references = slot.abilities.isNotEmpty
        ? slot.abilities
        : <String>[
            ...pokemon.abilities,
            if (pokemon.hiddenAbility != null) pokemon.hiddenAbility!,
          ];

    final keys = references.map(_key).toSet();
    for (final rule in rules) {
      if (rule.abilityAliases.any(keys.contains)) return rule;
    }
    return null;
  }

  static String _key(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(
          RegExp(r'^-+|-+$'),
          '',
        );
  }
}
