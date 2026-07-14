import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/models/battle_environment.dart';
import 'package:pokedex_5e_ita/models/battle_session.dart';
import 'package:pokedex_5e_ita/models/move_data.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/services/battle_environment_service.dart';

void main() {
  test('la tabella meteo rispetta i confini stagionali del manuale', () {
    expect(
      BattleEnvironmentService.rollWeather(BattleSeason.springSummer, 25),
      BattleWeather.harshSunCalm,
    );
    expect(
      BattleEnvironmentService.rollWeather(BattleSeason.springSummer, 26),
      BattleWeather.harshSunWindy,
    );
    expect(
      BattleEnvironmentService.rollWeather(BattleSeason.fallWinter, 81),
      BattleWeather.lightSnow,
    );
    expect(
      BattleEnvironmentService.rollWeather(BattleSeason.fallWinter, 100),
      BattleWeather.blizzard,
    );
  });

  test('il vantaggio opzionale usa il tipo della mossa e Weather Ball', () {
    const environment = BattleEnvironment(
      weather: BattleWeather.heavyRain,
      optionalWeatherDamageAdvantage: true,
    );
    final weatherBall = _move('Weather Ball', 'Normal');
    expect(
      BattleEnvironmentService.effectiveMoveType(weatherBall, environment),
      'Water',
    );
    expect(
      BattleEnvironmentService.grantsWeatherDamageAdvantage(
        environment: environment,
        move: weatherBall,
      ),
      isTrue,
    );
  });

  test('Terrain Adept configurato concede +2 solo nel terreno scelto', () {
    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: 1,
      feats: const ['Terrain Adept (Forest)'],
    );
    expect(
      BattleEnvironmentService.terrainAttackRollBonus(
        slot: slot,
        environment: const BattleEnvironment(
          naturalTerrain: BattleNaturalTerrain.forest,
        ),
      ),
      2,
    );
    expect(
      BattleEnvironmentService.terrainAttackRollBonus(
        slot: slot,
        environment: const BattleEnvironment(
          naturalTerrain: BattleNaturalTerrain.desert,
        ),
      ),
      0,
    );
  });

  test('abilità ambientali modificano CA, velocità e danni', () {
    final pokemon = _pokemon(abilities: const ['Sand Veil', 'Solar Power']);
    final slot = TeamSlot(
      slotIndex: 0,
      pokemonId: 1,
      abilities: const ['Sand Veil', 'Solar Power'],
    );
    const desertSun = BattleEnvironment(
      weather: BattleWeather.harshSunCalm,
      naturalTerrain: BattleNaturalTerrain.desert,
    );
    expect(
      BattleEnvironmentService.armorClassBonus(
        pokemon: pokemon,
        slot: slot,
        environment: desertSun,
      ),
      2,
    );
    expect(
      BattleEnvironmentService.damageRollBonus(
        pokemon: pokemon,
        slot: slot,
        environment: desertSun,
      ),
      2,
    );

    final swift = _pokemon(abilities: const ['Swift Swim']);
    final swiftSlot = TeamSlot(
      slotIndex: 0,
      pokemonId: 1,
      abilities: const ['Swift Swim'],
    );
    expect(
      BattleEnvironmentService.effectiveSpeed(
        baseSpeed: 30,
        pokemon: swift,
        slot: swiftSlot,
        environment: const BattleEnvironment(
          weather: BattleWeather.lightDrizzle,
        ),
      ),
      60,
    );
  });

  test('Grandine e Tempesta di sabbia rispettano immunità e livello', () {
    final normal = _pokemon();
    final normalSlot = TeamSlot(slotIndex: 0, pokemonId: 1);
    expect(
      BattleEnvironmentService.startTurnWeatherDamage(
        pokemon: normal,
        slot: normalSlot,
        environment: const BattleEnvironment(
          weather: BattleWeather.hail,
          weatherSourceLevel: 5,
        ),
      ),
      3,
    );

    final rock = _pokemon(types: const ['Rock']);
    expect(
      BattleEnvironmentService.startTurnWeatherDamage(
        pokemon: rock,
        slot: normalSlot,
        environment: const BattleEnvironment(
          weather: BattleWeather.sandstorm,
          weatherSourceLevel: 9,
        ),
      ),
      0,
    );
  });

  test('durate e ambiente sopravvivono al salvataggio della battaglia', () {
    const environment = BattleEnvironment(
      season: BattleSeason.fallWinter,
      weather: BattleWeather.hail,
      weatherRoundsRemaining: 5,
      weatherSourceLevel: 8,
      naturalTerrain: BattleNaturalTerrain.arctic,
      fieldTerrain: BattleFieldTerrain.misty,
      fieldTerrainRoundsRemaining: 3,
      optionalWeatherDamageAdvantage: true,
    );
    final session = BattleSession(
      profileId: 'profile',
      round: 2,
      turnIndex: 0,
      activeSlotIndex: 0,
      pokemonStates: const {},
      initiativeEntries: const [],
      environment: environment,
      updatedAt: DateTime(2026),
    );
    final restored = BattleSession.fromJson(session.toJson());
    expect(restored.environment.weather, BattleWeather.hail);
    expect(restored.environment.weatherRoundsRemaining, 5);
    expect(restored.environment.naturalTerrain, BattleNaturalTerrain.arctic);
    expect(restored.environment.fieldTerrain, BattleFieldTerrain.misty);

    final advanced = restored.environment.advanceRound();
    expect(advanced.weatherRoundsRemaining, 4);
    expect(advanced.fieldTerrainRoundsRemaining, 2);
  });
}

MoveData _move(String name, String type) {
  return MoveData(
    id: MoveData.referenceKey(name),
    name: name,
    type: type,
    pp: '5',
    range: '30ft',
    duration: 'Instantaneous',
    moveTime: '1 action',
    description: '',
    scaling: null,
    damageByLevel: const {
      1: MoveDamage(amount: 1, diceMax: 8, isMoveDamage: true),
    },
    movePowers: const ['DEX'],
    isAttack: true,
    save: null,
  );
}

Pokemon _pokemon({
  List<String> types = const ['Normal'],
  List<String> abilities = const [],
}) {
  return Pokemon(
    id: 1,
    name: 'Testmon',
    types: types,
    armorClass: 12,
    hitPoints: 10,
    size: 'Small',
    speed: 30,
    attributes: const PokemonAttributes(
      strength: 10,
      dexterity: 10,
      constitution: 10,
      intelligence: 10,
      wisdom: 10,
      charisma: 10,
    ),
    abilities: abilities,
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(
      startingMoves: [],
      levelMoves: {},
      tmMoves: [],
      eggMoves: [],
    ),
    hitDice: 6,
    sr: 0.25,
    minLevelFound: 1,
  );
}
