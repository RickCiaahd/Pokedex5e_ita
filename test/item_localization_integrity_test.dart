import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/bag_item.dart';
import 'package:pokedex_5e_ita/repositories/item_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';

import 'fixtures/item_held_names_it_155_194.dart';
import 'fixtures/item_held_names_it_195_234.dart';
import 'fixtures/item_held_names_it_235_274.dart';
import 'fixtures/item_held_names_it_275_317.dart';
import 'fixtures/item_trainer_gear_names_it_318_366.dart';

const _allowedTypes = {
  'pokeball',
  'medicine',
  'berry',
  'evolution',
  'held item',
  'trainer gear',
};

const _expectedHeldItemNames = <String, String>{
  ...heldItemNames155To194,
  ...heldItemNames195To234,
  ...heldItemNames235To274,
  ...heldItemNames275To317,
};

const _expectedEvolutionNames = <String, String>{
  'sun-stone': 'Pietrasolare',
  'moon-stone': 'Pietralunare',
  'fire-stone': 'Pietrafocaia',
  'thunder-stone': 'Pietratuono',
  'water-stone': 'Pietraidrica',
  'leaf-stone': 'Pietrafoglia',
  'shiny-stone': 'Pietrabrillo',
  'dusk-stone': 'Neropietra',
  'dawn-stone': 'Pietralbore',
  'ice-stone': 'Pietragelo',
  'oval-stone': 'Pietraovale',
  'alola-stone': 'Alola Stone',
  'kings-rock': 'Roccia di re',
  'razor-claw': 'Affilartigli',
  'razor-fang': 'Affilodente',
  'metal-coat': 'Metalcoperta',
  'deep-sea-scale': 'Squamabissi',
  'deep-sea-tooth': 'Dente Abissi',
  'dragon-scale': 'Squama Drago',
  'up-grade': 'Upgrade',
  'protector': 'Copertura',
  'electirizer': 'Elettritore',
  'magmarizer': 'Magmatore',
  'dubious-disc': 'Dubbiodisco',
  'reaper-cloth': 'Terrorpanno',
  'prism-scale': 'Squama Bella',
  'whipped-dream': 'Dolcespuma',
  'sachet': 'Bustina Aromi',
  'sweet': 'Bonbon',
  'cracked-pot': 'Teiera rotta',
  'chipped-pot': 'Teiera crepata',
  'unremarkable-teacup': 'Tazza dozzinale',
  'masterpiece-teacup': 'Tazza eccezionale',
  'galarica-wreath': 'Corona Galarnoce',
  'black-augurite': 'Augite nera',
  'peat-block': 'Blocco di torba',
  'auspicious-armor': 'Armatura fausta',
  'malicious-armor': 'Armatura infausta',
  'gimmighoul-coin': 'Moneta di Gimmighoul',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ItemLocalizationRepository.clearCache);

  test('i cataloghi italiani coprono tutti i sei blocchi completati', () async {
    final sourceItems = await _sourceItems();
    final sourceById = {
      for (final item in sourceItems) item['id'].toString(): item,
    };
    final scopedItems = sourceItems
        .where((item) => _allowedTypes.contains(item['type']))
        .toList(growable: false);
    final localizedItems = <String, Map<String, dynamic>>{};
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
      expect(_allowedTypes, contains(document['type']), reason: path);
      expect(document['range'], isA<Map>(), reason: path);
      expect(document['localizedCount'], items.length, reason: path);
      declaredCount += document['localizedCount'] as int;

      for (final entry in items.entries) {
        expect(localizedItems, isNot(contains(entry.key)), reason: path);
        localizedItems[entry.key] = Map<String, dynamic>.from(
          entry.value as Map,
        );
      }
    }

    expect(sourceItems.length, ItemLocalizationRepository.catalogCount);
    expect(scopedItems.length, ItemLocalizationRepository.localizedCount);
    expect(declaredCount, ItemLocalizationRepository.localizedCount);
    expect(localizedItems.length, ItemLocalizationRepository.localizedCount);

    final errors = <String>[];
    for (final entry in localizedItems.entries) {
      final source = sourceById[entry.key];
      if (source == null) {
        errors.add('${entry.key}: localizzazione priva di sorgente.');
        continue;
      }

      final localized = entry.value;
      final sourceDescription = _description(source['description']);
      final localizedDescription = _description(localized['description']);
      if (localized['sourceName']?.toString() != source['name']?.toString()) {
        errors.add('${entry.key}: nome tecnico modificato.');
      }
      if ((localized['name']?.toString().trim() ?? '').isEmpty) {
        errors.add('${entry.key}: nome visualizzato vuoto.');
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

  test('i 39 oggetti evolutivi usano i nomi verificati', () async {
    final document = await _loadLocalizationDocument(
      'assets/data/item_localization_it_evolution_116_154.json',
    );
    final names = _localizedNames(document);

    expect(document['type'], 'evolution');
    expect(document['localizedCount'], 39);
    expect(names, _expectedEvolutionNames);
    expect(names['sun-stone'], 'Pietrasolare');
    expect(names['alola-stone'], 'Alola Stone');
    expect(names['metal-coat'], 'Metalcoperta');
    expect(names['sweet'], 'Bonbon');
    expect(names['gimmighoul-coin'], 'Moneta di Gimmighoul');
  });

  test('i 163 strumenti da tenere usano i nomi verificati', () async {
    final names = <String, String>{};
    var declaredCount = 0;

    for (final path in ItemLocalizationRepository.assetPaths.where(
      (path) => path.contains('_held_'),
    )) {
      final document = await _loadLocalizationDocument(path);
      expect(document['type'], 'held item', reason: path);
      declaredCount += document['localizedCount'] as int;
      names.addAll(_localizedNames(document));
    }

    expect(declaredCount, 163);
    expect(names.length, 163);
    expect(names, _expectedHeldItemNames);
    expect(names['ability-shield'], 'Scudo abilità');
    expect(names['assault-vest'], 'Corpetto Assalto');
    expect(names['normalium-z'], 'Normium Z');
    expect(names['mirror-herb'], 'Foglia carbone');
    expect(names['fairy-feather'], 'Piuma fatata');
    expect(names['Fist-plate'], 'Lastrapugno');
    expect(names['gracidea-flower'], 'Gracidea');
    expect(names['leek'], 'Porro');
    expect(names['bug-memory-disc'], 'ROM Coleottero');
    expect(names['blue-orb'], 'Gemma blu');
    expect(names['megalite-stone'], 'Megalite Stone');
  });

  test('i 49 strumenti dell’Allenatore usano i nomi verificati', () async {
    final names = <String, String>{};
    var declaredCount = 0;

    for (final path in ItemLocalizationRepository.assetPaths.where(
      (path) => path.contains('_trainer_gear_'),
    )) {
      final document = await _loadLocalizationDocument(path);
      expect(document['type'], 'trainer gear', reason: path);
      declaredCount += document['localizedCount'] as int;
      names.addAll(_localizedNames(document));
    }

    expect(declaredCount, 49);
    expect(names.length, 49);
    expect(names, trainerGearNames318To366);
    expect(names['dna-splicer'], 'Cuneo DNA');
    expect(names['n-solarizer'], 'Necrosolix');
    expect(names['n-lunarizer'], 'Necrolunix');
    expect(names['prison-bottle'], 'Vaso del vincolo');
    expect(names['old-rod'], 'Amo Vecchio');
    expect(names['good-rod'], 'Amo Buono');
    expect(names['super-rod'], 'Super Amo');
    expect(names['key-stone'], 'Pietrachiave');
    expect(names['tera-orb'], 'Terasfera');
    expect(names['capture-styler'], 'Styler di cattura');
    expect(names['egg-incubator-super'], 'Superincubatrice');
  });

  test('il repository localizza la UI e conserva i dati tecnici', () async {
    final sourceItems = await _sourceItems();
    final sourceById = {
      for (final item in sourceItems) item['id'].toString(): item,
    };
    final localizations = await ItemLocalizationRepository().getEntries();
    final items = await ItemRepository().getWebItems();
    final byId = {for (final item in items) item.id: item};

    for (final entry in localizations.entries) {
      final source = sourceById[entry.key]!;
      final sourceItem = BagItem.fromWebJson(source);
      final item = byId[entry.key];

      expect(item, isNotNull, reason: entry.key);
      expect(item?.name, entry.value.name, reason: entry.key);
      expect(item?.technicalName, source['name'], reason: entry.key);
      expect(item?.type, sourceItem.type, reason: entry.key);
      expect(item?.cost, sourceItem.cost, reason: entry.key);
      expect(item?.spriteAssetPath, sourceItem.spriteAssetPath, reason: entry.key);
    }

    expect(byId['great-ball']?.name, 'Mega Ball');
    expect(byId['potion']?.name, 'Pozione');
    expect(byId['cheri-berry']?.name, 'Baccaliegia');
    expect(byId['sun-stone']?.name, 'Pietrasolare');
    expect(byId['ability-shield']?.name, 'Scudo abilità');
    expect(byId['ability-shield']?.technicalName, 'Ability Shield');
    expect(byId['mirror-herb']?.name, 'Foglia carbone');
    expect(byId['mirror-herb']?.technicalName, 'Mirror Herb');
    expect(byId['bug-memory-disc']?.name, 'ROM Coleottero');
    expect(byId['bug-memory-disc']?.technicalName, 'Bug Memory Disc');
    expect(byId['blue-orb']?.name, 'Gemma blu');
    expect(byId['blue-orb']?.technicalName, 'Blue Orb');
    expect(byId['megalite-stone']?.name, 'Megalite Stone');
    expect(byId['dna-splicer']?.name, 'Cuneo DNA');
    expect(byId['dna-splicer']?.technicalName, 'DNA Splicer');
    expect(byId['old-rod']?.name, 'Amo Vecchio');
    expect(byId['old-rod']?.technicalName, 'Old Rod');
    expect(byId['tera-orb']?.name, 'Terasfera');
    expect(byId['tera-orb']?.technicalName, 'Tera Orb');
    expect(byId['capture-styler']?.name, 'Styler di cattura');
    expect(byId['capture-styler']?.technicalName, 'Capture Styler');
    expect(byId['backpack']?.name, 'Zaino');
    expect(byId['backpack']?.technicalName, 'Backpack');
    expect(byId['egg-incubator-super']?.name, 'Superincubatrice');
    expect(
      byId['egg-incubator-super']?.technicalName,
      'Egg Incubator Super',
    );
  });
}

Future<Map<String, dynamic>> _loadLocalizationDocument(String path) async {
  return Map<String, dynamic>.from(
    jsonDecode(await rootBundle.loadString(path)),
  );
}

Map<String, String> _localizedNames(Map<String, dynamic> document) {
  final items = Map<String, dynamic>.from(document['items'] as Map);
  return <String, String>{
    for (final entry in items.entries)
      entry.key:
          Map<String, dynamic>.from(entry.value as Map)['name'].toString(),
  };
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
    r'\b\d+d\d+\b|\b\d+/\d+\b|\+\s*\d+|\b\d+(?:ft)?\b|\b(?:HP|PP|STR|DEX|CON|WIS|CHA|INT|AC|STAB|DC|CD)\b',
  );
  final result = <String, int>{};
  for (final match in expression.allMatches(value)) {
    var token = match.group(0)!.replaceAll(' ', '');
    if (token == 'CD') token = 'DC';
    if (token.endsWith('ft')) {
      token = token.substring(0, token.length - 2);
    }
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
