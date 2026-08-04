import 'dart:math';

import '../localization/ui_text.dart';
import '../models/battle_environment.dart';
import '../models/move_data.dart';
import '../models/pokemon.dart';
import '../models/pokemon_nature.dart';
import '../models/pokemon_type_localization.dart';
import '../models/team_slot.dart';

class BattleEnvironmentService {
  const BattleEnvironmentService._();

  static BattleWeather rollWeather(BattleSeason season, int d100) {
    final roll = d100.clamp(1, 100).toInt();
    if (season == BattleSeason.springSummer) {
      if (roll <= 25) return BattleWeather.harshSunCalm;
      if (roll <= 35) return BattleWeather.harshSunWindy;
      if (roll <= 65) return BattleWeather.cloudyCalm;
      if (roll <= 75) return BattleWeather.cloudyWindy;
      if (roll <= 80) return BattleWeather.foggy;
      if (roll <= 90) return BattleWeather.lightDrizzle;
      if (roll <= 99) return BattleWeather.heavyRain;
      return BattleWeather.dangerousStorm;
    }

    if (roll <= 15) return BattleWeather.harshSunCalm;
    if (roll <= 25) return BattleWeather.harshSunWindy;
    if (roll <= 40) return BattleWeather.cloudyCalm;
    if (roll <= 50) return BattleWeather.cloudyWindy;
    if (roll <= 60) return BattleWeather.foggy;
    if (roll <= 70) return BattleWeather.lightDrizzle;
    if (roll <= 80) return BattleWeather.heavyRain;
    if (roll <= 90) return BattleWeather.lightSnow;
    if (roll <= 99) return BattleWeather.heavySnow;
    return BattleWeather.blizzard;
  }

  static bool isHarshSun(BattleEnvironment environment) =>
      environment.weather == BattleWeather.harshSunCalm ||
      environment.weather == BattleWeather.harshSunWindy;

  static bool isRain(BattleEnvironment environment) =>
      environment.weather == BattleWeather.lightDrizzle ||
      environment.weather == BattleWeather.heavyRain ||
      environment.weather == BattleWeather.dangerousStorm;

  static bool isSnowOrHail(BattleEnvironment environment) =>
      environment.weather == BattleWeather.lightSnow ||
      environment.weather == BattleWeather.heavySnow ||
      environment.weather == BattleWeather.blizzard ||
      environment.weather == BattleWeather.hail;

  static bool isSandstorm(BattleEnvironment environment) =>
      environment.weather == BattleWeather.sandstorm;

  static Set<String> favoredMoveTypes(BattleEnvironment environment) {
    return switch (environment.weather) {
      BattleWeather.harshSunCalm => {'Grass', 'Ground', 'Fire'},
      BattleWeather.harshSunWindy => {
        'Grass',
        'Ground',
        'Fire',
        'Flying',
        'Dragon',
        'Psychic',
      },
      BattleWeather.cloudyCalm => {
        'Normal',
        'Rock',
        'Fairy',
        'Fighting',
        'Poison',
      },
      BattleWeather.cloudyWindy => {
        'Normal',
        'Rock',
        'Fairy',
        'Fighting',
        'Poison',
        'Flying',
        'Dragon',
        'Psychic',
      },
      BattleWeather.foggy => {'Dark', 'Ghost'},
      BattleWeather.lightDrizzle ||
      BattleWeather.heavyRain ||
      BattleWeather.dangerousStorm => {'Water', 'Electric', 'Bug'},
      BattleWeather.lightSnow ||
      BattleWeather.heavySnow ||
      BattleWeather.blizzard => {'Ice', 'Steel'},
      BattleWeather.clear ||
      BattleWeather.hail ||
      BattleWeather.sandstorm => const {},
    };
  }

  static String effectiveMoveType(
    MoveData move,
    BattleEnvironment environment,
  ) {
    if (_key(move.id) != 'weather-ball' && _key(move.name) != 'weather-ball') {
      return move.type;
    }
    if (isHarshSun(environment)) return 'Fire';
    if (isRain(environment)) return 'Water';
    if (isSandstorm(environment)) return 'Rock';
    if (isSnowOrHail(environment)) return 'Ice';
    return 'Normal';
  }

