import '../models/generated_npc_trainer.dart';
import '../models/generated_pokemon.dart';
import '../models/pokemon.dart';
import '../models/saved_npc_trainer.dart';

class SavedNpcTrainerMapperService {
  const SavedNpcTrainerMapperService();

  SavedNpcTrainer fromGenerated(
    GeneratedNpcTrainer trainer, {
    SavedNpcTrainer? existing,
    String? name,
    String? notes,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return SavedNpcTrainer(
      id: existing?.id ?? timestamp.microsecondsSinceEpoch.toString(),
      name: (name ?? trainer.name).trim(),
      epithet: trainer.epithet,
      trainerLevel: trainer.trainerLevel,
      rank: trainer.rank,
      origin: trainer.origin,
      path: trainer.path,
      specializations: trainer.specializations,
      preferredType: trainer.preferredType,
      personality: trainer.personality,
      motivation: trainer.motivation,
      quirk: trainer.quirk,
      openingLine: trainer.openingLine,
      tactics: trainer.tactics,
      rewardMoney: trainer.rewardMoney,
      rewards: trainer.rewards,
      team: [
        for (final pokemon in trainer.team)
          SavedNpcPokemon(
            pokemonId: pokemon.basePokemon.id,
            formName: pokemon.formName,
            level: pokemon.level,
            gender: pokemon.gender,
            nature: pokemon.nature,
            ability: pokemon.ability,
            selectedMoves: pokemon.selectedMoves,
            isShiny: pokemon.isShiny,
            maxHp: pokemon.maxHp,
          ),
      ],
      options: trainer.options,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
      notes: (notes ?? existing?.notes ?? '').trim(),
    );
  }

  GeneratedNpcTrainer toGenerated({
    required SavedNpcTrainer saved,
    required List<Pokemon> catalog,
  }) {
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final team = <GeneratedPokemon>[];
    for (final member in saved.team) {
      final basePokemon = byId[member.pokemonId];
      if (basePokemon == null) {
        throw StateError(
          'Il Pokémon #${member.pokemonId} non è più disponibile nel catalogo.',
        );
      }
      final resolved = basePokemon.resolveVariant(
        formName: member.formName,
        gender: member.gender,
      );
      team.add(
        GeneratedPokemon(
          basePokemon: basePokemon,
          pokemon: resolved,
          formName: member.formName,
          level: member.level,
          gender: member.gender,
          nature: member.nature,
          ability: member.ability,
          selectedMoves: member.selectedMoves,
          isShiny: member.isShiny,
          maxHp: member.maxHp,
        ),
      );
    }

    return GeneratedNpcTrainer(
      name: saved.name,
      epithet: saved.epithet,
      trainerLevel: saved.trainerLevel,
      rank: saved.rank,
      origin: saved.origin,
      path: saved.path,
      specializations: saved.specializations,
      preferredType: saved.preferredType,
      personality: saved.personality,
      motivation: saved.motivation,
      quirk: saved.quirk,
      openingLine: saved.openingLine,
      tactics: saved.tactics,
      rewardMoney: saved.rewardMoney,
      rewards: saved.rewards,
      team: team,
      options: saved.options,
      generatedAt: saved.updatedAt,
    );
  }
}
