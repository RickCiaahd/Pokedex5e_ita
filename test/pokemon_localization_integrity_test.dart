import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';

const _maxLocalizedPokemonId = 721;
const _categoryReferencePaths = [
  'docs/translation/pokemon-categories-it-001-649.json',
  'docs/translation/pokemon-categories-it-650-685.json',
  'docs/translation/pokemon-categories-it-686-721.json',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PokemonLocalizationRepository.clearCache();
    PokemonRepository.clearCache();
  });

  test('i file italiani coprono una sola volta tutti i Pokémon localizzati', () async {
    final ids = <int>{};
    final errors = <String>[];

    for (final path in PokemonLocalizationRepository.assetPaths) {
      final decoded = jsonDecode(await rootBundle.loadString(path));
      if (decoded is! Map) {
        errors.add('$path non contiene un oggetto JSON.');
        continue;
      }

      final document = Map<String, dynamic>.from(decoded);
      if (document['locale'] != 'it') {
        errors.add('$path non dichiara locale=it.');
      }
      if (document['source'] != 'assets/data/pokemon_flavor.json') {
        errors.add('$path usa una sorgente inattesa: ${document['source']}.');
      }

      final range = document['range'];
      final rawItems = document['items'];
      if (range is! Map || rawItems is! Map) {
        errors.add('$path non contiene range e items validi.');
        continue;
      }

      final rangeMap = Map<String, dynamic>.from(range);
      final from = _readInt(rangeMap['from']);
      final to = _readInt(rangeMap['to']);
      final expectedRange = {for (var id = from; id <= to; id++) id};
      final fileIds = <int>{};

      for (final entry in rawItems.entries) {
        final pokemonId = int.tryParse(entry.key.toString());
        if (pokemonId == null) {
          errors.add('$path contiene un ID non numerico: ${entry.key}.');
          continue;
        }
        if (!ids.add(pokemonId)) {
          errors.add('Traduzione duplicata per il Pokémon #$pokemonId.');
        }
        fileIds.add(pokemonId);

        if (entry.value is! Map) {
          errors.add('$path: traduzione #$pokemonId non valida.');
          continue;
        }
        final item = Map<String, dynamic>.from(entry.value as Map);
        final unexpectedKeys = item.keys.toSet().difference(const {
          'genus',
          'description',
        });
        if (unexpectedKeys.isNotEmpty) {
          errors.add(
            '$path: campi tecnici inattesi per #$pokemonId: $unexpectedKeys.',
          );
        }
        if ((item['genus']?.toString().trim() ?? '').isEmpty) {
          errors.add('$path: genere vuoto per #$pokemonId.');
        }
        if ((item['description']?.toString().trim() ?? '').isEmpty) {
          errors.add('$path: descrizione vuota per #$pokemonId.');
        }
      }

      if (fileIds.length != rawItems.length) {
        errors.add('$path contiene ID duplicati o non numerici.');
      }
      if (fileIds.difference(expectedRange).isNotEmpty ||
          expectedRange.difference(fileIds).isNotEmpty) {
        errors.add(
          '$path non corrisponde all intervallo dichiarato $from-$to.',
        );
      }
    }

    final expectedIds = {
      for (var id = 1; id <= _maxLocalizedPokemonId; id++) id,
    };
    if (ids.difference(expectedIds).isNotEmpty ||
        expectedIds.difference(ids).isNotEmpty) {
      errors.add(
        'Le traduzioni non coprono esattamente gli ID 1-$_maxLocalizedPokemonId.',
      );
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('il repository carica le 721 traduzioni italiane', () async {
    final texts = await PokemonLocalizationRepository().getPokemonTexts();

    expect(texts.length, _maxLocalizedPokemonId);
    expect(texts.keys.toSet(), {
      for (var id = 1; id <= _maxLocalizedPokemonId; id++) id,
    });
    expect(texts[1]?.genus, 'Pokémon Seme');
    expect(texts[1]?.description, startsWith('Bulbasaur'));
    expect(texts[151]?.genus, 'Pokémon Novaspecie');
    expect(texts[152]?.genus, 'Pokémon Foglia');
    expect(texts[152]?.description, startsWith('In lotta, Chikorita'));
    expect(texts[251]?.genus, 'Pokémon Tempovia');
    expect(texts[251]?.description, startsWith('Questo Pokémon'));
    expect(texts[252]?.genus, 'Pokémon Legnogeco');
    expect(texts[252]?.description, startsWith('Treecko'));
    expect(texts[386]?.genus, 'Pokémon DNA');
    expect(texts[386]?.description, startsWith('Il DNA'));
    expect(texts[387]?.genus, 'Pokémon Fogliolina');
    expect(texts[387]?.description, startsWith('Sotto la luce'));
    expect(texts[493]?.genus, 'Pokémon Primevo');
    expect(texts[493]?.description, startsWith('Secondo le leggende'));
    expect(texts[494]?.genus, 'Pokémon Vittoria');
    expect(texts[494]?.description, startsWith('Questo Pokémon porta'));
    expect(texts[500]?.genus, 'Pokémon Suincendio');
    expect(texts[649]?.genus, 'Pokémon Paleozoico');
    expect(texts[649]?.description, startsWith('Questo antico Pokémon'));
    expect(texts[650]?.genus, 'Pokémon Castanriccio');
    expect(texts[650]?.description, startsWith('Gli aculei'));
    expect(texts[720]?.genus, 'Pokémon Birba');
    expect(texts[721]?.genus, 'Pokémon Vapore');
    expect(texts[721]?.description, startsWith('Volcanion'));
  });

  test('le categorie coincidono con il riferimento italiano ufficiale', () async {
    final references = <int, String>{};
    final errors = <String>[];

    for (final path in _categoryReferencePaths) {
      final decoded = jsonDecode(await File(path).readAsString());
      if (decoded is! Map) {
        errors.add('$path non contiene un oggetto JSON.');
        continue;
      }

      final document = Map<String, dynamic>.from(decoded);
      if (document['source'] != 'https://wiki.pokemoncentral.it/Categoria') {
        errors.add('$path usa una fonte inattesa: ${document['source']}.');
      }

      final rawRange = document['range'];
      final rawItems = document['items'];
      if (rawRange is! Map || rawItems is! Map) {
        errors.add('$path non contiene range e items validi.');
        continue;
      }

      final range = Map<String, dynamic>.from(rawRange);
      final from = _readInt(range['from']);
      final to = _readInt(range['to']);
      final expectedRange = {for (var id = from; id <= to; id++) id};
      final fileIds = <int>{};

      for (final entry in rawItems.entries) {
        final pokemonId = int.tryParse(entry.key.toString());
        if (pokemonId == null) {
          errors.add('$path contiene un ID non numerico: ${entry.key}.');
          continue;
        }
        fileIds.add(pokemonId);

        if (entry.value is! Map) {
          errors.add('$path: riferimento non valido per #$pokemonId.');
          continue;
        }
        final reference = Map<String, dynamic>.from(entry.value as Map);
        final genus = reference['genus']?.toString().trim() ?? '';
        if (genus.isEmpty) {
          errors.add('$path: categoria mancante per #$pokemonId.');
        }
        if (references.containsKey(pokemonId)) {
          errors.add('Categoria duplicata nel riferimento per #$pokemonId.');
        } else {
          references[pokemonId] = genus;
        }
      }

      if (fileIds.difference(expectedRange).isNotEmpty ||
          expectedRange.difference(fileIds).isNotEmpty) {
        errors.add(
          '$path non corrisponde all intervallo dichiarato $from-$to.',
        );
      }
    }

    final expectedIds = {
      for (var id = 1; id <= _maxLocalizedPokemonId; id++) id,
    };
    if (references.keys.toSet().difference(expectedIds).isNotEmpty ||
        expectedIds.difference(references.keys.toSet()).isNotEmpty) {
      errors.add(
        'I riferimenti delle categorie non coprono esattamente gli ID '
        '1-$_maxLocalizedPokemonId.',
      );
    }

    final texts = await PokemonLocalizationRepository().getPokemonTexts();
    for (var pokemonId = 1;
        pokemonId <= _maxLocalizedPokemonId;
        pokemonId++) {
      final expectedGenus = references[pokemonId] ?? '';
      final actualGenus = texts[pokemonId]?.genus ?? '';
      if (actualGenus != expectedGenus) {
        errors.add(
          '#$pokemonId: categoria "$actualGenus", attesa "$expectedGenus".',
        );
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('le descrizioni localizzate preservano altezza e peso originali', () async {
    final raw = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString('assets/data/pokemon_flavor.json'),
      ),
    );
    final flavors = await PokemonRepository().getPokemonFlavors();

    expect(flavors.length, raw.length);
    for (var pokemonId = 1;
        pokemonId <= _maxLocalizedPokemonId;
        pokemonId++) {
      final source = Map<String, dynamic>.from(raw['$pokemonId'] as Map);
      final localized = flavors[pokemonId];
      expect(localized, isNotNull, reason: 'Pokémon #$pokemonId mancante.');
      expect(localized!.height, _readInt(source['height']));
      expect(localized.weight, _readInt(source['weight']));
      expect(localized.genus, startsWith('Pokémon '));
      expect(localized.flavor.trim(), isNotEmpty);
    }

    expect(flavors[1]?.genus, 'Pokémon Seme');
    expect(flavors[151]?.genus, 'Pokémon Novaspecie');
    expect(flavors[152]?.genus, 'Pokémon Foglia');
    expect(flavors[251]?.genus, 'Pokémon Tempovia');
    expect(flavors[252]?.genus, 'Pokémon Legnogeco');
    expect(flavors[386]?.genus, 'Pokémon DNA');
    expect(flavors[387]?.genus, 'Pokémon Fogliolina');
    expect(flavors[493]?.genus, 'Pokémon Primevo');
    expect(flavors[494]?.genus, 'Pokémon Vittoria');
    expect(flavors[500]?.genus, 'Pokémon Suincendio');
    expect(flavors[649]?.genus, 'Pokémon Paleozoico');
    expect(flavors[650]?.genus, 'Pokémon Castanriccio');
    expect(flavors[720]?.genus, 'Pokémon Birba');
    expect(flavors[721]?.genus, 'Pokémon Vapore');
  });
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
