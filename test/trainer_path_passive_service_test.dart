import 'package:flutter_test/flutter_test.dart';

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
    moves: const PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []),
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
