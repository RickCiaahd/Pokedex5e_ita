import '../models/level_progression.dart';
import '../localization/ui_text.dart';
import '../models/move_data.dart';
import '../models/pokemon.dart';
import '../models/pokemon_nature.dart';
import '../models/team_slot.dart';
import '../models/trainer_manual_options.dart';
import '../models/trainer_ui_localization.dart';
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
      'STR':
          pokemon.attributes.strength +
          (custom['STR'] ?? 0) +
          (nature['STR'] ?? 0) +
          (bonuses['STR'] ?? 0),
      'DEX':
          pokemon.attributes.dexterity +
          (custom['DEX'] ?? 0) +
          (nature['DEX'] ?? 0) +
          (bonuses['DEX'] ?? 0),
      'CON':
          pokemon.attributes.constitution +
          (custom['CON'] ?? 0) +
          (nature['CON'] ?? 0) +
          (bonuses['CON'] ?? 0),
      'INT':
          pokemon.attributes.intelligence +
          (custom['INT'] ?? 0) +
          (nature['INT'] ?? 0) +
          (bonuses['INT'] ?? 0),
      'WIS':
          pokemon.attributes.wisdom +
          (custom['WIS'] ?? 0) +
          (nature['WIS'] ?? 0) +
          (bonuses['WIS'] ?? 0),
      'CHA':
          pokemon.attributes.charisma +
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
    final bonus =
        hasFeature(profile, trainerPath: 'Ace Trainer', level: 9) &&
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
    String? moveTypeOverride,
  }) {
    final damaging =
        move.damageForLevel(pokemonLevel) != null ||
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
    final sameType = pokemonTypes.contains(
      _normalizeType(moveTypeOverride ?? move.type),
    );
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
    final resolvedLevel =
        level ??
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
    final constitutionModifier = (((attributes['CON'] ?? 10) - 10) / 2).floor();
    final toughBonus = slot?.feats.contains('Tough') == true
        ? safeLevel * 2
        : 0;
    final loyaltyBonus = loyaltyHpBonus(
      profile: profile,
      loyalty: slot?.loyalty ?? 0,
      level: safeLevel,
    );
    final hp =
        pokemon.hitPoints +
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
          title: uiTextForLanguage('Combattimento', 'Battle'),
          detail: uiTextForLanguage(
            'Tiri per colpire ${_signed(attackBonus)} · danni ${_signed(damageBonus)}.',
            'Attack rolls ${_signed(attackBonus)} · damage ${_signed(damageBonus)}.',
          ),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Ace Trainer', level: 9)) {
      final choice = profile.trainerPathChoices['aceMaxPotential'];
      if (choice != null && choice.isNotEmpty) {
        final detail = choice == '+10 ft velocità'
            ? uiTextForLanguage(
                'Velocità effettiva: ${effectiveSpeed(profile: profile, pokemon: pokemon, slot: slot)} ft.',
                'Effective Speed: ${effectiveSpeed(profile: profile, pokemon: pokemon, slot: slot)} ft.',
              )
            : uiTextForLanguage(
                '$choice applicato alle caratteristiche mostrate.',
                '${TrainerUiLocalization.optionLabel(choice)} applied to the displayed ability scores.',
              );
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
            detail: uiTextForLanguage(
              '+$modifier alle prove di abilità del Pokémon ($ability).',
              '+$modifier to the Pokémon’s ability checks ($ability).',
            ),
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
            uiTextForLanguage(
              'Bonus STAB del Path: +$typeMatches',
              'Path STAB bonus: +$typeMatches',
            ),
            if (profile.trainerLevel >= 5)
              uiTextForLanguage(
                '+2 ai tiri per colpire già incluso',
                '+2 to attack rolls already included',
              ),
            if (resistance != null)
              uiTextForLanguage(
                'resistenza scelta: $resistance',
                'chosen resistance: $resistance',
              ),
            if (profile.trainerLevel >= 15)
              uiTextForLanguage(
                'STAB applicabile a ogni mossa dannosa',
                'STAB can apply to every damaging move',
              ),
          ].join(' · '),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Commander', level: 2) &&
        slot.loyalty > 0) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Commander',
          detail: uiTextForLanguage(
            'I bonus positivi di Lealtà a PF e tiri salvezza sono raddoppiati.',
            'Positive Loyalty bonuses to HP and saving throws are doubled.',
          ),
        ),
      );
    }

    if (hasFeature(profile, trainerPath: 'Guru', level: 5)) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Mind',
          detail: uiTextForLanguage(
            'Competenza nei tiri salvezza di Saggezza.',
            'Proficiency in Wisdom saving throws.',
          ),
        ),
      );
    }

    final copied = profile.trainerPathChoices['hobbyistManyFaces'];
    if (profile.trainerPath == 'Hobbyist' && copied != null) {
      notes.add(
        TrainerPathPassiveNote(
          title: 'Many Faces',
          detail: uiTextForLanguage(
            'Privilegio copiato: $copied.',
            'Copied feature: ${TrainerUiLocalization.optionLabel(copied)}.',
          ),
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
