class TrainerProgression {
  const TrainerProgression._();

  static const int minLevel = 1;
  static const int maxLevel = 20;

  static const Map<int, int> pokeslotsByLevel = {
    1: 3,
    5: 4,
    10: 5,
    15: 6,
  };

  static const Map<int, int> maxControlledSrByLevel = {
    1: 2,
    3: 5,
    6: 8,
    8: 10,
    11: 12,
    14: 14,
    17: 15,
  };

  static int clampLevel(int level) {
    return level.clamp(minLevel, maxLevel).toInt();
  }

  static int pokeslotsForLevel(int level) {
    return _valueAtLevel(pokeslotsByLevel, clampLevel(level));
  }

  static int maxControlledSrForLevel(int level) {
    return _valueAtLevel(maxControlledSrByLevel, clampLevel(level));
  }

  static bool canControlSr({
    required int trainerLevel,
    required double pokemonSr,
  }) {
    return pokemonSr <= maxControlledSrForLevel(trainerLevel);
  }

  static int _valueAtLevel(Map<int, int> table, int level) {
    var selected = table.entries.first.value;

    for (final entry in table.entries) {
      if (level >= entry.key) {
        selected = entry.value;
      }
    }

    return selected;
  }
}
