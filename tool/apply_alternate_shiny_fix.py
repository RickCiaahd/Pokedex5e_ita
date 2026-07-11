from pathlib import Path

resolver_path = Path('lib/widgets/pokemon/pokemon_asset_image_legacy.dart')
resolver = resolver_path.read_text(encoding='utf-8')

old_prefixes = """    for (final formSlug in formSlugs) {
      for (final slug in candidateSlugs) {
        add('$_webPokemonRoot/$slug-$formSlug/');
        add('$_webPokemonRoot/${slug}_$formSlug/');
        add('$_webPokemonRoot/$slug/$formSlug/');
        for (final transform in _transformFolders) {
          add('$_webTransformRoot/$transform/$slug-$formSlug/');
          add('$_webTransformRoot/$transform/${slug}_$formSlug/');
          add('$_webTransformRoot/$transform/$slug/$formSlug/');
        }
      }
    }
"""
new_prefixes = """    for (final formSlug in formSlugs) {
      for (final slug in candidateSlugs) {
        add('$_webPokemonRoot/$slug-$formSlug/');
        add('$_webPokemonRoot/${slug}_$formSlug/');
        add('$_webPokemonRoot/$slug/$formSlug/');
        add('$_webPokemonRoot/$formSlug-$slug/');
        add('$_webPokemonRoot/${formSlug}_$slug/');
        add('$_webPokemonRoot/$formSlug/$slug/');
        for (final transform in _transformFolders) {
          add('$_webTransformRoot/$transform/$slug-$formSlug/');
          add('$_webTransformRoot/$transform/${slug}_$formSlug/');
          add('$_webTransformRoot/$transform/$slug/$formSlug/');
          add('$_webTransformRoot/$transform/$formSlug-$slug/');
          add('$_webTransformRoot/$transform/${formSlug}_$slug/');
          add('$_webTransformRoot/$transform/$formSlug/$slug/');
        }
      }
    }
"""
if old_prefixes not in resolver:
    raise SystemExit('Prefix candidate block not found')
resolver = resolver.replace(old_prefixes, new_prefixes, 1)

old_folders = """    for (final formSlug in formSlugs) {
      for (final slug in slugs) {
        addFolder('$_webPokemonRoot/$slug-$formSlug');
        addFolder('$_webPokemonRoot/${slug}_$formSlug');
        addFolder('$_webPokemonRoot/$slug/$formSlug');
      }
    }
"""
new_folders = """    for (final formSlug in formSlugs) {
      for (final slug in slugs) {
        addFolder('$_webPokemonRoot/$slug-$formSlug');
        addFolder('$_webPokemonRoot/${slug}_$formSlug');
        addFolder('$_webPokemonRoot/$slug/$formSlug');
        addFolder('$_webPokemonRoot/$formSlug-$slug');
        addFolder('$_webPokemonRoot/${formSlug}_$slug');
        addFolder('$_webPokemonRoot/$formSlug/$slug');
      }
    }
"""
if old_folders not in resolver:
    raise SystemExit('Web folder candidate block not found')
resolver = resolver.replace(old_folders, new_folders, 1)
resolver_path.write_text(resolver, encoding='utf-8')

test_path = Path('test/pokemon_asset_paths_test.dart')
test_source = test_path.read_text(encoding='utf-8')
marker = "\n}\n"
if not test_source.endswith(marker):
    raise SystemExit('Unexpected test file ending')
new_tests = r'''

  test(
    'Alolan Rattata shiny artwork is resolved before all fallbacks',
    () {
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
    },
  );

  test(
    'Dusk Mane Necrozma shiny artwork uses the form-first folder',
    () {
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
    },
  );

  testWidgets(
    'alternate shiny artwork is included in the Flutter asset bundle',
    (tester) async {
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
    },
  );
'''
test_source = test_source[:-len(marker)] + new_tests + marker
test_path.write_text(test_source, encoding='utf-8')
