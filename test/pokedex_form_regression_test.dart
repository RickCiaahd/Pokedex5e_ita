import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
    PokemonRepository.clearCache();
  });

  test('il Pokédex esclude gli stati temporanei di lotta', () {
    const battleOnly = <(String, String)>[
      ('Mimikyu', 'Busted Form'),
      ('Palafin', 'Hero Form'),
      ('Wishiwashi', 'School Form'),
      ('Castform', 'Sunny Form'),
      ('Cherrim', 'Sunshine Form'),
      ('Darmanitan', 'Zen Mode'),
      ('Meloetta', 'Pirouette Forme'),
      ('Aegislash', 'Blade Forme'),
      ('Xerneas', 'Active Mode'),
      ('Cramorant', 'Gulping Form'),
      ('Cramorant', 'Gorging Form'),
      ('Eiscue', 'Noice Face'),
      ('Morpeko', 'Hangry Mode'),
      ('Zygarde', 'Complete Forme'),
      ('Necrozma', 'Ultra Necrozma'),
      ('Eternatus', 'Eternamax'),
      ('Terapagos', 'Stellar Form'),
    ];

    for (final (species, form) in battleOnly) {
      expect(
        PokedexEntry.isTrackableForm(form, speciesName: species),
        isFalse,
        reason: '$species $form non deve apparire nel Pokédex',
      );
    }

    expect(
      PokedexEntry.isTrackableForm('Pom-Pom Style', speciesName: 'Oricorio'),
      isTrue,
    );
    expect(
      PokedexEntry.isTrackableForm('Dusk Mane', speciesName: 'Necrozma'),
      isTrue,
    );
    expect(
      PokedexEntry.isTrackableForm('10% Forme', speciesName: 'Zygarde'),
      isTrue,
    );
  });

  test('le forme predefinite collassano sulla Base senza duplicati', () {
    const defaults = <(String, String)>[
      ('Oricorio', 'Baile Style'),
      ('Aegislash', 'Shield Forme'),
      ('Wishiwashi', 'Solo Form'),
      ('Mimikyu', 'Disguised Form'),
      ('Palafin', 'Zero Form'),
      ('Giratina', 'Altered Forme'),
      ('Toxtricity', 'Amped Form'),
      ('Urshifu', 'Single Strike Style'),
      ('Gimmighoul', 'Chest Form'),
    ];

    for (final (species, form) in defaults) {
      expect(
        PokedexEntry.formKey(form, speciesName: species),
        'base',
        reason: '$species $form deve coincidere con Base',
      );
    }
  });

  test('Base usa l artwork canonico nei gruppi senza voce web generica', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final oricorio = pokemon.firstWhere((entry) => entry.id == 741);
    final shaymin = pokemon.firstWhere((entry) => entry.id == 492);
    final hoopa = pokemon.firstWhere((entry) => entry.id == 720);

    expect(oricorio.assetSlug, 'oricorio-baile-style');
    expect(shaymin.assetSlug, 'shaymin-land');
    expect(hoopa.assetSlug, 'hoopa-confined');

    expect(
      oricorio.resolveVariant(formName: "Pa'u").assetSlug,
      'oricorio-pau-style',
    );
    expect(shaymin.resolveVariant(formName: 'Sky').assetSlug, 'shaymin-sky');
    expect(hoopa.resolveVariant(formName: 'Unbound').assetSlug, 'hoopa-unbound');
  });

  test('Oricorio usa candidati grafici distinti per ogni stile', () {
    final repository = PokemonRepository();
    return repository.getAllPokemon().then((pokemon) {
      final oricorio = pokemon.firstWhere((entry) => entry.id == 741);
      final pomPom = PokemonAssetPaths.imageCandidates(
        pokemon: oricorio,
        useLargeArtwork: true,
        formName: 'Pom-Pom',
      );
      final pau = PokemonAssetPaths.imageCandidates(
        pokemon: oricorio,
        useLargeArtwork: true,
        formName: "Pa'u",
      );
      final sensu = PokemonAssetPaths.imageCandidates(
        pokemon: oricorio,
        useLargeArtwork: true,
        formName: 'Sensu',
      );

      expect(
        pomPom,
        contains(
          'assets/textures/textures_webapp/pokemon/oricorio-pom-pom-style/main.png',
        ),
      );
      expect(
        pau,
        contains(
          'assets/textures/textures_webapp/pokemon/oricorio-pau-style/main.png',
        ),
      );
      expect(
        sensu,
        contains(
          'assets/textures/textures_webapp/pokemon/oricorio-sensu-style/main.png',
        ),
      );
    });
  });

  test('in italiano le forme senza testo dedicato non mantengono descrizioni inglesi', () async {
    GameCatalogLocale.setLanguageCode('it');
    PokemonRepository.clearCache();

    final pokemon = await PokemonRepository().getAllPokemon();
    final oricorio = pokemon.firstWhere((entry) => entry.id == 741);
    final pomPom = oricorio.resolveVariant(formName: 'Pom-Pom');

    expect(oricorio.description, isNotNull);
    expect(oricorio.description, isNotEmpty);
    expect(pomPom.description, oricorio.description);
    expect(pomPom.genus, oricorio.genus);
  });
}
