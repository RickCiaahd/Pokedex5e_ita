enum BattleSeason { springSummer, fallWinter }

enum BattleWeather {
  clear,
  harshSunCalm,
  harshSunWindy,
  cloudyCalm,
  cloudyWindy,
  foggy,
  lightDrizzle,
  heavyRain,
  dangerousStorm,
  lightSnow,
  heavySnow,
  blizzard,
  hail,
  sandstorm,
}

enum BattleNaturalTerrain {
  none,
  coastal,
  swamp,
  forest,
  arctic,
  desert,
  grassland,
  hill,
  mountain,
  underwater,
}

enum BattleFieldTerrain { none, electric, grassy, misty, psychic }

extension BattleSeasonLabel on BattleSeason {
  String get label => switch (this) {
    BattleSeason.springSummer => 'Primavera / Estate',
    BattleSeason.fallWinter => 'Autunno / Inverno',
  };
}

extension BattleWeatherLabel on BattleWeather {
  String get label => switch (this) {
    BattleWeather.clear => 'Nessun meteo',
    BattleWeather.harshSunCalm => 'Sole intenso, calma',
    BattleWeather.harshSunWindy => 'Sole intenso, vento',
    BattleWeather.cloudyCalm => 'Nuvoloso, calma',
    BattleWeather.cloudyWindy => 'Nuvoloso, vento',
    BattleWeather.foggy => 'Nebbia',
    BattleWeather.lightDrizzle => 'Pioggerella',
    BattleWeather.heavyRain => 'Pioggia intensa',
    BattleWeather.dangerousStorm => 'Tempesta pericolosa',
    BattleWeather.lightSnow => 'Neve leggera',
    BattleWeather.heavySnow => 'Neve intensa',
    BattleWeather.blizzard => 'Bufera',
    BattleWeather.hail => 'Grandine',
    BattleWeather.sandstorm => 'Tempesta di sabbia',
  };
}

extension BattleNaturalTerrainLabel on BattleNaturalTerrain {
  String get label => switch (this) {
    BattleNaturalTerrain.none => 'Nessuno',
    BattleNaturalTerrain.coastal => 'Costa',
    BattleNaturalTerrain.swamp => 'Palude',
    BattleNaturalTerrain.forest => 'Foresta',
    BattleNaturalTerrain.arctic => 'Artico',
    BattleNaturalTerrain.desert => 'Deserto',
    BattleNaturalTerrain.grassland => 'Prateria',
    BattleNaturalTerrain.hill => 'Collina',
    BattleNaturalTerrain.mountain => 'Montagna',
    BattleNaturalTerrain.underwater => 'Subacqueo',
  };

  String get manualName => switch (this) {
    BattleNaturalTerrain.none => 'None',
    BattleNaturalTerrain.coastal => 'Coastal',
    BattleNaturalTerrain.swamp => 'Swamp',
    BattleNaturalTerrain.forest => 'Forest',
    BattleNaturalTerrain.arctic => 'Arctic',
    BattleNaturalTerrain.desert => 'Desert',
    BattleNaturalTerrain.grassland => 'Grassland',
    BattleNaturalTerrain.hill => 'Hill',
    BattleNaturalTerrain.mountain => 'Mountain',
    BattleNaturalTerrain.underwater => 'Underwater',
  };
}

extension BattleFieldTerrainLabel on BattleFieldTerrain {
  String get label => switch (this) {
    BattleFieldTerrain.none => 'Nessuno',
    BattleFieldTerrain.electric => 'Terreno Elettrico',
    BattleFieldTerrain.grassy => 'Terreno Erboso',
    BattleFieldTerrain.misty => 'Terreno Nebbioso',
    BattleFieldTerrain.psychic => 'Terreno Psichico',
  };
}

class BattleEnvironment {
  const BattleEnvironment({
    this.season = BattleSeason.springSummer,
    this.weather = BattleWeather.clear,
    this.weatherRoundsRemaining = 0,
    this.weatherSourceLevel = 0,
    this.naturalTerrain = BattleNaturalTerrain.none,
    this.fieldTerrain = BattleFieldTerrain.none,
    this.fieldTerrainRoundsRemaining = 0,
    this.optionalWeatherDamageAdvantage = false,
    this.suppressWeatherAbilities = false,
  });

  final BattleSeason season;
  final BattleWeather weather;
  final int weatherRoundsRemaining;
  final int weatherSourceLevel;
  final BattleNaturalTerrain naturalTerrain;
  final BattleFieldTerrain fieldTerrain;
  final int fieldTerrainRoundsRemaining;
  final bool optionalWeatherDamageAdvantage;
  final bool suppressWeatherAbilities;

