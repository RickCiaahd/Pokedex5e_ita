from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return text.replace(old, new, 1)


def replace_regex(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return updated


PASSIVE_SERVICE = r'''import '../models/level_progression.dart';
import '../models/move_data.dart';
import '../models/pokemon.dart';
import '../models/pokemon_nature.dart';
import '../models/team_slot.dart';
import '../models/trainer_manual_options.dart';
import '../models/user_profile.dart';

class TrainerPathPassiveNote {
  const TrainerPathPassiveNote({required this.title, required this.detail});

  final String title;
  final String detail;
}

class TrainerPathStabEffect {
  const TrainerPathStabEffect({
    required this.applies,
    required this.pathBonus,
    required this.extendedByPath,
  });

  final bool applies;
  final int pathBonus;
  final bool extendedByPath;
}

class TrainerPathPassiveService {
  const TrainerPathPassiveService._();

  static const Map<String, String> _typeAliases = {
    'normal': 'normal',
    'normale': 'normal',
    'fire': 'fire',
    'fuoco': 'fire',
    'water': 'water',
    'acqua': 'water',
    'electric': 'electric',
    'elettro': 'electric',
    'grass': 'grass',
    'erba': 'grass',
    'ice': 'ice',
    'ghiaccio': 'ice',
    'fighting': 'fighting',
    'lotta': 'fighting',
    'poison': 'poison',
    'veleno': 'poison',
    'ground': 'ground',
    'terra': 'ground',
    'flying': 'flying',
    'volante': 'flying',
    'psychic': 'psychic',
    'psico': 'psychic',
    'bug': 'bug',
    'coleottero': 'bug',
    'rock': 'rock',
    'roccia': 'rock',
    'ghost': 'ghost',
    'spettro': 'ghost',
    'dragon': 'dragon',
    'drago': 'dragon',
    'dark': 'dark',
    'buio': 'dark',
    'steel': 'steel',
    'acciaio': 'steel',
    'fairy': 'fairy',
    'folletto': 'fairy',
  };

  static bool hasFeature(
    UserProfile? profile, {
    required String trainerPath,
    required int level,
  }) {
    if (profile == null || profile.trainerLevel < level) return false;
    if (profile.trainerPath == trainerPath) return true;

    if (profile.trainerPath != 'Hobbyist' || profile.trainerLevel < 9) {
      return false;
    }
    final copied = profile.trainerPathChoices['hobbyistManyFaces'] ?? '';
    return copied.startsWith('$trainerPath · Lv $level ·');
  }

  static Map<String, int> effectiveAttributeScores({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
  }) {
    final custom = slot?.customAbilityScores ?? const <String, int>{};
    final nature = PokemonNature.forName(slot?.nature ?? 'No Nature');
    final bonuses = <String, int>{};

    if (slot != null &&
        hasFeature(profile, trainerPath: 'Ace Trainer', level: 9)) {
      final choice = profile?.trainerPathChoices['aceMaxPotential'];
      if (choice != null && choice.startsWith('+1 ')) {
        bonuses[choice.substring(3).trim().toUpperCase()] = 1;
      }
    }

    return {
      'STR': pokemon.attributes.strength +
          (custom['STR'] ?? 0) +
          (nature['STR'] ?? 0) +
          (bonuses['STR'] ?? 0),
      'DEX': pokemon.attributes.dexterity +
          (custom['DEX'] ?? 0) +
          (nature['DEX'] ?? 0) +
          (bonuses['DEX'] ?? 0),
      'CON': pokemon.attributes.constitution +
          (custom['CON'] ?? 0) +
          (nature['CON'] ?? 0) +
          (bonuses['CON'] ?? 0),
      'INT': pokemon.attributes.intelligence +
          (custom['INT'] ?? 0) +
          (nature['INT'] ?? 0) +
          (bonuses['INT'] ?? 0),
      'WIS': pokemon.attributes.wisdom +
          (custom['WIS'] ?? 0) +
          (nature['WIS'] ?? 0) +
          (bonuses['WIS'] ?? 0),
      'CHA': pokemon.attributes.charisma +
          (custom['CHA'] ?? 0) +
          (nature['CHA'] ?? 0) +
          (bonuses['CHA'] ?? 0),
    };
  }

  static int effectiveSpeed({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
  }) {
    if (slot == null || pokemon.speed <= 0) return pokemon.speed;
    final choice = profile?.trainerPathChoices['aceMaxPotential'];
    final bonus = hasFeature(profile, trainerPath: 'Ace Trainer', level: 9) &&
            choice == '+10 ft velocità'
        ? 10
        : 0;
    return pokemon.speed + bonus;
  }

  static int attackRollBonus({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
  }) {
    if (slot == null) return 0;
    var bonus = 0;
    if (hasFeature(profile, trainerPath: 'Ace Trainer', level: 2)) {
      bonus += 1;
    }
    if (hasFeature(profile, trainerPath: 'Type Master', level: 5) &&
        matchingSpecializationCount(profile, pokemon) > 0) {
      bonus += 2;
    }
    return bonus;
  }

  static int damageRollBonus({
    required UserProfile? profile,
    required TeamSlot? slot,
  }) {
    if (slot == null) return 0;
    return hasFeature(profile, trainerPath: 'Ace Trainer', level: 2) ? 1 : 0;
  }

  static TrainerPathStabEffect stabEffect({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
    required MoveData move,
    required int pokemonLevel,
  }) {
    final damaging = move.damageForLevel(pokemonLevel) != null ||
        move.damageByLevel.isNotEmpty ||
        move.damageModifier != null ||
        move.damageTypes.isNotEmpty;
    if (!damaging) {
      return const TrainerPathStabEffect(
        applies: false,
        pathBonus: 0,
        extendedByPath: false,
      );
    }

    final pokemonTypes = pokemon.types.map(_normalizeType).toSet();
    final sameType = pokemonTypes.contains(_normalizeType(move.type));
    if (slot == null) {
      return TrainerPathStabEffect(
        applies: sameType,
        pathBonus: 0,
        extendedByPath: false,
      );
    }

    final matchingTypes = matchingSpecializationCount(profile, pokemon);
    final hasTypeMaster =
        hasFeature(profile, trainerPath: 'Type Master', level: 2) &&
            matchingTypes > 0;
    final canExtend =
        hasFeature(profile, trainerPath: 'Type Master', level: 15) &&
            matchingTypes > 0;
    final applies = sameType || canExtend;

    return TrainerPathStabEffect(
      applies: applies,
      pathBonus: hasTypeMaster && applies ? matchingTypes.clamp(0, 2) : 0,
      extendedByPath: canExtend && !sameType,
    );
  }

  static int matchingSpecializationCount(
    UserProfile? profile,
    Pokemon pokemon,
  ) {
    if (profile == null) return 0;
    final specializedTypes = profile.specializations
        .map((name) => TrainerManualOptions.specializationTypeByName[name])
        .whereType<String>()
        .map(_normalizeType)
        .toSet();
    final matching = pokemon.types
        .map(_normalizeType)
        .where(specializedTypes.contains)
        .toSet()
        .length;
    return matching.clamp(0, 2).toInt();
  }

  static int maxHp({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
    int? level,
  }) {
    final resolvedLevel = level ??
        (slot == null
            ? pokemon.minLevelFound
            : LevelProgression.levelFromExperience(slot.experience));
    final safeLevel = resolvedLevel.clamp(1, LevelProgression.maxLevel).toInt();
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (safeLevel - minimumLevel)
        .clamp(0, LevelProgression.maxLevel)
        .toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final attributes = effectiveAttributeScores(
      profile: profile,
      pokemon: pokemon,
      slot: slot,
    );
    final constitutionModifier = ((attributes['CON'] ?? 10) - 10) ~/ 2;
    final toughBonus = slot?.feats.contains('Tough') == true
        ? safeLevel * 2
        : 0;
    final loyaltyBonus = loyaltyHpBonus(
      profile: profile,
      loyalty: slot?.loyalty ?? 0,
      level: safeLevel,
    );
    final hp = pokemon.hitPoints +
        (hitDieAverage * levelsGained) +
        (constitutionModifier * safeLevel) +
        toughBonus +
        loyaltyBonus;
    return hp < 1 ? 1 : hp;
  }

  static int loyaltyHpBonus({
    required UserProfile? profile,
    required int loyalty,
    required int level,
  }) {
    final base = switch (loyalty) {
      2 => (level / 2).ceil(),
      3 => level,
      _ => 0,
    };
    final doubled = hasFeature(profile, trainerPath: 'Commander', level: 2);
    return doubled && base > 0 ? base * 2 : base;
  }

  static int loyaltySavingThrowBonus({
    required UserProfile? profile,
    required int loyalty,
  }) {
    final base = loyalty.clamp(-1, 1).toInt();
    final doubled = hasFeature(profile, trainerPath: 'Commander', level: 2);
    return doubled && base > 0 ? base * 2 : base;
  }

  static List<String> savingThrowProficiencies({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
  }) {
    final saves = <String>{...pokemon.savingThrows};
    if (slot != null && hasFeature(profile, trainerPath: 'Guru', level: 5)) {
      saves.add('WIS');
    }
    return saves.toList(growable: false);
  }

  static int initialCapturedLoyalty(UserProfile profile) {
    return hasFeature(profile, trainerPath: 'Commander', level: 5) ? 1 : 0;
  }

  static int? starterLoyaltyFloor(UserProfile profile) {
    return hasFeature(profile, trainerPath: 'Commander', level: 2) ? 2 : null;
  }

  static List<TrainerPathPassiveNote> passiveNotes({
    required UserProfile? profile,
    required Pokemon pokemon,
    required TeamSlot? slot,
  }) {
    if (profile == null || slot == null || profile.trainerPath.isEmpty) {
      return const [];
    }
    final notes = <TrainerPathPassiveNote>[];

    final attackBonus = attackRollBonus(
      profile: profile,
      pokemon: pokemon,
      slot: slot,
    );
    final damageBonus = damageRollBonus(profile: profile, slot: slot);
    if (attackBonus != 0 || damageBonus != 0) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Combattimento',
          detail:
              'Tiri per colpire ${_signed(attackBonus)} · danni ${_signed(damageBonus)}.',
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Ace Trainer', level: 9)) {
      final choice = profile.trainerPathChoices['aceMaxPotential'];
      if (choice != null && choice.isNotEmpty) {
        final detail = choice == '+10 ft velocità'
            ? 'Velocità effettiva: ${effectiveSpeed(profile: profile, pokemon: pokemon, slot: slot)} ft.'
            : '$choice applicato alle caratteristiche mostrate.';
        notes.add(
          TrainerPathPassiveNote(title: 'Max Potential', detail: detail),
        );
      }
    }

    if (hasFeature(profile, trainerPath: 'Researcher', level: 2)) {
      final ability = profile.trainerPathChoices['researcherAbility'];
      if (ability != null) {
        final score = profile.abilityScores[ability] ?? 10;
        final modifier = ((score - 10) / 2).floor().clamp(1, 99).toInt();
        notes.add(
          TrainerPathPassiveNote(
            title: 'Researcher',
            detail: '+$modifier alle prove di abilità del Pokémon ($ability).',
          ),
        );
      }
    }

    final typeMatches = matchingSpecializationCount(profile, pokemon);
    if (hasFeature(profile, trainerPath: 'Type Master', level: 2) &&
        typeMatches > 0) {
      final resistance = profile.trainerPathChoices['typeMasterResistance'];
      notes.add(
        TrainerPathPassiveNote(
          title: 'Type Master',
          detail: [
            'Bonus STAB del Path: +$typeMatches',
            if (profile.trainerLevel >= 5) '+2 ai tiri per colpire già incluso',
            if (resistance != null) 'resistenza scelta: $resistance',
            if (profile.trainerLevel >= 15)
              'STAB applicabile a ogni mossa dannosa',
          ].join(' · '),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Commander', level: 2) &&
        slot.loyalty > 0) {
      notes.add(
        const TrainerPathPassiveNote(
          title: 'Commander',
          detail: 'I bonus positivi di Lealtà a PF e tiri salvezza sono raddoppiati.',
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Guru', level: 5)) {
      notes.add(
        const TrainerPathPassiveNote(
          title: 'Mind',
          detail: 'Competenza nei tiri salvezza di Saggezza.',
        ),
      );
    }

    final copied = profile.trainerPathChoices['hobbyistManyFaces'];
    if (profile.trainerPath == 'Hobbyist' && copied != null) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Many Faces',
          detail: 'Privilegio copiato: $copied.',
        ),
      );
    }

    return List.unmodifiable(notes);
  }

  static String _normalizeType(String value) {
    final key = value.trim().toLowerCase();
    return _typeAliases[key] ?? key;
  }

  static String _signed(int value) => value >= 0 ? '+$value' : '$value';
}
'''

PASSIVE_CARD = r'''import 'package:flutter/material.dart';

import '../../services/trainer_path_passive_service.dart';

class TrainerPathPassiveCard extends StatelessWidget {
  const TrainerPathPassiveCard({
    super.key,
    required this.trainerPath,
    required this.notes,
  });

  final String trainerPath;
  final List<TrainerPathPassiveNote> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BONUS PASSIVI TRAINER PATH',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trainerPath.isNotEmpty)
                  Chip(
                    label: Text(trainerPath),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < notes.length; index++) ...[
              Text(
                notes[index].title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(notes[index].detail),
              if (index != notes.length - 1) const Divider(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
'''

PASSIVE_TEST = r'''import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/trainer_path_passive_service.dart';

void main() {
  group('TrainerPathPassiveService', () {
    test('Ace Trainer applica attacco, danno e Max Potential', () {
      final profile = _profile(
        path: 'Ace Trainer',
        level: 9,
        choices: const {'aceMaxPotential': '+1 CON'},
      );
      final pokemon = _pokemon(types: const ['Fire']);
      final slot = _slot(loyalty: 0);

      expect(
        TrainerPathPassiveService.attackRollBonus(
          profile: profile,
          pokemon: pokemon,
          slot: slot,
        ),
        1,
      );
      expect(
        TrainerPathPassiveService.damageRollBonus(profile: profile, slot: slot),
        1,
      );
      expect(
        TrainerPathPassiveService.effectiveAttributeScores(
          profile: profile,
          pokemon: pokemon,
          slot: slot,
        )['CON'],
        13,
      );
    });

    test('Max Potential velocità non crea movimento da una velocità zero', () {
      final profile = _profile(
        path: 'Ace Trainer',
        level: 9,
        choices: const {'aceMaxPotential': '+10 ft velocità'},
      );

      expect(
        TrainerPathPassiveService.effectiveSpeed(
          profile: profile,
          pokemon: _pokemon(speed: 30),
          slot: _slot(),
        ),
        40,
      );
      expect(
        TrainerPathPassiveService.effectiveSpeed(
          profile: profile,
          pokemon: _pokemon(speed: 0),
          slot: _slot(),
        ),
        0,
      );
    });

    test('Type Master usa al massimo due specializzazioni compatibili', () {
      final profile = _profile(
        path: 'Type Master',
        level: 15,
        specializations: const ['Pyromaniac', 'Gardener'],
      );
      final pokemon = _pokemon(types: const ['Fire', 'Grass']);
      final slot = _slot();
      final sameTypeMove = _move(type: 'Fire');
      final offTypeMove = _move(type: 'Water');

      expect(
        TrainerPathPassiveService.attackRollBonus(
          profile: profile,
          pokemon: pokemon,
          slot: slot,
        ),
        2,
      );
      expect(
        TrainerPathPassiveService.stabEffect(
          profile: profile,
          pokemon: pokemon,
          slot: slot,
          move: sameTypeMove,
          pokemonLevel: 10,
        ).pathBonus,
        2,
      );
      final extended = TrainerPathPassiveService.stabEffect(
        profile: profile,
        pokemon: pokemon,
        slot: slot,
        move: offTypeMove,
        pokemonLevel: 10,
      );
      expect(extended.applies, isTrue);
      expect(extended.extendedByPath, isTrue);
      expect(extended.pathBonus, 2);
    });

    test('Commander raddoppia soltanto i bonus positivi di Lealtà', () {
      final profile = _profile(path: 'Commander', level: 5);

      expect(
        TrainerPathPassiveService.loyaltyHpBonus(
          profile: profile,
          loyalty: 2,
          level: 7,
        ),
        8,
      );
      expect(
        TrainerPathPassiveService.loyaltySavingThrowBonus(
          profile: profile,
          loyalty: 3,
        ),
        2,
      );
      expect(
        TrainerPathPassiveService.loyaltySavingThrowBonus(
          profile: profile,
          loyalty: -3,
        ),
        -1,
      );
      expect(TrainerPathPassiveService.starterLoyaltyFloor(profile), 2);
      expect(TrainerPathPassiveService.initialCapturedLoyalty(profile), 1);
    });

    test('Guru aggiunge competenza ai TS di Saggezza', () {
      final profile = _profile(path: 'Guru', level: 5);
      final saves = TrainerPathPassiveService.savingThrowProficiencies(
        profile: profile,
        pokemon: _pokemon(savingThrows: const ['DEX']),
        slot: _slot(),
      );

      expect(saves, containsAll(['DEX', 'WIS']));
    });

    test('Many Faces applica i privilegi passivi copiati supportati', () {
      final profile = _profile(
        path: 'Hobbyist',
        level: 9,
        choices: const {
          'hobbyistManyFaces': 'Ace Trainer · Lv 2 · Ace Trainer',
        },
      );

      expect(
        TrainerPathPassiveService.attackRollBonus(
          profile: profile,
          pokemon: _pokemon(),
          slot: _slot(),
        ),
        1,
      );
    });
  });
}

UserProfile _profile({
  required String path,
  required int level,
  Map<String, String> choices = const {},
  List<String> specializations = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return UserProfile(
    id: 'profile',
    name: 'Trainer',
    createdAt: now,
    updatedAt: now,
    trainerLevel: level,
    trainerPath: path,
    trainerPathChoices: choices,
    specializations: specializations,
  );
}

TeamSlot _slot({int loyalty = 0}) {
  return TeamSlot(slotIndex: 0, pokemonId: 1, loyalty: loyalty);
}

Pokemon _pokemon({
  List<String> types = const ['Normal'],
  int speed = 30,
  List<String> savingThrows = const [],
}) {
  return Pokemon(
    id: 1,
    name: 'Testmon',
    types: types,
    armorClass: 12,
    hitPoints: 10,
    size: 'Small',
    speed: speed,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 11,
      constitution: 12,
      intelligence: 9,
      wisdom: 10,
      charisma: 8,
    ),
    abilities: const [],
    hiddenAbility: null,
    skills: const [],
    savingThrows: savingThrows,
    moves: const PokemonMoves(
      startingMoves: [],
      levelMoves: {},
      tmMoves: [],
      eggMoves: [],
    ),
    hitDice: 6,
    sr: 0.5,
    minLevelFound: 1,
  );
}

MoveData _move({required String type}) {
  return MoveData(
    id: 'test-move',
    name: 'Test Move',
    type: type,
    pp: '10',
    range: '30 ft',
    duration: '-',
    moveTime: '1 action',
    description: '',
    scaling: null,
    damageByLevel: const {
      1: MoveDamage(amount: 1, diceMax: 6, isMoveDamage: true),
    },
    movePowers: const ['STR'],
    isAttack: true,
    save: null,
  );
}
'''

Path('lib/services/trainer_path_passive_service.dart').write_text(
    PASSIVE_SERVICE, encoding='utf-8'
)
Path('lib/widgets/trainer').mkdir(parents=True, exist_ok=True)
Path('lib/widgets/trainer/trainer_path_passive_card.dart').write_text(
    PASSIVE_CARD, encoding='utf-8'
)
Path('test/trainer_path_passive_service_test.dart').write_text(
    PASSIVE_TEST, encoding='utf-8'
)

# Battle Companion.
path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../services/battle_status_rules.dart';\nimport '../../widgets/battle/battle_status_assistance_card.dart';",
    "import '../../services/battle_status_rules.dart';\nimport '../../services/trainer_path_passive_service.dart';\nimport '../../widgets/battle/battle_status_assistance_card.dart';",
    'battle service import',
)
text = replace_once(
    text,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/pokemon/pokemon_asset_image.dart';\nimport '../../widgets/trainer/trainer_path_passive_card.dart';",
    'battle passive widget import',
)
text = replace_once(
    text,
    "  String? _message;\n  String? _restoredProfileId;",
    "  String? _message;\n  String? _restoredProfileId;\n  UserProfile? _activeProfile;",
    'battle active profile state',
)
text = replace_once(
    text,
    "    final profile = await _profileRepository.getActiveProfile();\n    final team = await _teamRepository.getTeam(profile.id);",
    "    final profile = await _profileRepository.getActiveProfile();\n    _activeProfile = profile;\n    final team = await _teamRepository.getTeam(profile.id);",
    'battle load profile',
)
text = replace_regex(
    text,
    r"  int _maxHpFor\(Pokemon pokemon, TeamSlot slot\) \{.*?\n  \}\n\n  Map<String, int> _attributeScores",
    "  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {\n"
    "    return TrainerPathPassiveService.maxHp(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "      level: _levelForSlot(slot),\n"
    "    );\n"
    "  }\n\n"
    "  Map<String, int> _attributeScores",
    'battle max hp',
)
text = replace_regex(
    text,
    r"  Map<String, int> _attributeScores\(Pokemon pokemon, TeamSlot slot\) \{.*?\n  \}\n\n  int _proficiency",
    "  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot slot) {\n"
    "    return TrainerPathPassiveService.effectiveAttributeScores(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "    );\n"
    "  }\n\n"
    "  int _proficiency",
    'battle attributes',
)
text = replace_regex(
    text,
    r"  String _moveStats\(MoveData move, Pokemon pokemon, TeamSlot slot\) \{.*?\n  \}\n\n  String _displayName",
    "  String _moveStats(MoveData move, Pokemon pokemon, TeamSlot slot) {\n"
    "    final level = _levelForSlot(slot);\n"
    "    final moveModifier = _bestMoveModifier(move, pokemon, slot);\n"
    "    final proficiency = _proficiency(level);\n"
    "    final attackPathBonus = TrainerPathPassiveService.attackRollBonus(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "    );\n"
    "    final damagePathBonus = TrainerPathPassiveService.damageRollBonus(\n"
    "      profile: _activeProfile,\n"
    "      slot: slot,\n"
    "    );\n"
    "    final stab = TrainerPathPassiveService.stabEffect(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "      move: move,\n"
    "      pokemonLevel: level,\n"
    "    );\n"
    "    final parts = <String>[];\n\n"
    "    if (move.isAttack) {\n"
    "      final attackBonus = moveModifier + proficiency + attackPathBonus;\n"
    "      parts.add('AB ${attackBonus >= 0 ? '+' : ''}$attackBonus');\n"
    "    }\n"
    "    if (move.save != null) parts.add('DC ${8 + proficiency + moveModifier}');\n\n"
    "    final damage = move.damageForLevel(level);\n"
    "    if (damage != null) {\n"
    "      final bonus = damagePathBonus == 0 ? '' : ' ${damagePathBonus > 0 ? '+' : ''}$damagePathBonus';\n"
    "      parts.add('${damage.label}$bonus');\n"
    "    }\n"
    "    if (stab.applies) {\n"
    "      final source = stab.extendedByPath ? 'STAB esteso' : 'STAB';\n"
    "      final bonus = stab.pathBonus == 0 ? '' : ' Path +${stab.pathBonus}';\n"
    "      parts.add('$source$bonus');\n"
    "    }\n"
    "    if (move.range != '-') parts.add(move.range);\n"
    "    if (move.duration != '-') parts.add(move.duration);\n\n"
    "    return parts.join(' • ');\n"
    "  }\n\n"
    "  String _displayName",
    'battle move stats',
)
text = replace_once(
    text,
    "          final heldItem = data.heldItemFor(activeSlot);\n\n          return RefreshIndicator(",
    "          final heldItem = data.heldItemFor(activeSlot);\n"
    "          final passiveNotes = TrainerPathPassiveService.passiveNotes(\n"
    "            profile: data.profile,\n"
    "            pokemon: pokemon,\n"
    "            slot: activeSlot,\n"
    "          );\n\n"
    "          return RefreshIndicator(",
    'battle passive notes local',
)
text = replace_once(
    text,
    "                ),\n                const SizedBox(height: 12),\n                BattleStatusAssistanceCard(",
    "                ),\n"
    "                if (passiveNotes.isNotEmpty) ...[\n"
    "                  const SizedBox(height: 12),\n"
    "                  TrainerPathPassiveCard(\n"
    "                    trainerPath: data.profile.trainerPath,\n"
    "                    notes: passiveNotes,\n"
    "                  ),\n"
    "                ],\n"
    "                const SizedBox(height: 12),\n"
    "                BattleStatusAssistanceCard(",
    'battle passive card',
)
path.write_text(text, encoding='utf-8')

