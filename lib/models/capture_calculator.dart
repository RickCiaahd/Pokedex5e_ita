class CaptureCheck {
  const CaptureCheck({
    required this.canAttempt,
    required this.dc,
    required this.hasAdvantage,
    this.blockedReason,
  });

  final bool canAttempt;
  final int? dc;
  final bool hasAdvantage;
  final String? blockedReason;
}

class CaptureCalculator {
  const CaptureCalculator._();

  static const Set<String> advantageStatusKeys = {
    'poisoned',
    'restrained',
    'asleep',
    'sleep',
    'burned',
    'burning',
    'confused',
    'paralyzed',
    'frozen',
  };

  static CaptureCheck check({
    required int trainerLevel,
    required int pokemonLevel,
    required double pokemonSr,
    required int remainingHp,
    Iterable<String> statusConditions = const [],
    int pokeballBonus = 0,
  }) {
    if (pokemonLevel > trainerLevel) {
      return const CaptureCheck(
        canAttempt: false,
        dc: null,
        hasAdvantage: false,
        blockedReason: 'Il livello del Pokemon supera quello del trainer.',
      );
    }

    if (remainingHp <= 0) {
      return const CaptureCheck(
        canAttempt: false,
        dc: null,
        hasAdvantage: false,
        blockedReason: 'Un Pokemon esausto non puo essere catturato.',
      );
    }

    final normalizedStatuses = statusConditions
        .map((status) => status.toLowerCase().trim())
        .toSet();

    return CaptureCheck(
      canAttempt: true,
      dc: catchDc(
        pokemonLevel: pokemonLevel,
        pokemonSr: pokemonSr,
        remainingHp: remainingHp,
        pokeballBonus: pokeballBonus,
      ),
      hasAdvantage: normalizedStatuses.any(advantageStatusKeys.contains),
    );
  }

  static int catchDc({
    required int pokemonLevel,
    required double pokemonSr,
    required int remainingHp,
    int pokeballBonus = 0,
  }) {
    final baseDc = 10 + pokemonSr.floor() + pokemonLevel + remainingHp ~/ 10;
    return baseDc - pokeballBonus;
  }
}
