import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Set<String> bundledAssets;
  late List<Pokemon> catalog;

  setUpAll(() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    bundledAssets = manifest.listAssets().toSet();
    catalog = await PokemonRepository().getAllPokemon();
  });

  group('File sorgente', () {
    test('l indice legacy punta solo a file Pokemon validi', () async {
      final rawIndex = jsonDecode(
        await rootBundle.loadString('assets/data/index_order.json'),
      );
      expect(rawIndex, isA<Map>());

      final index = Map<String, dynamic>.from(rawIndex as Map);
      final errors = <String>[];
      final indexedNames = <String>{};

      for (final entry in index.entries) {
        final expectedId = int.tryParse(entry.key);
        if (expectedId == null || expectedId <= 0) {
          errors.add('Indice Pokemon non valido: ${entry.key}');
          continue;
        }
        if (entry.value is! List) {
          errors.add('La voce $expectedId dell indice non contiene una lista.');
          continue;
        }

        for (final value in entry.value as List) {
          final name = value.toString().trim();
          if (name.isEmpty) {
            errors.add('Nome vuoto nell indice alla voce $expectedId.');
            continue;
          }
          if (!indexedNames.add(name.toLowerCase())) {
            errors.add('Nome duplicato nell indice legacy: $name.');
          }

          final path = 'assets/data/pokemon/${_legacyFileName(name)}.json';
          if (!bundledAssets.contains(path)) {
            errors.add('File mancante per #$expectedId $name: $path');
            continue;
          }

          try {
            final rawPokemon = jsonDecode(await rootBundle.loadString(path));
            if (rawPokemon is! Map) {
              errors.add('JSON non valido per #$expectedId $name.');
              continue;
            }
            final pokemonJson = Map<String, dynamic>.from(rawPokemon);
            final actualId = _readInt(pokemonJson['index']);
            if (actualId != expectedId) {
              errors.add(
                'Indice incoerente per $name: atteso $expectedId, trovato $actualId.',
              );
            }
          } catch (error) {
            errors.add('Impossibile leggere #$expectedId $name: $error');
          }
        }
      }

      expect(errors, isEmpty, reason: _errorReport(errors));
    });

    test('i cataloghi web hanno identificatori univoci e campi minimi', () async {
      final errors = <String>[];

      final rawPokemonCatalog = jsonDecode(
        await rootBundle.loadString('assets/data_webapp/pokemon.json'),
      );
      if (rawPokemonCatalog is! Map) {
        errors.add('assets/data_webapp/pokemon.json non contiene un oggetto.');
      } else {
        final items = Map<String, dynamic>.from(rawPokemonCatalog)['items'];
        _validateWebItems(
          label: 'Pokemon',
          items: items,
          errors: errors,
          requirePositiveNumber: true,
        );
      }

      final rawMoveCatalog = jsonDecode(
        await rootBundle.loadString('assets/data_webapp/moves.json'),
      );
      if (rawMoveCatalog is! Map) {
        errors.add('assets/data_webapp/moves.json non contiene un oggetto.');
      } else {
        final moves = Map<String, dynamic>.from(rawMoveCatalog)['moves'];
        _validateWebItems(label: 'Mossa', items: moves, errors: errors);
      }

      final rawAbilityCatalog = jsonDecode(
        await rootBundle.loadString('assets/data_webapp/abilities.json'),
      );
      if (rawAbilityCatalog is! Map) {
        errors.add('assets/data_webapp/abilities.json non contiene un oggetto.');
      } else {
        final abilities = Map<String, dynamic>.from(
          rawAbilityCatalog,
        )['items'];
        _validateWebItems(label: 'Abilita', items: abilities, errors: errors);
      }

      expect(errors, isEmpty, reason: _errorReport(errors));
    });
  });

  group('Catalogo unificato', () {
    test('contiene tutte le specie con ID positivi e univoci', () {
      expect(
        catalog.length,
        greaterThanOrEqualTo(1000),
        reason: 'Il catalogo unificato deve includere anche le generazioni recenti.',
      );

      final errors = <String>[];
      final ids = <int>{};
      final names = <String>{};

      for (final pokemon in catalog) {
        if (pokemon.id <= 0) {
          errors.add('ID non positivo per ${pokemon.name}: ${pokemon.id}.');
        }
        if (!ids.add(pokemon.id)) {
          errors.add('ID duplicato nel catalogo unificato: ${pokemon.id}.');
        }
        if (pokemon.name.trim().isEmpty) {
          errors.add('Nome vuoto per il Pokemon #${pokemon.id}.');
        }
        final normalizedName = pokemon.name.trim().toLowerCase();
        if (!names.add(normalizedName)) {
          errors.add('Nome specie duplicato: ${pokemon.name}.');
        }
      }

      expect(errors, isEmpty, reason: _errorReport(errors));
    });

    test('statistiche, mosse e forme rispettano i vincoli minimi', () {
      final errors = <String>[];

      for (final species in catalog) {
        _validatePokemon(species, '${species.name} base', errors);

        final formKeys = <String>{};
        for (final definition in species.formDefinitions) {
          final gender = Pokemon.normalizeGenderValue(definition.gender);
          final key = gender == null
              ? 'form:${Pokemon.formReferenceKey(definition.key, species.name)}'
              : 'gender:$gender';

          if (key == 'form:base') {
            errors.add(
              '${species.name}: una forma alternativa e normalizzata come base.',
            );
          }
          if (!formKeys.add(key)) {
            errors.add('${species.name}: forma duplicata $key.');
          }
          if (definition.displayName.trim().isEmpty) {
            errors.add('${species.name}: forma con etichetta vuota.');
          }
          if (definition.pokemon.id != species.id) {
            errors.add(
              '${species.name} ${definition.displayName}: ID ${definition.pokemon.id} diverso da ${species.id}.',
            );
          }

          _validatePokemon(
            definition.pokemon,
            '${species.name} ${definition.displayName}',
            errors,
          );
        }
      }

      expect(errors, isEmpty, reason: _errorReport(errors));
    });

    test('ogni specie ha almeno un immagine inclusa nel bundle', () {
      final missing = <String>[];

      for (final pokemon in catalog) {
        if (!_hasBundledImage(pokemon, bundledAssets)) {
          missing.add('#${pokemon.id} ${pokemon.name}');
        }
      }

      expect(
        missing,
        isEmpty,
        reason: 'Pokemon senza artwork o sprite:\n${_errorReport(missing)}',
      );
    });

    test('i cataloghi di mosse e abilita sono caricabili', () async {
      final moves = await MoveRepository().getAllWebMoves();
      final abilities = await AbilityRepository().getWebAbilities(
        includeDeprecated: true,
      );
      final errors = <String>[];

      if (moves.isEmpty) errors.add('Il catalogo mosse web e vuoto.');
      for (final move in moves) {
        if (move.id.trim().isEmpty) {
          errors.add('Mossa con ID vuoto: ${move.name}.');
        }
        if (move.name.trim().isEmpty) {
          errors.add('Mossa con nome vuoto: ${move.id}.');
        }
        if (move.type.trim().isEmpty) errors.add('${move.name}: tipo vuoto.');
        if (move.description.trim().isEmpty) {
          errors.add('${move.name}: descrizione vuota.');
        }
      }

      if (abilities.isEmpty) errors.add('Il catalogo abilita web e vuoto.');
      final abilityIds = <String>{};
      for (final ability in abilities) {
        if (!abilityIds.add(ability.id)) {
          errors.add('ID abilita duplicato: ${ability.id}.');
        }
        if (ability.id.trim().isEmpty) errors.add('Abilita con ID vuoto.');
        if (ability.name.trim().isEmpty) {
          errors.add('Abilita ${ability.id} con nome vuoto.');
        }
        if (ability.description.trim().isEmpty) {
          errors.add('${ability.name}: descrizione vuota.');
        }
      }

      expect(errors, isEmpty, reason: _errorReport(errors));
    });
  });
}

