import '../repositories/pokedex_repositry.dart';
import '../repositories/pokemon_pc_repository.dart';
import '../repositories/team_repository.dart';

class PokedexOwnershipService {
  PokedexOwnershipService({
    PokedexRepository? pokedexRepository,
    TeamRepository? teamRepository,
    PokemonPcRepository? pcRepository,
  })  : _pokedexRepository = pokedexRepository ?? PokedexRepository(),
        _teamRepository = teamRepository ?? TeamRepository(),
        _pcRepository = pcRepository ?? PokemonPcRepository();

  final PokedexRepository _pokedexRepository;
  final TeamRepository _teamRepository;
  final PokemonPcRepository _pcRepository;

  Future<void> registerOwned({
    required String profileId,
    required int pokemonId,
    String? formName,
  }) async {
    await _pokedexRepository.registerCaught(
      profileId: profileId,
      pokemonId: pokemonId,
      formName: formName,
    );
  }

  Future<void> syncOwnedCollection(String profileId) async {
    final results = await Future.wait([
      _teamRepository.getTeam(profileId),
      _pcRepository.getPokemon(profileId),
    ]);
    final team = results[0] as List;
    final pcPokemon = results[1] as List;

    for (final slot in team) {
      final pokemonId = slot.pokemonId as int?;
      if (pokemonId == null) continue;
      await registerOwned(
        profileId: profileId,
        pokemonId: pokemonId,
        formName: slot.formName as String?,
      );
    }

    for (final stored in pcPokemon) {
      await registerOwned(
        profileId: profileId,
        pokemonId: stored.pokemonId as int,
        formName: stored.formName as String?,
      );
    }
  }
}