  bool get hasWeather => weather != BattleWeather.clear;
  bool get hasTimedWeather => hasWeather && weatherRoundsRemaining > 0;
  bool get hasFieldTerrain =>
      fieldTerrain != BattleFieldTerrain.none &&
      fieldTerrainRoundsRemaining > 0;

  BattleEnvironment copyWith({
    BattleSeason? season,
    BattleWeather? weather,
    int? weatherRoundsRemaining,
    int? weatherSourceLevel,
    BattleNaturalTerrain? naturalTerrain,
    BattleFieldTerrain? fieldTerrain,
    int? fieldTerrainRoundsRemaining,
    bool? optionalWeatherDamageAdvantage,
    bool? suppressWeatherAbilities,
  }) {
    return BattleEnvironment(
      season: season ?? this.season,
      weather: weather ?? this.weather,
      weatherRoundsRemaining:
          (weatherRoundsRemaining ?? this.weatherRoundsRemaining)
              .clamp(0, 99)
              .toInt(),
      weatherSourceLevel: (weatherSourceLevel ?? this.weatherSourceLevel)
          .clamp(0, 20)
          .toInt(),
      naturalTerrain: naturalTerrain ?? this.naturalTerrain,
      fieldTerrain: fieldTerrain ?? this.fieldTerrain,
      fieldTerrainRoundsRemaining:
          (fieldTerrainRoundsRemaining ?? this.fieldTerrainRoundsRemaining)
              .clamp(0, 99)
              .toInt(),
      optionalWeatherDamageAdvantage:
          optionalWeatherDamageAdvantage ?? this.optionalWeatherDamageAdvantage,
      suppressWeatherAbilities:
          suppressWeatherAbilities ?? this.suppressWeatherAbilities,
    );
  }

  BattleEnvironment advanceRound() {
    var nextWeather = weather;
    var nextWeatherRounds = weatherRoundsRemaining;
    var nextSourceLevel = weatherSourceLevel;
    if (nextWeatherRounds > 0) {
      nextWeatherRounds -= 1;
      if (nextWeatherRounds == 0) {
        nextWeather = BattleWeather.clear;
        nextSourceLevel = 0;
      }
    }

    var nextField = fieldTerrain;
    var nextFieldRounds = fieldTerrainRoundsRemaining;
    if (nextFieldRounds > 0) {
      nextFieldRounds -= 1;
      if (nextFieldRounds == 0) nextField = BattleFieldTerrain.none;
    }

    return copyWith(
      weather: nextWeather,
      weatherRoundsRemaining: nextWeatherRounds,
      weatherSourceLevel: nextSourceLevel,
      fieldTerrain: nextField,
      fieldTerrainRoundsRemaining: nextFieldRounds,
    );
  }

  Map<String, dynamic> toJson() => {
    'season': season.name,
    'weather': weather.name,
    'weatherRoundsRemaining': weatherRoundsRemaining,
    'weatherSourceLevel': weatherSourceLevel,
    'naturalTerrain': naturalTerrain.name,
    'fieldTerrain': fieldTerrain.name,
    'fieldTerrainRoundsRemaining': fieldTerrainRoundsRemaining,
    'optionalWeatherDamageAdvantage': optionalWeatherDamageAdvantage,
    'suppressWeatherAbilities': suppressWeatherAbilities,
  };

  factory BattleEnvironment.fromJson(Map<String, dynamic> json) {
    T readEnum<T extends Enum>(List<T> values, dynamic raw, T fallback) {
      final name = raw?.toString() ?? '';
      for (final value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }

    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final weather = readEnum(
      BattleWeather.values,
      json['weather'],
      BattleWeather.clear,
    );
    final fieldTerrain = readEnum(
      BattleFieldTerrain.values,
      json['fieldTerrain'],
      BattleFieldTerrain.none,
    );

    return BattleEnvironment(
      season: readEnum(
        BattleSeason.values,
        json['season'],
        BattleSeason.springSummer,
      ),
      weather: weather,
      weatherRoundsRemaining: weather == BattleWeather.clear
          ? 0
          : readInt(json['weatherRoundsRemaining']).clamp(0, 99).toInt(),
      weatherSourceLevel: readInt(
        json['weatherSourceLevel'],
      ).clamp(0, 20).toInt(),
      naturalTerrain: readEnum(
        BattleNaturalTerrain.values,
        json['naturalTerrain'],
        BattleNaturalTerrain.none,
      ),
      fieldTerrain: fieldTerrain,
      fieldTerrainRoundsRemaining: fieldTerrain == BattleFieldTerrain.none
          ? 0
          : readInt(json['fieldTerrainRoundsRemaining']).clamp(0, 99).toInt(),
      optionalWeatherDamageAdvantage:
          json['optionalWeatherDamageAdvantage'] == true,
      suppressWeatherAbilities: json['suppressWeatherAbilities'] == true,
    );
  }
}