# Pokémon detail screen.
path = Path('lib/screens/pokemon/pokemon_detail_screen_legacy.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../models/team_slot.dart';",
    "import '../../models/team_slot.dart';\nimport '../../models/user_profile.dart';",
    'detail user profile import',
)
text = replace_once(
    text,
    "import '../../services/evolution_service.dart';",
    "import '../../services/evolution_service.dart';\nimport '../../services/trainer_path_passive_service.dart';",
    'detail passive service import',
)
text = replace_once(
    text,
    "import '../../widgets/pokemon/pokemon_asset_image.dart';",
    "import '../../widgets/pokemon/pokemon_asset_image.dart';\nimport '../../widgets/trainer/trainer_path_passive_card.dart';",
    'detail passive widget import',
)
text = replace_once(
    text,
    "  TeamSlot? _teamSlot;\n  Map<String, MoveData?> _moves = {};",
    "  TeamSlot? _teamSlot;\n  UserProfile? _profile;\n  Map<String, MoveData?> _moves = {};",
    'detail profile state',
)
text = replace_once(
    text,
    "  int get _savingThrowLoyaltyBonus => _loyalty.clamp(-1, 1).toInt();",
    "  int get _savingThrowLoyaltyBonus =>\n      TrainerPathPassiveService.loyaltySavingThrowBonus(\n        profile: _profile,\n        loyalty: _loyalty,\n      );",
    'detail loyalty save bonus',
)
text = replace_regex(
    text,
    r"  int _loyaltyHpBonus\(int loyalty, int level\) \{.*?\n  \}\n\n  int _maxHpFor\(Pokemon pokemon, TeamSlot\? slot\) \{.*?\n  \}",
    "  int _maxHpFor(Pokemon pokemon, TeamSlot? slot) {\n"
    "    return TrainerPathPassiveService.maxHp(\n"
    "      profile: _profile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "      level: slot == null\n"
    "          ? pokemon.minLevelFound\n"
    "          : LevelProgression.levelFromExperience(slot.experience),\n"
    "    );\n"
    "  }",
    'detail max hp',
)
text = replace_once(
    text,
    "      _itemRepository.getWebItems(),\n    ]);",
    "      _itemRepository.getWebItems(),\n      _profileRepository.getActiveProfile(),\n    ]);",
    'detail load profile future',
)
text = replace_once(
    text,
    "      _itemCatalog = {for (final item in items) item.id: item};\n      _evolutionChoices = evolutionChoices;",
    "      _itemCatalog = {for (final item in items) item.id: item};\n      _profile = results[5] as UserProfile;\n      _evolutionChoices = evolutionChoices;",
    'detail assign profile',
)
text = replace_regex(
    text,
    r"  Map<String, int> _attributeScores\(Pokemon pokemon, TeamSlot\? slot\) \{.*?\n  \}\n\n  int _bestMoveModifier",
    "  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot? slot) {\n"
    "    return TrainerPathPassiveService.effectiveAttributeScores(\n"
    "      profile: _profile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "    );\n"
    "  }\n\n"
    "  int _bestMoveModifier",
    'detail attributes',
)
text = replace_regex(
    text,
    r"  String _moveStats\(MoveData move\) \{.*?\n  \}\n\n  String _moveLabel",
    "  String _moveStats(MoveData move) {\n"
    "    final parts = <String>[];\n"
    "    final moveModifier = _bestMoveModifier(move);\n"
    "    final proficiency = _proficiency(_level);\n"
    "    final attackPathBonus = TrainerPathPassiveService.attackRollBonus(\n"
    "      profile: _profile,\n"
    "      pokemon: _pokemon,\n"
    "      slot: _teamSlot,\n"
    "    );\n"
    "    final damagePathBonus = TrainerPathPassiveService.damageRollBonus(\n"
    "      profile: _profile,\n"
    "      slot: _teamSlot,\n"
    "    );\n"
    "    final stab = TrainerPathPassiveService.stabEffect(\n"
    "      profile: _profile,\n"
    "      pokemon: _pokemon,\n"
    "      slot: _teamSlot,\n"
    "      move: move,\n"
    "      pokemonLevel: _level,\n"
    "    );\n\n"
    "    if (move.isAttack) {\n"
    "      final attackBonus = moveModifier + proficiency + attackPathBonus;\n"
    "      parts.add('AB: ${attackBonus >= 0 ? '+' : ''}$attackBonus');\n"
    "    }\n"
    "    if (move.save != null) {\n"
    "      parts.add('DC: ${8 + proficiency + moveModifier}');\n"
    "    }\n\n"
    "    final damage = move.damageForLevel(_level);\n"
    "    if (damage != null) {\n"
    "      final bonus = damagePathBonus == 0 ? '' : ' ${damagePathBonus > 0 ? '+' : ''}$damagePathBonus';\n"
    "      parts.add('${damage.label}$bonus');\n"
    "    }\n"
    "    if (stab.applies) {\n"
    "      final source = stab.extendedByPath ? 'STAB esteso' : 'STAB';\n"
    "      final bonus = stab.pathBonus == 0 ? '' : ' Path +${stab.pathBonus}';\n"
    "      parts.add('$source$bonus');\n"
    "    }\n"
    "    if (move.range != '-') parts.add(move.range);\n"
    "    if (move.duration != '-') parts.add(move.duration);\n\n"
    "    return parts.join('  ||  ');\n"
    "  }\n\n"
    "  String _moveLabel",
    'detail move stats',
)
text = replace_once(
    text,
    "    final attributes = _attributeScores(pokemon, _teamSlot);\n    final evolutionLabel = _evolutionLabel();",
    "    final attributes = _attributeScores(pokemon, _teamSlot);\n"
    "    final evolutionLabel = _evolutionLabel();\n"
    "    final savingThrows = TrainerPathPassiveService.savingThrowProficiencies(\n"
    "      profile: _profile,\n"
    "      pokemon: pokemon,\n"
    "      slot: _teamSlot,\n"
    "    );\n"
    "    final passiveNotes = TrainerPathPassiveService.passiveNotes(\n"
    "      profile: _profile,\n"
    "      pokemon: pokemon,\n"
    "      slot: _teamSlot,\n"
    "    );",
    'detail locals',
)
text = replace_once(
    text,
    "                          savingThrowLoyaltyBonus: _savingThrowLoyaltyBonus,\n                          statusEffects: _currentStatusEffects,",
    "                          savingThrowLoyaltyBonus: _savingThrowLoyaltyBonus,\n"
    "                          savingThrows: savingThrows,\n"
    "                          statusEffects: _currentStatusEffects,",
    'detail pass saves header',
)
text = replace_once(
    text,
    "                        ),\n                        const TabBar(",
    "                        ),\n"
    "                        if (passiveNotes.isNotEmpty)\n"
    "                          Padding(\n"
    "                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),\n"
    "                            child: TrainerPathPassiveCard(\n"
    "                              trainerPath: _profile?.trainerPath ?? '',\n"
    "                              notes: passiveNotes,\n"
    "                            ),\n"
    "                          ),\n"
    "                        const TabBar(",
    'detail passive card',
)
text = replace_once(
    text,
    "    required this.savingThrowLoyaltyBonus,\n    required this.statusEffects,",
    "    required this.savingThrowLoyaltyBonus,\n    required this.savingThrows,\n    required this.statusEffects,",
    'header constructor saves',
)
text = replace_once(
    text,
    "  final int savingThrowLoyaltyBonus;\n  final List<String> statusEffects;",
    "  final int savingThrowLoyaltyBonus;\n  final List<String> savingThrows;\n  final List<String> statusEffects;",
    'header field saves',
)
text = replace_once(
    text,
    "            savingThrows: pokemon.savingThrows,",
    "            savingThrows: savingThrows,",
    'header use saves',
)
path.write_text(text, encoding='utf-8')

