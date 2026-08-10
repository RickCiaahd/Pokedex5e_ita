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

  testWidgets('Flower forms keep dedicated artwork and compact sprites', (
    tester,
  ) async {
    final catalog = await PokemonRepository().getAllPokemon();
    final floette = catalog.firstWhere((p) => p.id == 670);
    final florges = catalog.firstWhere((p) => p.id == 671);
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
      final floetteArtwork = 'assets/textures/pokemons/670Floette $form.png';
      final florgesArtwork = 'assets/textures/pokemons/671Florges $form.png';
      final floetteShinyArtwork =
          'assets/textures/pokemons/670Floette $form Shiny.png';
      final florgesShinyArtwork =
          'assets/textures/pokemons/671Florges $form Shiny.png';
      final floetteSprite = 'assets/textures/sprites/670Floette $form.png';
      final florgesSprite = 'assets/textures/sprites/671Florges $form.png';
      final floetteShinySprite =
          'assets/textures/sprites/670Floette $form Shiny.png';
      final florgesShinySprite =
          'assets/textures/sprites/671Florges $form Shiny.png';

      expect(assets, contains(floetteArtwork));
      expect(assets, contains(florgesArtwork));
      expect(assets, contains(floetteShinyArtwork));
      expect(assets, contains(florgesShinyArtwork));
      expect(assets, contains(floetteSprite));
      expect(assets, contains(florgesSprite));
      expect(assets, contains(floetteShinySprite));
      expect(assets, contains(florgesShinySprite));

      final floetteCompact = PokemonAssetPaths.imageCandidates(
        pokemon: floette,
        useLargeArtwork: false,
        formName: form,
      );
      final florgesCompact = PokemonAssetPaths.imageCandidates(
        pokemon: florges,
        useLargeArtwork: false,
        formName: form,
      );
      final floetteShinyCompact = PokemonAssetPaths.imageCandidates(
        pokemon: floette,
        useLargeArtwork: false,
        formName: form,
        isShiny: true,
      );
      final florgesShinyCompact = PokemonAssetPaths.imageCandidates(
        pokemon: florges,
        useLargeArtwork: false,
        formName: form,
        isShiny: true,
      );
      final floetteLargeShiny = PokemonAssetPaths.imageCandidates(
        pokemon: floette,
        useLargeArtwork: true,
        formName: form,
        isShiny: true,
      );
      final florgesLargeShiny = PokemonAssetPaths.imageCandidates(
        pokemon: florges,
        useLargeArtwork: true,
        formName: form,
        isShiny: true,
      );

      expect(floetteCompact, contains(floetteSprite));
      expect(florgesCompact, contains(florgesSprite));
      expect(floetteShinyCompact, contains(floetteShinySprite));
      expect(florgesShinyCompact, contains(florgesShinySprite));
      expect(
        floetteCompact.indexOf(floetteSprite),
        lessThan(floetteCompact.indexOf(floetteArtwork)),
      );
      expect(
        florgesCompact.indexOf(florgesSprite),
        lessThan(florgesCompact.indexOf(florgesArtwork)),
      );
      expect(
        floetteShinyCompact.indexOf(floetteShinySprite),
        lessThan(floetteShinyCompact.indexOf(floetteShinyArtwork)),
      );
      expect(
        florgesShinyCompact.indexOf(florgesShinySprite),
        lessThan(florgesShinyCompact.indexOf(florgesShinyArtwork)),
      );
      expect(floetteLargeShiny, contains(floetteShinyArtwork));
      expect(florgesLargeShiny, contains(florgesShinyArtwork));
    }

    const eternalArtwork =
        'assets/textures/pokemons/670Floette Eternal Flower.png';
    const eternalSprite =
        'assets/textures/sprites/670Floette Eternal Flower.png';
    const eternalShinySprite =
        'assets/textures/sprites/670Floette Eternal Flower Shiny.png';
    expect(assets, contains(eternalArtwork));
    expect(assets, contains(eternalSprite));
    expect(assets, contains(eternalShinySprite));
    final eternalCompact = PokemonAssetPaths.imageCandidates(
      pokemon: floette,
      useLargeArtwork: false,
      formName: 'Eternal Flower',
    );
    expect(eternalCompact, contains(eternalSprite));
    expect(
      eternalCompact.indexOf(eternalSprite),
      lessThan(eternalCompact.indexOf(eternalArtwork)),
    );
    final eternalShinyCompact = PokemonAssetPaths.imageCandidates(
      pokemon: floette,
      useLargeArtwork: false,
      formName: 'Eternal Flower',
      isShiny: true,
    );
    expect(eternalShinyCompact, contains(eternalShinySprite));
  });
}
