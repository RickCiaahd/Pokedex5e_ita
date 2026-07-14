import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/pokemon_transfer_bundle.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/services/pokemon_transfer_service.dart';

void main() {
  test('il file di un singolo Pokémon conserva tutti i dati utili', () {
    final source = TeamSlot(
      slotIndex: 4,
      pokemonId: 25,
      experience: 3200,
      currentHp: 18,
      nickname: 'Saetta',
      selectedMoves: const ['thunderbolt', 'quick-attack'],
      isShiny: true,
      gender: 'female',
      formName: 'Normal',
      nature: 'Jolly',
      heldItem: 'light-ball',
      abilities: const ['Static'],
      feats: const ['Terrain Adept (Forest)'],
      extraSkills: const ['Acrobatics'],
      statusEffects: const ['Paralyzed'],
      customAbilityScores: const {'DEX': 2},
      loyalty: 3,
    );
    final bundle = PokemonTransferBundle.single(
      slot: source,
      sourceTrainerName: 'Misty',
      exportedAt: DateTime.utc(2026, 7, 15),
    );
    final service = PokemonTransferService();
    final restored = service.decode(service.encode(bundle));
    final slot = restored.pokemon.single;

    expect(restored.kind, PokemonTransferKind.pokemon);
    expect(restored.sourceTrainerName, 'Misty');
    expect(slot.slotIndex, 0);
    expect(slot.pokemonId, 25);
    expect(slot.nickname, 'Saetta');
    expect(slot.selectedMoves, ['thunderbolt', 'quick-attack']);
    expect(slot.isShiny, isTrue);
    expect(slot.heldItem, 'light-ball');
    expect(slot.feats, ['Terrain Adept (Forest)']);
    expect(slot.customAbilityScores['DEX'], 2);
    expect(slot.loyalty, 3);
  });

  test(
    'importare un Pokémon sostituisce lo slot e salva il precedente nel PC',
    () {
      final current = _emptyTeam();
      current[2] = TeamSlot(slotIndex: 2, pokemonId: 1, nickname: 'Vecchio');
      final bundle = PokemonTransferBundle.single(
        slot: TeamSlot(slotIndex: 0, pokemonId: 4, nickname: 'Nuovo'),
        sourceTrainerName: 'Rosso',
      );

      final plan = PokemonTransferService.planPokemonImport(
        currentTeam: current,
        bundle: bundle,
        targetSlotIndex: 2,
      );

      expect(plan.updatedTeam[2].pokemonId, 4);
      expect(plan.updatedTeam[2].nickname, 'Nuovo');
      expect(plan.toPc.single.pokemonId, 1);
      expect(plan.replacedPokemon, 1);
      expect(plan.importedToTeam, 1);
    },
  );

  test('importare una squadra preserva le uova e manda gli esuberi nel PC', () {
    final current = _emptyTeam();
    current[0] = TeamSlot(slotIndex: 0, pokemonId: 1);
    current[1] = TeamSlot(slotIndex: 1, pokemonId: null, eggId: 'egg-1');
    current[2] = TeamSlot(slotIndex: 2, pokemonId: 7);

    final bundle = PokemonTransferBundle.team(
      sourceTrainerName: 'Blu',
      slots: [
        TeamSlot(slotIndex: 0, pokemonId: 4),
        TeamSlot(slotIndex: 1, pokemonId: 25),
        TeamSlot(slotIndex: 2, pokemonId: 39),
        TeamSlot(slotIndex: 3, pokemonId: 52),
      ],
    );

    final plan = PokemonTransferService.planTeamImport(
      currentTeam: current,
      bundle: bundle,
      unlockedPokeslots: 3,
    );

    expect(plan.updatedTeam[0].pokemonId, 4);
    expect(plan.updatedTeam[1].eggId, 'egg-1');
    expect(plan.updatedTeam[2].pokemonId, 25);
    expect(plan.importedToTeam, 2);
    expect(plan.replacedPokemon, 2);
    expect(plan.overflowToPc, 2);
    expect(
      plan.toPc.map((slot) => slot.pokemonId),
      containsAll(<int?>[1, 7, 39, 52]),
    );
  });

  test('un uovo non può essere esportato come Pokémon', () {
    expect(
      () => PokemonTransferBundle.single(
        slot: TeamSlot(slotIndex: 0, pokemonId: null, eggId: 'egg'),
        sourceTrainerName: 'Brock',
      ),
      throwsFormatException,
    );
  });
}

List<TeamSlot> _emptyTeam() {
  return List<TeamSlot>.generate(
    6,
    (index) => TeamSlot(slotIndex: index, pokemonId: null),
  );
}
