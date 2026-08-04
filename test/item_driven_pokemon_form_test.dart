import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/generated_pokemon.dart';
import 'package:pokedex_5e_ita/models/item_driven_pokemon_form.dart';
import 'package:pokedex_5e_ita/models/pc_pokemon.dart';
import 'package:pokedex_5e_ita/models/pokedex_entry.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/pokemon_generator_service.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('item-driven Pokémon forms', () {
    test('every Elemental Plate maps to the expected Arceus type', () {
      const expectedTypes = <String, String>{
        'draco-plate': 'Dragon',
        'dread-plate': 'Dark',
        'earth-plate': 'Ground',
        'Fist-plate': 'Fighting',
        'flame-plate': 'Fire',
        'icicle-plate': 'Ice',
        'insect-plate': 'Bug',
        'iron-plate': 'Steel',
        'meadow-plate': 'Grass',
        'mind-plate': 'Psychic',
        'pixie-plate': 'Fairy',
        'sky-plate': 'Flying',
        'splash-plate': 'Water',
        'spooky-plate': 'Ghost',
        'stone-plate': 'Rock',
        'toxic-plate': 'Poison',
        'zap-plate': 'Electric',
      };

      for (final entry in expectedTypes.entries) {
        expect(
          ItemDrivenPokemonForm.formNameForHeldItem(
            pokemonId: ItemDrivenPokemonForm.arceusId,
            heldItem: entry.key,
          ),
          entry.value,
        );
      }
    });

    test('every Memory Disc maps to the expected Silvally type', () {
      const expectedTypes = <String, String>{
        'bug-memory-disc': 'Bug',
        'dark-memory-disc': 'Dark',
        'dragon-memory-disc': 'Dragon',
        'electric-memory-disc': 'Electric',
        'fairy-memory-disc': 'Fairy',
        'fighting-memory-disc': 'Fighting',
        'fire-memory-disc': 'Fire',
        'flying-memory-disc': 'Flying',
        'ghost-memory-disc': 'Ghost',
        'grass-memory-disc': 'Grass',
        'ground-memory-disc': 'Ground',
        'ice-memory-disc': 'Ice',
        'poison-memory-disc': 'Poison',
        'psychic-memory-disc': 'Psychic',
        'rock-memory-disc': 'Rock',
        'steel-memory-disc': 'Steel',
        'water-memory-disc': 'Water',
      };

      for (final entry in expectedTypes.entries) {
        expect(
          ItemDrivenPokemonForm.formNameForHeldItem(
            pokemonId: ItemDrivenPokemonForm.silvallyId,
            heldItem: entry.key,
          ),
          entry.value,
        );
      }
    });

    test('every Module maps to the expected Genesect form and move type', () {
      const expected = <String, (String, String)>{
        'burn-drive': ('Burn', 'Fire'),
        'chill-drive': ('Chill', 'Ice'),
        'douse-drive': ('Douse', 'Water'),
        'shock-drive': ('Shock', 'Electric'),
      };

      for (final entry in expected.entries) {
        expect(
          ItemDrivenPokemonForm.formNameForHeldItem(
            pokemonId: ItemDrivenPokemonForm.genesectId,
            heldItem: entry.key,
          ),
          entry.value.$1,
        );
        expect(
          ItemDrivenPokemonForm.effectiveMoveType(
            pokemonId: ItemDrivenPokemonForm.genesectId,
            moveReference: 'Techno Blast',
            heldItem: entry.key,
            fallbackType: 'Varies',
          ),
          entry.value.$2,
        );
      }
    });

    test('Arceus derives its form from the held Elemental Plate', () {
      final slot = TeamSlot(
        slotIndex: 0,
        pokemonId: ItemDrivenPokemonForm.arceusId,
        formName: 'Fire',
        heldItem: 'splash-plate',
      );

      expect(slot.formName, isNull);
      expect(slot.effectiveFormName, 'Water');
    });

    test('Silvally derives its form from the held Memory Disc', () {
      final slot = TeamSlot(
        slotIndex: 0,
        pokemonId: ItemDrivenPokemonForm.silvallyId,
        formName: 'Dragon',
        heldItem: 'bug-memory-disc',
      );

      expect(slot.formName, isNull);
      expect(slot.effectiveFormName, 'Bug');
    });

    test('Genesect derives its visual form only from the held Module', () {
      final slot = TeamSlot(
        slotIndex: 0,
        pokemonId: ItemDrivenPokemonForm.genesectId,
        formName: 'Shock',
        heldItem: 'burn-drive',
      );

      expect(slot.formName, isNull);
      expect(slot.effectiveFormName, 'Burn');
    });

    test('missing or incompatible items restore the Normal base form', () {
      final arceus = TeamSlot(
        slotIndex: 0,
        pokemonId: ItemDrivenPokemonForm.arceusId,
        heldItem: 'bug-memory-disc',
      );
      final silvally = TeamSlot(
        slotIndex: 1,
        pokemonId: ItemDrivenPokemonForm.silvallyId,
        heldItem: 'flame-plate',
      );
      final genesect = TeamSlot(
        slotIndex: 2,
        pokemonId: ItemDrivenPokemonForm.genesectId,
        heldItem: 'water-memory-disc',
      );

      expect(arceus.effectiveFormName, isNull);
      expect(silvally.effectiveFormName, isNull);
      expect(genesect.effectiveFormName, isNull);
    });

    test('localized legacy item names remain compatible', () {
      expect(
        ItemDrivenPokemonForm.formNameForHeldItem(
          pokemonId: ItemDrivenPokemonForm.arceusId,
          heldItem: 'Lastrasaetta',
        ),
        'Electric',
      );
      expect(
        ItemDrivenPokemonForm.formNameForHeldItem(
          pokemonId: ItemDrivenPokemonForm.silvallyId,
          heldItem: 'ROM Acqua',
        ),
        'Water',
      );
      expect(
        ItemDrivenPokemonForm.formNameForHeldItem(
          pokemonId: ItemDrivenPokemonForm.genesectId,
          heldItem: 'Voltmodulo',
        ),
        'Shock',
      );
    });

    test('PC data also drops old manually selected forms', () {
      final stored = PcPokemon(
        id: 'silvally-test',
        pokemonId: ItemDrivenPokemonForm.silvallyId,
        formName: 'Ghost',
        heldItem: 'ghost-memory-disc',
      );

      expect(stored.formName, isNull);
      expect(stored.effectiveFormName, 'Ghost');
    });
  });

  test('item-driven variants have the expected Pokémon types', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final arceus = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.arceusId,
    );
    final silvally = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.silvallyId,
    );
    final genesect = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.genesectId,
    );

    expect(arceus.resolveVariant(formName: 'Water').types, <String>['Water']);
    expect(silvally.resolveVariant(formName: 'Bug').types, <String>['Bug']);
    expect(
      genesect.resolveVariant(formName: 'Burn').types,
      <String>['Bug', 'Steel'],
    );
  });

  test('item-driven forms are not exposed as manual choices', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final arceus = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.arceusId,
    );
    final silvally = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.silvallyId,
    );
    final genesect = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.genesectId,
    );

    expect(await PokemonAssetPaths.formChoices(arceus), isEmpty);
    expect(await PokemonAssetPaths.formChoices(silvally), isEmpty);
    expect(await PokemonAssetPaths.formChoices(genesect), isEmpty);
    expect(
      PokedexEntry.isTrackableForm('Arceus (Fire)', speciesName: 'Arceus'),
      isFalse,
    );
    expect(
      const PokemonGeneratorService().eligibleFormNames(
        arceus,
        const PokemonGeneratorFilters(),
      ),
      <String?>[null],
    );
    expect(
      const PokemonGeneratorService().eligibleFormNames(
        genesect,
        const PokemonGeneratorFilters(),
      ),
      <String?>[null],
    );
  });

  test(
    'type-specific artwork follows the documented filename convention',
    () async {
      final catalog = await PokemonRepository().getAllPokemon();
      final arceus = catalog.firstWhere(
        (pokemon) => pokemon.id == ItemDrivenPokemonForm.arceusId,
      );

      final artwork = PokemonAssetPaths.imageCandidates(
        pokemon: arceus,
        useLargeArtwork: true,
        formName: 'Water',
        isShiny: true,
      );
      final sprite = PokemonAssetPaths.imageCandidates(
        pokemon: arceus,
        useLargeArtwork: false,
        formName: 'Water',
        isShiny: true,
      );

      expect(
        artwork,
        contains(
          'assets/textures/textures_webapp/pokemon/arceus/main-water-shiny.webp',
        ),
      );
      expect(
        sprite,
        contains(
          'assets/textures/textures_webapp/pokemon/arceus/sprite-water-shiny.webp',
        ),
      );
    },
  );

  test('Genesect artwork follows the Module filename convention', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final genesect = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.genesectId,
    );

    final artwork = PokemonAssetPaths.imageCandidates(
      pokemon: genesect,
      useLargeArtwork: true,
      formName: 'Burn',
      isShiny: true,
    );
    final sprite = PokemonAssetPaths.imageCandidates(
      pokemon: genesect,
      useLargeArtwork: false,
      formName: 'Burn',
      isShiny: true,
    );

    expect(
      artwork,
      contains(
        'assets/textures/textures_webapp/pokemon/genesect/main-burn-shiny.webp',
      ),
    );
    expect(
      sprite,
      contains(
        'assets/textures/textures_webapp/pokemon/genesect/sprite-burn-shiny.webp',
      ),
    );
  });

  test('signature move types follow the held item and never use Varies', () {
    expect(
      ItemDrivenPokemonForm.effectiveMoveType(
        pokemonId: ItemDrivenPokemonForm.arceusId,
        moveReference: 'Judgment',
        heldItem: 'flame-plate',
        fallbackType: 'Varies',
      ),
      'Fire',
    );
    expect(
      ItemDrivenPokemonForm.effectiveMoveType(
        pokemonId: ItemDrivenPokemonForm.silvallyId,
        moveReference: 'Multi-Attack',
        heldItem: 'water-memory-disc',
        fallbackType: 'Varies',
      ),
      'Water',
    );
    expect(
      ItemDrivenPokemonForm.effectiveMoveType(
        pokemonId: ItemDrivenPokemonForm.genesectId,
        moveReference: 'Tecnobotto',
        heldItem: null,
        fallbackType: 'Varies',
      ),
      'Normal',
    );
  });
}
