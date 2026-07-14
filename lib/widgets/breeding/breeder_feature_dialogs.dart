import 'package:flutter/material.dart';

import '../../models/breeding_egg.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../services/breeder_feature_service.dart';

class GoodGenesChoice {
  const GoodGenesChoice._({
    required this.abilityBonuses,
    this.feat,
  });

  factory GoodGenesChoice.abilityScores(Map<String, int> bonuses) {
    return GoodGenesChoice._(abilityBonuses: Map.unmodifiable(bonuses));
  }

  factory GoodGenesChoice.feat(String feat) {
    return GoodGenesChoice._(abilityBonuses: const {}, feat: feat);
  }

  final Map<String, int> abilityBonuses;
  final String? feat;

  String get summary {
    final selectedFeat = feat;
    if (selectedFeat != null) return 'Talento: $selectedFeat';
    return abilityBonuses.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '+${entry.value} ${entry.key}')
        .join(' · ');
  }
}

Future<GoodGenesChoice?> showGoodGenesDialog(
  BuildContext context, {
  required Pokemon pokemon,
  required Map<String, String> featDescriptions,
  BreederFeatureService service = const BreederFeatureService(),
}) async {
  const abilities = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];
  var mode = 'abilities';
  var allocation = <String, int>{for (final ability in abilities) ability: 0};
  String? selectedFeat;
  final feats = featDescriptions.keys.toList()..sort();

  return showDialog<GoodGenesChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final spent = allocation.values.fold<int>(0, (sum, value) => sum + value);
        final validAllocation = service.isValidGoodGenesAllocation(
          pokemon: pokemon,
          bonuses: allocation,
        );
        final canConfirm = mode == 'abilities'
            ? validAllocation
            : selectedFeat != null;

        return AlertDialog(
          title: const Text('Good Genes'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Il Pokémon appena schiuso ottiene 2 punti da aggiungere alle caratteristiche, oppure un talento.',
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'abilities',
                        icon: Icon(Icons.add_chart),
                        label: Text('2 PUNTI'),
                      ),
                      ButtonSegment(
                        value: 'feat',
                        icon: Icon(Icons.auto_awesome),
                        label: Text('TALENTO'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      setDialogState(() => mode = selection.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (mode == 'abilities') ...[
                    Text(
                      'Punti assegnati: $spent/2 · massimo 20 prima della Natura',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    for (final ability in abilities)
                      _AbilityPointRow(
                        ability: ability,
                        baseScore: service.baseAbilityScore(pokemon, ability),
                        points: allocation[ability] ?? 0,
                        canDecrease: (allocation[ability] ?? 0) > 0,
                        canIncrease:
                            spent < 2 &&
                            service.baseAbilityScore(pokemon, ability) +
                                    (allocation[ability] ?? 0) <
                                20,
                        onDecrease: () {
                          setDialogState(() {
                            allocation = {
                              ...allocation,
                              ability: (allocation[ability] ?? 0) - 1,
                            };
                          });
                        },
                        onIncrease: () {
                          setDialogState(() {
                            allocation = {
                              ...allocation,
                              ability: (allocation[ability] ?? 0) + 1,
                            };
                          });
                        },
                      ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedFeat,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Talento',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final feat in feats)
                          DropdownMenuItem(value: feat, child: Text(feat)),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedFeat = value);
                      },
                    ),
                    if (selectedFeat != null) ...[
                      const SizedBox(height: 10),
                      Text(featDescriptions[selectedFeat] ?? ''),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ANNULLA SCHIUSA'),
            ),
            FilledButton(
              onPressed: canConfirm
                  ? () {
                      Navigator.of(dialogContext).pop(
                        mode == 'abilities'
                            ? GoodGenesChoice.abilityScores(allocation)
                            : GoodGenesChoice.feat(selectedFeat!),
                      );
                    }
                  : null,
              child: const Text('CONFERMA'),
            ),
          ],
        );
      },
    ),
  );
}

