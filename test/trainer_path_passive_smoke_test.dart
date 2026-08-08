import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/services/trainer_path_passive_service.dart';

Pokemon _pokemon({
  int id = 1,
  String name = 'Testmon',
  String size = 'Small',
  int constitution = 10,
  int hitPoints = 8,
  int hitDice = 6,
}) {
  return Pokemon(
    id: id,
    name: name,
    types: const ['Normal'],
    armorClass: 10,
    hitPoints: hitPoints,
    size: size,
    speed: 30,
    attributes: PokemonAttributes(
      strength: 10,
      dexterity: 10,
      constitution: constitution,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: const [],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: [],
      levelMoves: {},
      tmMoves: [],
    ),
    hitDice: hitDice,
    sr: 0.5,
    minLevelFound: 1,
  );
}

void main() {
  test('senza profilo o Pokémon posseduto non applica bonus del Trainer Path', () {
    final pokemon = _pokemon();
    final slot = TeamSlot(slotIndex: 0, pokemonId: 1);

    expect(
      TrainerPathPassiveService.attackRollBonus(
        profile: null,
        pokemon: pokemon,
        slot: null,
      ),
      0,
    );
    expect(
      TrainerPathPassiveService.damageRollBonus(profile: null, slot: null),
      0,
    );
    expect(
      TrainerPathPassiveService.effectiveSpeed(
        profile: null,
        pokemon: pokemon,
        slot: slot,
      ),
      30,
    );
    expect(
      TrainerPathPassiveService.maxHp(
        profile: null,
        pokemon: pokemon,
        slot: slot,
        level: 1,
      ),
      8,
    );
  });

  test('Schooling aumenta la COS di Wishiwashi senza aumentare i PF', () {
    final solo = _pokemon(
      id: 746,
      name: 'Wishiwashi',
      size: 'Tiny',
      constitution: 10,
      hitPoints: 18,
      hitDice: 8,
    );
    final school = _pokemon(
      id: 746,
      name: 'Wishiwashi',
      size: 'Huge',
      constitution: 15,
      hitPoints: 18,
      hitDice: 8,
    );
    final slot = TeamSlot(slotIndex: 0, pokemonId: 746);

    final soloHp = TrainerPathPassiveService.maxHp(
      profile: null,
      pokemon: solo,
      slot: slot,
      level: 8,
    );
    final schoolHp = TrainerPathPassiveService.maxHp(
      profile: null,
      pokemon: school,
      slot: slot,
      level: 8,
    );

    expect(schoolHp, soloHp);
    expect(
      TrainerPathPassiveService.effectiveAttributeScores(
        profile: null,
        pokemon: school,
        slot: slot,
      )['CON'],
      15,
    );
  });
}
