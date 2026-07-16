import 'dart:typed_data';

import '../models/custom_pokemon_definition.dart';
import '../models/move_data.dart';

class CustomPokemonRuntimeRegistry {
  CustomPokemonRuntimeRegistry._();

  static final Map<int, CustomPokemonDefinition> _definitions = {};

  static void replaceAll(Iterable<CustomPokemonDefinition> definitions) {
    _definitions
      ..clear()
      ..addEntries(
        definitions.map((definition) => MapEntry(definition.pokemonId, definition)),
      );
  }

  static void register(CustomPokemonDefinition definition) {
    _definitions[definition.pokemonId] = definition;
  }

  static void unregister(int pokemonId) {
    _definitions.remove(pokemonId);
  }

  static CustomPokemonDefinition? definitionFor(int pokemonId) {
    return _definitions[pokemonId];
  }

  static bool isCustomPokemon(int pokemonId) {
    return _definitions.containsKey(pokemonId);
  }

  static Uint8List? imageBytesFor(int pokemonId) {
    return _definitions[pokemonId]?.imageBytes;
  }

  static MoveData? moveFor(int pokemonId, String reference) {
    final definition = _definitions[pokemonId];
    if (definition == null) return null;
    return definition.localMoveCatalog()[MoveData.referenceKey(reference)];
  }

  static Map<String, MoveData> moveCatalogFor(int pokemonId) {
    return _definitions[pokemonId]?.localMoveCatalog() ?? const {};
  }

  static String? abilityDescriptionFor(int pokemonId, String abilityName) {
    return _definitions[pokemonId]?.localAbilityCatalog()[abilityName];
  }

  static Map<String, String> abilityCatalogFor(int pokemonId) {
    return _definitions[pokemonId]?.localAbilityCatalog() ?? const {};
  }
}
