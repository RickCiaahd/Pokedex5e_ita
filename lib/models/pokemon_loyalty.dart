class PokemonLoyalty {
  const PokemonLoyalty._();

  static const int min = -3;
  static const int max = 3;

  static int clamp(int value) => value.clamp(min, max).toInt();

  static int hitPointBonus({
    required int level,
    required int loyalty,
  }) {
    if (loyalty >= 3) {
      return level;
    }
    if (loyalty >= 2) {
      return (level / 2).ceil();
    }
    return 0;
  }

  static int savingThrowBonus(int loyalty) {
    if (loyalty > 0) {
      return 1;
    }
    if (loyalty < 0) {
      return -1;
    }
    return 0;
  }

  static String label(int loyalty) {
    return switch (clamp(loyalty)) {
      -3 => 'Disloyal',
      -2 => 'Indifferent',
      -1 => 'Upset',
      1 => 'Content',
      2 => 'Pleased',
      3 => 'Loyal',
      _ => 'Neutral',
    };
  }

  static String summary({
    required int level,
    required int loyalty,
  }) {
    final value = clamp(loyalty);
    final hpBonus = hitPointBonus(level: level, loyalty: value);
    final saveBonus = savingThrowBonus(value);
    final parts = <String>[
      '${value >= 0 ? '+' : ''}$value ${label(value)}',
    ];

    if (hpBonus != 0) {
      parts.add('PF max +$hpBonus');
    }
    if (saveBonus != 0) {
      parts.add('TS ${saveBonus >= 0 ? '+' : ''}$saveBonus');
    }

    return parts.join(' | ');
  }
}
