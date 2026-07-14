import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/services/trainer_path_passive_service.dart';

void main() {
  test('senza profilo o Pokémon posseduto non applica bonus del Trainer Path', () {
    final pokemon = Pokemon(
      id: 1,
      name: 'Testmon',
      types: const ['Normal'],
      armorClass: 10,
      hitPoints: 8,
      size: 'Small',
      speed: 30,
      attributes: const PokemonAttributes(
        strength: 10,
        dexterity: 10,
        constitution: 10,
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
      hitDice: 6,
      sr: 0.5,
      minLevelFound: 1,
    );
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
}
