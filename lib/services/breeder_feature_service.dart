import '../models/pokemon.dart';
import '../models/user_profile.dart';
import 'trainer_path_passive_service.dart';

class BreederFeatureService {
  const BreederFeatureService();

  static const List<String> abilityKeys = [
    'STR',
    'DEX',
    'CON',
    'INT',
    'WIS',
    'CHA',
  ];

  bool hasGoodGenes(UserProfile profile) {
    return TrainerPathPassiveService.hasFeature(
      profile,
      trainerPath: 'Pokémon Breeder',
      level: 9,
    );
  }

  bool hasMasterOfTraits(UserProfile profile) {
    return TrainerPathPassiveService.hasFeature(
      profile,
      trainerPath: 'Pokémon Breeder',
      level: 15,
    );
  }

  int baseAbilityScore(Pokemon pokemon, String ability) {
    return switch (ability) {
      'STR' => pokemon.attributes.strength,
      'DEX' => pokemon.attributes.dexterity,
      'CON' => pokemon.attributes.constitution,
      'INT' => pokemon.attributes.intelligence,
      'WIS' => pokemon.attributes.wisdom,
      'CHA' => pokemon.attributes.charisma,
      _ => 0,
    };
  }

  bool isValidGoodGenesAllocation({
    required Pokemon pokemon,
    required Map<String, int> bonuses,
  }) {
    if (bonuses.keys.any((key) => !abilityKeys.contains(key))) return false;
    if (bonuses.values.any((value) => value < 0)) return false;
    final total = bonuses.values.fold<int>(0, (sum, value) => sum + value);
    if (total != 2) return false;
    for (final ability in abilityKeys) {
      final value = bonuses[ability] ?? 0;
      if (baseAbilityScore(pokemon, ability) + value > 20) return false;
    }
    return true;
  }

  List<String> availableGenders(Pokemon pokemon) {
    final ratio = (pokemon.genderRatio ?? '').trim().toLowerCase();
    if (ratio.contains('genderless') ||
        ratio.contains('none') ||
        ratio.contains('unknown')) {
      return const ['Genderless'];
    }
    final maleOnly =
        ratio.contains('100% male') || ratio.contains('male 100');
    final femaleOnly =
        ratio.contains('100% female') || ratio.contains('female 100');
    if (maleOnly && !femaleOnly) return const ['Male'];
    if (femaleOnly && !maleOnly) return const ['Female'];
    return const ['Male', 'Female'];
  }

  List<String> applyMasterTraitEggMoves({
    required Pokemon child,
    required List<String> selectedMoves,
    required List<String> inheritedMoves,
    required List<String> replacements,
  }) {
    if (inheritedMoves.isEmpty) return List.unmodifiable(selectedMoves);
    if (replacements.length != inheritedMoves.length) {
      throw ArgumentError(
        'Il numero di Egg Moves scelte deve coincidere con quelle ereditate.',
      );
    }

    final allowed = {
      for (final move in child.moves.eggMoves) _moveKey(move): move,
    };
    for (final replacement in replacements) {
      if (!allowed.containsKey(_moveKey(replacement))) {
        throw ArgumentError('$replacement non è una Egg Move disponibile.');
      }
    }

    final inheritedKeys = inheritedMoves.map(_moveKey).toSet();
    final result = <String>[];
    final seen = <String>{};

    void add(String move) {
      final key = _moveKey(move);
      if (key.isEmpty || !seen.add(key)) return;
      result.add(move);
    }

    for (final move in selectedMoves) {
      if (!inheritedKeys.contains(_moveKey(move))) add(move);
    }
    for (final move in replacements) {
      add(allowed[_moveKey(move)] ?? move);
    }
    for (final move in child.moves.startingMoves) {
      if (result.length >= 4) break;
      add(move);
    }

    return List.unmodifiable(result.take(4));
  }

  String _moveKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
