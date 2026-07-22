import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/custom_pokemon_definition.dart';
import '../repositories/profile_repository.dart';

class CustomPokemonDiscoveryService {
  CustomPokemonDiscoveryService({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  final ProfileRepository _profileRepository;

  Future<Box> _box() => Hive.openBox(HiveBoxes.customPokemonDiscovery);

  String _key(String profileId, String stableId) => '$profileId::$stableId';

  Future<bool> isRevealed(
    CustomPokemonDefinition definition, {
    String? profileId,
  }) async {
    if (!definition.advanced.sealedForPlayer) return true;
    final effectiveProfileId =
        profileId ?? (await _profileRepository.getActiveProfile()).id;
    final box = await _box();
    return box.get(_key(effectiveProfileId, definition.stableId)) == true;
  }

  Future<bool> isVisible(
    CustomPokemonDefinition definition, {
    String? profileId,
  }) async {
    return !definition.advanced.sealedForPlayer ||
        await isRevealed(definition, profileId: profileId);
  }

  Future<List<CustomPokemonDefinition>> visibleDefinitions(
    Iterable<CustomPokemonDefinition> definitions, {
    String? profileId,
  }) async {
    final effectiveProfileId =
        profileId ?? (await _profileRepository.getActiveProfile()).id;
    final box = await _box();
    return [
      for (final definition in definitions)
        if (!definition.advanced.sealedForPlayer ||
            box.get(_key(effectiveProfileId, definition.stableId)) == true)
          definition,
    ];
  }

  Future<bool> revealByPokemonId(int pokemonId) async {
    final definition = await _definitionByPokemonId(pokemonId);
    if (definition == null || !definition.advanced.sealedForPlayer) return false;
    final profile = await _profileRepository.getActiveProfile();
    final box = await _box();
    final key = _key(profile.id, definition.stableId);
    if (box.get(key) == true) return false;
    await box.put(key, true);
    await box.flush();
    return true;
  }

  Future<void> concealForCurrentProfile(String stableId) async {
    final profile = await _profileRepository.getActiveProfile();
    final box = await _box();
    await box.delete(_key(profile.id, stableId));
    await box.flush();
  }

  Future<CustomPokemonDefinition?> _definitionByPokemonId(int pokemonId) async {
    final box = await Hive.openBox(HiveBoxes.customPokemon);
    for (final value in box.values) {
      if (value is! Map) continue;
      try {
        final definition = CustomPokemonDefinition.fromJson(
          Map<String, dynamic>.from(value),
        );
        if (definition.pokemonId == pokemonId) return definition;
      } on FormatException {
        // Una definizione corrotta non deve bloccare la scoperta delle altre.
      }
    }
    return null;
  }
}
