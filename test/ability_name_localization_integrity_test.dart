import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/ability_localization_repository.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AbilityLocalizationRepository.clearCache);

  test('il riferimento ufficiale copre 308 delle 330 voci del catalogo', () async {
    final sourceDocument = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString('assets/data_webapp/abilities.json'),
      ),
    );
    final sourceItems = List<dynamic>.from(sourceDocument['items'] ?? const []);
    final sourceById = <String, Map<String, dynamic>>{
      for (final raw in sourceItems)
        Map<String, dynamic>.from(raw as Map)['id'].toString():
            Map<String, dynamic>.from(raw),
    };

    final referenceDocument = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString(
          AbilityLocalizationRepository.nameAssetPath,
        ),
      ),
    );
    final referenceItems = Map<String, dynamic>.from(
      referenceDocument['items'] as Map,
    );

    expect(sourceItems.length, 330);
    expect(sourceById.length, 330);
    expect(referenceDocument['locale'], 'it');
    expect(
      referenceDocument['source'],
      'https://wiki.pokemoncentral.it/Abilit%C3%A0',
    );
    expect(referenceDocument['catalogCount'], 330);
    expect(referenceDocument['matchedCount'], 308);
    expect(referenceDocument['unmatchedCount'], 22);
    expect(referenceItems.length, 308);
    expect(referenceItems.keys.toSet().difference(sourceById.keys.toSet()), isEmpty);
    expect(sourceById.keys.toSet().difference(referenceItems.keys.toSet()).length, 22);

    final errors = <String>[];
    for (final entry in referenceItems.entries) {
      final source = sourceById[entry.key];
      if (source == null || entry.value is! Map) {
        errors.add('${entry.key}: riferimento non valido.');
        continue;
      }
      final reference = Map<String, dynamic>.from(entry.value as Map);
      final sourceName = source['name']?.toString() ?? '';
      if (reference['sourceName']?.toString() != sourceName) {
        errors.add('${entry.key}: il nome tecnico sorgente non coincide.');
      }
      if ((reference['name']?.toString().trim() ?? '').isEmpty) {
        errors.add('${entry.key}: nome italiano vuoto.');
      }
      if (reference['officialNumber'] is! num) {
        errors.add('${entry.key}: numero ufficiale non valido.');
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('le 22 voci specifiche del catalogo completano i nomi italiani', () async {
    final sourceDocument = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString('assets/data_webapp/abilities.json'),
      ),
    );
    final sourceItems = List<dynamic>.from(sourceDocument['items'] ?? const []);
    final sourceById = <String, Map<String, dynamic>>{
      for (final raw in sourceItems)
        Map<String, dynamic>.from(raw as Map)['id'].toString():
            Map<String, dynamic>.from(raw),
    };
    final officialDocument = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString(AbilityLocalizationRepository.nameAssetPath)),
    );
    final officialIds = Map<String, dynamic>.from(
      officialDocument['items'] as Map,
    ).keys.toSet();
    final customDocument = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString(
          AbilityLocalizationRepository.customNameAssetPath,
        ),
      ),
    );
    final customItems = Map<String, dynamic>.from(
      customDocument['items'] as Map,
    );

    expect(customDocument['locale'], 'it');
    expect(customDocument['source'], 'assets/data_webapp/abilities.json');
    expect(customDocument['catalogCount'], 330);
    expect(customDocument['localizedCount'], 22);
    expect(customItems.length, 22);
    expect(customItems.keys.toSet(), sourceById.keys.toSet().difference(officialIds));
    for (final entry in customItems.entries) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      expect(item['sourceName'], sourceById[entry.key]?['name']);
      expect(item['name']?.toString().trim(), isNotEmpty);
    }
  });
  test('i nomi verificati coincidono con le denominazioni italiane attese', () async {
    final names = await AbilityLocalizationRepository().getNames();

    expect(names.length, 330);
    expect(names['adaptability'], 'Adattabilità');
    expect(names['aftermath'], 'Scoppio');
    expect(names['air-lock'], 'Riparo');
    expect(names['poison-point'], 'Velenopunte');
    expect(names['as-one'], 'Sintonia Equina');
    expect(names['zen-mode-galarian'], 'Stato Zen');
    expect(names['power-construct-10'], 'Sciamefusione');
    expect(names['power-construct-50'], 'Sciamefusione');
    expect(names['power-construct-100'], 'Sciamefusione');
    expect(names['embody-aspect-teal'], 'Albergamemorie');
    expect(names['embody-aspect-heartflame'], 'Albergamemorie');
    expect(names['embody-aspect-wellspring'], 'Albergamemorie');
    expect(names['embody-aspect-cornerstone'], 'Albergamemorie');
    expect(names['hospitality'], 'Ospitalità');
    expect(names['minds-eye'], 'Occhio Interiore');
    expect(names['toxic-chain'], 'Catena Tossica');
    expect(names['supersweet-syrup'], 'Sciroppo Sublime');
    expect(names['tera-shift'], 'Teramorfosi');
    expect(names['tera-shell'], 'Teraguscio');
    expect(names['teraform-zero'], 'Zeroformazione');
    expect(names['poison-puppeteer'], 'Malia Tossica');
    expect(names['air-slash'], 'Eterelama');
    expect(names['drifter'], 'Fluttuante');
    expect(names['paper-thin'], 'Fragile come Carta');
    expect(names['transformer'], 'Trasformista');
  });

  test('il repository conserva il nome tecnico e localizza solo la UI', () async {
    final repository = AbilityRepository();
    final abilities = await repository.getWebAbilities(includeDeprecated: true);
    final byId = {for (final ability in abilities) ability.id: ability};

    expect(abilities.length, 330);
    expect(byId['adaptability']?.name, 'Adaptability');
    expect(byId['adaptability']?.displayName, 'Adattabilità');
    expect(byId['adaptability']?.description, startsWith('Quando questo Pokémon'));
    expect(byId['poison-point']?.name, 'Poison Point');
    expect(byId['poison-point']?.displayName, 'Velenopunte');
    expect(byId['hospitality']?.name, 'Hospitality');
    expect(byId['hospitality']?.displayName, 'Ospitalità');
    expect(byId['air-slash']?.name, 'Air Slash');
    expect(byId['air-slash']?.displayName, 'Eterelama');
    expect(byId['drifter']?.name, 'Drifter');
    expect(byId['drifter']?.displayName, 'Fluttuante');

    final displayNames = await repository.getAbilityDisplayNames();
    expect(displayNames['Adaptability'], 'Adattabilità');
    expect(displayNames['Poison Point'], 'Velenopunte');
    expect(displayNames['Hospitality'], 'Ospitalità');
    expect(displayNames['Air Slash'], 'Eterelama');
    expect(displayNames['Drifter'], 'Fluttuante');

    final descriptions = await repository.getAbilityDescriptions();
    expect(descriptions, contains('Adaptability'));
    expect(descriptions, isNot(contains('Adattabilità')));
  });
}
