import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('reads older saved profiles with trainer defaults', () {
      final profile = UserProfile.fromJson({
        'id': 'old-profile',
        'name': 'Riccardo',
        'createdAt': '2026-07-07T10:00:00.000',
        'updatedAt': '2026-07-07T10:00:00.000',
      });

      expect(profile.trainerLevel, 1);
      expect(profile.money, 0);
      expect(profile.abilityScores, UserProfile.defaultAbilityScores);
      expect(profile.armorClass, 10);
      expect(profile.maxHp, 8);
      expect(profile.currentHp, 8);
      expect(profile.speed, 30);
      expect(profile.trainerRace, '');
      expect(profile.background, '');
      expect(profile.starterPokemon, '');
      expect(profile.startingPack, '');
      expect(profile.skillProficiencies, isEmpty);
      expect(profile.savingThrowProficiencies, isEmpty);
      expect(profile.specializations, isEmpty);
      expect(profile.trainerPath, '');
    });

    test('persists trainer companion fields', () {
      final profile = UserProfile(
        id: 'profile',
        name: 'Trainer',
        createdAt: DateTime(2026, 7, 7),
        updatedAt: DateTime(2026, 7, 7),
        trainerLevel: 5,
        money: 1200,
        abilityScores: const {
          'STR': 12,
          'DEX': 14,
          'CON': 13,
          'INT': 10,
          'WIS': 16,
          'CHA': 11,
        },
        armorClass: 13,
        maxHp: 32,
        currentHp: 24,
        speed: 30,
        trainerRace: 'Human',
        background: 'Ranger',
        starterPokemon: 'Bulbasaur',
        startingPack: "Explorer's pack",
        skillProficiencies: const ['Nature', 'Survival'],
        savingThrowProficiencies: const ['DEX', 'WIS'],
        specializations: const ['Gardener'],
        trainerPath: 'Ranger',
      );

      final json = profile.toJson();

      expect(json['trainerLevel'], 5);
      expect(json['money'], 1200);
      expect(json['abilityScores']['DEX'], 14);
      expect(json['armorClass'], 13);
      expect(json['maxHp'], 32);
      expect(json['currentHp'], 24);
      expect(json['speed'], 30);
      expect(json['trainerRace'], 'Human');
      expect(json['background'], 'Ranger');
      expect(json['starterPokemon'], 'Bulbasaur');
      expect(json['startingPack'], "Explorer's pack");
      expect(json['skillProficiencies'], ['Nature', 'Survival']);
      expect(json['savingThrowProficiencies'], ['DEX', 'WIS']);
      expect(json['specializations'], ['Gardener']);
      expect(json['trainerPath'], 'Ranger');
    });

    test('copyWith updates trainer companion fields', () {
      final profile = UserProfile(
        id: 'profile',
        name: 'Trainer',
        createdAt: DateTime(2026, 7, 7),
        updatedAt: DateTime(2026, 7, 7),
      );

      final updated = profile.copyWith(
        name: 'Capopalestra',
        trainerLevel: 8,
        money: 2500,
        abilityScores: const {
          'STR': 10,
          'DEX': 16,
          'CON': 12,
          'INT': 11,
          'WIS': 14,
          'CHA': 13,
        },
        armorClass: 15,
        maxHp: 48,
        currentHp: 41,
        speed: 35,
        trainerRace: 'Human',
        background: 'Gym Leader',
        starterPokemon: 'Charmander',
        startingPack: "Dungeoneer's pack",
        skillProficiencies: const ['Persuasion', 'Insight'],
        savingThrowProficiencies: const ['STR'],
        specializations: const ['Pyromaniac'],
        trainerPath: 'Ace Trainer',
      );

      expect(updated.id, profile.id);
      expect(updated.name, 'Capopalestra');
      expect(updated.trainerLevel, 8);
      expect(updated.money, 2500);
      expect(updated.abilityScores['DEX'], 16);
      expect(updated.armorClass, 15);
      expect(updated.maxHp, 48);
      expect(updated.currentHp, 41);
      expect(updated.speed, 35);
      expect(updated.trainerRace, 'Human');
      expect(updated.background, 'Gym Leader');
      expect(updated.starterPokemon, 'Charmander');
      expect(updated.startingPack, "Dungeoneer's pack");
      expect(updated.skillProficiencies, ['Persuasion', 'Insight']);
      expect(updated.savingThrowProficiencies, ['STR']);
      expect(updated.specializations, ['Pyromaniac']);
      expect(updated.trainerPath, 'Ace Trainer');
      expect(updated.createdAt, profile.createdAt);
    });
  });
}