# Bag max HP consistency.
path = Path('lib/screens/bag/bag_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../repositories/tm_repository.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    "import '../../repositories/tm_repository.dart';\nimport '../../services/trainer_path_passive_service.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    'bag passive import',
)
text = replace_once(
    text,
    "  String? _selectedType;\n  String? _message;",
    "  String? _selectedType;\n  String? _message;\n  UserProfile? _activeProfile;",
    'bag active profile state',
)
text = replace_once(
    text,
    "    final profile = await _profileRepository.getActiveProfile();\n    final catalog = await _itemRepository.getWebItems();",
    "    final profile = await _profileRepository.getActiveProfile();\n    _activeProfile = profile;\n    final catalog = await _itemRepository.getWebItems();",
    'bag load profile',
)
text = replace_regex(
    text,
    r"  int _maxHpFor\(Pokemon pokemon, TeamSlot slot\) \{.*?\n  \}\n\n  int _loyaltyHpBonus\(int loyalty, int level\) \{.*?\n  \}",
    "  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {\n"
    "    return TrainerPathPassiveService.maxHp(\n"
    "      profile: _activeProfile,\n"
    "      pokemon: pokemon,\n"
    "      slot: slot,\n"
    "      level: LevelProgression.levelFromExperience(slot.experience),\n"
    "    );\n"
    "  }",
    'bag max hp',
)
path.write_text(text, encoding='utf-8')