Future<BreedingEgg?> showMasterTraitsDialog(
  BuildContext context, {
  required BreedingEgg egg,
  required Pokemon pokemon,
  BreederFeatureService service = const BreederFeatureService(),
}) async {
  var selectedGender = egg.gender;
  var selectedNature = egg.nature;
  var selectedAbility = egg.ability;
  var selectedEggMoves = <String>{...egg.inheritedMoves};

  return showDialog<BreedingEgg>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final resolved = pokemon.resolveVariant(
          formName: egg.formName,
          gender: selectedGender,
        );
        final genders = service.availableGenders(resolved);
        final abilities = resolved.abilities.toSet().toList()..sort();
        final eggMoves = resolved.moves.eggMoves.toSet().toList()..sort();
        final replacementCount = egg.inheritedMoves.length;

        if (!genders.contains(selectedGender)) {
          selectedGender = genders.isEmpty ? null : genders.first;
        }
        if (!abilities.contains(selectedAbility)) {
          selectedAbility = abilities.isEmpty ? null : abilities.first;
        }
        selectedEggMoves = selectedEggMoves
            .where(eggMoves.contains)
            .take(replacementCount)
            .toSet();

        final validMoves = replacementCount == 0 ||
            selectedEggMoves.length == replacementCount;

        return AlertDialog(
          title: const Text('Master of Traits'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Scegli sesso, Natura e abilità disponibili del Pokémon che nascerà.',
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Sesso',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final gender in genders)
                        DropdownMenuItem(value: gender, child: Text(gender)),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedGender = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: PokemonNature.names.contains(selectedNature)
                        ? selectedNature
                        : PokemonNature.names.first,
                    decoration: const InputDecoration(
                      labelText: 'Natura',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final nature in PokemonNature.names)
                        DropdownMenuItem(value: nature, child: Text(nature)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedNature = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAbility,
                    decoration: const InputDecoration(
                      labelText: 'Abilità non nascosta',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final ability in abilities)
                        DropdownMenuItem(value: ability, child: Text(ability)),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedAbility = value);
                    },
                  ),
                  if (replacementCount > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Egg Moves: scegline esattamente $replacementCount',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Puoi mantenere le mosse ereditate oppure sostituirle con altre dalla lista Egg Moves della specie.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final move in eggMoves)
                          FilterChip(
                            label: Text(move),
                            selected: selectedEggMoves.contains(move),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  if (selectedEggMoves.length < replacementCount) {
                                    selectedEggMoves.add(move);
                                  }
                                } else {
                                  selectedEggMoves.remove(move);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    if (!validMoves)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Completa la selezione delle Egg Moves.',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: validMoves &&
                      selectedGender != null &&
                      selectedAbility != null
                  ? () {
                      final replacements = selectedEggMoves.toList()..sort();
                      final selectedMoves = service.applyMasterTraitEggMoves(
                        child: resolved,
                        selectedMoves: egg.selectedMoves,
                        inheritedMoves: egg.inheritedMoves,
                        replacements: replacements,
                      );
                      Navigator.of(dialogContext).pop(
                        egg.copyWith(
                          gender: selectedGender,
                          nature: selectedNature,
                          ability: selectedAbility,
                          selectedMoves: selectedMoves,
                          inheritedMoves: replacements,
                          masterTraitsCustomized: true,
                        ),
                      );
                    }
                  : null,
              child: const Text('SALVA SCELTE'),
            ),
          ],
        );
      },
    ),
  );
}

class _AbilityPointRow extends StatelessWidget {
  const _AbilityPointRow({
    required this.ability,
    required this.baseScore,
    required this.points,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String ability;
  final int baseScore;
  final int points;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            ability,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(child: Text('$baseScore → ${baseScore + points}')),
        IconButton(
          tooltip: 'Rimuovi punto da $ability',
          onPressed: canDecrease ? onDecrease : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '+$points',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: 'Aggiungi punto a $ability',
          onPressed: canIncrease ? onIncrease : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
