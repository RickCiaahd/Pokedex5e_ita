import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/move_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';

import 'fixtures/move_names_it_001_050.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(MoveLocalizationRepository.clearCache);

  test('i cataloghi italiani coprono le prime 50 mosse in ordine', () async {
    final sourceMoves = await _sourceMoves();
    final sourceById = {
      for (final move in sourceMoves) move['id'].toString(): move,
    };
    final localizedMoves = <String, Map<String, dynamic>>{};
    var declaredCount = 0;

    for (final path in MoveLocalizationRepository.assetPaths) {
      final document = await _loadDocument(path);
      final items = Map<String, dynamic>.from(document['items'] as Map);
      final range = Map<String, dynamic>.from(document['range'] as Map);
      final start = range['start'] as int;
      final end = range['end'] as int;
      final expectedIds = sourceMoves
          .sublist(start - 1, end)
          .map((move) => move['id'].toString())
          .toList(growable: false);

      expect(document['locale'], 'it', reason: path);
      expect(document['source'], MoveLocalizationRepository.sourceAssetPath);
      expect(document['type'], 'move', reason: path);
      expect(document['localizedCount'], items.length, reason: path);
      expect(items.keys.toList(), expectedIds, reason: path);
      declaredCount += document['localizedCount'] as int;

      for (final entry in items.entries) {
        expect(localizedMoves, isNot(contains(entry.key)), reason: path);
        localizedMoves[entry.key] = Map<String, dynamic>.from(
          entry.value as Map,
        );
      }
    }

    expect(sourceMoves.length, MoveLocalizationRepository.catalogCount);
    expect(declaredCount, MoveLocalizationRepository.localizedCount);
    expect(localizedMoves.length, MoveLocalizationRepository.localizedCount);
    expect(localizedMoves.keys.toList(), moveNames1To50.keys.toList());

    final errors = <String>[];
    for (final entry in localizedMoves.entries) {
      final source = sourceById[entry.key];
      if (source == null) {
        errors.add('${entry.key}: localizzazione priva di sorgente.');
        continue;
      }

      final localized = entry.value;
      if (localized['sourceName']?.toString() != source['name']?.toString()) {
        errors.add('${entry.key}: nome tecnico modificato.');
      }
      if ((localized['name']?.toString().trim() ?? '').isEmpty) {
        errors.add('${entry.key}: nome visualizzato vuoto.');
      }

      final sourceDescription = _descriptionBlocks(source['description']);
      final localizedDescription = _descriptionBlocks(
        localized['description'],
      );
      if (sourceDescription.length != localizedDescription.length) {
        errors.add('${entry.key}: numero di blocchi descrittivi modificato.');
      }

      final sourceHigherLevels = source['higherLevels']?.toString();
      final localizedHigherLevels = localized['higherLevels']?.toString();
      if ((sourceHigherLevels == null) != (localizedHigherLevels == null)) {
        errors.add('${entry.key}: presenza di higherLevels modificata.');
      }

      final sourceText = [
        _flattenText(sourceDescription),
        sourceHigherLevels ?? '',
      ].join(' ');
      final localizedText = [
        _flattenText(localizedDescription),
        localizedHigherLevels ?? '',
      ].join(' ');
      if (!_sameCounts(
        _mechanicalTokenCounts(sourceText),
        _mechanicalTokenCounts(localizedText),
      )) {
        errors.add('${entry.key}: valori meccanici modificati.');
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('le prime 50 mosse usano i nomi italiani verificati', () async {
    final names = <String, String>{};

    for (final path in MoveLocalizationRepository.assetPaths) {
      final document = await _loadDocument(path);
      final items = Map<String, dynamic>.from(document['items'] as Map);
      names.addAll({
        for (final entry in items.entries)
          entry.key: Map<String, dynamic>.from(
            entry.value as Map,
          )['name'].toString(),
      });
    }

    expect(names, moveNames1To50);
    expect(names['absorb'], 'Assorbimento');
    expect(names['aerial-ace'], 'Aeroassalto');
    expect(names['aura-wheel'], 'Ruota d’Aura');
    expect(names['behemoth-bash'], 'Colpo Maestoso');
  });

  test('il repository mostra l’italiano e conserva i riferimenti inglesi', () async {
    final repository = MoveRepository();
    final absorbById = await repository.getMove('absorb');
    final absorbByEnglishName = await repository.getMove('Absorb');
    final absorbByItalianName = await repository.getMove('Assorbimento');
    final acupressure = await repository.getMove('Acupressure');
    final unlocalized = await repository.getMove('chatter');

    expect(absorbById, isNotNull);
    expect(absorbById?.name, 'Assorbimento');
    expect(absorbById?.technicalName, 'Absorb');
    expect(absorbByEnglishName?.id, 'absorb');
    expect(absorbByItalianName?.id, 'absorb');
    expect(absorbById?.description, contains('1d4 + MOVE'));
    expect(absorbById?.description, contains('Livelli superiori:'));

    expect(acupressure?.name, 'Acupressione');
    expect(acupressure?.technicalName, 'Acupressure');
    expect(acupressure?.description, contains('d6 | Effetto'));
    expect(acupressure?.description, contains('+10 PF temporanei'));

    expect(unlocalized?.name, 'Chatter');
    expect(unlocalized?.technicalName, 'Chatter');
  });
}

Future<Map<String, dynamic>> _loadDocument(String path) async {
  return Map<String, dynamic>.from(
    jsonDecode(await rootBundle.loadString(path)),
  );
}

Future<List<Map<String, dynamic>>> _sourceMoves() async {
  final document = Map<String, dynamic>.from(
    jsonDecode(
      await rootBundle.loadString(MoveLocalizationRepository.sourceAssetPath),
    ),
  );
  return List<dynamic>.from(document['moves'] ?? const [])
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList(growable: false);
}

List<dynamic> _descriptionBlocks(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  if (value is String && value.trim().isNotEmpty) return [value];
  return const [];
}

String _flattenText(dynamic value) {
  if (value is Iterable) {
    return value.map(_flattenText).join(' ');
  }
  if (value is Map) {
    return value.values.map(_flattenText).join(' ');
  }
  return value?.toString() ?? '';
}

Map<String, int> _mechanicalTokenCounts(String value) {
  final expression = RegExp(
    r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+(?:ft|\s*(?:feet|foot|piedi|piede))?\b|\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\b',
  );
  final result = <String, int>{};
  for (final match in expression.allMatches(value)) {
    final token = _canonicalToken(match.group(0)!);
    result[token] = (result[token] ?? 0) + 1;
  }
  return result;
}

String _canonicalToken(String value) {
  var token = value.toUpperCase().replaceAll(' ', '');
  token = token.replaceAll(RegExp(r'(FT|FEET|FOOT|PIEDI|PIEDE)$'), '');
  const aliases = <String, String>{
    'PF': 'HP',
    'FOR': 'STR',
    'DES': 'DEX',
    'COS': 'CON',
    'SAG': 'WIS',
    'CAR': 'CHA',
    'CA': 'AC',
    'CD': 'DC',
  };
  return aliases[token] ?? token;
}

bool _sameCounts(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
