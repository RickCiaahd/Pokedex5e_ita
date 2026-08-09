import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Deoxys Speed Form follows the 5e Transformer rule', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final deoxys = catalog.firstWhere((pokemon) => pokemon.id == 386);

    final speedNote = BattleFormChangeService.effectNote(deoxys, 'Speed');

    expect(speedNote, isNotNull);
    expect(speedNote, contains('azione di attacco aggiuntiva ogni turno'));
    expect(
      speedNote,
      contains('quell’attacco viene effettuato con svantaggio'),
    );
    expect(speedNote, contains('bersagli hanno vantaggio'));
    expect(
      speedNote,
      isNot(contains('attacchi contro Deoxys hanno svantaggio')),
    );
    expect(BattleFormChangeService.attackRollBonus(deoxys, 'Attack'), 5);
    expect(BattleFormChangeService.armorClassBonus(deoxys, 'Defense'), 3);
  });

  test('Floette and Florges flower forms resolve dedicated artwork', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final pokemonById = {
      670: catalog.firstWhere((pokemon) => pokemon.id == 670),
      671: catalog.firstWhere((pokemon) => pokemon.id == 671),
    };
    const namesById = {670: 'Floette', 671: 'Florges'};
    const forms = [
      'Yellow Flower',
      'Orange Flower',
      'Blue Flower',
      'White Flower',
    ];

    for (final entry in pokemonById.entries) {
      final pokemon = entry.value;
      final speciesName = namesById[entry.key]!;
      for (final form in forms) {
        final artworkPath =
            'assets/textures/sprites/${entry.key}$speciesName $form.png';
        final candidates = PokemonAssetPaths.imageCandidates(
          pokemon: pokemon,
          useLargeArtwork: false,
          formName: form,
        );
        expect(candidates, contains(artworkPath), reason: '$speciesName $form');
      }
    }
  });

  testWidgets('Flower artwork is bundled without shiny form assets', (
    tester,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    const forms = [
      'Yellow Flower',
      'Orange Flower',
      'Blue Flower',
      'White Flower',
    ];

    for (final form in forms) {
      expect(
        assets,
        contains('assets/textures/sprites/670Floette $form.png'),
        reason: 'Floette $form',
      );
      expect(
        assets,
        contains('assets/textures/sprites/671Florges $form.png'),
        reason: 'Florges $form',
      );
      expect(
        assets,
        isNot(contains('assets/textures/sprites/670Floette $form Shiny.png')),
        reason: 'Floette shiny must stay an appearance, not a form asset',
      );
      expect(
        assets,
        isNot(contains('assets/textures/sprites/671Florges $form Shiny.png')),
        reason: 'Florges shiny must stay an appearance, not a form asset',
      );
    }
  });
}