void _validateWebItems({
  required String label,
  required dynamic items,
  required List<String> errors,
  bool requirePositiveNumber = false,
}) {
  if (items is! List || items.isEmpty) {
    errors.add('Il catalogo $label non contiene elementi.');
    return;
  }

  final ids = <String>{};
  for (var index = 0; index < items.length; index++) {
    final value = items[index];
    if (value is! Map) {
      errors.add('$label alla posizione $index non e un oggetto.');
      continue;
    }

    final item = Map<String, dynamic>.from(value);
    final id = item['id']?.toString().trim() ?? '';
    final name = item['name']?.toString().trim() ?? '';
    if (id.isEmpty) errors.add('$label alla posizione $index con ID vuoto.');
    if (name.isEmpty) errors.add('$label $id con nome vuoto.');
    if (id.isNotEmpty && !ids.add(id)) {
      errors.add('ID $label duplicato: $id.');
    }

    if (requirePositiveNumber && _readInt(item['number']) <= 0) {
      errors.add('$label $id con numero non positivo: ${item['number']}.');
    }
  }
}

void _validatePokemon(Pokemon pokemon, String label, List<String> errors) {
  if (pokemon.name.trim().isEmpty) errors.add('$label: nome vuoto.');
  if (pokemon.types.isEmpty || pokemon.types.any((type) => type.trim().isEmpty)) {
    errors.add('$label: tipo mancante o vuoto.');
  }
  if (pokemon.armorClass <= 0) errors.add('$label: CA ${pokemon.armorClass}.');
  if (pokemon.hitPoints <= 0) errors.add('$label: PF ${pokemon.hitPoints}.');
  if (pokemon.speed <= 0) errors.add('$label: velocita ${pokemon.speed}.');
  if (pokemon.hitDice <= 0) errors.add('$label: dado vita d${pokemon.hitDice}.');
  if (pokemon.sr < 0) errors.add('$label: SR ${pokemon.sr}.');
  if (pokemon.minLevelFound < 0) {
    errors.add('$label: livello minimo ${pokemon.minLevelFound}.');
  }
  if (pokemon.abilities.isEmpty ||
      pokemon.abilities.any((ability) => ability.trim().isEmpty)) {
    errors.add('$label: abilita mancanti o vuote.');
  }

  final scores = <String, int>{
    'FOR': pokemon.attributes.strength,
    'DES': pokemon.attributes.dexterity,
    'COS': pokemon.attributes.constitution,
    'INT': pokemon.attributes.intelligence,
    'SAG': pokemon.attributes.wisdom,
    'CAR': pokemon.attributes.charisma,
  };
  for (final score in scores.entries) {
    if (score.value <= 0 || score.value > 40) {
      errors.add('$label: ${score.key} ${score.value}.');
    }
  }

  final moveReferences = <String>[
    ...pokemon.moves.startingMoves,
    for (final moves in pokemon.moves.levelMoves.values) ...moves,
  ];
  if (moveReferences.any((move) => move.trim().isEmpty)) {
    errors.add('$label: riferimento a una mossa vuoto.');
  }
  for (final level in pokemon.moves.levelMoves.keys) {
    if (level <= 0 || level > 20) {
      errors.add('$label: livello mossa non valido $level.');
    }
  }
  if (pokemon.moves.tmMoves.any((tm) => tm <= 0)) {
    errors.add('$label: numero TM non positivo.');
  }
}

bool _hasBundledImage(Pokemon pokemon, Set<String> assets) {
  for (final useLargeArtwork in const [true, false]) {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: pokemon,
      useLargeArtwork: useLargeArtwork,
    );
    if (candidates.any(assets.contains)) return true;

    final prefixes = PokemonAssetPaths.imageCandidatePrefixes(
      pokemon: pokemon,
      useLargeArtwork: useLargeArtwork,
    );
    if (assets.any(
      (asset) => prefixes.any((prefix) => asset.startsWith(prefix)),
    )) {
      return true;
    }
  }

  return false;
}

String _legacyFileName(String name) {
  return name
      .replaceAll(' ♀', '-f')
      .replaceAll(' ♂', '-m')
      .replaceAll(':', '')
      .replaceAll('é', 'e');
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _errorReport(List<String> errors) {
  const maxLines = 100;
  final visible = errors.take(maxLines).join('\n');
  if (errors.length <= maxLines) return visible;
  return '$visible\n... e altri ${errors.length - maxLines} errori.';
}
