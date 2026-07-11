import '../models/pc_pokemon.dart';
import '../models/team_slot.dart';
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
    final teamFuture = _teamRepository.getTeam(profileId);
    final pcFuture = _pcRepository.getPokemon(profileId);
    final team = await teamFuture;
    final pcPokemon = await pcFuture;

    await _registerTeam(profileId, team);
    await _registerPc(profileId, pcPokemon);
  }

  Future<void> _registerTeam(
    String profileId,
    List<TeamSlot> team,
  ) async {
    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      await registerOwned(
        profileId: profileId,
        pokemonId: pokemonId,
        formName: slot.formName,
      );
    }
  }

  Future<void> _registerPc(
    String profileId,
    List<PcPokemon> pokemon,
  ) async {
    for (final stored in pokemon) {
      await registerOwned(
        profileId: profileId,
        pokemonId: stored.pokemonId,
        formName: stored.formName,
      );
    }
  }
}
