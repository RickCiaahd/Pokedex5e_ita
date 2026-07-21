import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_minior_asset_paths.dart';

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
    final assets = manifest.listAssets();
    expect(assets, contains(paths.first));
    expect(
      assets,
      contains(
        'assets/textures/textures_webapp/pokemon/minior-meteor-form/main.png',
      ),
    );
  });

  test('gender-only textures do not create a Forma selector', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final pikachu = pokemon.firstWhere((entry) => entry.id == 25);
    final choices = await PokemonAssetPaths.formChoices(pikachu);

    expect(choices, isEmpty);
  });
}
