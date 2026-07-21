import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_gender_appearance.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_gender_asset_paths.dart';

Pokemon pokemon(int id, String name, {String? assetSlug}) {
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
    assetSlug: assetSlug,
  );
}

void main() {
  test('catalog contains all 102 visually dimorphic species', () {
    expect(PokemonGenderAppearance.visuallyDimorphicIds, hasLength(102));
  });

  test('well-known dimorphic species are recognized', () {
    for (final entry in const {
      25: 'Pikachu',
      202: 'Wobbuffet',
      449: 'Hippopotas',
      450: 'Hippowdon',
      668: 'Pyroar',
      678: 'Meowstic',
      876: 'Indeedee',
    }.entries) {
      expect(
        PokemonGenderAppearance.hasVisibleDifference(
          pokemon(entry.key, entry.value),
        ),
        isTrue,
        reason: entry.value,
      );
    }
  });

  test('female Pikachu uses canonical files inside the base folder', () {
    final candidates = PokemonGenderAssetPaths.candidates(
      pokemon: pokemon(25, 'Pikachu'),
      useLargeArtwork: true,
      gender: 'Femmina',
    );

    expect(
      candidates,
      contains(
        'assets/textures/textures_webapp/pokemon/pikachu/main-f.png',
      ),
    );
    expect(
      candidates,
      contains(
        'assets/textures/textures_webapp/pokemon/pikachu/main-female.png',
      ),
    );
  });

  test('shiny female Wobbuffet falls back to the same-sex normal sprite', () {
    final candidates = PokemonGenderAssetPaths.candidates(
      pokemon: pokemon(202, 'Wobbuffet'),
      useLargeArtwork: false,
      gender: 'female',
      isShiny: true,
    );

    const shiny =
        'assets/textures/textures_webapp/pokemon/wobbuffet/sprite-shiny-f.png';
    const normal =
        'assets/textures/textures_webapp/pokemon/wobbuffet/sprite-f.png';

    expect(candidates, contains(shiny));
    expect(candidates, contains(normal));
    expect(candidates.indexOf(shiny), lessThan(candidates.indexOf(normal)));
  });

  test('permanent forms may keep gender files in their own folder', () {
    final candidates = PokemonGenderAssetPaths.candidates(
      pokemon: pokemon(215, 'Sneasel'),
      useLargeArtwork: true,
      formName: 'Hisuian Sneasel',
      gender: 'female',
    );

    expect(
      candidates,
      contains(
        'assets/textures/textures_webapp/pokemon/sneasel-hisuian/main-f.png',
      ),
    );
    expect(
      candidates,
      contains(
        'assets/textures/textures_webapp/pokemon/hisuian-sneasel/main-f.png',
      ),
    );
    expect(
      candidates,
      contains(
        'assets/textures/textures_webapp/pokemon/sneasel-hisui/main-f.png',
      ),
    );
  });

  test('genderless and unspecified Pokémon add no extra candidates', () {
    expect(
      PokemonGenderAssetPaths.candidates(
        pokemon: pokemon(81, 'Magnemite'),
        useLargeArtwork: true,
        gender: 'genderless',
      ),
      isEmpty,
    );
    expect(
      PokemonGenderAssetPaths.candidates(
        pokemon: pokemon(25, 'Pikachu'),
        useLargeArtwork: true,
      ),
      isEmpty,
    );
  });
}
