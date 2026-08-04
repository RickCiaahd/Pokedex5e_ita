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

      expect(arceus.effectiveFormName, isNull);
      expect(silvally.effectiveFormName, isNull);
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

  test('Arceus and Silvally types follow their effective item forms', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final arceus = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.arceusId,
    );
    final silvally = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.silvallyId,
    );

    expect(arceus.resolveVariant(formName: 'Water').types, <String>['Water']);
    expect(silvally.resolveVariant(formName: 'Bug').types, <String>['Bug']);
  });

  test('item-driven forms are not exposed as manual choices', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final arceus = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.arceusId,
    );
    final silvally = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.silvallyId,
    );

    expect(await PokemonAssetPaths.formChoices(arceus), isEmpty);
    expect(await PokemonAssetPaths.formChoices(silvally), isEmpty);
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
}
