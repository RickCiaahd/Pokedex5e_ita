import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/bag_item.dart';
import 'package:pokedex_5e_ita/repositories/item_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';

const _expectedNames = <String, String>{
  'poke-ball': 'Poké Ball',
  'great-ball': 'Mega Ball',
  'ultra-ball': 'Ultra Ball',
  'master-ball': 'Master Ball',
  'safari-ball': 'Safari Ball',
  'fast-ball': 'Rapid Ball',
  'level-ball': 'Level Ball',
  'lure-ball': 'Esca Ball',
  'heavy-ball': 'Peso Ball',
  'love-ball': 'Love Ball',
  'friend-ball': 'Friend Ball',
  'moon-ball': 'Luna Ball',
  'sport-ball': 'Gara Ball',
  'net-ball': 'Rete Ball',
  'dive-ball': 'Sub Ball',
  'nest-ball': 'Minor Ball',
  'repeat-ball': 'Bis Ball',
  'timer-ball': 'Timer Ball',
  'luxury-ball': 'Chic Ball',
  'premier-ball': 'Premier Ball',
  'dusk-ball': 'Scuro Ball',
  'heal-ball': 'Cura Ball',
  'quick-ball': 'Velox Ball',
  'dream-ball': 'Dream Ball',
  'potion': 'Pozione',
  'super-potion': 'Superpozione',
  'hyper-potion': 'Iperpozione',
  'antidote': 'Antidoto',
  'burn-heal': 'Antiscottatura',
  'ice-heal': 'Antigelo',
  'awakening': 'Sveglia',
  'paralyze-heal': 'Antiparalisi',
  'max-potion': 'Pozione Max',
  'full-heal': 'Cura Totale',
  'full-restore': 'Ricarica Totale',
  'revive': 'Revitalizzante',
  'max-revive': 'Revitalizzante Max',
  'fresh-water': 'Acqua Fresca',
  'soda-pop': 'Gassosa',
  'berry-juice': 'Succo di Bacca',
  'lemonade': 'Lemonsucco',
  'moomoo-milk': 'Latte Mumu',
  'energy-powder': 'Polvenergia',
  'energy-root': 'Radicenergia',
  'heal-powder': 'Polvocura',
  'revival-herb': 'Vitalerba',
  'ether': 'Etere',
  'max-ether': 'Etere Max',
  'elixir': 'Elisir',
  'max-elixir': 'Elisir Max',
  'sacred-ash': 'Ceneremagica',
  'hp-up': 'PS-Su',
  'protein': 'Proteina',
  'iron': 'Ferro',
  'carbos': 'Carburante',
  'calcium': 'Calcio',
  'zinc': 'Zinco',
  'pp-up': 'PP-Su',
  'ability-capsule': 'Capsula Abilità',
  'guard-spec': 'Superguardia',
  'dire-hit': 'Supercolpo',
  'x-attack': 'Attacco X',
  'x-defense': 'Difesa X',
  'x-speed': 'Velocità X',
  'x-accuracy': 'Precisione X',
  'x-sp-atk': 'Att. Speciale X',
  'x-sp-def': 'Dif. Sp. X',
  'red-nectar': 'Nettare Rosso',
  'yellow-nectar': 'Nettare Giallo',
  'pink-nectar': 'Nettare Rosa',
  'purple-nectar': 'Nettare Viola',
  'pewter-crunchies': 'Plumbeosalatini',
  'health-candy': 'Caramella vitalità S',
  'mighty-candy': 'Caramella potenza S',
  'tough-candy': 'Caramella protezione S',
  'smart-candy': 'Caramella acume S',
  'courage-candy': 'Caramella intuito S',
  'quick-candy': 'Caramella rapidità S',
  'health-wing': 'Piumsalute',
  'muscle-wing': 'Piumpotenza',
  'resist-wing': 'Piumtutela',
  'genius-wing': 'Piumingegno',
  'clever-wing': 'Piumintuito',
  'swift-wing': 'Piumreazione',
  'max-honey': 'Mielemax',
  'max-mushrooms': 'Fungomax',
  'ability-patch': 'Cerotto abilità',
  'cheri-berry': 'Baccaliegia',
  'chesto-berry': 'Baccastagna',
  'pecha-berry': 'Baccapesca',
  'rawst-berry': 'Baccafrago',
  'aspear-berry': 'Baccaperina',
  'leppa-berry': 'Baccamela',
  'oran-berry': 'Baccarancia',
  'persim-berry': 'Baccaki',
  'lum-berry': 'Baccaprugna',
  'sitrus-berry': 'Baccacedro',
  'occa-berry': 'Baccacao',
  'passho-berry': 'Baccapasflo',
  'wacan-berry': 'Baccaparmen',
  'rindo-berry': 'Baccarindo',
  'yache-berry': 'Baccamoya',
  'chople-berry': 'Baccarosmel',
  'kebia-berry': 'Baccakebia',
  'shuca-berry': 'Baccanaca',
  'coba-berry': 'Baccababa',
  'payapa-berry': 'Baccapayapa',
  'tanga-berry': 'Baccaitan',
  'charti-berry': 'Baccaciofo',
  'kasib-berry': 'Baccacitrus',
  'haban-berry': 'Baccahaban',
  'colbur-berry': 'Baccaxan',
  'babiri-berry': 'Baccababiri',
  'chilan-berry': 'Baccacinlan',
  'roseli-berry': 'Baccarcadè',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ItemLocalizationRepository.clearCache);

  test('i blocchi completati coprono Poké Ball, medicine e bacche', () async {
    final sourceItems = await _sourceItems();
    final scopedItems = sourceItems
        .where(
          (item) => const {
            'pokeball',
            'medicine',
            'berry',
          }.contains(item['type']),
        )
        .toList(growable: false);
    final sourceById = {
      for (final item in sourceItems) item['id'].toString(): item,
    };
    final localizedItems = <String, dynamic>{};
    var declaredCount = 0;

    for (final path in ItemLocalizationRepository.assetPaths) {
      final document = Map<String, dynamic>.from(
        jsonDecode(await rootBundle.loadString(path)),
      );
      final items = Map<String, dynamic>.from(document['items'] as Map);

      expect(document['locale'], 'it', reason: path);
      expect(
        document['source'],
        ItemLocalizationRepository.sourceAssetPath,
        reason: path,
      );
      expect(
        const {'pokeball', 'medicine', 'berry'},
        contains(document['type']),
      );
      expect(document['range'], isA<Map>());
      expect(document['localizedCount'], items.length, reason: path);
      declaredCount += document['localizedCount'] as int;

      for (final entry in items.entries) {
        expect(localizedItems, isNot(contains(entry.key)));
        localizedItems[entry.key] = entry.value;
      }
    }

    expect(sourceItems.length, ItemLocalizationRepository.catalogCount);
    expect(scopedItems.length, ItemLocalizationRepository.localizedCount);
    expect(declaredCount, 115);
    expect(localizedItems.length, 115);
    expect(localizedItems.keys.toSet(), _expectedNames.keys.toSet());

    final errors = <String>[];
    for (final entry in localizedItems.entries) {
      final source = sourceById[entry.key];
      if (source == null || entry.value is! Map) {
        errors.add('${entry.key}: localizzazione priva di sorgente.');
        continue;
      }

      final localized = Map<String, dynamic>.from(entry.value as Map);
      final sourceDescription = _description(source['description']);
      final localizedDescription = _description(localized['description']);
      if (localized['sourceName']?.toString() != source['name']?.toString()) {
        errors.add('${entry.key}: nome tecnico modificato.');
      }
      if (localized['name']?.toString() != _expectedNames[entry.key]) {
        errors.add('${entry.key}: nome italiano non verificato.');
      }
      if (localizedDescription.length != sourceDescription.length) {
        errors.add('${entry.key}: numero di paragrafi non conservato.');
      }
      if (!_sameCounts(
        _tokenCounts(sourceDescription.join(' ')),
        _tokenCounts(localizedDescription.join(' ')),
      )) {
        errors.add('${entry.key}: valori meccanici modificati.');
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('i nomi coincidono con il riferimento italiano verificato', () async {
    final entries = await ItemLocalizationRepository().getEntries();

    expect(entries.length, 115);
    expect(
      {for (final entry in entries.entries) entry.key: entry.value.name},
      _expectedNames,
    );
    expect(entries['great-ball']?.name, 'Mega Ball');
    expect(entries['max-revive']?.name, 'Revitalizzante Max');
    expect(entries['berry-juice']?.name, 'Succo di Bacca');
    expect(entries['x-sp-def']?.name, 'Dif. Sp. X');
    expect(entries['red-nectar']?.name, 'Nettare Rosso');
    expect(entries['cheri-berry']?.name, 'Baccaliegia');
    expect(entries['sitrus-berry']?.name, 'Baccacedro');
    expect(entries['passho-berry']?.name, 'Baccapasflo');
    expect(entries['chople-berry']?.name, 'Baccarosmel');
    expect(entries['roseli-berry']?.name, 'Baccarcadè');
  });

  test('il repository localizza la UI e conserva i dati tecnici', () async {
    final sourceItems = await _sourceItems();
    final sourceById = {
      for (final item in sourceItems) item['id'].toString(): item,
    };
    final items = await ItemRepository().getWebItems();
    final byId = {for (final item in items) item.id: item};

    for (final entry in _expectedNames.entries) {
      final source = sourceById[entry.key]!;
      final sourceItem = BagItem.fromWebJson(source);
      final item = byId[entry.key];

      expect(item, isNotNull, reason: entry.key);
      expect(item?.name, entry.value, reason: entry.key);
      expect(item?.technicalName, source['name'], reason: entry.key);
      expect(item?.type, sourceItem.type, reason: entry.key);
      expect(item?.cost, sourceItem.cost, reason: entry.key);
      expect(item?.spriteAssetPath, sourceItem.spriteAssetPath, reason: entry.key);
    }

    expect(byId['great-ball']?.name, 'Mega Ball');
    expect(byId['great-ball']?.technicalName, 'Great Ball');
    expect(byId['potion']?.name, 'Pozione');
    expect(byId['potion']?.technicalName, 'Potion');
    expect(byId['cheri-berry']?.name, 'Baccaliegia');
    expect(byId['cheri-berry']?.technicalName, 'Cheri Berry');
    expect(byId['roseli-berry']?.name, 'Baccarcadè');
    expect(byId['roseli-berry']?.technicalName, 'Roseli Berry');
    expect(byId['backpack']?.name, 'Backpack');
    expect(byId['backpack']?.technicalName, 'Backpack');
  });
}

Future<List<Map<String, dynamic>>> _sourceItems() async {
  final document = Map<String, dynamic>.from(
    jsonDecode(
      await rootBundle.loadString(ItemLocalizationRepository.sourceAssetPath),
    ),
  );
  return List<dynamic>.from(document['items'] ?? const [])
      .map((value) => Map<String, dynamic>.from(value as Map))
      .toList(growable: false);
}

List<String> _description(dynamic value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) return [value];
  return const [];
}

Map<String, int> _tokenCounts(String value) {
  final expression = RegExp(
    r'\b\d+d\d+\b|\b\d+/\d+\b|\+\s*\d+|\b\d+(?:ft)?\b|\b(?:HP|PP|STR|DEX|CON|WIS|CHA|INT|AC|DC|CD)\b',
  );
  final result = <String, int>{};
  for (final match in expression.allMatches(value)) {
    var token = match.group(0)!.replaceAll(' ', '');
    if (token == 'CD') token = 'DC';
    result[token] = (result[token] ?? 0) + 1;
  }
  return result;
}

bool _sameCounts(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
