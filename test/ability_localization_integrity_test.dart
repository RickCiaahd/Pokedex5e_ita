import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/ability_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AbilityLocalizationRepository.clearCache);

  test('le traduzioni coprono una sola volta tutte le abilità sorgente', () async {
    final source = await _loadSourceItems();
    final sourceIds = source.map((item) => item['id'].toString()).toList();
    final localizedIds = <String>{};
    final errors = <String>[];
    var expectedStartIndex = 1;

    for (final path in AbilityLocalizationRepository.assetPaths) {
      final decoded = jsonDecode(await rootBundle.loadString(path));
      if (decoded is! Map) {
        errors.add('$path non contiene un oggetto JSON.');
        continue;
      }

      final document = Map<String, dynamic>.from(decoded);
      if (document['locale'] != 'it') {
        errors.add('$path non dichiara locale=it.');
      }
      if (document['source'] != 'assets/data_webapp/abilities.json') {
        errors.add('$path usa una sorgente inattesa: ${document['source']}.');
      }

      final rawRange = document['range'];
      final rawItems = document['items'];
      if (rawRange is! Map || rawItems is! Map) {
        errors.add('$path non contiene range e items validi.');
        continue;
      }

      final range = Map<String, dynamic>.from(rawRange);
      final fromIndex = _readInt(range['fromIndex']);
      final toIndex = _readInt(range['toIndex']);
      if (fromIndex != expectedStartIndex || toIndex < fromIndex) {
        errors.add('$path dichiara un intervallo non consecutivo.');
      }
      expectedStartIndex = toIndex + 1;

      final expectedIds = sourceIds.sublist(fromIndex - 1, toIndex).toSet();
      final fileIds = <String>{};
      for (final entry in rawItems.entries) {
        final abilityId = entry.key.toString().trim();
        if (abilityId.isEmpty) {
          errors.add('$path contiene un ID vuoto.');
          continue;
        }
        if (!localizedIds.add(abilityId)) {
          errors.add('Traduzione duplicata per l’abilità $abilityId.');
        }
        fileIds.add(abilityId);

        if (entry.value is! Map) {
          errors.add('$path: traduzione non valida per $abilityId.');
          continue;
        }
        final item = Map<String, dynamic>.from(entry.value as Map);
        final unexpectedKeys = item.keys.toSet().difference(const {
          'description',
        });
        if (unexpectedKeys.isNotEmpty) {
          errors.add('$path: campi inattesi per $abilityId: $unexpectedKeys.');
        }
        if ((item['description']?.toString().trim() ?? '').isEmpty) {
          errors.add('$path: descrizione vuota per $abilityId.');
        }
      }

      if (fileIds.difference(expectedIds).isNotEmpty ||
          expectedIds.difference(fileIds).isNotEmpty) {
        errors.add(
          '$path non corrisponde agli indici dichiarati '
          '$fromIndex-$toIndex.',
        );
      }
    }

    expect(expectedStartIndex, source.length + 1);
    expect(localizedIds, sourceIds.toSet());
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('numeri, dadi e percentuali restano invariati', () async {
    final source = await _loadSourceItems();
    final localized = await AbilityLocalizationRepository().getDescriptions();
    final errors = <String>[];

    for (final item in source) {
      final abilityId = item['id'].toString();
      final sourceDescription = item['description']?.toString() ?? '';
      final localizedDescription = localized[abilityId] ?? '';
      final sourceTokens = _mechanicalTokens(sourceDescription)..sort();
      final localizedTokens = _mechanicalTokens(localizedDescription)..sort();
      if (!_sameList(sourceTokens, localizedTokens)) {
        errors.add(
          '$abilityId: token sorgente $sourceTokens, '
          'token tradotti $localizedTokens.',
        );
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('il repository applica 330 descrizioni senza cambiare i metadati', () async {
    final source = await _loadSourceItems();
    final localizedDescriptions =
        await AbilityLocalizationRepository().getDescriptions();
    final abilities = await AbilityRepository().getWebAbilities(
      includeDeprecated: true,
    );
    final abilitiesById = {for (final ability in abilities) ability.id: ability};

    expect(localizedDescriptions.length, 330);
    expect(abilitiesById.length, source.length);

    for (final item in source) {
      final abilityId = item['id'].toString();
      final ability = abilitiesById[abilityId];
      expect(ability, isNotNull, reason: 'Abilità $abilityId mancante.');
      expect(ability!.name, item['name']?.toString() ?? '');
      expect(ability.deprecated, item['deprecated'] == true);
      expect(ability.description, localizedDescriptions[abilityId]);
    }

    expect(
      abilitiesById['adaptability']?.description,
      startsWith('Quando questo Pokémon usa una mossa'),
    );
    expect(
      abilitiesById['commander']?.description,
      contains('Dondozo'),
    );
    expect(
      abilitiesById['zero-to-hero']?.description,
      contains('Hero Form'),
    );
  });
}

Future<List<Map<String, dynamic>>> _loadSourceItems() async {
  final decoded = jsonDecode(
    await rootBundle.loadString('assets/data_webapp/abilities.json'),
  );
  final document = Map<String, dynamic>.from(decoded as Map);
  return List<dynamic>.from(document['items'] ?? const [])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);
}

List<String> _mechanicalTokens(String value) {
  final expression = RegExp(
    r'\b\d+d\d+\b|[-+]?\d+(?:\.\d+)?%?',
    caseSensitive: false,
  );
  return expression.allMatches(value).map((match) => match.group(0)!).toList();
}

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
