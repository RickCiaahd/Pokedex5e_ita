import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pokemon.dart';

import '../models/pokemon_flavor.dart';

class PokemonRepository {
  static List<Pokemon>? _cachedAllPokemon;

  Future<List<Pokemon>> getAllPokemon() async {
    if (_cachedAllPokemon != null) {
      return List<Pokemon>.from(_cachedAllPokemon!);
    }

    final pokemonByNumber = <int, Pokemon>{};

    for (final pokemon in await _getLegacyPokemon()) {
      if (pokemon.id <= 0) continue;
      pokemonByNumber[pokemon.id] = pokemon;
    }

    for (final pokemon in await _getWebappPokemon()) {
      if (pokemon.id <= 0) continue;
      pokemonByNumber.putIfAbsent(pokemon.id, () => pokemon);
    }

    final pokemonList = pokemonByNumber.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    _cachedAllPokemon = pokemonList;

    return List<Pokemon>.from(pokemonList);
  }

  Future<List<Pokemon>> _getLegacyPokemon() async {
    final indexString = await rootBundle.loadString(
      'assets/data/index_order.json',
    );

    final Map<String, dynamic> indexMap = jsonDecode(indexString);
    final List<Pokemon> pokemonList = [];

    final orderedKeys = indexMap.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    for (final key in orderedKeys) {
      final List<dynamic> names = indexMap[key];

      for (final dynamic name in names) {
        final pokemonName = name.toString();

        try {
          final fileName = _normalizePokemonFileName(pokemonName);

          final jsonString = await rootBundle.loadString(
            'assets/data/pokemon/$fileName.json',
          );

          final Map<String, dynamic> json = jsonDecode(jsonString);

          pokemonList.add(Pokemon.fromJson(pokemonName, json));
        } catch (e) {
          debugPrint('Errore caricando $pokemonName: $e');
        }
      }
    }

    return pokemonList;
  }

  Future<List<Pokemon>> _getWebappPokemon() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/pokemon.json',
      );
      final json = Map<String, dynamic>.from(jsonDecode(jsonString));
      final items = List<dynamic>.from(json['items'] ?? const []);
      final pokemonList = <Pokemon>[];

      for (final item in items) {
        if (item is! Map) continue;

        try {
          final pokemon = Pokemon.fromWebJson(Map<String, dynamic>.from(item));
          if (pokemon.id > 0 && pokemon.name.trim().isNotEmpty) {
            pokemonList.add(pokemon);
          }
        } catch (error) {
          debugPrint('Errore convertendo Pokemon webapp: $error');
        }
      }

      return pokemonList;
    } catch (error) {
      debugPrint('Catalogo Pokemon webapp non disponibile: $error');
      return const [];
    }
  }

  Future<Map<int, PokemonFlavor>> getPokemonFlavors() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/pokemon_flavor.json',
    );

    final Map<String, dynamic> json = jsonDecode(jsonString);

    return json.map(
      (key, value) => MapEntry(
        int.parse(key),
        PokemonFlavor.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  String _normalizePokemonFileName(String name) {
    return name
        .replaceAll(' ♀', '-f')
        .replaceAll(' ♂', '-m')
        .replaceAll(':', '')
        .replaceAll('é', 'e');
  }
}
