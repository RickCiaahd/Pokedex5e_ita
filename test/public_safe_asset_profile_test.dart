import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

const _blockedRoots = <String>[
  'assets/textures/pokemons/',
  'assets/textures/sprites/',
  'assets/textures/textures_webapp/pokemon/',
  'assets/textures/textures_webapp/pokemon_transforms/',
];

const _publicSafeBuild = bool.fromEnvironment(
  'TRAINER_ATLAS_PUBLIC_SAFE',
);

Pokemon _pokemon() {
  return const Pokemon(
    id: 1,
    name: 'Bulbasaur',
    types: [],
    armorClass: 0,
    hitPoints: 0,
    size: 'Unknown',
    speed: 0,
    attributes: PokemonAttributes(
      strength: 0,
      dexterity: 0,
      constitution: 0,
      intelligence: 0,
      wisdom: 0,
      charisma: 0,
    ),
    abilities: [],
    hiddenAbility: null,
    skills: [],
    savingThrows: [],
    moves: PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []),
    hitDice: 0,
    sr: 0,
    minLevelFound: 0,
  );
}

void main() {
  testWidgets('the public AssetManifest excludes every blocked artwork root', (
    tester,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    for (final root in _blockedRoots) {
      expect(
        assets.where((path) => path.startsWith(root)),
        isEmpty,
        reason: '$root must not be packaged in the public-safe build',
      );
    }

    expect(assets, contains('assets/data/GPL-3.0.txt'));
    expect(assets, contains('assets/data/NOTICE.txt'));
  }, skip: !_publicSafeBuild);

  testWidgets('missing creature artwork resolves to the in-app fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PokemonAssetImage(
              pokemon: _pokemon(),
              useLargeArtwork: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Icon), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !_publicSafeBuild);
}
