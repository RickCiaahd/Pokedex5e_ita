import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';

import '../database/hive_boxes.dart';
import '../models/custom_pokemon_definition.dart';
import '../services/custom_pokemon_runtime_registry.dart';

class CustomPokemonRepository {
  static int _revision = 0;

  static int get revision => _revision;

  Future<Box> _box() => Hive.openBox(HiveBoxes.customPokemon);

  Future<List<CustomPokemonDefinition>> getAll() async {
    Box box;
    try {
      box = await _box();
    } catch (error) {
      // Il catalogo statico viene caricato anche in test puri che non inizializzano
      // Hive. In quel contesto l'assenza del deposito utente equivale a non avere
      // Fakemon installati, mentre ogni altro errore deve continuare a emergere.
      final message = error.toString();
      if (message.contains('HiveError') && message.contains('initialize Hive')) {
        CustomPokemonRuntimeRegistry.replaceAll(const []);
        return const [];
      }
      rethrow;
    }

    final definitions = <CustomPokemonDefinition>[];

    for (final value in box.values) {
      if (value is! Map) continue;
      try {
        definitions.add(
          CustomPokemonDefinition.fromJson(Map<String, dynamic>.from(value)),
        );
      } on FormatException {
        // Una voce danneggiata non deve impedire il caricamento delle altre.
      }
    }

    definitions.sort((a, b) {
      final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return nameCompare != 0
          ? nameCompare
          : a.pokemonId.compareTo(b.pokemonId);
    });
    CustomPokemonRuntimeRegistry.replaceAll(definitions);
    return definitions;
  }

  Future<CustomPokemonDefinition?> getByStableId(String stableId) async {
    final box = await _box();
    final value = box.get(stableId);
    if (value is! Map) return null;
    return CustomPokemonDefinition.fromJson(Map<String, dynamic>.from(value));
  }

  Future<CustomPokemonDefinition?> getByPokemonId(int pokemonId) async {
    final definitions = await getAll();
    for (final definition in definitions) {
      if (definition.pokemonId == pokemonId) return definition;
    }
    return null;
  }

  Future<void> save(CustomPokemonDefinition definition) async {
    definition.validate();
    final box = await _box();

    for (final entry in box.toMap().entries) {
      if (entry.key == definition.stableId || entry.value is! Map) continue;
      final existing = CustomPokemonDefinition.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (existing.pokemonId == definition.pokemonId) {
        throw FormatException(
          'L’ID interno ${definition.pokemonId} è già usato da ${existing.name}.',
        );
      }
    }

    await box.put(definition.stableId, definition.toJson());
    await box.flush();
    CustomPokemonRuntimeRegistry.register(definition);
    _revision += 1;
  }

  Future<void> delete(String stableId) async {
    final box = await _box();
    final value = box.get(stableId);
    if (value is Map) {
      try {
        final definition = CustomPokemonDefinition.fromJson(
          Map<String, dynamic>.from(value),
        );
        CustomPokemonRuntimeRegistry.unregister(definition.pokemonId);
      } on FormatException {
        // La voce viene rimossa anche quando non è più leggibile.
      }
    }
    await box.delete(stableId);
    await box.flush();
    _revision += 1;
  }

  Future<int> allocatePokemonId() async {
    final definitions = await getAll();
    var next = CustomPokemonDefinition.firstCustomPokemonId;
    for (final definition in definitions) {
      if (definition.pokemonId >= next) next = definition.pokemonId + 1;
    }
    return next;
  }

  String createStableId() {
    final timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toRadixString(36);
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(36);
    return 'fakemon-$timestamp-$random';
  }

  Future<bool> containsStableId(String stableId) async {
    final box = await _box();
    return box.containsKey(stableId);
  }

  Future<bool> containsPokemonId(int pokemonId) async {
    return await getByPokemonId(pokemonId) != null;
  }
}
