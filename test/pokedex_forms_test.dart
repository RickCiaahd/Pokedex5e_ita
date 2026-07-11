import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/services/pokedex_form_catalog.dart';

Pokemon _pokemon({
  required int id,
  required String name,
  required List<String> types,
  List<PokemonFormDefinition> forms = const [],
}) {
  return Pokemon(
    id: id,
    name: name,
    types: types,
    armorClass: 12,
    hitPoints: 16,
    size: 'Tiny',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 6,
      dexterity: 15,
      constitution: 11,
      intelligence: 6,
      wisdom: 9,
      charisma: 7,
    ),
    abilities: const [],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []),
    hitDice: 6,
    sr: 0.25,
    minLevelFound: 1,
    formDefinitions: forms,
  );
}

void main() {
  late Pokemon rattata;

  setUp(() {
    final alolan = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Dark', 'Normal'],
    );
    rattata = _pokemon(
      id: 19,
      name: 'Rattata',
      types: const ['Normal'],
      forms: [
        PokemonFormDefinition(
          key: 'Alola',
          displayName: 'Alolan Rattata',
          pokemon: alolan,
        ),
      ],
    );
  });

  test('legacy species progress migrates to the base form', () {
    final entry = PokedexEntry.fromJson({
      'pokemonId': 19,
      'seen': true,
      'caught': true,
    });

    expect(entry.caught, isTrue);
    expect(entry.formFor(PokedexEntry.baseFormKey).caught, isTrue);
  });

  test('base form is passed explicitly to the artwork resolver', () {
    final options = PokedexFormCatalog.optionsFor(rattata);
    final base = options.firstWhere((form) => form.isBase);

    expect(base.formName, 'Base');
  });

  test('caught alternate form has priority over a seen base form', () {
    final entry = PokedexEntry(pokemonId: 19)
        .withFormStatus(
          formKey: 'base',
          formName: 'Base',
          seen: true,
          caught: false,
        )
        .withFormStatus(
          formKey: 'alolan',
          formName: 'Alolan',
          seen: true,
          caught: true,
        );

    final preferred = PokedexFormCatalog.preferredFor(rattata, entry);

    expect(preferred.key, 'alolan');
    expect(preferred.pokemon.types, containsAll(<String>['Dark', 'Normal']));
  });

  test('base form has priority when both forms share the same status', () {
    final entry = PokedexEntry(pokemonId: 19)
        .withFormStatus(
          formKey: 'base',
          formName: 'Base',
          seen: true,
          caught: true,
        )
        .withFormStatus(
          formKey: 'alolan-rattata',
          formName: 'Alolan Rattata',
          seen: true,
          caught: true,
        );

    final preferred = PokedexFormCatalog.preferredFor(rattata, entry);

    expect(preferred.isBase, isTrue);
  });

  test('equivalent form aliases are merged into one status', () {
    final entry = PokedexEntry(pokemonId: 19)
        .withFormStatus(
          formKey: 'alolan-rattata',
          formName: 'Alolan Rattata',
          seen: true,
          caught: false,
        )
        .withFormStatus(
          formKey: 'alolan',
          formName: 'Alolan',
          aliases: const {'alolan-rattata'},
          seen: true,
          caught: true,
        );

    expect(entry.forms, hasLength(1));
    expect(entry.formFor('alolan').caught, isTrue);
  });

  test('temporary battle transformations are excluded from Pokédex forms', () {
    final charizard = _pokemon(
      id: 6,
      name: 'Charizard',
      types: const ['Fire', 'Flying'],
      forms: [
        PokemonFormDefinition(
          key: 'mega-x',
          displayName: 'Mega X',
          pokemon: _pokemon(
            id: 6,
            name: 'Charizard',
            types: const ['Fire', 'Dragon'],
          ),
        ),
      ],
    );

    final options = PokedexFormCatalog.optionsFor(charizard);

    expect(options, hasLength(1));
    expect(options.single.isBase, isTrue);
  });
}
