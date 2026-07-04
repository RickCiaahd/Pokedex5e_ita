class LevelProgression {
  static const int maxLevel = 20;

  static const Map<int, int> thresholds = {
    1: 0,
    2: 200,
    3: 800,
    4: 2000,
    5: 6000,
    6: 12000,
    7: 20000,
    8: 30000,
    9: 44000,
    10: 62000,
    11: 82000,
    12: 104000,
    13: 128000,
    14: 158000,
    15: 194000,
    16: 234000,
    17: 278000,
    18: 326000,
    19: 382000,
    20: 450000,
  };

  static int levelFromExperience(int experience) {
    final safeExperience = experience < 0 ? 0 : experience;
    var level = 1;

    for (final entry in thresholds.entries) {
      if (safeExperience >= entry.value) {
        level = entry.key;
      }
    }

    return level;
  }

  static int thresholdForLevel(int level) {
    return thresholds[level] ?? thresholds[maxLevel]!;
  }

  static int nextThresholdForLevel(int level) {
    return thresholds[level + 1] ?? thresholds[maxLevel]!;
  }

  static int applyExperienceInput({
    required int currentExperience,
    required String input,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return currentExperience;

    final value = int.tryParse(trimmed);
    if (value == null) return currentExperience;

    if (trimmed.startsWith('+') || trimmed.startsWith('-')) {
      return (currentExperience + value)
          .clamp(0, thresholds[maxLevel]!)
          .toInt();
    }

    return value.clamp(0, thresholds[maxLevel]!).toInt();
  }
}
