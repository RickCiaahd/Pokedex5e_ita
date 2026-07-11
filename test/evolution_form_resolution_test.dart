import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/evolution_data.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/evolution_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = EvolutionService();

  EvolutionOption option({
    required String from,
    required String to,
    required String toName,
  }) {
    return EvolutionOption(
      id: '$from-to-$to',
      fromKey: from,
      toKey: to,
      toName: toName,
      conditions: const [],
      effects: const [],
    );
  }

  test('regional form is carried to the evolved species', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final target = service.resolveTarget(
      option: option(from: 'rattata', to: 'raticate', toName: 'Raticate'),
      currentPokemon: rattata.resolveVariant(formName: 'Alolan'),
      slot: const TeamSlot(
        slotIndex: 0,
        pokemonId: 19,
        formName: 'Alolan',
      ),
      catalog: catalog,
    );

    expect(target, isNotNull);
    expect(target!.basePokemon.id, 20);
    expect(
      Pokemon.formReferenceKey(target.formName ?? '', target.basePokemon.name),
      'alolan',
    );
    expect(target.pokemon.types, containsAll(<String>['Dark', 'Normal']));
  });

  test('explicit regional evolution key resolves species and form', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final pikachu = catalog.firstWhere((pokemon) => pokemon.id == 25);
    final target = service.resolveTarget(
      option: option(
        from: 'pikachu',
        to: 'alolan-raichu',
        toName: 'Alolan Raichu',
      ),
      currentPokemon: pikachu,
      slot: const TeamSlot(slotIndex: 0, pokemonId: 25),
      catalog: catalog,
    );

    expect(target, isNotNull);
    expect(target!.basePokemon.id, 26);
    expect(
      Pokemon.formReferenceKey(target.formName ?? '', target.basePokemon.name),
      'alolan',
    );
    expect(target.pokemon.types, containsAll(<String>['Electric', 'Psychic']));
  });

  test('base form remains base when evolving', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final target = service.resolveTarget(
      option: option(from: 'rattata', to: 'raticate', toName: 'Raticate'),
      currentPokemon: rattata,
      slot: const TeamSlot(slotIndex: 0, pokemonId: 19),
      catalog: catalog,
    );

    expect(target, isNotNull);
    expect(target!.basePokemon.id, 20);
    expect(target.formName, isNull);
    expect(target.pokemon.types, isNot(contains('Dark')));
  });
}
