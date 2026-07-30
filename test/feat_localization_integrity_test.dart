import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/repositories/feat_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GameCatalogLocale.setLanguageCode('it'));

  test('la localizzazione copre tutti i 36 privilegi senza cambiare le regole', () async {
    final source = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString(FeatRepository.sourceAssetPath)),
    );
    final localized = Map<String, dynamic>.from(
      jsonDecode(
        await rootBundle.loadString(FeatRepository.localizationAssetPath),
      ),
    );
    final items = Map<String, dynamic>.from(localized['items'] as Map);

    expect(localized['locale'], 'it');
    expect(localized['source'], FeatRepository.sourceAssetPath);
    expect(localized['catalogCount'], 36);
    expect(source.length, 36);
    expect(items.keys.toSet(), source.keys.toSet());

    final errors = <String>[];
    for (final key in source.keys) {
      final sourceItem = Map<String, dynamic>.from(source[key] as Map);
      final localizedItem = Map<String, dynamic>.from(items[key] as Map);
      if ((localizedItem['name']?.toString().trim() ?? '').isEmpty ||
          (localizedItem['description']?.toString().trim() ?? '').isEmpty) {
        errors.add('$key: localizzazione incompleta.');
        continue;
      }
      final sourceTokens = _mechanicalTokens(
        sourceItem['Description']?.toString() ?? '',
      )..sort();
      final localizedTokens = _mechanicalTokens(
        localizedItem['description']?.toString() ?? '',
      )..sort();
      if (!_sameList(sourceTokens, localizedTokens)) {
        errors.add('$key: valori meccanici non corrispondenti.');
      }
    }
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('il repository localizza solo la visualizzazione italiana', () async {
    final repository = FeatRepository();
    final descriptions = await repository.getFeatDescriptions();
    final names = await repository.getFeatDisplayNames();

    expect(names.length, 36);
    expect(names['Able-Bodied'], 'Fisico Resistente');
    expect(names['AC Up'], 'Aumento della CA');
    expect(names['Actor'], 'Attore');
    expect(names['Alert'], 'Allerta');
    expect(names['Skilled'], 'Abile');
    expect(names['Skulker'], 'Appostato');
    expect(descriptions['Actor'], contains('Carisma (Inganno)'));
    expect(descriptions['Alert'], contains('bonus di +5 all’iniziativa'));
    expect(descriptions['Elemental Adept'], contains('mosse che attiva'));
    expect(descriptions['Skilled'], contains('diversa da Addestrare Animali'));
    expect(descriptions['Combo Master'], contains('Sfuriate'));
    expect(descriptions['Combo Master'], isNot(contains('Fury Swipes')));
    expect(
      descriptions.values.where(
        (description) =>
            description.contains('Pag.') ||
            description.contains('manuale del giocatore') ||
            description.contains('PHB:'),
      ),
      isEmpty,
    );

    GameCatalogLocale.setLanguageCode('en');
    final englishDescriptions = await repository.getFeatDescriptions();
    final englishNames = await repository.getFeatDisplayNames();
    expect(englishNames['Actor'], 'Actor');
    expect(englishDescriptions['Actor'], contains('Charisma (Deception)'));
    expect(englishDescriptions['Alert'], contains('+5 bonus to initiative'));
    expect(englishDescriptions['Elemental Adept'], contains('Moves you activate'));
    expect(englishDescriptions['Skilled'], contains('other than Animal Handling'));
    expect(englishDescriptions['AC Up'], startsWith('Your Pokémon'));
    expect(
      englishDescriptions.values.where(
        (description) =>
            description.contains('PHB:') ||
            description.contains('Player’s Handbook page'),
      ),
      isEmpty,
    );
  });
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
