import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/trainer_manual_content.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';
import 'package:pokedex_5e_ita/services/trainer_path_automation_service.dart';

void main() {
  group('TrainerPathAutomationService resources', () {
    test('calcola automaticamente dadi e utilizzi dalle caratteristiche', () {
      final resources = TrainerPathAutomationService.resourcesFor(
        trainerPath: 'Ace Trainer',
        trainerLevel: 15,
        abilityScores: const {
          'STR': 10,
          'DEX': 10,
          'CON': 10,
          'INT': 10,
          'WIS': 16,
          'CHA': 10,
        },
      );

      expect(resources.map((item) => item.id), [
        'aceBattleDice',
        'aceRapidSwitching',
      ]);
      expect(resources.every((item) => item.maxUses == 4), isTrue);
    });

    test('i punti di Grunt e Tactician seguono il livello', () {
      final grunt = TrainerPathAutomationService.resourcesFor(
        trainerPath: 'Grunt',
        trainerLevel: 7,
        abilityScores: UserProfile.defaultAbilityScores,
      );
      final tactician = TrainerPathAutomationService.resourcesFor(
        trainerPath: 'Tactician',
        trainerLevel: 12,
        abilityScores: UserProfile.defaultAbilityScores,
      );

      expect(grunt.single.maxUses, 7);
      expect(tactician.single.maxUses, 12);
    });

    test('la riserva di Nurse vale livello per cinque', () {
      final resources = TrainerPathAutomationService.resourcesFor(
        trainerPath: 'Nurse',
        trainerLevel: 9,
        abilityScores: UserProfile.defaultAbilityScores,
      );

      expect(resources.single.id, 'nurseHealingPool');
      expect(resources.single.maxUses, 45);
    });

    test('il riposo breve recupera solo le risorse corrette', () {
      final definitions = TrainerPathAutomationService.resourcesFor(
        trainerPath: 'Commander',
        trainerLevel: 15,
        abilityScores: const {
          'STR': 10,
          'DEX': 10,
          'CON': 10,
          'INT': 10,
          'WIS': 10,
          'CHA': 16,
        },
      );
      final spent = {'commanderShowMe': 0, 'commanderTeamCommand': 1};

      final shortRest = TrainerPathAutomationService.restoreForRest(
        current: spent,
        definitions: definitions,
        rest: TrainerPathResourceReset.shortRest,
      );
      final longRest = TrainerPathAutomationService.restoreForRest(
        current: spent,
        definitions: definitions,
        rest: TrainerPathResourceReset.longRest,
      );

      expect(shortRest['commanderShowMe'], 1);
      expect(shortRest['commanderTeamCommand'], 1);
      expect(longRest['commanderTeamCommand'], 4);
    });

    test(
      'il cambio di caratteristica riduce senza superare il nuovo massimo',
      () {
        final definitions = TrainerPathAutomationService.resourcesFor(
          trainerPath: 'Ace Trainer',
          trainerLevel: 5,
          abilityScores: const {
            'STR': 10,
            'DEX': 10,
            'CON': 10,
            'INT': 10,
            'WIS': 12,
            'CHA': 10,
          },
        );

        final reconciled = TrainerPathAutomationService.reconcileResources(
          current: const {'aceBattleDice': 5},
          definitions: definitions,
        );

        expect(reconciled['aceBattleDice'], 2);
      },
    );
  });

  group('TrainerPathAutomationService choices', () {
    const paths = [
      TrainerPath(
        name: 'Ace Trainer',
        features: [
          TrainerPathFeature(level: 2, title: 'Ace Trainer', description: ''),
          TrainerPathFeature(level: 5, title: 'Battle Master', description: ''),
        ],
      ),
      TrainerPath(
        name: 'Hobbyist',
        features: [
          TrainerPathFeature(level: 9, title: 'Many Faces', description: ''),
        ],
      ),
    ];

    test('Researcher richiede la scelta tra WIS e INT', () {
      final choices = TrainerPathAutomationService.choicesFor(
        trainerPath: 'Researcher',
        trainerLevel: 2,
        trainerPaths: paths,
        specializations: const [],
        teamPokemonNames: const [],
      );

      expect(choices.single.id, 'researcherAbility');
      expect(choices.single.options, ['WIS', 'INT']);
    });

    test('Type Master limita la resistenza ai tipi specializzati', () {
      final choices = TrainerPathAutomationService.choicesFor(
        trainerPath: 'Type Master',
        trainerLevel: 9,
        trainerPaths: paths,
        specializations: const ['Pyromaniac', 'Gardener'],
        teamPokemonNames: const [],
      );

      expect(choices.single.options, ['Erba', 'Fuoco']);
    });

    test('il secondo legame del Ranger è facoltativo', () {
      final choices = TrainerPathAutomationService.choicesFor(
        trainerPath: 'Ranger',
        trainerLevel: 9,
        trainerPaths: paths,
        specializations: const [],
        teamPokemonNames: const ['Slot 1 · Pikachu', 'Slot 2 · Eevee'],
      );

      final missing = TrainerPathAutomationService.missingChoices(
        current: const {
          'rangerConnectionAbility': 'WIS',
          'rangerStrongBond1': 'Slot 1 · Pikachu',
        },
        definitions: choices,
      );

      expect(missing, isEmpty);
    });
  });

  test('UserProfile mantiene compatibilità e serializza lo stato del path', () {
    final now = DateTime.utc(2026, 7, 14);
    final legacy = UserProfile.fromJson({
      'id': 'legacy',
      'name': 'Legacy',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'trainerPath': 'Grunt',
    });

    expect(legacy.trainerPathChoices, isEmpty);
    expect(legacy.trainerPathResources, isEmpty);

    final updated = legacy.copyWith(
      trainerPathChoices: const {'researcherAbility': 'INT'},
      trainerPathResources: const {'gruntShadowPoints': 3},
    );
    final restored = UserProfile.fromJson(updated.toJson());

    expect(restored.trainerPathChoices['researcherAbility'], 'INT');
    expect(restored.trainerPathResources['gruntShadowPoints'], 3);
  });
}
