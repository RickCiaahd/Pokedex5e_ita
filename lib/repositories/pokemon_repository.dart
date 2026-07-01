import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pokemon.dart';

class PokemonRepository {
  Future<List<Pokemon>> getAllPokemon() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/pokemon.json',
    );

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((json) => Pokemon.fromJson(json))
        .toList();
  }
}