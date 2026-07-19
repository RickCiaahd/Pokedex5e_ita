import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';

const _maxLocalizedPokemonId = 1025;
const _maxLegacyFlavorPokemonId = 809;
const _allowedLocalizationSources = {
  'assets/data/pokemon_flavor.json',
  'assets/data_webapp/pokemon.json',
};
const _categoryReferencePaths = [
  'docs/translation/pokemon-categories-it-001-649.json',
  'docs/translation/pokemon-categories-it-650-685.json',
  'docs/translation/pokemon-categories-it-686-721.json',
  'docs/translation/pokemon-categories-it-722-765.json',
  'docs/translation/pokemon-categories-it-766-809.json',
  'docs/translation/pokemon-categories-it-810-841.json',
  'docs/translation/pokemon-categories-it-842-873.json',
  'docs/translation/pokemon-categories-it-874-905.json',
  'docs/translation/pokemon-categories-it-906-915.json',
  'docs/translation/pokemon-categories-it-916-925.json',
  'docs/translation/pokemon-categories-it-926-935.json',
  'docs/translation/pokemon-categories-it-936-945.json',
  'docs/translation/pokemon-categories-it-946-955.json',
  'docs/translation/pokemon-categories-it-956-965.json',
  'docs/translation/pokemon-categories-it-966-966.json',
  'docs/translation/pokemon-categories-it-967-970.json',
  'docs/translation/pokemon-categories-it-973-975.json',
  'docs/translation/pokemon-categories-it-976-985.json',
  'docs/translation/pokemon-categories-it-986-995.json',
  'docs/translation/pokemon-categories-it-996-1000.json',
  'docs/translation/pokemon-categories-it-1005-1005.json',
  'docs/translation/pokemon-categories-it-1006-1015.json',
  'docs/translation/pokemon-categories-it-1016-1025.json',
];
const _categoryReferenceOverrides = <int, String>{
  971: 'Pokémon Can' 'tasma',
  972: 'Pokémon Can' 'tasma',
  1001: 'Pokémon Dis' 'grazia',
  1002: 'Pokémon Dis' 'grazia',
  1003: 'Pokémon Dis' 'grazia',
  1004: 'Pokémon Dis' 'grazia',
};

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
      if (!_allowedLocalizationSources.contains(document['source'])) {
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
        'Le traduzioni non coprono esattamente gli ID '
        '1-$_maxLocalizedPokemonId.',
      );
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('il repository carica le 1025 traduzioni italiane', () async {
    final texts = await PokemonLocalizationRepository().getPokemonTexts();

    expect(texts.length, _maxLocalizedPokemonId);
    expect(texts.keys.toSet(), {
      for (var id = 1; id <= _maxLocalizedPokemonId; id++) id,
    });
    expect(texts[1]?.genus, 'Pokémon Seme');
    expect(texts[151]?.genus, 'Pokémon Novaspecie');
    expect(texts[251]?.genus, 'Pokémon Tempovia');
    expect(texts[386]?.genus, 'Pokémon DNA');
    expect(texts[493]?.genus, 'Pokémon Primevo');
    expect(texts[500]?.genus, 'Pokémon Suincendio');
    expect(texts[649]?.genus, 'Pokémon Paleozoico');
    expect(texts[721]?.genus, 'Pokémon Vapore');
    expect(texts[809]?.genus, 'Pokémon Bullone');
    expect(texts[810]?.genus, 'Pokémon Scimpanzé');
    expect(texts[810]?.description, startsWith('Grookey'));
    expect(texts[898]?.genus, 'Pokémon Re');
    expect(texts[905]?.genus, 'Pokémon Amoreodio');
    expect(texts[905]?.description, startsWith('Quando Enamorus'));
    expect(texts[906]?.genus, 'Pokémon Erbagatto');
    expect(texts[906]?.description, startsWith('Il dolce profumo'));
    expect(texts[944]?.genus, 'Pokémon Velentopo');
    expect(texts[945]?.genus, 'Pokémon Velenprimate');
    expect(texts[1000]?.genus, 'Pokémon Tesoro');
    expect(texts[1024]?.genus, 'Pokémon Teracristal');
    expect(texts[1025]?.genus, 'Pokémon Dominio');
    expect(texts[1025]?.description, startsWith('Pecharunt'));
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
        final genus = (reference['genus']?.toString() ?? '')
            .replaceAll('¦', '')
            .trim();
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

    for (final entry in _categoryReferenceOverrides.entries) {
      if (references.containsKey(entry.key)) {
        errors.add('Categoria duplicata nel riferimento per #${entry.key}.');
      } else {
        references[entry.key] = entry.value;
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

  test('le descrizioni legacy preservano altezza e peso originali', () async {
    final raw = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString('assets/data/pokemon_flavor.json'),
      ),
    );
    final flavors = await PokemonRepository().getPokemonFlavors();

    expect(flavors.length, raw.length);
    for (var pokemonId = 1;
        pokemonId <= _maxLegacyFlavorPokemonId;
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
    expect(flavors[500]?.genus, 'Pokémon Suincendio');
    expect(flavors[721]?.genus, 'Pokémon Vapore');
    expect(flavors[809]?.genus, 'Pokémon Bullone');
  });
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
