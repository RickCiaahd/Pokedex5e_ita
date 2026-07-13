import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_npc_trainer.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_content.dart';
import 'package:pokedex_5e_ita/services/npc_trainer_generator_service.dart';

void main() {
  const service = NpcTrainerGeneratorService();
  final catalog = [
    _pokemon(id: 4, name: 'Charmander', types: const ['Fire'], sr: 0.5),
    _pokemon(id: 37, name: 'Vulpix', types: const ['Fire'], sr: 1),
    _pokemon(id: 58, name: 'Growlithe', types: const ['Fire'], sr: 1.5),
    _pokemon(id: 7, name: 'Squirtle', types: const ['Water'], sr: 0.5),
    _pokemon(id: 1, name: 'Bulbasaur', types: const ['Grass'], sr: 0.5),
  ];
  const origins = [
    TrainerOrigin(
      name: 'Umano',
      description: '',
      abilityBonuses: {},
      skillProficiencies: [],
      savingThrowProficiencies: [],
    ),
  ];
  const paths = [TrainerPath(name: 'Ace Trainer', features: [])];
  const specializations = ['Pyromaniac', 'Swimmer', 'Gardener'];

  test('a themed trainer receives only Pokémon of the preferred type', () {
    final trainer = service.generate(
      catalog: catalog,
      options: const NpcTrainerGeneratorOptions(
        trainerLevel: 5,
        pokemonLevel: 5,
        teamSize: 3,
        specialization: 'Pyromaniac',
        composition: NpcTeamComposition.themed,
      ),
      specializations: specializations,
      origins: origins,
      paths: paths,
      random: Random(3),
    );

    expect(trainer, isNotNull);
    expect(trainer!.specializations.first, 'Pyromaniac');
    expect(trainer.preferredType, 'Fire');
    expect(
      trainer.team.every((member) => member.pokemon.types.contains('Fire')),
      isTrue,
    );
  });

  test('duplicates disabled produces distinct species', () {
    final trainer = service.generate(
      catalog: catalog,
      options: const NpcTrainerGeneratorOptions(
        trainerLevel: 5,
        pokemonLevel: 5,
        teamSize: 4,
        specialization: 'Pyromaniac',
        composition: NpcTeamComposition.mixed,
        allowDuplicates: false,
      ),
      specializations: specializations,
      origins: origins,
      paths: paths,
      random: Random(9),
    );

    expect(trainer, isNotNull);
    final ids = trainer!.team.map((member) => member.basePokemon.id).toSet();
    expect(ids, hasLength(trainer.team.length));
  });

  test('trainer rank increases the maximum controllable SR', () {
    const common = NpcTrainerGeneratorOptions(
      trainerLevel: 5,
      rank: NpcTrainerRank.common,
    );
    const boss = NpcTrainerGeneratorOptions(
      trainerLevel: 5,
      rank: NpcTrainerRank.boss,
    );

    expect(service.maxSrFor(common), 5);
    expect(service.maxSrFor(boss), 9);
  });

  test('themed generation fails clearly when the type has no candidates', () {
    final trainer = service.generate(
      catalog: [catalog.firstWhere((pokemon) => pokemon.name == 'Squirtle')],
      options: const NpcTrainerGeneratorOptions(
        specialization: 'Pyromaniac',
        composition: NpcTeamComposition.themed,
      ),
      specializations: specializations,
      origins: origins,
      paths: paths,
      random: Random(2),
    );

    expect(trainer, isNull);
  });
}

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
  required double sr,
}) {
  return Pokemon(
    id: id,
    name: name,
    types: types,
    armorClass: 12,
    hitPoints: 12,
    size: 'Small',
    speed: 9,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 12,
      constitution: 10,
      intelligence: 8,
      wisdom: 10,
      charisma: 8,
    ),
    abilities: const ['Run Away'],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: ['Tackle'],
      levelMoves: {},
      tmMoves: [],
    ),
    hitDice: 6,
    sr: sr,
    minLevelFound: 1,
  );
}
