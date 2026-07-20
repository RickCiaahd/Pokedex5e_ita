import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('battle form support covers in-combat transformations', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final byName = {for (final entry in pokemon) entry.name: entry};

    for (final name in const [
      'Deoxys',
      'Castform',
      'Cherrim',
      'Darmanitan',
      'Meloetta',
      'Aegislash',
      'Wishiwashi',
      'Minior',
      'Mimikyu',
      'Cramorant',
      'Eiscue',
      'Morpeko',
      'Palafin',
      'Terapagos',
    ]) {
      expect(
        BattleFormChangeService.supports(byName[name]!),
        isTrue,
        reason: name,
      );
    }
    expect(BattleFormChangeService.supports(byName['Pikachu']!), isFalse);
  });

  test('Deoxys uses official Italian form labels and 5e bonuses', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final deoxys = pokemon.firstWhere((entry) => entry.id == 386);

    expect(BattleFormChangeService.formLabel(deoxys, 'Base'), 'Forma Normale');
    expect(
      BattleFormChangeService.formLabel(deoxys, 'Attack'),
      'Forma Attacco',
    );
    expect(
      BattleFormChangeService.formLabel(deoxys, 'Defense'),
      'Forma Difesa',
    );
    expect(
      BattleFormChangeService.formLabel(deoxys, 'Speed'),
      'Forma Velocità',
    );
    expect(BattleFormChangeService.attackRollBonus(deoxys, 'Attack'), 5);
    expect(BattleFormChangeService.armorClassBonus(deoxys, 'Defense'), 3);
  });

  test('Darmanitan does not mix Unovan and Galarian battle forms', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final darmanitan = pokemon.firstWhere((entry) => entry.id == 555);
    final unovan = TeamSlot(slotIndex: 0, pokemonId: 555);
    final galarian = TeamSlot(
      slotIndex: 1,
      pokemonId: 555,
      formName: 'Galarian Darmanitan Standard Mode',
    );

    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: unovan,
        formName: 'Zen',
      ),
      isTrue,
    );
    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: unovan,
        formName: 'Galarian Zen',
      ),
      isFalse,
    );
    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: galarian,
        formName: 'Galarian Zen',
      ),
      isTrue,
    );
  });
}
