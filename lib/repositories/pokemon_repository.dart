import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pokemon.dart';

class PokemonRepository {
  Future<List<Pokemon>> getAllPokemon() async {
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

          pokemonList.add(
            Pokemon.fromJson(pokemonName, json),
          );
        } catch (e) {
          debugPrint('Errore caricando $pokemonName: $e');
        }
      }
    }

    return pokemonList;
  }

  String _normalizePokemonFileName(String name) {

    return name
        .replaceAll(' ♀', '-f')
        .replaceAll(' ♂', '-m')
        .replaceAll(':', '')
        .replaceAll('é', 'e');
  }
}