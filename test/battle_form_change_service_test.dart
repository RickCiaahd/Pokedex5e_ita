import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/battle_environment.dart';
import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';

MoveData _move(String name, {bool damaging = false}) {
  return MoveData(
    id: MoveData.referenceKey(name),
    name: name,
    sourceName: name,
    type: 'Normal',
    pp: '10',
    range: '-',
    duration: '-',
    moveTime: '1 action',
    description: '',
    scaling: null,
    damageByLevel: damaging
        ? const {
            1: MoveDamage(amount: 1, diceMax: 6, isMoveDamage: true),
          }
        : const {},
    movePowers: const ['STR'],
    isAttack: damaging,
    save: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('battle form support covers automatic and controlled runtime forms', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final byName = {for (final entry in pokemon) entry.name: entry};
    const expectedSpecies = [
      'Deoxys',
      'Castform',
      'Cherrim',
      'Darmanitan',
      'Giratina',
      'Hoopa',
      'Keldeo',
      'Kyurem',
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
      'Oricorio',
      'Rotom',
      'Shaymin',
      'Tornadus',
      'Thundurus',
      'Landorus',
      'Enamorus',
      'Terapagos',
    ];

    final missing = expectedSpecies.where((name) => !byName.containsKey(name));
    expect(
      missing,
      isEmpty,
      reason: 'Specie attese non trovate nel catalogo: ${missing.join(', ')}',
    );
    for (final name in expectedSpecies) {
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

  test('Castform and Cherrim follow the registered weather', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final castform = catalog.firstWhere((entry) => entry.name == 'Castform');
    final cherrim = catalog.firstWhere((entry) => entry.name == 'Cherrim');
    final castformSlot = TeamSlot(
      slotIndex: 0,
      pokemonId: castform.id,
      abilities: const ['Forecast'],
    );
    final cherrimSlot = TeamSlot(slotIndex: 1, pokemonId: cherrim.id);

    expect(
      BattleFormChangeService.environmentForm(
        castform,
        castformSlot,
        const BattleEnvironment(weather: BattleWeather.harshSunCalm),
      ),
      'sunny',
    );
    expect(
      BattleFormChangeService.environmentForm(
        castform,
        castformSlot,
        const BattleEnvironment(weather: BattleWeather.heavyRain),
      ),
      'rainy',
    );
    expect(
      BattleFormChangeService.environmentForm(
        castform,
        castformSlot,
        const BattleEnvironment(weather: BattleWeather.hail),
      ),
      'snowy',
    );
    expect(
      BattleFormChangeService.environmentForm(
        castform,
        castformSlot,
        const BattleEnvironment(
          weather: BattleWeather.harshSunCalm,
          suppressWeatherAbilities: true,
        ),
      ),
      'Base',
    );
    expect(
      BattleFormChangeService.environmentForm(
        cherrim,
        cherrimSlot,
        const BattleEnvironment(weather: BattleWeather.harshSunWindy),
      ),
      'sunshine',
    );
  });

  test('Darmanitan switches Zen Mode at the half-HP threshold', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final darmanitan = catalog.firstWhere((entry) => entry.id == 555);
    final unovan = TeamSlot(
      slotIndex: 0,
      pokemonId: 555,
      abilities: const ['Zen Mode'],
    );
    final galarian = TeamSlot(
      slotIndex: 1,
      pokemonId: 555,
      formName: 'Galarian Darmanitan Standard Mode',
      abilities: const ['Zen Mode (Galarian)'],
    );

    expect(
      BattleFormChangeService.afterHpChange(
        pokemon: darmanitan,
        slot: unovan,
        currentFormName: 'Base',
        currentHp: 50,
        maxHp: 100,
      ).formName,
      'zen',
    );
    expect(
      BattleFormChangeService.afterHpChange(
        pokemon: darmanitan,
        slot: unovan,
        currentFormName: 'Zen',
        currentHp: 51,
        maxHp: 100,
      ).formName,
      'Base',
    );
    expect(
      BattleFormChangeService.afterHpChange(
        pokemon: darmanitan,
        slot: galarian,
        currentFormName: 'Galarian Standard',
        currentHp: 30,
        maxHp: 100,
      ).formName,
      'galar-zen',
    );

    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: unovan,
        formName: 'Galarian Zen',
      ),
      isFalse,
    );
  });

  test('Wishiwashi enforces level, turn, HP and short-rest lock', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final wishiwashi = catalog.firstWhere((entry) => entry.name == 'Wishiwashi');
    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: wishiwashi.id,
      experience: 6000,
      abilities: const ['Schooling'],
    );

    expect(
      BattleFormChangeService.wishiwashiSchoolEligibility(
        pokemon: wishiwashi,
        slot: slot,
        currentHp: 26,
        maxHp: 100,
        ruleState: const {},
        isTurnStart: true,
      ).isAvailable,
      isTrue,
    );
    expect(
      BattleFormChangeService.wishiwashiSchoolEligibility(
        pokemon: wishiwashi,
        slot: slot,
        currentHp: 25,
        maxHp: 100,
        ruleState: const {},
        isTurnStart: true,
      ).isAvailable,
      isFalse,
    );
    expect(
      BattleFormChangeService.wishiwashiSchoolEligibility(
        pokemon: wishiwashi,
        slot: slot,
        currentHp: 60,
        maxHp: 100,
        ruleState: const {},
        isTurnStart: false,
      ).isAvailable,
      isFalse,
    );
    expect(
      BattleFormChangeService.wishiwashiSchoolEligibility(
        pokemon: wishiwashi,
        slot: slot,
        currentHp: 60,
        maxHp: 100,
        ruleState: const {
          BattleFormChangeService.wishiwashiSchoolingLockedKey: 1,
        },
        isTurnStart: true,
      ).isAvailable,
      isFalse,
    );

    final revert = BattleFormChangeService.afterHpChange(
      pokemon: wishiwashi,
      slot: slot,
      currentFormName: 'School Form',
      currentHp: 24,
      maxHp: 100,
    );
    expect(revert.formName, 'Base');
    expect(revert.lockWishiwashiSchooling, isTrue);
  });

  test('Meloetta and Aegislash react to the move actually used', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final meloetta = catalog.firstWhere((entry) => entry.name == 'Meloetta');
    final aegislash = catalog.firstWhere((entry) => entry.name == 'Aegislash');
    final meloettaSlot = TeamSlot(slotIndex: 0, pokemonId: meloetta.id);
    final aegislashSlot = TeamSlot(
      slotIndex: 1,
      pokemonId: aegislash.id,
      abilities: const ['Stance Change'],
    );

    expect(
      BattleFormChangeService.formAfterMove(
        pokemon: meloetta,
        slot: meloettaSlot,
        currentFormName: 'Base',
        move: _move('Relic Song'),
      ),
      'pirouette',
    );
    expect(
      BattleFormChangeService.formAfterMove(
        pokemon: meloetta,
        slot: meloettaSlot,
        currentFormName: 'Pirouette',
        move: _move('Relic Song'),
      ),
      'Base',
    );
    expect(
      BattleFormChangeService.formAfterMove(
        pokemon: aegislash,
        slot: aegislashSlot,
        currentFormName: 'Base',
        move: _move("King's Shield"),
      ),
      'shield',
    );
    expect(
      BattleFormChangeService.formAfterMove(
        pokemon: aegislash,
        slot: aegislashSlot,
        currentFormName: 'Shield',
        move: _move('Slash', damaging: true),
      ),
      'Base',
    );
  });

  test('Zygarde Power Construct upgrades and fully heals', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final zygarde = catalog.firstWhere((entry) => entry.id == 718);
    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: zygarde.id,
      abilities: const ['Power Construct'],
    );

    final ten = BattleFormChangeService.afterHpChange(
      pokemon: zygarde,
      slot: slot,
      currentFormName: '10% Forme',
      currentHp: 49,
      maxHp: 100,
    );
    expect(ten.formName, '50');
    expect(ten.restoreToFull, isTrue);

    final fifty = BattleFormChangeService.afterHpChange(
      pokemon: zygarde,
      slot: slot,
      currentFormName: '50% Forme',
      currentHp: 49,
      maxHp: 100,
    );
    expect(fifty.formName, 'complete');
    expect(fifty.restoreToFull, isTrue);
  });

  test('Minior, Eiscue and Morpeko follow their automatic triggers', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final minior = catalog.firstWhere((entry) => entry.name == 'Minior');
    final eiscue = catalog.firstWhere((entry) => entry.name == 'Eiscue');
    final morpeko = catalog.firstWhere((entry) => entry.name == 'Morpeko');
    final miniorSlot = TeamSlot(
      slotIndex: 0,
      pokemonId: minior.id,
      abilities: const ['Shields Down'],
    );
    final eiscueSlot = TeamSlot(
      slotIndex: 1,
      pokemonId: eiscue.id,
      abilities: const ['Ice Face'],
    );
    final morpekoSlot = TeamSlot(
      slotIndex: 2,
      pokemonId: morpeko.id,
      abilities: const ['Hunger Switch'],
    );

    expect(
      BattleFormChangeService.afterHpChange(
        pokemon: minior,
        slot: miniorSlot,
        currentFormName: 'Base',
        currentHp: 49,
        maxHp: 100,
      ).formName,
      'core-red',
    );

    final iceFace = BattleFormChangeService.onIncomingDamage(
      pokemon: eiscue,
      slot: eiscueSlot,
      currentFormName: 'Base',
      damage: 12,
    );
    expect(iceFace.damage, 6);
    expect(iceFace.formName, 'noice-face');
    expect(BattleFormChangeService.armorClassBonus(eiscue, 'Noice Face'), -3);
    expect(BattleFormChangeService.speedBonus(eiscue, 'Noice Face'), 5);
    expect(
      BattleFormChangeService.formAtTurnStart(
        pokemon: eiscue,
        slot: eiscueSlot,
        currentFormName: 'Noice Face',
        environment: const BattleEnvironment(weather: BattleWeather.hail),
      ),
      'Base',
    );

    expect(
      BattleFormChangeService.formAtTurnStart(
        pokemon: morpeko,
        slot: morpekoSlot,
        currentFormName: 'Base',
        environment: const BattleEnvironment(),
      ),
      'hangry',
    );
    expect(
      BattleFormChangeService.formAtTurnStart(
        pokemon: morpeko,
        slot: morpekoSlot,
        currentFormName: 'Hangry Mode',
        environment: const BattleEnvironment(),
      ),
      'Base',
    );
  });

  test('Palafin Hero form requires its trigger and is once per long rest', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final palafin = catalog.firstWhere((entry) => entry.id == 964);
    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: palafin.id,
      abilities: const ['Zero to Hero'],
    );
    final token = BattleFormChangeService.palafinLongRestUseToken(slot);

    final available = BattleFormChangeService.palafinHeroEligibility(
      pokemon: palafin,
      slot: slot,
      longRestUses: const {},
    );
    expect(available.isAvailable, isTrue);
    expect(available.confirmationText, isNotNull);

    final spent = BattleFormChangeService.palafinHeroEligibility(
      pokemon: palafin,
      slot: slot,
      longRestUses: {token},
    );
    expect(spent.isAvailable, isFalse);

    expect(BattleFormChangeService.armorClassBonus(palafin, 'Hero Form'), 4);
    final modified = BattleFormChangeService.applyAttributeScoreModifiers(
      palafin,
      'Hero Form',
      const {'STR': 14, 'DEX': 18, 'CON': 16},
    );
    expect(modified['STR'], 18);
    expect(modified['DEX'], 22);
    expect(modified['CON'], 16);
  });

  test('Cramorant does not invent Gulping or Gorging conditions', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final cramorant = catalog.firstWhere((entry) => entry.name == 'Cramorant');
    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: cramorant.id,
      abilities: const ['Gulp Missile'],
    );

    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: cramorant,
        slot: slot,
        formName: 'Gulping Form',
      ),
      isFalse,
    );
    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: cramorant,
        slot: slot,
        formName: 'Base',
      ),
      isTrue,
    );
    expect(
      BattleFormChangeService.cramorantMoveCue(
        cramorant,
        slot,
        _move('Surf'),
      ),
      isNotNull,
    );
  });

  test('Keldeo Resolute form follows Secret Sword', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final keldeo = catalog.firstWhere((entry) => entry.name == 'Keldeo');

    expect(
      BattleFormChangeService.ruleFormAtBattleStart(
        keldeo,
        TeamSlot(
          slotIndex: 0,
          pokemonId: keldeo.id,
          selectedMoves: const ['Secret Sword'],
        ),
        const BattleEnvironment(),
      ),
      'resolute',
    );
    expect(
      BattleFormChangeService.ruleFormAtBattleStart(
        keldeo,
        TeamSlot(slotIndex: 1, pokemonId: keldeo.id),
        const BattleEnvironment(),
      ),
      'Base',
    );
  });

  test('item and companion requirements guard persistent form changes', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final necrozma = catalog.firstWhere((entry) => entry.name == 'Necrozma');
    final kyurem = catalog.firstWhere((entry) => entry.name == 'Kyurem');
    final hoopa = catalog.firstWhere((entry) => entry.name == 'Hoopa');
    final giratina = catalog.firstWhere((entry) => entry.name == 'Giratina');
    final oricorio = catalog.firstWhere((entry) => entry.name == 'Oricorio');
    final shaymin = catalog.firstWhere((entry) => entry.name == 'Shaymin');
    final landorus = catalog.firstWhere((entry) => entry.name == 'Landorus');

    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: necrozma,
        slot: TeamSlot(slotIndex: 0, pokemonId: necrozma.id),
        targetFormName: 'Dusk Mane',
        inventoryItemIds: const {},
        teamPokemonIds: const {},
      ).isAvailable,
      isFalse,
    );
    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: necrozma,
        slot: TeamSlot(slotIndex: 0, pokemonId: necrozma.id),
        targetFormName: 'Dusk Mane',
        inventoryItemIds: const {'n-solarizer'},
        teamPokemonIds: const {791},
      ).isAvailable,
      isTrue,
    );
    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: kyurem,
        slot: TeamSlot(slotIndex: 1, pokemonId: kyurem.id),
        targetFormName: 'Black',
        inventoryItemIds: const {'dna-splicer'},
        teamPokemonIds: const {644},
      ).isAvailable,
      isTrue,
    );
    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: hoopa,
        slot: TeamSlot(slotIndex: 2, pokemonId: hoopa.id),
        targetFormName: 'Unbound',
        inventoryItemIds: const {'prison-bottle'},
        teamPokemonIds: const {},
      ).isAvailable,
      isTrue,
    );
    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: giratina,
        slot: TeamSlot(slotIndex: 3, pokemonId: giratina.id),
        targetFormName: 'Origin',
        inventoryItemIds: const {},
        teamPokemonIds: const {},
      ).confirmationText,
      isNotNull,
    );

    final nectar = BattleFormChangeService.manualEligibility(
      pokemon: oricorio,
      slot: TeamSlot(slotIndex: 4, pokemonId: oricorio.id),
      targetFormName: 'Baile Style',
      inventoryItemIds: const {'red-nectar'},
      teamPokemonIds: const {},
    );
    expect(nectar.isAvailable, isTrue);
    expect(nectar.consumeItemId, 'red-nectar');

    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: shaymin,
        slot: TeamSlot(
          slotIndex: 5,
          pokemonId: shaymin.id,
          heldItem: 'gracidea-flower',
        ),
        targetFormName: 'Sky Forme',
        inventoryItemIds: const {},
        teamPokemonIds: const {},
      ).isAvailable,
      isTrue,
    );
    expect(
      BattleFormChangeService.manualEligibility(
        pokemon: landorus,
        slot: TeamSlot(
          slotIndex: 6,
          pokemonId: landorus.id,
          heldItem: 'reveal-glass',
        ),
        targetFormName: 'Therian Forme',
        inventoryItemIds: const {},
        teamPokemonIds: const {},
      ).isAvailable,
      isTrue,
    );
  });

  test('Terapagos Tera Shift uses are based on CON modifier', () async {
    final catalog = await PokemonRepository().getAllPokemon();
    final terapagos = catalog.firstWhere((entry) => entry.name == 'Terapagos');

    expect(
      BattleFormChangeService.terapagosDailyShiftUses(
        terapagos,
        TeamSlot(
          slotIndex: 0,
          pokemonId: terapagos.id,
          customAbilityScores: const {'CON': 18},
        ),
      ),
      4,
    );
  });
}
