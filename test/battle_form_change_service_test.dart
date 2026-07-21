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
      'Zygarde',
      'Wishiwashi',
      'Minior',
      'Mimikyu',
      'Necrozma',
      'Cramorant',
      'Eiscue',
      'Morpeko',
      'Palafin',
      'Ogerpon',
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
    expect(
      BattleFormChangeService.canonicalFormKey(
        darmanitan,
        'Forma di Galar · Stato Zen',
      ),
      'galarian-zen',
    );
  });

  test(
    'Zygarde uses Forma 50% as base and keeps all three stat profiles',
    () async {
      final pokemon = await PokemonRepository().getAllPokemon();
      final zygarde = pokemon.firstWhere((entry) => entry.id == 718);

      expect(BattleFormChangeService.canonicalFormKey(zygarde, 'Base'), '50');
      expect(BattleFormChangeService.formLabel(zygarde, 'Base'), 'Forma 50%');
      expect(
        BattleFormChangeService.formLabel(zygarde, '10% Forme'),
        'Forma 10%',
      );
      expect(
        BattleFormChangeService.formLabel(zygarde, 'Complete Forme'),
        'Forma Perfetta',
      );

      final ten = zygarde.resolveVariant(formName: '10% Forme');
      final fifty = zygarde.resolveVariant(formName: '50% Forme');
      final complete = zygarde.resolveVariant(formName: 'Complete Forme');

      expect(ten.armorClass, 16);
      expect(ten.attributes.dexterity, 19);
      expect(fifty.armorClass, 18);
      expect(fifty.attributes.constitution, 20);
      expect(complete.armorClass, 20);
      expect(complete.attributes.constitution, 30);
    },
  );

  test(
    'Palafin Forma Possente applies battle-only CA, FOR and DES bonuses',
    () async {
      final pokemon = await PokemonRepository().getAllPokemon();
      final palafin = pokemon.firstWhere((entry) => entry.id == 964);

      expect(
        BattleFormChangeService.formLabel(palafin, 'Hero Form'),
        'Forma Possente',
      );
      expect(BattleFormChangeService.armorClassBonus(palafin, 'Hero Form'), 4);

      final modified = BattleFormChangeService.applyAttributeScoreModifiers(
        palafin,
        'Hero Form',
        const {'STR': 14, 'DEX': 18, 'CON': 16},
      );
      expect(modified['STR'], 18);
      expect(modified['DEX'], 22);
      expect(modified['CON'], 16);

      final base = BattleFormChangeService.applyAttributeScoreModifiers(
        palafin,
        'Base',
        const {'STR': 14, 'DEX': 18},
      );
      expect(base, const {'STR': 14, 'DEX': 18});
    },
  );
}
