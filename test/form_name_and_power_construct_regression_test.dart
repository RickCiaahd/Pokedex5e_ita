import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/localization/pokemon_form_localization.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GameCatalogLocale.setLanguageCode('it');
    PokemonRepository.clearCache();
    AbilityRepository.clearCache();
  });

  test('Oricorio usa i quattro nomi italiani richiesti in ogni UI', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final oricorio = catalog.firstWhere((pokemon) => pokemon.name == 'Oricorio');

    const expected = <String?, String>{
      null: 'Stile Flamenco',
      'Baile': 'Stile Flamenco',
      'Pom Pom': 'Stile Cheerdance',
      "Pa'u": 'Stile Hula',
      'Sensu': 'Stile Buyō',
    };

    for (final entry in expected.entries) {
      expect(
        PokemonFormLocalization.formLabel(oricorio, entry.key),
        entry.value,
      );
      expect(
        BattleFormChangeService.formLabel(oricorio, entry.key),
        entry.value,
      );
    }
  });

  test('le forme controllate non ricadono più sui nomi inglesi', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    Pokemon species(String name) =>
        catalog.firstWhere((pokemon) => pokemon.name == name);

    expect(
      BattleFormChangeService.formLabel(species('Rotom'), 'Heat'),
      'Forma Calore',
    );
    expect(
      BattleFormChangeService.formLabel(species('Shaymin'), 'Sky'),
      'Forma Cielo',
    );
    for (final name in const ['Tornadus', 'Thundurus', 'Landorus', 'Enamorus']) {
      expect(
        BattleFormChangeService.formLabel(species(name), 'Therian'),
        'Forma Totem',
      );
      expect(
        BattleFormChangeService.formLabel(species(name), 'Incarnate'),
        'Forma Incarnazione',
      );
    }
  });

  test('tutte le forme runtime evitano marcatori inglesi nella UI italiana', () async {
    final catalog = await PokemonRepository().getAllPokemon(includeSealed: true);
    final errors = <String>[];
    final englishMarkers = RegExp(
      r'\b(form|forme|style|mode|cloak|mask|pattern|trim|flower|plumage|breed|face|cream|swirl|drive|rider|segment|incarnate|therian|ordinary|resolute|land|sky|attack|defense|speed|sunny|rainy|snowy|altered|origin|confined|unbound|standard|spring|summer|autumn|winter|hero|zero|hangry|disguised|busted|phony|antique|natural|eternal|heat|wash|frost|fan|mow|small|average|large|supersize|black|white|solo|school|baile|sensu|meteor|gulping|gorging|amped|single|rapid|family|chest|roaming|curly|droopy|stretchy|normal|bug|dark|dragon|electric|fairy|fighting|fire|flying|ghost|grass|ground|ice|poison|psychic|rock|steel|water)\b',
      caseSensitive: false,
    );

    for (final pokemon in catalog) {
      for (final definition in pokemon.formDefinitions) {
        if (definition.gender != null) continue;
        final label = PokemonFormLocalization.formLabel(
          pokemon,
          definition.displayName,
        );
        if (englishMarkers.hasMatch(label)) {
          errors.add(
            '${pokemon.name}: ${definition.displayName} -> $label',
          );
        }
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('Power Construct appare una sola volta come Sciamefusione', () async {
    final repository = AbilityRepository();
    final visible = await repository.getWebAbilities();
    final visiblePowerConstruct = visible
        .where(
          (ability) =>
              ability.id == 'power-construct' ||
              ability.id.startsWith('power-construct-') ||
              ability.name.startsWith('Power Construct'),
        )
        .toList(growable: false);

    expect(visiblePowerConstruct, hasLength(1));
    expect(visiblePowerConstruct.single.id, 'power-construct');
    expect(visiblePowerConstruct.single.name, 'Power Construct');
    expect(visiblePowerConstruct.single.displayName, 'Sciamefusione');

    final technical = await repository.getWebAbilities(includeDeprecated: true);
    final technicalIds = technical.map((ability) => ability.id).toSet();
    expect(technical, hasLength(330));
    expect(
      technicalIds,
      containsAll(const {
        'power-construct-10',
        'power-construct-50',
        'power-construct-100',
      }),
    );

    final displayNames = await repository.getAbilityDisplayNames();
    expect(displayNames['Power Construct'], 'Sciamefusione');

    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: 718,
      abilities: const [
        'Power Construct',
        'Power Construct (10%)',
        'Power Construct (50%)',
        'Power Construct (100%)',
      ],
    );
    expect(slot.abilities, const ['Power Construct']);
  });
}
