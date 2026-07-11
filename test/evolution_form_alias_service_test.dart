import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/evolution_form_alias_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = EvolutionFormAliasService();

  test('Alolan Rattata prefers Alolan Raticate for the base target name', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final result = service.build(
      currentBasePokemon: rattata,
      slot: const TeamSlot(
        slotIndex: 0,
        pokemonId: 19,
        formName: 'Alolan',
      ),
      catalog: catalog,
    );

    final aliasPokemon = result.pokemon.firstWhere(
      (pokemon) => pokemon.id < 0 && pokemon.name == 'Raticate',
    );
    final alias = result.bySyntheticId[aliasPokemon.id];

    expect(alias, isNotNull);
    expect(alias!.basePokemon.id, 20);
    expect(
      Pokemon.formReferenceKey(alias.formName, alias.basePokemon.name),
      'alolan',
    );
    expect(aliasPokemon.types, containsAll(<String>['Dark', 'Normal']));
  });

  test('explicit Alolan Raichu evolution target is available by name', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final pikachu = catalog.firstWhere((pokemon) => pokemon.id == 25);
    final result = service.build(
      currentBasePokemon: pikachu,
      slot: const TeamSlot(slotIndex: 0, pokemonId: 25),
      catalog: catalog,
    );

    final aliasPokemon = result.pokemon.firstWhere(
      (pokemon) =>
          pokemon.id < 0 &&
          pokemon.name.toLowerCase() == 'alolan raichu',
    );
    final alias = result.bySyntheticId[aliasPokemon.id];

    expect(alias, isNotNull);
    expect(alias!.basePokemon.id, 26);
    expect(
      Pokemon.formReferenceKey(alias.formName, alias.basePokemon.name),
      'alolan',
    );
    expect(aliasPokemon.types, containsAll(<String>['Electric', 'Psychic']));
  });

  test('temporary battle transformations are not evolution aliases', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final charizard = catalog.firstWhere((pokemon) => pokemon.id == 6);
    final withMega = charizard.copyWith(
      formDefinitions: [
        PokemonFormDefinition(
          key: 'mega-x',
          displayName: 'Mega X',
          pokemon: charizard,
        ),
      ],
    );

    final result = service.build(
      currentBasePokemon: withMega,
      slot: const TeamSlot(slotIndex: 0, pokemonId: 6),
      catalog: [withMega],
    );

    expect(result.bySyntheticId, isEmpty);
    expect(result.pokemon, [withMega]);
  });
}
