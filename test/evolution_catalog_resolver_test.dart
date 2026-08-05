import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/localization/pokemon_form_localization.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/evolution_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/evolution_catalog_resolver.dart';
import 'package:pokedex_5e_ita/services/evolution_form_alias_service.dart';
import 'package:pokedex_5e_ita/services/evolution_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const resolver = EvolutionCatalogResolver();
  const aliasService = EvolutionFormAliasService();

  setUpAll(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('le forme di Hisui usano la propria catena evolutiva', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();
    final sneasel = catalog.firstWhere((pokemon) => pokemon.id == 215);
    final hisui = sneasel.resolveVariant(formName: 'Hisuian');

    expect(hisui.assetSlug, 'sneasel-hisui');

    final evolution = resolver.evolutionFor(
      pokemon: hisui,
      evolutions: evolutions,
    );

    expect(evolution, isNotNull);
    expect(
      evolution!.options.map((option) => option.toKey),
      contains('sneasler'),
    );
  });

  test('un bersaglio forma di Hisui viene risolto dal suo id tecnico', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();
    final quilava = catalog.firstWhere((pokemon) => pokemon.id == 156);
    final evolution = resolver.evolutionFor(
      pokemon: quilava,
      evolutions: evolutions,
    );
    final option = evolution!.options.firstWhere(
      (candidate) => candidate.toKey == 'typhlosion-hisui',
    );
    final aliases = aliasService.build(
      currentBasePokemon: quilava,
      slot: TeamSlot(slotIndex: 0, pokemonId: quilava.id),
      catalog: catalog,
    );

    final target = resolver.targetPokemonFor(
      option: option,
      catalog: aliases.pokemon,
    );

    expect(target, isNotNull);
    expect(target!.assetSlug, 'typhlosion-hisui');
    expect(target.id, lessThan(0));
    expect(aliases.bySyntheticId[target.id]?.basePokemon.id, 157);
  });

  test('Galar e Paldea usano la regola della forma attiva', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();

    final meowth = catalog.firstWhere((pokemon) => pokemon.id == 52);
    final galar = meowth.resolveVariant(formName: 'Galarian');
    final galarEvolution = resolver.evolutionFor(
      pokemon: galar,
      evolutions: evolutions,
    );
    expect(galar.assetSlug, 'galarian-meowth');
    expect(
      galarEvolution!.options.map((option) => option.toKey),
      contains('perrserker'),
    );

    final wooper = catalog.firstWhere((pokemon) => pokemon.id == 194);
    final paldea = wooper.resolveVariant(formName: 'Paldean');
    final paldeaEvolution = resolver.evolutionFor(
      pokemon: paldea,
      evolutions: evolutions,
    );
    expect(paldea.assetSlug, 'wooper-paldea');
    expect(
      paldeaEvolution!.options.map((option) => option.toKey),
      contains('clodsire'),
    );
  });

  test('Basculin Striscia Bianca usa la propria evoluzione', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();
    final basculin = catalog.firstWhere((pokemon) => pokemon.id == 550);
    final white = basculin.resolveVariant(formName: 'White Striped');

    expect(white.assetSlug, 'basculin-white-striped');
    final evolution = resolver.evolutionFor(
      pokemon: white,
      evolutions: evolutions,
    );

    expect(evolution, isNotNull);
    expect(
      evolution!.options.map((option) => option.toKey),
      containsAll(<String>['basculegion-m', 'basculegion-f']),
    );
  });

  test('Scrigno e Ambulante evolvono entrambi in Gholdengo', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();
    final gimmighoul = catalog.firstWhere((pokemon) => pokemon.id == 999);
    final roaming = gimmighoul.resolveVariant(formName: 'Roaming');

    expect(gimmighoul.name, 'Gimmighoul (Scrigno)');
    expect(gimmighoul.assetSlug, 'gimmighoul');
    expect(roaming.assetSlug, 'gimmighoul-roaming');
    expect(PokemonFormLocalization.formLabel(gimmighoul, null), 'Scrigno');
    expect(
      PokemonFormLocalization.formLabel(gimmighoul, 'Roaming'),
      'Ambulante',
    );

    final chestEvolution = resolver.evolutionFor(
      pokemon: gimmighoul,
      evolutions: evolutions,
    );
    final roamingEvolution = resolver.evolutionFor(
      pokemon: roaming,
      evolutions: evolutions,
    );

    expect(
      chestEvolution!.options.map((option) => option.toKey),
      contains('gholdengo'),
    );
    expect(
      roamingEvolution!.options.map((option) => option.toKey),
      contains('gholdengo'),
    );

    final chestEligibility = const EvolutionService()
        .evaluateOptions(
          pokemon: gimmighoul,
          slot: TeamSlot(slotIndex: 0, pokemonId: gimmighoul.id),
          evolution: chestEvolution,
          inventory: const [],
          itemCatalog: const [],
        )
        .singleWhere((entry) => entry.option.toKey == 'gholdengo');
    final roamingEligibility = const EvolutionService()
        .evaluateOptions(
          pokemon: roaming,
          slot: TeamSlot(slotIndex: 0, pokemonId: roaming.id),
          evolution: roamingEvolution,
          inventory: const [],
          itemCatalog: const [],
        )
        .singleWhere((entry) => entry.option.toKey == 'gholdengo');

    expect(chestEligibility.isAvailable, isTrue);
    expect(roamingEligibility.isAvailable, isTrue);
    expect(
      chestEligibility.conditionLabels,
      contains('Oppure prima del livello 10 consumando ₽9.999'),
    );
  });

  test('tutte le forme con evoluzione usano il proprio id tecnico', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();
    var checkedForms = 0;

    for (final basePokemon in catalog) {
      for (final definition in basePokemon.formDefinitions) {
        if (definition.gender != null) continue;
        final concrete = definition.pokemon.copyWith(
          formDefinitions: basePokemon.formDefinitions,
        );
        final assetSlug = concrete.assetSlug;
        if (assetSlug == null || !evolutions.containsKey(assetSlug)) continue;

        checkedForms++;
        final resolved = resolver.evolutionFor(
          pokemon: concrete,
          evolutions: evolutions,
        );
        expect(
          resolved,
          isNotNull,
          reason: 'Evoluzione non risolta per la forma $assetSlug',
        );
        expect(resolved!.options, isNotEmpty);
      }
    }

    expect(checkedForms, greaterThan(20));
  });

  test('tutti i bersagli canonici del catalogo sono risolvibili', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final evolutions = await EvolutionRepository().getEvolutionData();
    final aliases = aliasService.build(
      currentBasePokemon: catalog.first,
      slot: null,
      catalog: catalog,
    );
    final checked = <String>{};

    for (final evolution in evolutions.values) {
      for (final option in evolution.options) {
        final signature = '${option.fromKey}|${option.toKey}|${option.id}';
        if (!checked.add(signature)) continue;

        final target = resolver.targetPokemonFor(
          option: option,
          catalog: aliases.pokemon,
        );
        expect(
          target,
          isNotNull,
          reason: 'Bersaglio non risolto: ${option.fromKey} -> ${option.toKey}',
        );
      }
    }

    expect(checked.length, greaterThan(500));
  });

  test('le etichette regionali visibili sono italiane', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final meowth = catalog.firstWhere((pokemon) => pokemon.id == 52);
    final sneasel = catalog.firstWhere((pokemon) => pokemon.id == 215);
    final wooper = catalog.firstWhere((pokemon) => pokemon.id == 194);

    expect(
      PokemonFormLocalization.formLabel(rattata, 'Alolan'),
      'Forma di Alola',
    );
    expect(
      PokemonFormLocalization.formLabel(meowth, 'Galarian'),
      'Forma di Galar',
    );
    expect(
      PokemonFormLocalization.formLabel(sneasel, 'Hisuian'),
      'Forma di Hisui',
    );
    expect(
      PokemonFormLocalization.formLabel(wooper, 'Paldean'),
      'Forma di Paldea',
    );
  });
}
