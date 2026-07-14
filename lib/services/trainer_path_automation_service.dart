import '../models/trainer_manual_content.dart';
import '../models/trainer_manual_options.dart';

enum TrainerPathResourceReset { shortRest, longRest }

class TrainerPathResourceDefinition {
  const TrainerPathResourceDefinition({
    required this.id,
    required this.label,
    required this.featureTitle,
    required this.featureLevel,
    required this.maxUses,
    required this.reset,
    this.unitLabel = 'usi',
  });

  final String id;
  final String label;
  final String featureTitle;
  final int featureLevel;
  final int maxUses;
  final TrainerPathResourceReset reset;
  final String unitLabel;

  String get resetLabel => switch (reset) {
        TrainerPathResourceReset.shortRest => 'Riposo breve',
        TrainerPathResourceReset.longRest => 'Riposo lungo',
      };
}

class TrainerPathChoiceDefinition {
  const TrainerPathChoiceDefinition({
    required this.id,
    required this.label,
    required this.featureTitle,
    required this.featureLevel,
    required this.options,
    required this.description,
    this.isRequired = true,
  });

  final String id;
  final String label;
  final String featureTitle;
  final int featureLevel;
  final List<String> options;
  final String description;
  final bool isRequired;
}

class TrainerPathAutomationService {
  const TrainerPathAutomationService._();

  static List<TrainerPathResourceDefinition> resourcesFor({
    required String trainerPath,
    required int trainerLevel,
    required Map<String, int> abilityScores,
    Map<String, String> choices = const {},
  }) {
    final resources = <TrainerPathResourceDefinition>[];
    final wisUses = _usesFromAbility(abilityScores, 'WIS');
    final intUses = _usesFromAbility(abilityScores, 'INT');
    final chaUses = _usesFromAbility(abilityScores, 'CHA');

    void add({
      required int level,
      required String id,
      required String label,
      required String feature,
      required int maxUses,
      required TrainerPathResourceReset reset,
      String unitLabel = 'usi',
    }) {
      if (trainerLevel < level) return;
      resources.add(
        TrainerPathResourceDefinition(
          id: id,
          label: label,
          featureTitle: feature,
          featureLevel: level,
          maxUses: maxUses,
          reset: reset,
          unitLabel: unitLabel,
        ),
      );
    }

    switch (trainerPath) {
      case 'Ace Trainer':
        add(
          level: 5,
          id: 'aceBattleDice',
          label: 'Dadi battaglia d6',
          feature: 'Battle Master',
          maxUses: wisUses,
          reset: TrainerPathResourceReset.longRest,
          unitLabel: 'dadi',
        );
        add(
          level: 15,
          id: 'aceRapidSwitching',
          label: 'Rapid Switching',
          feature: 'Rapid Switching',
          maxUses: wisUses,
          reset: TrainerPathResourceReset.longRest,
        );
      case 'Hobbyist':
        add(
          level: 5,
          id: 'hobbyistAbilityDice',
          label: 'Dadi abilità d6',
          feature: 'Versatile',
          maxUses: wisUses,
          reset: TrainerPathResourceReset.longRest,
          unitLabel: 'dadi',
        );
      case 'Pokéchef':
        add(
          level: 5,
          id: 'chefTreats',
          label: 'Edible Treat',
          feature: 'Edible Treat',
          maxUses: wisUses,
          reset: TrainerPathResourceReset.longRest,
          unitLabel: 'treat',
        );
        add(
          level: 9,
          id: 'chefCheerleader',
          label: 'Cheerleader',
          feature: 'Cheerleader',
          maxUses: 1,
          reset: TrainerPathResourceReset.shortRest,
        );
      case 'Researcher':
        add(
          level: 15,
          id: 'researcherProfessor',
          label: 'Professor',
          feature: 'Professor',
          maxUses: intUses,
          reset: TrainerPathResourceReset.longRest,
        );
      case 'Pokémon Collector':
        add(
          level: 5,
          id: 'collectorCatchAdvantage',
          label: "Gotta Catch 'Em All",
          feature: "Gotta Catch 'Em All",
          maxUses: 1,
          reset: TrainerPathResourceReset.longRest,
        );
      case 'Nurse':
        add(
          level: 5,
          id: 'nurseHealingPool',
          label: 'Riserva di guarigione',
          feature: 'Pure Heart',
          maxUses: trainerLevel * 5,
          reset: TrainerPathResourceReset.longRest,
          unitLabel: 'punti',
        );
        add(
          level: 15,
          id: 'nurseJoy',
          label: 'Joy',
          feature: 'Joy',
          maxUses: 1,
          reset: TrainerPathResourceReset.longRest,
        );
      case 'Commander':
        add(
          level: 9,
          id: 'commanderShowMe',
          label: "Show Me What You've Got",
          feature: "Show Me What You've Got",
          maxUses: 1,
          reset: TrainerPathResourceReset.shortRest,
        );
        add(
          level: 15,
          id: 'commanderTeamCommand',
          label: "We're a Team",
          feature: "We're a Team",
          maxUses: chaUses,
          reset: TrainerPathResourceReset.longRest,
        );
      case 'Grunt':
        add(
          level: 2,
          id: 'gruntShadowPoints',
          label: 'Shadow Points',
          feature: 'Sabotage',
          maxUses: trainerLevel,
          reset: TrainerPathResourceReset.longRest,
          unitLabel: 'punti',
        );
      case 'Tactician':
        add(
          level: 2,
          id: 'tacticianPoints',
          label: 'Tactical Points',
          feature: 'Tactician',
          maxUses: trainerLevel,
          reset: TrainerPathResourceReset.longRest,
          unitLabel: 'punti',
        );
      case 'Ranger':
        final connectionAbility = choices['rangerConnectionAbility'] == 'CHA'
            ? 'CHA'
            : 'WIS';
        add(
          level: 5,
          id: 'rangerDeepConnection',
          label: 'Deep Connection',
          feature: 'Deep Connection',
          maxUses: _usesFromAbility(abilityScores, connectionAbility),
          reset: TrainerPathResourceReset.longRest,
        );
      case 'Guru':
        add(
          level: 15,
          id: 'guruSpirit',
          label: 'Spirit',
          feature: 'Spirit',
          maxUses: wisUses,
          reset: TrainerPathResourceReset.longRest,
        );
    }

    return List.unmodifiable(resources);
  }

