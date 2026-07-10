import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Alolan Rattata applies mechanical variant data', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final rattata = pokemon.firstWhere((entry) => entry.id == 19);
    final alolan = rattata.resolveVariant(formName: 'Alolan Rattata');

    expect(alolan.types, containsAll(<String>['Dark', 'Normal']));
    expect(alolan.abilities, contains('Gluttony'));
    expect(alolan.moves.startingMoves, contains('Quick Attack'));
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

  test('web gender variants are selected from the saved gender', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final indeedee = pokemon.firstWhere((entry) => entry.id == 876);
    final male = indeedee.resolveVariant(gender: 'male');
    final female = indeedee.resolveVariant(gender: 'female');

    expect(male.assetSlug, contains('indeedee-m'));
    expect(female.assetSlug, contains('indeedee-f'));
  });
}
