import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
    PokemonRepository.clearCache();
  });

  test(
    'lo stesso repository mosse cambia testi senza cambiare ID tecnico',
    () async {
      final repository = MoveRepository();

      GameCatalogLocale.setLanguageCode('it');
      final italian = await repository.getMove('struggle');

      GameCatalogLocale.setLanguageCode('en');
      final english = await repository.getMove('struggle');

      expect(italian, isNotNull);
      expect(english, isNotNull);
      expect(italian!.id, english!.id);
      expect(italian.technicalName, 'Struggle');
      expect(english.technicalName, 'Struggle');
      expect(italian.name, 'Scontro');
      expect(english.name, 'Struggle');
      expect(italian.description, isNot(english.description));
    },
  );

  test('abilità e oggetti usano overlay soltanto in italiano', () async {
    final abilityRepository = AbilityRepository();
    final itemRepository = ItemRepository();

    GameCatalogLocale.setLanguageCode('it');
    final italianAbilities = await abilityRepository.getWebAbilities(
      includeDeprecated: true,
    );
    final italianItems = await itemRepository.getWebItems();

    GameCatalogLocale.setLanguageCode('en');
    final englishAbilities = await abilityRepository.getWebAbilities(
      includeDeprecated: true,
    );
    final englishItems = await itemRepository.getWebItems();

    final italianOvergrow = italianAbilities.firstWhere(
      (ability) => ability.id == 'overgrow',
    );
    final englishOvergrow = englishAbilities.firstWhere(
      (ability) => ability.id == 'overgrow',
    );
    expect(italianOvergrow.name, englishOvergrow.name);
    expect(englishOvergrow.displayName, englishOvergrow.name);
    expect(italianOvergrow.displayName, isNot(englishOvergrow.displayName));
    expect(italianOvergrow.description, isNot(englishOvergrow.description));

    final italianLeftovers = italianItems.firstWhere(
      (item) => item.id == 'leftovers',
    );
    final englishLeftovers = englishItems.firstWhere(
      (item) => item.id == 'leftovers',
    );
    expect(italianLeftovers.name, 'Avanzi');
    expect(englishLeftovers.name, 'Leftovers');
    expect(italianLeftovers.id, englishLeftovers.id);
    expect(italianLeftovers.sourceName, 'Leftovers');
  });

  test(
    'Pokémon usa i flavor sorgente inglesi e gli overlay italiani',
    () async {
      final repository = PokemonRepository();

      GameCatalogLocale.setLanguageCode('it');
      final italian = (await repository.getAllPokemon()).firstWhere(
        (pokemon) => pokemon.id == 1,
      );

      GameCatalogLocale.setLanguageCode('en');
      final english = (await repository.getAllPokemon()).firstWhere(
        (pokemon) => pokemon.id == 1,
      );

      expect(italian.id, english.id);
      expect(italian.name, english.name);
      expect(italian.genus, isNotEmpty);
      expect(english.genus, isNotEmpty);
      expect(italian.genus, isNot(english.genus));
      expect(italian.description, isNot(english.description));
    },
  );
}
