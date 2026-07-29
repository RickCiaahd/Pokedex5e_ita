import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_minior_asset_paths.dart';

void _expectSameBattleStats(Pokemon first, Pokemon second) {
  expect(first.armorClass, second.armorClass);
  expect(first.hitPoints, second.hitPoints);
  expect(first.speed, second.speed);
  expect(first.attributes.strength, second.attributes.strength);
  expect(first.attributes.dexterity, second.attributes.dexterity);
  expect(first.attributes.constitution, second.attributes.constitution);
  expect(first.attributes.intelligence, second.attributes.intelligence);
  expect(first.attributes.wisdom, second.attributes.wisdom);
  expect(first.attributes.charisma, second.attributes.charisma);
}

void _expectBundledCandidate(List<String> assets, String candidate) {
  final webp = candidate.endsWith('.png')
      ? '${candidate.substring(0, candidate.length - 4)}.webp'
      : candidate;
  expect(
    assets,
    anyOf(contains(webp), contains(candidate)),
    reason: 'Expected the preferred WebP or PNG fallback for $candidate',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Minior exposes seven aesthetic cores with shared statistics', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final minior = pokemon.firstWhere((entry) => entry.id == 774);

    const forms = {
      'core-red': 'Nucleo Rosso',
      'core-orange': 'Nucleo Arancione',
      'core-yellow': 'Nucleo Giallo',
      'core-green': 'Nucleo Verde',
      'core-blue': 'Nucleo Azzurro',
      'core-indigo': 'Nucleo Indaco',
      'core-violet': 'Nucleo Violetto',
    };

    expect(BattleFormChangeService.formLabel(minior, 'Base'), 'Forma Meteora');
    for (final entry in forms.entries) {
      expect(BattleFormChangeService.formLabel(minior, entry.key), entry.value);
      final core = minior.resolveVariant(formName: entry.key);
      expect(core.armorClass, 14, reason: entry.key);
      expect(core.attributes.dexterity, 18, reason: entry.key);
    }
  });

  test('Minior uses the dedicated Meteor Form images by default', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final minior = pokemon.firstWhere((entry) => entry.id == 774);

    final normal = PokemonMiniorAssetPaths.candidates(
      pokemon: minior,
      useLargeArtwork: true,
      formName: 'Base',
    );
    final shiny = PokemonMiniorAssetPaths.candidates(
      pokemon: minior,
      useLargeArtwork: true,
      formName: 'Forma Meteora',
      isShiny: true,
    );

    expect(
      normal.first,
      'assets/textures/textures_webapp/pokemon/minior-meteor-form/main.png',
    );
    expect(
      shiny.first,
      'assets/textures/textures_webapp/pokemon/minior-meteor-form/main-shiny.png',
    );

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    _expectBundledCandidate(assets, normal.first);
    _expectBundledCandidate(assets, shiny.first);
  });

  test('Minior colour candidates point to the bundled shared folder', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final minior = pokemon.firstWhere((entry) => entry.id == 774);
    final paths = PokemonMiniorAssetPaths.candidates(
      pokemon: minior,
      useLargeArtwork: true,
      formName: 'core-indigo',
      isShiny: true,
    );

    expect(
      paths.first,
      'assets/textures/textures_webapp/pokemon/minior-core/main-indigo-shiny.png',
    );

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _expectBundledCandidate(manifest.listAssets(), paths.first);
  });

  test('gender-only textures do not create a Forma selector', () async {
    final pokemon = await PokemonRepository().getAllPokemon();

    for (final id in const [25, 668, 678]) {
      final species = pokemon.firstWhere((entry) => entry.id == id);
      final choices = await PokemonAssetPaths.formChoices(species);
      expect(choices, isEmpty, reason: species.name);
    }
  });

  test(
    'Pyroar gender changes appearance without changing battle data',
    () async {
      final pokemon = await PokemonRepository().getAllPokemon();
      final pyroar = pokemon.firstWhere((entry) => entry.id == 668);
      final male = pyroar.resolveVariant(gender: 'male');
      final female = pyroar.resolveVariant(gender: 'female');

      _expectSameBattleStats(male, female);
      expect(male.abilities, female.abilities);
      expect(male.hiddenAbility, female.hiddenAbility);
    },
  );

  test(
    'Meowstic keeps its stats but changes learnset and hidden ability',
    () async {
      final pokemon = await PokemonRepository().getAllPokemon();
      final meowstic = pokemon.firstWhere((entry) => entry.id == 678);
      final male = meowstic.resolveVariant(gender: 'male');
      final female = meowstic.resolveVariant(gender: 'female');

      _expectSameBattleStats(male, female);
      expect(male.hiddenAbility, 'Prankster');
      expect(female.hiddenAbility, 'Competitive');
      expect(
        male.moves.startingMoves,
        isNot(equals(female.moves.startingMoves)),
      );
    },
  );
}
