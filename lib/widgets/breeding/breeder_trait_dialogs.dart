import 'package:flutter/material.dart';

import '../../models/battle_environment.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../services/battle_environment_service.dart';

class MasterOfTraitsSelection {
  const MasterOfTraitsSelection({
    this.gender,
    this.nature,
    this.ability,
    this.replacementEggMoves = const [],
  });

  final String? gender;
  final String? nature;
  final String? ability;
  final List<String> replacementEggMoves;
}

Future<MasterOfTraitsSelection?> showMasterOfTraitsDialog({
  required BuildContext context,
  required Pokemon pokemon,
  required List<String> genders,
  required List<String> abilities,
  required int replaceableEggMoveCount,
}) {
  return showDialog<MasterOfTraitsSelection>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MasterOfTraitsDialog(
      pokemon: pokemon,
      genders: genders,
      abilities: abilities,
      replaceableEggMoveCount: replaceableEggMoveCount,
    ),
  );
}

class _MasterOfTraitsDialog extends StatefulWidget {
  const _MasterOfTraitsDialog({
    required this.pokemon,
    required this.genders,
    required this.abilities,
    required this.replaceableEggMoveCount,
  });

  final Pokemon pokemon;
  final List<String> genders;
  final List<String> abilities;
  final int replaceableEggMoveCount;

  @override
  State<_MasterOfTraitsDialog> createState() => _MasterOfTraitsDialogState();
}

class _MasterOfTraitsDialogState extends State<_MasterOfTraitsDialog> {
  static const _random = '__random__';

  String _gender = _random;
  String _nature = _random;
  String _ability = _random;
  final Set<String> _replacementMoves = {};

  @override
  Widget build(BuildContext context) {
    final natures =
        PokemonNature.names
            .where((nature) => nature != 'No Nature')
            .toList(growable: false)
          ..sort();
    final eggMoves = widget.pokemon.moves.eggMoves.toSet().toList()..sort();

    return AlertDialog(
      title: const Text('Master of Traits'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Per ${widget.pokemon.name} puoi ignorare i tiri e scegliere sesso, natura e abilità tra le opzioni disponibili. Lascia Casuale per usare le normali regole di schiusa.',
              ),
              const SizedBox(height: 14),
              _TraitDropdown(
                label: 'Sesso',
                value: _gender,
                options: widget.genders,
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 10),
              _TraitDropdown(
                label: 'Natura',
                value: _nature,
                options: natures,
                onChanged: (value) => setState(() => _nature = value),
              ),
              const SizedBox(height: 10),
              _TraitDropdown(
                label: 'Abilità non nascosta',
                value: _ability,
                options: widget.abilities,
                onChanged: (value) => setState(() => _ability = value),
              ),
              if (widget.replaceableEggMoveCount > 0 &&
                  eggMoves.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Egg Moves sostitutive (${_replacementMoves.length}/${widget.replaceableEggMoveCount})',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Puoi sostituire fino allo stesso numero di Egg Moves ereditate. Le selezioni non usate mantengono le mosse ereditate originali.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final move in eggMoves)
                      FilterChip(
                        label: Text(move),
                        selected: _replacementMoves.contains(move),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (_replacementMoves.length <
                                  widget.replaceableEggMoveCount) {
                                _replacementMoves.add(move);
                              }
                            } else {
                              _replacementMoves.remove(move);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              MasterOfTraitsSelection(
                gender: _gender == _random ? null : _gender,
                nature: _nature == _random ? null : _nature,
                ability: _ability == _random ? null : _ability,
                replacementEggMoves: _replacementMoves.toList(growable: false),
              ),
            );
          },
          child: const Text('CONFERMA'),
        ),
      ],
    );
  }
}

class _TraitDropdown extends StatelessWidget {
  const _TraitDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(
          value: _MasterOfTraitsDialogState._random,
          child: Text('Casuale secondo il manuale'),
        ),
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class GoodGenesSelection {
  const GoodGenesSelection({this.abilityBonuses = const {}, this.feat});

  final Map<String, int> abilityBonuses;
  final String? feat;
}

Future<GoodGenesSelection?> showGoodGenesDialog({
  required BuildContext context,
  required String pokemonName,
  required Map<String, String> featDescriptions,
}) {
  return showDialog<GoodGenesSelection>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GoodGenesDialog(
      pokemonName: pokemonName,
      featDescriptions: featDescriptions,
    ),
  );
}

