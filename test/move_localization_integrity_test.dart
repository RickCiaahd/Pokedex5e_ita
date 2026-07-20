import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/move_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';

import 'fixtures/move_names_it_001_050.dart';
import 'fixtures/move_names_it_051_250.dart';
import 'fixtures/move_names_it_251_450.dart';
import 'fixtures/move_names_it_451_650.dart';
import 'fixtures/move_names_it_651_830.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(MoveLocalizationRepository.clearCache);

  test('i cataloghi italiani coprono tutte le 830 mosse in ordine', () async {
    final sourceMoves = await _sourceMoves();
    final sourceById = {
      for (final move in sourceMoves) move['id'].toString(): move,
    };
    final localizedMoves = <String, Map<String, dynamic>>{};
    final expectedNames = <String, String>{
      ...moveNames1To50,
      ...moveNames51To250,
      ...moveNames251To450,
      ...moveNames451To650,
      ...moveNames651To830,
    };
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
    expect(localizedMoves.keys.toList(), expectedNames.keys.toList());

    final errors = <String>[];
    var localizedPosition = 0;
    for (final entry in localizedMoves.entries) {
      localizedPosition += 1;
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
      final sourceTokens = _mechanicalTokenCounts(
        sourceText,
        includeHealthPhrases: localizedPosition > 450,
      );
      final localizedTokens = _mechanicalTokenCounts(
        localizedText,
        includeHealthPhrases: localizedPosition > 450,
      );
      if (!_sameCounts(sourceTokens, localizedTokens)) {
        errors.add(
          '${entry.key}: valori meccanici modificati. '
          'sorgente=$sourceTokens localizzato=$localizedTokens',
        );
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('tutte le 830 mosse usano i nomi italiani verificati', () async {
    final names = <String, String>{};
    final expectedNames = <String, String>{
      ...moveNames1To50,
      ...moveNames51To250,
      ...moveNames251To450,
      ...moveNames451To650,
      ...moveNames651To830,
    };

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

    expect(names, expectedNames);
    expect(names['absorb'], 'Assorbimento');
    expect(names['aerial-ace'], 'Aeroassalto');
    expect(names['aura-wheel'], 'Ruota d’Aura');
    expect(names['behemoth-bash'], 'Colpo Maestoso');
    expect(names['behemoth-blade'], 'Taglio Maestoso');
    expect(names['blood-moon'], 'Luna Rossa');
    expect(names['draco-power'], 'Draco Power');
    expect(names['flash'], 'Flash');
    expect(names['halo-song'], 'Halo Song');
    expect(names['ivy-cudgel'], 'Clava di Liane');
    expect(names['matcha-gotcha'], 'Spruzzatè');
    expect(names['mist'], 'Nebbia');
    expect(names['mist-ball'], 'Foschisfera');
    expect(names['natures-madness'], 'Ira della Natura');
    expect(names['raging-bull'], 'Scatenatoro');
    expect(names['sludge-bomb'], 'Fangobomba');
    expect(names['syrup-bomb'], 'Bomba Sciroppata');
    expect(names['thunderbolt'], 'Fulmine');
    expect(names['water-spout'], 'Zampillo');
    expect(names['zing-zap'], 'Elettropizzico');
  });

  test('il repository mostra l’italiano e conserva i riferimenti inglesi', () async {
    final repository = MoveRepository();
    final absorbById = await repository.getMove('absorb');
    final absorbByEnglishName = await repository.getMove('Absorb');
    final absorbByItalianName = await repository.getMove('Assorbimento');
    final bloodMoonByEnglishName = await repository.getMove('Blood Moon');
    final bloodMoonByItalianName = await repository.getMove('Luna Rossa');
    final ivyCudgelByEnglishName = await repository.getMove('Ivy Cudgel');
    final ivyCudgelByItalianName = await repository.getMove('Clava di Liane');
    final matchaByItalianName = await repository.getMove('Spruzzatè');
    final acupressure = await repository.getMove('Acupressure');
    final mistBallByItalianName = await repository.getMove('Foschisfera');
    final sludgeBombByEnglishName = await repository.getMove('Sludge Bomb');
    final syrupBombByItalianName = await repository.getMove('Bomba Sciroppata');
    final zingZapByEnglishName = await repository.getMove('Zing Zap');

    expect(absorbById, isNotNull);
    expect(absorbById?.name, 'Assorbimento');
    expect(absorbById?.technicalName, 'Absorb');
    expect(absorbByEnglishName?.id, 'absorb');
    expect(absorbByItalianName?.id, 'absorb');
    expect(absorbById?.description, contains('1d4 + MOVE'));
    expect(absorbById?.description, contains('Livelli superiori:'));

    expect(bloodMoonByEnglishName?.id, 'blood-moon');
    expect(bloodMoonByItalianName?.id, 'blood-moon');
    expect(bloodMoonByItalianName?.name, 'Luna Rossa');
    expect(bloodMoonByItalianName?.technicalName, 'Blood Moon');

    expect(ivyCudgelByEnglishName?.id, 'ivy-cudgel');
    expect(ivyCudgelByItalianName?.id, 'ivy-cudgel');
    expect(ivyCudgelByItalianName?.technicalName, 'Ivy Cudgel');
    expect(matchaByItalianName?.id, 'matcha-gotcha');
    expect(matchaByItalianName?.technicalName, 'Matcha Gotcha');

    expect(mistBallByItalianName?.id, 'mist-ball');
    expect(mistBallByItalianName?.technicalName, 'Mist Ball');
    expect(sludgeBombByEnglishName?.name, 'Fangobomba');
    expect(sludgeBombByEnglishName?.technicalName, 'Sludge Bomb');

    expect(acupressure?.name, 'Acupressione');
    expect(acupressure?.technicalName, 'Acupressure');
    expect(acupressure?.description, contains('d6 | Effetto'));
    expect(acupressure?.description, contains('+10 PF temporanei'));

    expect(syrupBombByItalianName?.id, 'syrup-bomb');
    expect(syrupBombByItalianName?.technicalName, 'Syrup Bomb');
    expect(zingZapByEnglishName?.name, 'Elettropizzico');
    expect(zingZapByEnglishName?.technicalName, 'Zing Zap');
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

Map<String, int> _mechanicalTokenCounts(
  String value, {
  bool includeHealthPhrases = false,
}) {
  var normalizedValue = value;
  for (final pattern in <RegExp>[
    RegExp(r'\bCD della mossa\b', caseSensitive: false),
    RegExp(r'\bMovimento CD\b', caseSensitive: false),
    RegExp(r'\bMove DC\b', caseSensitive: false),
  ]) {
    normalizedValue = normalizedValue.replaceAll(pattern, 'MOVE DC');
  }
  for (final pattern in <RegExp>[
    RegExp(r'\bvalore CD per questa mossa\b', caseSensitive: false),
    RegExp(r'\bCD di questa mossa\b', caseSensitive: false),
    RegExp(r'\bCD per questa mossa\b', caseSensitive: false),
  ]) {
    normalizedValue = normalizedValue.replaceAll(pattern, 'DC');
  }

  final expression = RegExp(
    includeHealthPhrases
        ? r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+[sx]\b|\b\d+(?:ft|\s*(?:feet|foot|piedi|piede))?\b|\b(?:hitpoints?|hit points?|Hit Points?|punti ferita|Punti ferita)\b|\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\b|\b(?:flinch|flinches|flinched)\b'
        : r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+(?:ft|\s*(?:feet|foot|piedi|piede))?\b|\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED|flinch(?:es|ed)?)\b',
  );
  final result = <String, int>{};
  for (final match in expression.allMatches(normalizedValue)) {
    final token = _canonicalToken(match.group(0)!);
    result[token] = (result[token] ?? 0) + 1;
  }
  return result;
}

String _canonicalToken(String value) {
  var token = value.toUpperCase().replaceAll(' ', '');
  token = token.replaceAll(RegExp(r'(FT|FEET|FOOT|PIEDI|PIEDE)$'), '');
  if (RegExp(r'^\d+[SX]$').hasMatch(token)) {
    token = token.substring(0, token.length - 1);
  }
  if (token == 'HITPOINT' ||
      token == 'HITPOINTS' ||
      token == 'PUNTIFERITA') {
    return 'HP';
  }
  const aliases = <String, String>{
    'PF': 'HP',
    'FOR': 'STR',
    'DES': 'DEX',
    'COS': 'CON',
    'SAG': 'WIS',
    'CAR': 'CHA',
    'CA': 'AC',
    'CD': 'DC',
    'FLINCH': 'FLINCHED',
    'FLINCHES': 'FLINCHED',
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