# Capture: Commander gives +1 Loyalty to newly caught Pokémon.
path = Path('lib/screens/capture/capture_pokemon_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../repositories/team_repository.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    "import '../../repositories/team_repository.dart';\nimport '../../services/trainer_path_passive_service.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    'capture passive import',
)
text = replace_once(
    text,
    "    final naturalAbilities = selectedPokemon.abilities\n        .take(2)\n        .toList(growable: false);\n\n    if (teamSlot != null) {",
    "    final naturalAbilities = selectedPokemon.abilities\n"
    "        .take(2)\n"
    "        .toList(growable: false);\n"
    "    final initialLoyalty =\n"
    "        TrainerPathPassiveService.initialCapturedLoyalty(profile);\n\n"
    "    if (teamSlot != null) {",
    'capture initial loyalty',
)
text = replace_once(
    text,
    "          selectedMoves: startingMoves,\n          abilities: naturalAbilities,\n        ),",
    "          selectedMoves: startingMoves,\n"
    "          abilities: naturalAbilities,\n"
    "          loyalty: initialLoyalty,\n"
    "        ),",
    'capture team loyalty',
)
text = replace_once(
    text,
    "        selectedMoves: startingMoves,\n        abilities: naturalAbilities,\n      );",
    "        selectedMoves: startingMoves,\n"
    "        abilities: naturalAbilities,\n"
    "        loyalty: initialLoyalty,\n"
    "      );",
    'capture pc loyalty',
)
path.write_text(text, encoding='utf-8')

