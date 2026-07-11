import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

Pokemon _pokemon(int id, String name) {
  return Pokemon(
    id: id,
    name: name,
    types: const [],
    armorClass: 0,
    hitPoints: 0,
    size: 'Unknown',
    speed: 0,
    attributes: const PokemonAttributes(
      strength: 0,
      dexterity: 0,
      constitution: 0,
      intelligence: 0,
      wisdom: 0,
      charisma: 0,
    ),
    abilities: const [],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []),
    hitDice: 0,
    sr: 0,
    minLevelFound: 0,
  );
}

void main() {
  test('Alolan Rattata artwork is resolved before the base web artwork', () {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(19, 'Rattata'),
      useLargeArtwork: true,
      formName: 'Alolan Rattata',
    );

    const alternate = 'assets/textures/pokemons/19Alolan Rattata.png';
    const base = 'assets/textures/textures_webapp/pokemon/rattata/main.png';

    expect(candidates, contains(alternate));
    expect(candidates, contains(base));
    expect(candidates.indexOf(alternate), lessThan(candidates.indexOf(base)));
  });

  test('Dusk Mane Necrozma sprite is resolved before the base web sprite', () {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(800, 'Necrozma'),
      useLargeArtwork: false,
      formName: 'Dusk Mane Necrozma',
    );

    const alternate = 'assets/textures/sprites/800Dusk Mane Necrozma.png';
    const base = 'assets/textures/textures_webapp/pokemon/necrozma/sprite.png';

    expect(candidates, contains(alternate));
    expect(candidates, contains(base));
    expect(candidates.indexOf(alternate), lessThan(candidates.indexOf(base)));
  });

  test('Abomasnow shiny artwork is resolved before normal detail artwork', () {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(460, 'Abomasnow'),
      useLargeArtwork: true,
      isShiny: true,
    );

    const shiny =
        'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.png';
    const normal = 'assets/textures/textures_webapp/pokemon/abomasnow/main.png';

    expect(candidates, contains(shiny));
    expect(candidates, contains(normal));
    expect(candidates.indexOf(shiny), lessThan(candidates.indexOf(normal)));
  });

  testWidgets(
    'Abomasnow shiny artwork is included in the Flutter asset bundle',
    (tester) async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      expect(
        manifest.listAssets(),
        contains(
          'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.png',
        ),
      );
    },
  );

  test('Alolan Rattata shiny artwork is resolved before all fallbacks', () {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(19, 'Rattata'),
      useLargeArtwork: true,
      formName: 'Alolan Rattata',
      isShiny: true,
    );

    const alternateShiny =
        'assets/textures/textures_webapp/pokemon/alolan-rattata/main-shiny.png';
    const alternateNormal =
        'assets/textures/textures_webapp/pokemon/alolan-rattata/main.png';
    const baseShiny =
        'assets/textures/textures_webapp/pokemon/rattata/main-shiny.png';

    expect(candidates, contains(alternateShiny));
    expect(candidates, contains(alternateNormal));
    expect(candidates, contains(baseShiny));
    expect(
      candidates.indexOf(alternateShiny),
      lessThan(candidates.indexOf(alternateNormal)),
    );
    expect(
      candidates.indexOf(alternateShiny),
      lessThan(candidates.indexOf(baseShiny)),
    );
  });

  test('Dusk Mane Necrozma shiny artwork uses the form-first folder', () {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(800, 'Necrozma'),
      useLargeArtwork: true,
      formName: 'Dusk Mane Necrozma',
      isShiny: true,
    );

    const alternateShiny =
        'assets/textures/textures_webapp/pokemon/dusk-mane-necrozma/main-shiny.png';
    const baseShiny =
        'assets/textures/textures_webapp/pokemon/necrozma/main-shiny.png';

    expect(candidates, contains(alternateShiny));
    expect(candidates, contains(baseShiny));
    expect(
      candidates.indexOf(alternateShiny),
      lessThan(candidates.indexOf(baseShiny)),
    );
  });

  testWidgets('alternate shiny artwork is included in the Flutter asset bundle', (
    tester,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    expect(
      assets,
      contains(
        'assets/textures/textures_webapp/pokemon/alolan-rattata/main-shiny.png',
      ),
    );
    expect(
      assets,
      contains(
        'assets/textures/textures_webapp/pokemon/dusk-mane-necrozma/main-shiny.png',
      ),
    );
  });
}
