part of 'bag_screen.dart';

extension _BagScreenHelpers on _BagScreenState {
  _MedicineUseResult? _applyMedicine({
    required BagItem item,
    required TeamSlot slot,
    required Pokemon pokemon,
  }) {
    final maxHp = _maxHpFor(pokemon, slot);
    final currentHp = slot.currentHp.clamp(0, maxHp).toInt();
    final statusEffects = [...slot.statusEffects];
    var updatedHp = currentHp;
    var updatedStatuses = [...statusEffects];
    var healingText = '';
    var statusText = '';

    final healAmount = _healingAmount(item.id);
    final isReviveItem = _isReviveMedicine(item.id);

    if (healAmount != null) {
      if (currentHp <= 0 && !isReviveItem) return null;
      if (currentHp > 0 && isReviveItem) return null;

      updatedHp = (currentHp + healAmount).clamp(0, maxHp).toInt();
      if (updatedHp != currentHp) {
        healingText = 'recupera ${updatedHp - currentHp} HP';
      }
    }

    final curedStatuses = _statusesCuredBy(item.id, statusEffects);
    if (curedStatuses.isNotEmpty) {
      updatedStatuses = updatedStatuses
          .where((status) => !curedStatuses.contains(status))
          .toList(growable: false);
      statusText = curedStatuses.length == statusEffects.length
          ? 'guarisce dagli status'
          : 'guarisce da ${curedStatuses.join(', ')}';
    }

    if (updatedHp == currentHp &&
        _sameStrings(updatedStatuses, statusEffects)) {
      return null;
    }

    final displayName = slot.nickname ?? pokemon.name;
    final effects = [
      healingText,
      statusText,
    ].where((part) => part.isNotEmpty).join(' e ');

    return _MedicineUseResult(
      updatedSlot: slot.copyWith(
        currentHp: updatedHp,
        statusEffects: updatedStatuses,
      ),
      message: context.uiText(
        '$displayName $effects usando ${item.name}.',
        '$displayName $effects using ${item.name}.',
      ),
    );
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {
    return TrainerPathPassiveService.maxHp(
      profile: _activeProfile,
      pokemon: pokemon,
      slot: slot,
      level: LevelProgression.levelFromExperience(slot.experience),
    );
  }

  bool _isSupportedMedicine(String itemId) {
    return _healingItemIds.contains(itemId) ||
        _statusMedicineItemIds.contains(itemId) ||
        _berryMedicineItemIds.contains(itemId);
  }

  bool _isReviveMedicine(String itemId) {
    return const {'revive', 'max-revive', 'revival-herb'}.contains(itemId);
  }

  int? _healingAmount(String itemId) {
    switch (itemId) {
      case 'potion':
      case 'revive':
      case 'oran-berry':
        return _rollDice(2, 4, 2);
      case 'super-potion':
      case 'energy-powder':
        return _rollDice(3, 6, 6);
      case 'hyper-potion':
      case 'energy-root':
      case 'max-revive':
      case 'revival-herb':
        return _rollDice(4, 12, 10);
      case 'max-potion':
      case 'full-restore':
        return 70;
      case 'sitrus-berry':
        return 30;
      case 'fresh-water':
        return 7;
      case 'soda-pop':
        return 10;
      case 'berry-juice':
        return 20;
      case 'lemonade':
        return 30;
      case 'moomoo-milk':
        return 50;
      default:
        return null;
    }
  }

  int _rollDice(int diceCount, int sides, int bonus) {
    var total = bonus;
    for (var i = 0; i < diceCount; i++) {
      total += _random.nextInt(sides) + 1;
    }
    return total;
  }

  List<String> _statusesCuredBy(String itemId, List<String> statuses) {
    final targets = _statusTargetsByMedicine[itemId];
    if (targets == null) return const [];
    if (targets.contains('*')) return List<String>.from(statuses);

    return statuses.where(targets.contains).toList(growable: false);
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  int? _tmNumberFromItemId(String itemId) {
    final match = RegExp(r'^tm-(\d+)$').firstMatch(itemId);
    if (match == null) return null;

    return int.tryParse(match.group(1) ?? '');
  }

  List<String> _normalizedMoves(List<String> moves) {
    return moves.where((move) => move.trim().isNotEmpty).take(4).toList();
  }

  bool _knowsMove(List<String> selectedMoves, MoveData move) {
    final moveKeys = {
      MoveData.referenceKey(move.id),
      MoveData.referenceKey(move.name),
    }..removeWhere((key) => key.isEmpty);

    return selectedMoves.any(
      (reference) => moveKeys.contains(MoveData.referenceKey(reference)),
    );
  }
}
