import '../models/custom_pokemon_definition.dart';
import '../models/custom_pokemon_transfer_bundle.dart';
import '../repositories/custom_pokemon_repository.dart';
import '../repositories/pokemon_repository.dart';
import 'custom_pokemon_transfer_service.dart';

class EmbeddedCustomPokemonInstallResult {
  const EmbeddedCustomPokemonInstallResult({
    required this.pokemonIdMap,
    required this.installed,
    required this.updated,
    required this.remapped,
  });

  final Map<int, int> pokemonIdMap;
  final int installed;
  final int updated;
  final int remapped;

  int resolvePokemonId(int sourcePokemonId) {
    return pokemonIdMap[sourcePokemonId] ?? sourcePokemonId;
  }
}

/// Adds custom species definitions to composite transfers and restores them
/// before the transferred Pokémon references are persisted.
class EmbeddedCustomPokemonTransferService {
  EmbeddedCustomPokemonTransferService({
    CustomPokemonRepository? repository,
    CustomPokemonTransferService? transferService,
  }) : _repository = repository ?? CustomPokemonRepository(),
       _transferService =
           transferService ??
           CustomPokemonTransferService(repository: repository);

  final CustomPokemonRepository _repository;
  final CustomPokemonTransferService _transferService;

  Future<List<CustomPokemonDefinition>> definitionsForPokemonIds(
    Iterable<int> pokemonIds,
  ) async {
    final requestedIds = pokemonIds
        .where(
          (pokemonId) =>
              pokemonId >= CustomPokemonDefinition.firstCustomPokemonId,
        )
        .toSet();
    if (requestedIds.isEmpty) return const [];

    final definitions = await _repository.getAll();
    final byPokemonId = {
      for (final definition in definitions) definition.pokemonId: definition,
    };
    final missingIds = requestedIds.difference(byPokemonId.keys.toSet());
    if (missingIds.isNotEmpty) {
      final ordered = missingIds.toList()..sort();
      throw FormatException(
        'Impossibile esportare: mancano le definizioni Fakemon per '
        '${ordered.map((id) => '#$id').join(', ')}.',
      );
    }

    final result = [for (final id in requestedIds) byPokemonId[id]!]
      ..sort((a, b) => a.pokemonId.compareTo(b.pokemonId));
    return List<CustomPokemonDefinition>.unmodifiable(result);
  }

  Future<EmbeddedCustomPokemonInstallResult> installDefinitions(
    Iterable<CustomPokemonDefinition> definitions,
  ) async {
    final incoming = definitions.toList(growable: false);
    if (incoming.isEmpty) {
      return const EmbeddedCustomPokemonInstallResult(
        pokemonIdMap: {},
        installed: 0,
        updated: 0,
        remapped: 0,
      );
    }

    final stableIds = <String>{};
    final pokemonIds = <int>{};
    for (final definition in incoming) {
      definition.validate();
      if (!stableIds.add(definition.stableId)) {
        throw FormatException(
          'Il trasferimento contiene più definizioni per ${definition.name}.',
        );
      }
      if (!pokemonIds.add(definition.pokemonId)) {
        throw FormatException(
          'Il trasferimento contiene più Fakemon con ID ${definition.pokemonId}.',
        );
      }
    }

    final idMap = <int, int>{};
    var installed = 0;
    var updated = 0;
    var remapped = 0;

    for (final definition in incoming) {
      final existed =
          await _repository.getByStableId(definition.stableId) != null;
      final result = await _transferService.importBundle(
        CustomPokemonTransferBundle.create(definition),
      );
      idMap[definition.pokemonId] = result.definition.pokemonId;
      if (result.updatedExisting || existed) {
        updated += 1;
      } else {
        installed += 1;
      }
      if (result.remappedPokemonId ||
          result.definition.pokemonId != definition.pokemonId) {
        remapped += 1;
      }
    }

    PokemonRepository.clearCache();
    return EmbeddedCustomPokemonInstallResult(
      pokemonIdMap: Map<int, int>.unmodifiable(idMap),
      installed: installed,
      updated: updated,
      remapped: remapped,
    );
  }
}
