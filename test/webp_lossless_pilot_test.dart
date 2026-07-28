import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

const _pilotWebpAssets = <String>[
  'assets/textures/textures_webapp/pokemon/abomasnow/main.webp',
  'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.webp',
  'assets/textures/textures_webapp/pokemon/alolan-rattata/main.webp',
  'assets/textures/textures_webapp/pokemon/alolan-rattata/main-shiny.webp',
  'assets/textures/textures_webapp/pokemon/dusk-mane-necrozma/main-shiny.webp',
  'assets/textures/textures_webapp/pokemon/bulbasaur/sprite.webp',
  'assets/textures/textures_webapp/pokemon/bulbasaur/sprite-shiny.webp',
  'assets/textures/textures_webapp/pokemon/indeedee-f/sprite.webp',
  'assets/textures/textures_webapp/pokemon/meowstic-m/sprite.webp',
  'assets/textures/textures_webapp/pokemon/meowstic-m/sprite-shiny.webp',
  'assets/textures/textures_webapp/pokemon/alolan-rattata/sprite-shiny.webp',
  'assets/textures/textures_webapp/pokemon/tyrunt/sprite.webp',
];

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
  test('WebP is preferred before PNG for web artwork candidates', () {
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(460, 'Abomasnow'),
      useLargeArtwork: true,
      isShiny: true,
    );

    const webp =
        'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.webp';
    const png =
        'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.png';
    expect(candidates, contains(webp));
    expect(candidates, contains(png));
    expect(candidates.indexOf(webp), lessThan(candidates.indexOf(png)));
  });

  testWidgets('pilot WebP assets replace their PNG counterparts', (
    tester,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    for (final webp in _pilotWebpAssets) {
      expect(assets, contains(webp), reason: webp);
      expect(
        assets,
        isNot(contains(webp.replaceFirst(RegExp(r'\.webp$'), '.png'))),
        reason: webp,
      );
    }
  });
}