class _GoodGenesDialog extends StatefulWidget {
  const _GoodGenesDialog({
    required this.pokemonName,
    required this.featDescriptions,
  });

  final String pokemonName;
  final Map<String, String> featDescriptions;

  @override
  State<_GoodGenesDialog> createState() => _GoodGenesDialogState();
}

class _GoodGenesDialogState extends State<_GoodGenesDialog> {
  static const _abilities = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];

  bool _useFeat = false;
  final Map<String, int> _bonuses = {
    for (final ability in _abilities) ability: 0,
  };
  String? _feat;
  BattleNaturalTerrain? _terrainAdept;

  int get _spent => _bonuses.values.fold(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    final feats = widget.featDescriptions.keys.toList()..sort();
    final valid = _useFeat
        ? _feat != null && (_feat != 'Terrain Adept' || _terrainAdept != null)
        : _spent == 2;

    return AlertDialog(
      title: const Text('Good Genes'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.pokemonName} sta per schiudersi. Il privilegio assegna 2 punti alle caratteristiche oppure un talento.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('2 punti caratteristica'),
                    selected: !_useFeat,
                    onSelected: (_) => setState(() => _useFeat = false),
                  ),
                  ChoiceChip(
                    label: const Text('Un talento'),
                    selected: _useFeat,
                    onSelected: (_) => setState(() => _useFeat = true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!_useFeat) ...[
                Text(
                  'Punti spesi: $_spent/2',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                for (final ability in _abilities)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ability,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: (_bonuses[ability] ?? 0) > 0
                            ? () => setState(() {
                                _bonuses[ability] =
                                    (_bonuses[ability] ?? 0) - 1;
                              })
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '+${_bonuses[ability] ?? 0}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: _spent < 2
                            ? () => setState(() {
                                _bonuses[ability] =
                                    (_bonuses[ability] ?? 0) + 1;
                              })
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: feats.contains(_feat) ? _feat : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Talento'),
                  items: [
                    for (final feat in feats)
                      DropdownMenuItem(value: feat, child: Text(feat)),
                  ],
                  onChanged: (value) => setState(() {
                    _feat = value;
                    if (value != 'Terrain Adept') _terrainAdept = null;
                  }),
                ),
                if (_feat == 'Terrain Adept') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BattleNaturalTerrain>(
                    initialValue: _terrainAdept,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Terreno di Terrain Adept',
                    ),
                    items: [
                      for (final terrain in BattleNaturalTerrain.values)
                        if (terrain != BattleNaturalTerrain.none)
                          DropdownMenuItem(
                            value: terrain,
                            child: Text(terrain.label),
                          ),
                    ],
                    onChanged: (value) => setState(() => _terrainAdept = value),
                  ),
                ],
                if (_feat != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.featDescriptions[_feat] ?? ''),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
        ),
        FilledButton(
          onPressed: valid
              ? () {
                  Navigator.of(context).pop(
                    GoodGenesSelection(
                      abilityBonuses: _useFeat
                          ? const {}
                          : {
                              for (final entry in _bonuses.entries)
                                if (entry.value > 0) entry.key: entry.value,
                            },
                      feat: _useFeat
                          ? _feat == 'Terrain Adept' && _terrainAdept != null
                                ? BattleEnvironmentService.terrainAdeptFeat(
                                    _terrainAdept!,
                                  )
                                : _feat
                          : null,
                    ),
                  );
                }
              : null,
          child: const Text('APPLICA E SCHIUDI'),
        ),
      ],
    );
  }
}

Future<int?> showEggHpDialog({
  required BuildContext context,
  required int currentHp,
  required int maxHp,
}) async {
  final controller = TextEditingController(text: '$currentHp');
  final raw = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('PF dell’uovo'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: 'Nuovi PF oppure modifica (+/-)',
          helperText:
              'Il manuale assegna CA 8 e $maxHp PF. A 0 PF l’uovo è distrutto.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('APPLICA'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (raw == null) return null;
  final input = raw.trim();
  final parsed = int.tryParse(input);
  if (parsed == null) return null;
  final value = input.startsWith('+') || input.startsWith('-')
      ? currentHp + parsed
      : parsed;
  return value.clamp(0, maxHp).toInt();
}
