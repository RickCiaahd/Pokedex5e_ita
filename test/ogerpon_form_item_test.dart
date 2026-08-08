import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/item_driven_pokemon_form.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Ogerpon form and Tera type are derived from the held mask', () {
    const expected = <String, (String, String)>{
      'teal-mask': ('Teal Mask', 'Grass'),
      'wellspring-mask': ('Wellspring Mask', 'Water'),
      'hearthflame-mask': ('Hearthflame Mask', 'Fire'),
      'cornerstone-mask': ('Cornerstone Mask', 'Rock'),
    };

    for (final entry in expected.entries) {
      expect(
        ItemDrivenPokemonForm.formNameForHeldItem(
          pokemonId: ItemDrivenPokemonForm.ogerponId,
          heldItem: entry.key,
        ),
        entry.value.$1,
      );
      expect(
        ItemDrivenPokemonForm.ogerponMaskType(entry.key),
        entry.value.$2,
      );

      final slot = TeamSlot(
        slotIndex: 0,
        pokemonId: ItemDrivenPokemonForm.ogerponId,
        formName: 'Wellspring Mask',
        heldItem: entry.key,
      );
      expect(slot.formName, isNull);
      expect(slot.effectiveFormName, entry.value.$1);
    }
  });

  test('Ogerpon repository variant follows the held mask typing and artwork', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final ogerpon = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.ogerponId,
    );
    const expected = <String, (Set<String>, String)>{
      'teal-mask': ({'grass'}, 'ogerpon'),
      'wellspring-mask': ({'grass', 'water'}, 'ogerpon-wellspring-mask'),
      'hearthflame-mask': ({'grass', 'fire'}, 'ogerpon-hearthflame-mask'),
      'cornerstone-mask': ({'grass', 'rock'}, 'ogerpon-cornerstone-mask'),
    };

    for (final entry in expected.entries) {
      final slot = TeamSlot(
        slotIndex: 0,
        pokemonId: ogerpon.id,
        heldItem: entry.key,
      );
      final resolved = ogerpon.resolveVariant(formName: slot.effectiveFormName);
      expect(
        resolved.types.map((type) => type.toLowerCase()).toSet(),
        entry.value.$1,
        reason: '${entry.key} deve aggiornare i tipi effettivi di Ogerpon',
      );
      expect(
        resolved.assetSlug,
        entry.value.$2,
        reason: '${entry.key} deve usare l artwork della maschera corretta',
      );
    }
  });

  test('localized Ogerpon mask names remain compatible', () {
    expect(
      ItemDrivenPokemonForm.formNameForHeldItem(
        pokemonId: ItemDrivenPokemonForm.ogerponId,
        heldItem: 'Maschera Pozzo',
      ),
      'Wellspring Mask',
    );
    expect(
      ItemDrivenPokemonForm.ogerponMaskType('Maschera Focolare'),
      'Fire',
    );
  });

  test('Ogerpon masks are present in the bag catalog', () async {
    final items = await ItemRepository().getWebItems();
    final ids = items.map((item) => item.id).toSet();

    expect(ids, containsAll(const <String>[
      'teal-mask',
      'wellspring-mask',
      'hearthflame-mask',
      'cornerstone-mask',
    ]));
  });

  test('Ogerpon mask forms are not exposed as independent manual choices', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final ogerpon = catalog.firstWhere(
      (pokemon) => pokemon.id == ItemDrivenPokemonForm.ogerponId,
    );

    expect(await PokemonAssetPaths.formChoices(ogerpon), isEmpty);
  });
}