  static bool grantsWeatherDamageAdvantage({
    required BattleEnvironment environment,
    required MoveData move,
  }) {
    if (!environment.optionalWeatherDamageAdvantage || !_isDamagingMove(move)) {
      return false;
    }
    final effectiveType = effectiveMoveType(move, environment);
    return favoredMoveTypes(
      environment,
    ).any((type) => PokemonTypeLocalization.sameType(type, effectiveType));
  }

  static int terrainAttackRollBonus({
    required TeamSlot slot,
    required BattleEnvironment environment,
  }) {
    final adept = terrainAdeptTerrain(slot.feats);
    return adept != null && adept == environment.naturalTerrain ? 2 : 0;
  }

  static BattleNaturalTerrain? terrainAdeptTerrain(Iterable<String> feats) {
    for (final feat in feats) {
      final terrain = terrainFromFeat(feat);
      if (terrain != null) return terrain;
    }
    return null;
  }

  static BattleNaturalTerrain? terrainFromFeat(String feat) {
    final trimmed = feat.trim();
    if (!trimmed.toLowerCase().startsWith('terrain adept')) return null;
    final match = RegExp(
      r'terrain\s+adept\s*(?:\(|:|-)?\s*([^)]*)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    final selected = match?.group(1)?.trim().toLowerCase() ?? '';
    if (selected.isEmpty || selected == 'terrain adept') return null;
    for (final terrain in BattleNaturalTerrain.values) {
      if (terrain == BattleNaturalTerrain.none) continue;
      if (terrain.manualName.toLowerCase() == selected ||
          terrain.label.toLowerCase() == selected) {
        return terrain;
      }
    }
    return null;
  }

  static String featBaseName(String feat) =>
      feat.trim().toLowerCase().startsWith('terrain adept')
      ? 'Terrain Adept'
      : feat.trim();

  static String terrainAdeptFeat(BattleNaturalTerrain terrain) =>
      'Terrain Adept (${terrain.manualName})';

  static int baseArmorClass(Pokemon pokemon, TeamSlot slot) {
    final nature = PokemonNature.forName(slot.nature);
    final acUpCount = slot.feats
        .where((feat) => featBaseName(feat) == 'AC Up')
        .length;
    return pokemon.armorClass + (nature['AC'] ?? 0) + acUpCount;
  }

  static int armorClassBonus({
    required Pokemon pokemon,
    required TeamSlot slot,
    required BattleEnvironment environment,
  }) {
    final abilities = _abilityKeys(pokemon, slot);
    var bonus = 0;
    final weatherAllowed = !environment.suppressWeatherAbilities;

    if (abilities.contains('sand-veil') &&
        (environment.naturalTerrain == BattleNaturalTerrain.desert ||
            (weatherAllowed && isSandstorm(environment)))) {
      bonus = max(bonus, 2);
    }
    if (abilities.contains('snow-cloak') &&
        (environment.naturalTerrain == BattleNaturalTerrain.arctic ||
            (weatherAllowed && isSnowOrHail(environment)))) {
      bonus = max(bonus, 2);
    }
    if (abilities.contains('stone-veil') &&
        (environment.naturalTerrain == BattleNaturalTerrain.hill ||
            environment.naturalTerrain == BattleNaturalTerrain.mountain ||
            (weatherAllowed && isSandstorm(environment)))) {
      bonus = max(bonus, 2);
    }
    if (abilities.contains('grass-pelt') &&
        (environment.naturalTerrain == BattleNaturalTerrain.grassland ||
            environment.fieldTerrain == BattleFieldTerrain.grassy &&
                environment.hasFieldTerrain)) {
      bonus = max(bonus, 1);
    }
    return bonus;
  }

  static int effectiveSpeed({
    required int baseSpeed,
    required Pokemon pokemon,
    required TeamSlot slot,
    required BattleEnvironment environment,
  }) {
    if (baseSpeed <= 0) return baseSpeed;
    final abilities = _abilityKeys(pokemon, slot);
    var doubled = false;
    final weatherAllowed = !environment.suppressWeatherAbilities;

    if (weatherAllowed &&
        abilities.contains('chlorophyll') &&
        isHarshSun(environment)) {
      doubled = true;
    }
    if (weatherAllowed &&
        abilities.contains('swift-swim') &&
        isRain(environment)) {
      doubled = true;
    }
    if (abilities.contains('sand-rush') &&
        (environment.naturalTerrain == BattleNaturalTerrain.desert ||
            (weatherAllowed && isSandstorm(environment)))) {
      doubled = true;
    }
    if (abilities.contains('surge-surfer') &&
        environment.fieldTerrain == BattleFieldTerrain.electric &&
        environment.hasFieldTerrain) {
      doubled = true;
    }
    return doubled ? baseSpeed * 2 : baseSpeed;
  }

  static int damageRollBonus({
    required Pokemon pokemon,
    required TeamSlot slot,
    required BattleEnvironment environment,
  }) {
    if (environment.suppressWeatherAbilities) return 0;
    return _abilityKeys(pokemon, slot).contains('solar-power') &&
            isHarshSun(environment)
        ? 2
        : 0;
  }

  static int terrainMoveModifierBonus({
    required BattleEnvironment environment,
    required MoveData move,
    required int moveModifier,
  }) {
    if (!environment.hasFieldTerrain || !_isDamagingMove(move)) return 0;
    final type = effectiveMoveType(move, environment);
    final applies = switch (environment.fieldTerrain) {
      BattleFieldTerrain.electric => PokemonTypeLocalization.sameType(
        type,
        'Electric',
      ),
      BattleFieldTerrain.grassy => PokemonTypeLocalization.sameType(
        type,
        'Grass',
      ),
      BattleFieldTerrain.psychic => PokemonTypeLocalization.sameType(
        type,
        'Psychic',
      ),
      BattleFieldTerrain.none || BattleFieldTerrain.misty => false,
    };
    return applies ? moveModifier : 0;
  }

  static int? startTurnWeatherDamage({
    required Pokemon pokemon,
    required TeamSlot slot,
    required BattleEnvironment environment,
  }) {
    if (environment.weatherSourceLevel <= 0) return null;
    final abilities = _abilityKeys(pokemon, slot);
    if (environment.weather == BattleWeather.hail) {
      final immune =
          pokemon.types.any(
            (type) => PokemonTypeLocalization.sameType(type, 'Ice'),
          ) ||
          abilities.contains('snow-cloak');
      return immune ? 0 : (environment.weatherSourceLevel / 2).ceil();
    }
    if (environment.weather == BattleWeather.sandstorm) {
      final immuneType = pokemon.types.any(
        (type) => const [
          'Rock',
          'Steel',
          'Ground',
        ].any((immune) => PokemonTypeLocalization.sameType(type, immune)),
      );
      final immuneAbility =
          abilities.contains('sand-rush') || abilities.contains('sand-veil');
      return immuneType || immuneAbility
          ? 0
          : (environment.weatherSourceLevel / 2).ceil();
    }
    return null;
  }

  static List<String> pokemonNotes({
    required Pokemon pokemon,
    required TeamSlot slot,
    required int level,
    required int proficiency,
    required BattleEnvironment environment,
  }) {
    final notes = <String>[];
    final abilities = _abilityKeys(pokemon, slot);
    final weatherAllowed = !environment.suppressWeatherAbilities;

    if (environment.hasTimedWeather) {
      notes.add(
        uiTextForLanguage(
          '${environment.weather.label}: ${environment.weatherRoundsRemaining} round rimanenti.',
          '${environment.weather.englishLabel}: ${environment.weatherRoundsRemaining} rounds remaining.',
        ),
      );
    }
    if (environment.hasFieldTerrain) {
      notes.add(
        uiTextForLanguage(
          '${environment.fieldTerrain.label}: ${environment.fieldTerrainRoundsRemaining} round rimanenti.',
          '${environment.fieldTerrain.englishLabel}: ${environment.fieldTerrainRoundsRemaining} rounds remaining.',
        ),
      );
      switch (environment.fieldTerrain) {
        case BattleFieldTerrain.electric:
          notes.add(
            uiTextForLanguage(
              'Le creature a terra non possono dormire; le mosse Elettro raddoppiano il modificatore di caratteristica della mossa ai danni.',
              'Grounded creatures cannot fall asleep; Electric moves double the MOVE modifier added to damage.',
            ),
          );
          break;
        case BattleFieldTerrain.grassy:
          notes.add(
            uiTextForLanguage(
              'Fine turno: le creature a terra recuperano $proficiency HP; le mosse Erba raddoppiano il modificatore di caratteristica della mossa ai danni.',
              'End of turn: grounded creatures recover $proficiency HP; Grass moves double the MOVE modifier added to damage.',
            ),
          );
          break;
        case BattleFieldTerrain.misty:
          notes.add(
            uiTextForLanguage(
              'Le creature a terra non possono ricevere nuovi status.',
              'Grounded creatures cannot gain new conditions.',
            ),
          );
          break;
        case BattleFieldTerrain.psychic:
          notes.add(
            uiTextForLanguage(
              'Le creature a terra non possono usare azioni bonus; le mosse Psico raddoppiano il modificatore di caratteristica della mossa ai danni.',
              'Grounded creatures cannot use bonus actions; Psychic moves double the MOVE modifier added to damage.',
            ),
          );
          break;
        case BattleFieldTerrain.none:
          break;
      }
    }

    final hazard = startTurnWeatherDamage(
      pokemon: pokemon,
      slot: slot,
      environment: environment,
    );
    if (hazard != null) {
      if (hazard == 0) {
        notes.add(
          uiTextForLanguage(
            'È immune ai danni di ${environment.weather.label}.',
            'It is immune to ${environment.weather.englishLabel} damage.',
          ),
        );
      } else {
        notes.add(
          uiTextForLanguage(
            'Inizio turno: subisce $hazard danni da ${environment.weather.label}.',
            'Start of turn: takes $hazard damage from ${environment.weather.englishLabel}.',
          ),
        );
      }
    } else if ((environment.weather == BattleWeather.hail ||
            environment.weather == BattleWeather.sandstorm) &&
        environment.weatherSourceLevel == 0) {
      notes.add(
        uiTextForLanguage(
          '${environment.weather.label} naturale: secondo il manuale non infligge danni automatici.',
          'Natural ${environment.weather.englishLabel}: according to the manual it deals no automatic damage.',
        ),
      );
    }

    if (environment.suppressWeatherAbilities) {
      notes.add(
        uiTextForLanguage(
          'Air Lock / Cloud Nine attivo: i bonus e malus delle abilità legate al meteo sono soppressi.',
          'Air Lock / Cloud Nine active: bonuses and penalties from weather-related abilities are suppressed.',
        ),
      );
    }

    if (weatherAllowed && abilities.contains('dry-skin')) {
      if (isHarshSun(environment)) {
        notes.add(
          uiTextForLanguage(
            'Dry Skin - fine turno: subisce $proficiency danni.',
            'Dry Skin - end of turn: takes $proficiency damage.',
          ),
        );
      } else if (isRain(environment)) {
        notes.add(
          uiTextForLanguage(
            'Dry Skin - fine turno: recupera $proficiency HP.',
            'Dry Skin - end of turn: recovers $proficiency HP.',
          ),
        );
      }
    }
    if (weatherAllowed &&
        abilities.contains('ice-body') &&
        isSnowOrHail(environment)) {
      notes.add(
        uiTextForLanguage(
          'Ice Body - fine turno: recupera $proficiency HP.',
          'Ice Body - end of turn: recovers $proficiency HP.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('rain-dish') &&
        isRain(environment)) {
      notes.add(
        uiTextForLanguage(
          'Rain Dish - fine turno: recupera $proficiency HP.',
          'Rain Dish - end of turn: recovers $proficiency HP.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('healing-rain') &&
        isRain(environment)) {
      notes.add(
        uiTextForLanguage(
          'Healing Rain - azione: recupera $level HP.',
          'Healing Rain - action: recovers $level HP.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('hydration') &&
        (isRain(environment) ||
            environment.naturalTerrain == BattleNaturalTerrain.underwater)) {
      notes.add(
        uiTextForLanguage(
          'Hydration - immune agli status negativi in queste condizioni.',
          'Hydration - immune to negative conditions in these circumstances.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('leaf-guard') &&
        isHarshSun(environment)) {
      notes.add(
        uiTextForLanguage(
          'Leaf Guard - immune agli status negativi sotto il sole intenso.',
          'Leaf Guard - immune to negative conditions in harsh sunlight.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('flower-gift') &&
        isHarshSun(environment)) {
      notes.add(
        uiTextForLanguage(
          'Flower Gift - gli alleati entro 30 ft aggiungono +$proficiency ai danni.',
          'Flower Gift - allies within 30 ft add +$proficiency to damage.',
        ),
      );
    }
    if (weatherAllowed && abilities.contains('forecast')) {
      final form = isRain(environment)
          ? uiTextForLanguage('Acqua', 'Water')
          : isHarshSun(environment)
          ? uiTextForLanguage('Fuoco', 'Fire')
          : isSnowOrHail(environment)
          ? uiTextForLanguage('Ghiaccio', 'Ice')
          : uiTextForLanguage('Normale', 'Normal');
      notes.add(
        uiTextForLanguage(
          'Forecast - forma e tipo attuali: $form.',
          'Forecast - current form and type: $form.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('sand-force') &&
        isSandstorm(environment)) {
      notes.add(
        uiTextForLanguage(
          'Sand Force - lo STAB viene raddoppiato quando colpisce.',
          'Sand Force - STAB is doubled on a hit.',
        ),
      );
    }
    if (weatherAllowed &&
        abilities.contains('solar-power') &&
        isHarshSun(environment)) {
      notes.add(
        uiTextForLanguage(
          'Solar Power - +2 a tutti i tiri di danno.',
          'Solar Power - +2 to all damage rolls.',
        ),
      );
    }

    if (abilities.contains('drizzle')) {
      notes.add(
        uiTextForLanguage(
          'Drizzle - all’ingresso può impostare Pioggerella per 5 round.',
          'Drizzle - on entry it can set Light Drizzle for 5 rounds.',
        ),
      );
    }
    if (abilities.contains('drought')) {
      notes.add(
        uiTextForLanguage(
          'Drought - all’ingresso può impostare Sole intenso per 5 round.',
          'Drought - on entry it can set Harsh Sunlight for 5 rounds.',
        ),
      );
    }
    if (abilities.contains('sand-stream')) {
      notes.add(
        uiTextForLanguage(
          'Sand Stream - all’ingresso può impostare Tempesta di sabbia per 5 round.',
          'Sand Stream - on entry it can set Sandstorm for 5 rounds.',
        ),
      );
    }
    if (abilities.contains('snow-warning')) {
      notes.add(
        uiTextForLanguage(
          'Snow Warning - all’ingresso può impostare Grandine per 5 round.',
          'Snow Warning - on entry it can set Hail for 5 rounds.',
        ),
      );
    }
    if (abilities.contains('air-lock') || abilities.contains('cloud-nine')) {
      notes.add(
        uiTextForLanguage(
          'Questa abilità può sopprimere le abilità legate al meteo: attiva l’opzione nel pannello Ambiente.',
          'This ability can suppress weather-related abilities: enable the option in the Environment panel.',
        ),
      );
    }

    final adept = terrainAdeptTerrain(slot.feats);
    if (slot.feats.any((feat) => featBaseName(feat) == 'Terrain Adept')) {
      if (adept == null) {
        notes.add(
          uiTextForLanguage(
            'Terrain Adept non configurato: scegli il terreno dalla schermata Modifica Pokémon.',
            'Terrain Adept is not configured: choose a terrain on the Edit Pokémon screen.',
          ),
        );
      } else if (adept == environment.naturalTerrain) {
        notes.add(
          uiTextForLanguage(
            'Terrain Adept (${adept.label}) - +2 ai tiri per colpire.',
            'Terrain Adept (${adept.englishLabel}) - +2 to attack rolls.',
          ),
        );
      }
    }

    return notes;
  }

  static List<String> moveNotes({
    required BattleEnvironment environment,
    required MoveData move,
    required int moveModifier,
  }) {
    final notes = <String>[];
    final effectiveType = effectiveMoveType(move, environment);
    if (!PokemonTypeLocalization.sameType(effectiveType, move.type)) {
      notes.add(
        uiTextForLanguage(
          'Weather Ball: tipo ${PokemonTypeLocalization.italianLabel(effectiveType)}.',
          'Weather Ball: ${PokemonTypeLocalization.englishValue(effectiveType)} type.',
        ),
      );
    }
    if (grantsWeatherDamageAdvantage(environment: environment, move: move)) {
      notes.add(
        uiTextForLanguage(
          'Meteo: tira i danni due volte e usa il risultato migliore.',
          'Weather: roll damage twice and use the higher result.',
        ),
      );
    }
    final terrainBonus = terrainMoveModifierBonus(
      environment: environment,
      move: move,
      moveModifier: moveModifier,
    );
    if (terrainBonus != 0) {
      notes.add(
        uiTextForLanguage(
          '${environment.fieldTerrain.label}: modificatore di caratteristica della mossa raddoppiato (${terrainBonus >= 0 ? '+' : ''}$terrainBonus aggiuntivo).',
          '${environment.fieldTerrain.englishLabel}: MOVE modifier doubled (${terrainBonus >= 0 ? '+' : ''}$terrainBonus additional).',
        ),
      );
    }
    return notes;
  }

  static bool isEnvironmentMove(MoveData? move) {
    if (move == null) return false;
    return const {
      'rain-dance',
      'sunny-day',
      'hail',
      'sandstorm',
      'electric-terrain',
      'grassy-terrain',
      'misty-terrain',
      'psychic-terrain',
    }.contains(_key(move.id.isEmpty ? move.name : move.id));
  }

  static BattleEnvironment applyMove({
    required BattleEnvironment environment,
    required MoveData move,
    required int sourceLevel,
    String? heldItemId,
  }) {
    final key = _key(move.id.isEmpty ? move.name : move.id);
    final item = _key(heldItemId ?? '');
    switch (key) {
      case 'rain-dance':
        return environment.copyWith(
          weather: BattleWeather.heavyRain,
          weatherRoundsRemaining: 5 + (item == 'damp-rock' ? 3 : 0),
          weatherSourceLevel: sourceLevel,
        );
      case 'sunny-day':
        return environment.copyWith(
          weather: BattleWeather.harshSunCalm,
          weatherRoundsRemaining: 5 + (item == 'heat-rock' ? 3 : 0),
          weatherSourceLevel: sourceLevel,
        );
      case 'hail':
        return environment.copyWith(
          weather: BattleWeather.hail,
          weatherRoundsRemaining: 5 + (item == 'icy-rock' ? 3 : 0),
          weatherSourceLevel: sourceLevel,
        );
      case 'sandstorm':
        return environment.copyWith(
          weather: BattleWeather.sandstorm,
          weatherRoundsRemaining: 5 + (item == 'smooth-rock' ? 3 : 0),
          weatherSourceLevel: sourceLevel,
        );
      case 'electric-terrain':
        return environment.copyWith(
          fieldTerrain: BattleFieldTerrain.electric,
          fieldTerrainRoundsRemaining: 3,
        );
      case 'grassy-terrain':
        return environment.copyWith(
          fieldTerrain: BattleFieldTerrain.grassy,
          fieldTerrainRoundsRemaining: 3,
        );
      case 'misty-terrain':
        return environment.copyWith(
          fieldTerrain: BattleFieldTerrain.misty,
          fieldTerrainRoundsRemaining: 3,
        );
      case 'psychic-terrain':
        return environment.copyWith(
          fieldTerrain: BattleFieldTerrain.psychic,
          fieldTerrainRoundsRemaining: 3,
        );
    }
    return environment;
  }

  static String environmentMoveMessage(MoveData move) {
    final key = _key(move.id.isEmpty ? move.name : move.id);
    return switch (key) {
      'rain-dance' => uiTextForLanguage(
        'Rain Dance ha impostato Pioggia intensa.',
        'Rain Dance set Heavy Rain.',
      ),
      'sunny-day' => uiTextForLanguage(
        'Sunny Day ha impostato Sole intenso.',
        'Sunny Day set Harsh Sunlight.',
      ),
      'hail' => uiTextForLanguage(
        'Hail ha impostato Grandine.',
        'Hail was set.',
      ),
      'sandstorm' => uiTextForLanguage(
        'Sandstorm ha impostato Tempesta di sabbia.',
        'Sandstorm was set.',
      ),
      'electric-terrain' => uiTextForLanguage(
        'Electric Terrain è attivo per 3 round.',
        'Electric Terrain is active for 3 rounds.',
      ),
      'grassy-terrain' => uiTextForLanguage(
        'Grassy Terrain è attivo per 3 round.',
        'Grassy Terrain is active for 3 rounds.',
      ),
      'misty-terrain' => uiTextForLanguage(
        'Misty Terrain è attivo per 3 round.',
        'Misty Terrain is active for 3 rounds.',
      ),
      'psychic-terrain' => uiTextForLanguage(
        'Psychic Terrain è attivo per 3 round.',
        'Psychic Terrain is active for 3 rounds.',
      ),
      _ => '',
    };
  }

  static bool _isDamagingMove(MoveData move) =>
      move.damageByLevel.isNotEmpty ||
      move.damageModifier != null ||
      move.damageTypes.isNotEmpty;

  static Set<String> _abilityKeys(Pokemon pokemon, TeamSlot slot) {
    final selected = slot.abilities.isEmpty
        ? pokemon.abilities
        : slot.abilities;
    return selected.map(_key).where((value) => value.isNotEmpty).toSet();
  }

  static String _key(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
