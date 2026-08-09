import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Alolan Rattata applies mechanical variant data', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final rattata = pokemon.firstWhere((entry) => entry.id == 19);
    final alolan = rattata.resolveVariant(formName: 'Alolan Rattata');

    expect(alolan.types, containsAll(<String>['Dark', 'Normal']));
    expect(alolan.abilities, contains('Gluttony'));
    expect(alolan.moves.startingMoves, contains('Quick Attack'));
    expect(alolan.genus, 'Pokémon Topo');
    expect(alolan.description, isNotNull);
    expect(alolan.description, isNotEmpty);
    expect(alolan.description, isNot(startsWith('Night after night')));
    expect(alolan.heightMeters, 0.3);
    expect(alolan.weightKg, 3.8);
  });

  test('Dusk Mane Necrozma deep-merges stats and types', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final necrozma = pokemon.firstWhere((entry) => entry.id == 800);
    final duskMane = necrozma.resolveVariant(formName: 'Dusk Mane Necrozma');

    expect(duskMane.armorClass, 19);
    expect(duskMane.types, <String>['Psychic', 'Steel']);
    expect(duskMane.attributes.strength, 22);
    expect(duskMane.attributes.wisdom, 20);
  });

  test('Deoxys exposes one base form plus Attack, Defense and Speed', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final deoxys = pokemon.firstWhere((entry) => entry.id == 386);
    final choices = await PokemonAssetPaths.formChoices(deoxys);
    final keys = choices
        .map((choice) => Pokemon.formReferenceKey(choice.name, deoxys.name))
        .toList(growable: false);

    expect(keys.where((key) => key == 'base'), hasLength(1));
    expect(keys, containsAll(<String>['attack', 'defense', 'speed']));
    expect(deoxys.resolveVariant(formName: 'Attack').name, 'Deoxys');
  });

  test('Aegislash Shield Forme swaps AC and DEX', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final aegislash = pokemon.firstWhere((entry) => entry.id == 681);
    final shield = aegislash.resolveVariant(formName: 'Shield');

    expect(shield.armorClass, 20);
    expect(shield.attributes.dexterity, 15);
  });

  test('Darmanitan Zen Mode applies the 5e form mechanics', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final darmanitan = pokemon.firstWhere((entry) => entry.id == 555);
    final zen = darmanitan.resolveVariant(formName: 'Zen');

    expect(zen.armorClass, 18);
    expect(zen.types, <String>['Fire', 'Psychic']);
    expect(zen.attributes.strength, 12);
    expect(zen.attributes.wisdom, 17);
  });

  test('web gender variants are selected from the saved gender', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final indeedee = pokemon.firstWhere((entry) => entry.id == 876);
    final male = indeedee.resolveVariant(gender: 'male');
    final female = indeedee.resolveVariant(gender: 'female');

    expect(male.assetSlug, contains('indeedee-m'));
    expect(female.assetSlug, contains('indeedee-f'));
  });
}
