import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Deoxys Speed Form follows the 5e Transformer rule', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final deoxys = catalog.firstWhere((pokemon) => pokemon.id == 386);
    final note = BattleFormChangeService.effectNote(deoxys, 'Speed');
    expect(note, contains('azione di attacco aggiuntiva ogni turno'));
    expect(note, contains('quell’attacco viene effettuato con svantaggio'));
    expect(note, contains('bersagli hanno vantaggio'));
    expect(note, isNot(contains('attacchi contro Deoxys hanno svantaggio')));
    expect(BattleFormChangeService.attackRollBonus(deoxys, 'Attack'), 5);
    expect(BattleFormChangeService.armorClassBonus(deoxys, 'Defense'), 3);
  });

  test('Floette and Florges have canonical flower choices only', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final floette = catalog.firstWhere((p) => p.id == 670);
    final florges = catalog.firstWhere((p) => p.id == 671);

    expect(
      PokedexEntry.formKey('Eternal', speciesName: floette.name),
      'eternal-flower',
    );
    expect(
      PokedexEntry.formKey('Eternal Flower', speciesName: floette.name),
      'eternal-flower',
    );
    expect(
      floette.formDefinitions.where(
        (definition) =>
            PokedexEntry.formKey(
              definition.displayName,
              speciesName: floette.name,
            ) ==
            'eternal-flower',
      ),
      hasLength(1),
    );
    expect(
      (await PokemonAssetPaths.formChoices(
        floette,
      )).map((e) => e.name).toList(),
      const [
        'Base',
        'Blue Flower',
        'Orange Flower',
        'White Flower',
        'Yellow Flower',
        'Eternal Flower',
      ],
    );
    expect(
      (await PokemonAssetPaths.formChoices(
        florges,
      )).map((e) => e.name).toList(),
      const [
        'Base',
        'Blue Flower',
        'Orange Flower',
        'White Flower',
        'Yellow Flower',
      ],
    );
  });

  testWidgets('Flower artwork bundle uses dedicated artwork, not bad sprites', (
    tester,
  ) async {
    final assets = (await AssetManifest.loadFromAssetBundle(
      rootBundle,
    )).listAssets();
    const forms = [
      'Blue Flower',
      'Orange Flower',
      'White Flower',
      'Yellow Flower',
    ];
    for (final form in forms) {
      expect(assets, contains('assets/textures/pokemons/670Floette $form.png'));
      expect(assets, contains('assets/textures/pokemons/671Florges $form.png'));
      expect(
        assets,
        isNot(contains('assets/textures/sprites/670Floette $form.png')),
      );
      expect(
        assets,
        isNot(contains('assets/textures/sprites/671Florges $form.png')),
      );
    }
    expect(
      assets,
      contains('assets/textures/pokemons/670Floette Eternal Flower.png'),
    );
  });
}