# Trainer sheet: Commander raises the selected starter to Loyal on save.
path = Path('lib/screens/trainer/trainer_sheet_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../services/trainer_path_automation_service.dart';",
    "import '../../services/trainer_path_automation_service.dart';\nimport '../../services/trainer_path_passive_service.dart';",
    'trainer sheet passive import',
)
text = replace_once(
    text,
    "  Future<void> _saveProfile() async {",
    "  Future<void> _applyTrainerPathTeamPassives(UserProfile profile) async {\n"
    "    final loyaltyFloor =\n"
    "        TrainerPathPassiveService.starterLoyaltyFloor(profile);\n"
    "    final starterName = profile.starterPokemon.trim();\n"
    "    if (loyaltyFloor == null || starterName.isEmpty) return;\n\n"
    "    final updatedTeam = <TeamSlot>[];\n"
    "    for (final slot in _team) {\n"
    "      final pokemonId = slot.pokemonId;\n"
    "      final pokemon = pokemonId == null ? null : _pokemonById[pokemonId];\n"
    "      if (pokemon?.name != starterName || slot.loyalty >= loyaltyFloor) {\n"
    "        updatedTeam.add(slot);\n"
    "        continue;\n"
    "      }\n"
    "      final updatedSlot = slot.copyWith(loyalty: loyaltyFloor);\n"
    "      await _teamRepository.updateSlot(\n"
    "        profileId: profile.id,\n"
    "        updatedSlot: updatedSlot,\n"
    "      );\n"
    "      updatedTeam.add(updatedSlot);\n"
    "    }\n"
    "    _team = updatedTeam;\n"
    "  }\n\n"
    "  Future<void> _saveProfile() async {",
    'trainer sheet passive helper',
)
text = replace_once(
    text,
    "      await _profileRepository.saveProfile(updated);\n\n      if (!mounted) return;",
    "      await _profileRepository.saveProfile(updated);\n"
    "      await _applyTrainerPathTeamPassives(updated);\n\n"
    "      if (!mounted) return;",
    'trainer sheet apply passives',
)
path.write_text(text, encoding='utf-8')

# Changelog.
path = Path('CHANGELOG.md')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "- pannello condiviso di assistenza agli status per Battle Companion e Fight del Master, con promemoria distinti per inizio turno, azione, mossa subita e fine turno.\n- gestione persistente di risorse, riposi e scelte specifiche dei Trainer Path nella Scheda Allenatore.",
    "- pannello condiviso di assistenza agli status per Battle Companion e Fight del Master, con promemoria distinti per inizio turno, azione, mossa subita e fine turno.\n"
    "- gestione persistente di risorse, riposi e scelte specifiche dei Trainer Path nella Scheda Allenatore.\n"
    "- applicazione automatica dei bonus passivi principali dei Trainer Path a caratteristiche, PF, tiri per colpire, danni, STAB, tiri salvezza e Lealtà.",
    'changelog added',
)
text = replace_once(
    text,
    "- automazione dei bonus passivi dei Trainer Path sulle statistiche dei Pokémon;\n",
    "",
    'changelog remove planned passive',
)
path.write_text(text, encoding='utf-8')