  static List<TrainerPathChoiceDefinition> choicesFor({
    required String trainerPath,
    required int trainerLevel,
    required List<TrainerPath> trainerPaths,
    required List<String> specializations,
    required List<String> teamPokemonNames,
  }) {
    final choices = <TrainerPathChoiceDefinition>[];

    void add({
      required int level,
      required String id,
      required String label,
      required String feature,
      required List<String> options,
      required String description,
      bool isRequired = true,
    }) {
      if (trainerLevel < level) return;
      choices.add(
        TrainerPathChoiceDefinition(
          id: id,
          label: label,
          featureTitle: feature,
          featureLevel: level,
          options: List.unmodifiable(options),
          description: description,
          isRequired: isRequired,
        ),
      );
    }

    switch (trainerPath) {
      case 'Ace Trainer':
        add(
          level: 9,
          id: 'aceMaxPotential',
          label: 'Potenziamento permanente',
          feature: 'Max Potential',
          options: const [
            '+10 ft velocità',
            '+1 STR',
            '+1 DEX',
            '+1 CON',
          ],
          description:
              'La scelta si applica a tutti i Pokémon dell’Allenatore.',
        );
      case 'Hobbyist':
        final featureOptions = <String>[];
        for (final path in trainerPaths) {
          if (path.name == 'Hobbyist') continue;
          for (final feature in path.features) {
            if (feature.level <= 9 && feature.level <= trainerLevel) {
              featureOptions.add(
                '${path.name} · Lv ${feature.level} · ${feature.title}',
              );
            }
          }
        }
        featureOptions.sort();
        add(
          level: 9,
          id: 'hobbyistManyFaces',
          label: 'Privilegio copiato',
          feature: 'Many Faces',
          options: featureOptions,
          description:
              'Scegli un privilegio di livello 2, 5 o 9 appartenente a un altro Trainer Path.',
        );
      case 'Researcher':
        add(
          level: 2,
          id: 'researcherAbility',
          label: 'Caratteristica di ricerca',
          feature: 'Researcher',
          options: const ['WIS', 'INT'],
          description:
              'Il modificatore scelto viene aggiunto alle prove di abilità dei tuoi Pokémon, minimo +1.',
        );
      case 'Type Master':
        final typeOptions = specializations
            .map((value) => TrainerManualOptions.specializationTypeByName[value])
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
        add(
          level: 9,
          id: 'typeMasterResistance',
          label: 'Resistenza scelta',
          feature: 'Storing Power',
          options: typeOptions,
          description:
              'La resistenza deve appartenere a uno dei tipi delle tue specializzazioni.',
        );
      case 'Ranger':
        add(
          level: 5,
          id: 'rangerConnectionAbility',
          label: 'Caratteristica di Deep Connection',
          feature: 'Deep Connection',
          options: const ['WIS', 'CHA'],
          description:
              'Determina il numero di utilizzi giornalieri, con un minimo di 1.',
        );
        final names = teamPokemonNames.toSet().toList()..sort();
        add(
          level: 9,
          id: 'rangerStrongBond1',
          label: 'Primo legame',
          feature: 'Strong Bond',
          options: names,
          description:
              'Il legame può essere ridefinito dopo un riposo lungo.',
        );
        add(
          level: 9,
          id: 'rangerStrongBond2',
          label: 'Secondo legame',
          feature: 'Strong Bond',
          options: ['Nessun secondo legame', ...names],
          description:
              'Scegli Nessun secondo legame per mantenere un solo Pokémon legato.',
          isRequired: false,
        );
    }

    return List.unmodifiable(choices);
  }

