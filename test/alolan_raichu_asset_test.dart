import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

Pokemon _raichu() {
  return const Pokemon(
    id: 26,
    name: 'Raichu',
    types: ['Electric'],
    armorClass: 15,
    hitPoints: 50,
    size: 'Small',
    speed: 35,
    attributes: PokemonAttributes(
      strength: 12,
      dexterity: 18,
      constitution: 15,
      intelligence: 6,
      wisdom: 12,
      charisma: 10,
    ),
    abilities: ['Static'],
    hiddenAbility: 'Lightning Rod',
    skills: ['Acrobatics'],
    savingThrows: ['Dexterity'],
    moves: PokemonMoves(startingMoves: [], levelMoves: {}, tmMoves: []),
    hitDice: 10,
    sr: 7,
    minLevelFound: 5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Raichu di Alola usa l artwork regionale nella scheda', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PokemonAssetImage(
            pokemon: _raichu(),
            formName: 'Alolan Raichu',
            useLargeArtwork: true,
            size: 112,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;

    expect(
      provider.assetName,
      'assets/textures/textures_webapp/pokemon/alolan-raichu/main.png',
    );
  });
}
