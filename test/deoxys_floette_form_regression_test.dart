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

  test(
    'Floette flower forms resolve distinct normal and shiny sprites',
    () async {
      final catalog = await PokemonRepository().getAllPokemon();
      final floette = catalog.firstWhere((pokemon) => pokemon.id == 670);
      const forms = [
        'Yellow Flower',
        'Orange Flower',
        'Blue Flower',
        'White Flower',
      ];

      for (final form in forms) {
        final normalPath = 'assets/textures/sprites/670Floette $form.png';
        final shinyPath = 'assets/textures/sprites/670Floette $form Shiny.png';
        final normalCandidates = PokemonAssetPaths.imageCandidates(
          pokemon: floette,
          useLargeArtwork: false,
          formName: form,
        );
        final shinyCandidates = PokemonAssetPaths.imageCandidates(
          pokemon: floette,
          useLargeArtwork: false,
          formName: form,
          isShiny: true,
        );

        expect(normalCandidates, contains(normalPath), reason: form);
        expect(shinyCandidates, contains(shinyPath), reason: '$form shiny');
        expect(shinyCandidates, contains(normalPath), reason: '$form fallback');
        expect(
          shinyCandidates.indexOf(shinyPath),
          lessThan(shinyCandidates.indexOf(normalPath)),
          reason: '$form must prefer its shiny sprite',
        );
      }
    },
  );

  testWidgets(
    'Floette flower sprites are included in the Flutter asset bundle',
    (tester) async {
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
          reason: form,
        );
        expect(
          assets,
          contains('assets/textures/sprites/670Floette $form Shiny.png'),
          reason: '$form shiny',
        );
      }
    },
  );
}
