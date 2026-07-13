import '../models/generated_encounter.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import '../models/saved_encounter.dart';
import 'encounter_generator_service.dart';

class SavedEncounterMapperService {
  const SavedEncounterMapperService({
    this.encounterService = const EncounterGeneratorService(),
  });

  final EncounterGeneratorService encounterService;

  SavedEncounter fromGenerated(
    GeneratedEncounter encounter, {
    required String name,
    String notes = '',
    SavedEncounter? existing,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return SavedEncounter(
      id: existing?.id ?? timestamp.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      notes: notes.trim(),
      source: encounter.source,
      party: encounter.party,
      filters: encounter.filters,
      targetDifficulty: encounter.targetDifficulty,
      members: [
        for (final member in encounter.members)
          SavedEncounterMember(
            pokemonId: member.pokemon.basePokemon.id,
            formName: member.pokemon.formName,
            level: member.pokemon.level,
            gender: member.pokemon.gender,
            nature: member.pokemon.nature,
            ability: member.pokemon.ability,
            selectedMoves: member.pokemon.selectedMoves,
            isShiny: member.pokemon.isShiny,
            maxHp: member.pokemon.maxHp,
            isLocked: member.isLocked,
          ),
      ],
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
      collectionId: encounter.collectionId,
      collectionName: encounter.collectionName,
    );
  }

  GeneratedEncounter toGenerated({
    required SavedEncounter saved,
    required List<Pokemon> catalog,
  }) {
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final members = <EncounterMember>[];
    for (final savedMember in saved.members) {
      final basePokemon = byId[savedMember.pokemonId];
      if (basePokemon == null) {
        throw StateError(
          'Il Pokémon #${savedMember.pokemonId} non è più disponibile nel catalogo.',
        );
      }
      final resolvedPokemon = basePokemon.resolveVariant(
        formName: savedMember.formName,
        gender: savedMember.gender,
      );
      members.add(
        EncounterMember(
          pokemon: GeneratedPokemon(
            basePokemon: basePokemon,
            pokemon: resolvedPokemon,
            formName: savedMember.formName,
            level: savedMember.level,
            gender: savedMember.gender,
            nature: savedMember.nature,
            ability: savedMember.ability,
            selectedMoves: savedMember.selectedMoves,
            isShiny: savedMember.isShiny,
            maxHp: savedMember.maxHp,
          ),
          isLocked: savedMember.isLocked,
        ),
      );
    }

    final estimate = encounterService.estimate(
      party: saved.party,
      generated: members.map((member) => member.pokemon),
      targetDifficulty: saved.targetDifficulty,
    );
    return GeneratedEncounter(
      id: saved.id,
      source: saved.source,
      title: saved.name,
      party: saved.party,
      filters: saved.filters,
      targetDifficulty: saved.targetDifficulty,
      members: members,
      estimate: estimate,
      createdAt: saved.createdAt,
      collectionId: saved.collectionId,
      collectionName: saved.collectionName,
    );
  }
}
