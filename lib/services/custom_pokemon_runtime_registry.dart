import 'dart:typed_data';

import '../models/custom_pokemon_advanced_data.dart';
import '../models/custom_pokemon_definition.dart';
import '../models/move_data.dart';
import '../models/pokemon.dart';

class CustomPokemonRuntimeRegistry {
  CustomPokemonRuntimeRegistry._();

  static final Map<int, CustomPokemonDefinition> _definitions = {};

  static void replaceAll(Iterable<CustomPokemonDefinition> definitions) {
    _definitions
      ..clear()
      ..addEntries(
        definitions.map(
          (definition) => MapEntry(definition.pokemonId, definition),
        ),
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

  static Iterable<CustomPokemonDefinition> get definitions {
    return _definitions.values;
  }

  static bool isCustomPokemon(int pokemonId) {
    return _definitions.containsKey(pokemonId);
  }

  static Uint8List? imageBytesFor(
    int pokemonId, {
    String? formName,
    bool shiny = false,
  }) {
    final definition = _definitions[pokemonId];
    if (definition == null) return null;
    final key = Pokemon.formReferenceKey(formName ?? '', definition.name);
    if (key.isNotEmpty && key != 'base') {
      for (final form in definition.advanced.forms) {
        final formKey = Pokemon.formReferenceKey(form.name, definition.name);
        final idKey = Pokemon.formReferenceKey(form.id, definition.name);
        if (key == formKey || key == idKey) {
          return shiny
              ? form.shinyImageBytes ?? form.imageBytes
              : form.imageBytes;
        }
      }
    }
    return shiny
        ? definition.shinyImageBytes ?? definition.imageBytes
        : definition.imageBytes;
  }

  static CustomPokemonDefinition? definitionByStableId(String? stableId) {
    if (stableId == null || stableId.isEmpty) return null;
    for (final definition in _definitions.values) {
      if (definition.stableId == stableId) return definition;
    }
    return null;
  }

  static CustomPokemonDefinition? resolveReference(
    CustomPokemonReference reference,
  ) {
    final byId = reference.pokemonId == null
        ? null
        : _definitions[reference.pokemonId];
    return byId ?? definitionByStableId(reference.stableId);
  }

  static bool isTemporaryForm(int pokemonId, String? formName) {
    final definition = _definitions[pokemonId];
    if (definition == null) return false;
    final key = Pokemon.formReferenceKey(formName ?? '', definition.name);
    return definition.advanced.forms.any(
      (form) =>
          form.duration == CustomPokemonFormDuration.battle &&
          (Pokemon.formReferenceKey(form.name, definition.name) == key ||
              Pokemon.formReferenceKey(form.id, definition.name) == key),
    );
  }

  static bool hasTemporaryForms(int pokemonId) {
    return _definitions[pokemonId]?.advanced.forms.any(
          (form) => form.duration == CustomPokemonFormDuration.battle,
        ) ==
        true;
  }

  static MoveData? moveFor(int pokemonId, String reference) {
    final definition = _definitions[pokemonId];
    if (definition == null) return null;
    return definition.localMoveCatalog()[MoveData.referenceKey(reference)];
  }

  static MoveData? moveForAny(String reference) {
    final key = MoveData.referenceKey(reference);
    if (key.isEmpty) return null;

    MoveData? selected;
    String? selectedSignature;
    for (final definition in _definitions.values) {
      final candidate = definition.localMoveCatalog()[key];
      if (candidate == null) continue;

      final signature = _moveSignature(candidate);
      if (selected == null) {
        selected = candidate;
        selectedSignature = signature;
        continue;
      }
      if (signature != selectedSignature) {
        return null;
      }
    }
    return selected;
  }

  static String _moveSignature(MoveData move) {
    final damageEntries = move.damageByLevel.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      move.name,
      move.type,
      move.pp,
      move.range,
      move.duration,
      move.moveTime,
      move.description,
      move.scaling ?? '',
      move.higherLevels ?? '',
      move.damageModifier ?? '',
      move.attackScope ?? '',
      move.save ?? '',
      move.isAttack.toString(),
      move.movePowers.join('|'),
      move.damageTypes.join('|'),
      for (final entry in damageEntries)
        '${entry.key}:${entry.value.amount}:${entry.value.diceMax}:${entry.value.isMoveDamage}',
    ].join('\u001f');
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