  static Map<String, int> reconcileResources({
    required Map<String, int> current,
    required List<TrainerPathResourceDefinition> definitions,
    bool refillNewResources = true,
  }) {
    final next = {...current};
    for (final definition in definitions) {
      next[definition.id] = current.containsKey(definition.id)
          ? (current[definition.id] ?? 0)
              .clamp(0, definition.maxUses)
              .toInt()
          : refillNewResources
              ? definition.maxUses
              : 0;
    }
    return next;
  }

  static Map<String, int> restoreForRest({
    required Map<String, int> current,
    required List<TrainerPathResourceDefinition> definitions,
    required TrainerPathResourceReset rest,
  }) {
    final next = {...current};
    for (final definition in definitions) {
      next[definition.id] = rest == TrainerPathResourceReset.longRest ||
              definition.reset == TrainerPathResourceReset.shortRest
          ? definition.maxUses
          : (current[definition.id] ?? definition.maxUses)
              .clamp(0, definition.maxUses)
              .toInt();
    }
    return next;
  }

  static Map<String, String> reconcileChoices({
    required Map<String, String> current,
    required List<TrainerPathChoiceDefinition> definitions,
  }) {
    final next = {...current};
    for (final definition in definitions) {
      final selected = current[definition.id];
      if (selected == null || !definition.options.contains(selected)) {
        next.remove(definition.id);
      }
    }
    return next;
  }

  static List<TrainerPathChoiceDefinition> missingChoices({
    required Map<String, String> current,
    required List<TrainerPathChoiceDefinition> definitions,
  }) {
    return definitions.where((definition) {
      if (!definition.isRequired || definition.options.isEmpty) return false;
      final selected = current[definition.id];
      return selected == null || !definition.options.contains(selected);
    }).toList(growable: false);
  }

  static int _usesFromAbility(Map<String, int> abilityScores, String ability) {
    final score = abilityScores[ability] ?? 10;
    final modifier = ((score - 10) / 2).floor();
    return (1 + modifier).clamp(1, 99).toInt();
  }
}
