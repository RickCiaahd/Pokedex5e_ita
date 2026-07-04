import 'package:flutter/material.dart';

import '../../models/evolution_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';

class PokemonEditResult {
  const PokemonEditResult({required this.slot, this.evolveRequested = false});

  final TeamSlot slot;
  final bool evolveRequested;
}

class PokemonEditScreen extends StatefulWidget {
  const PokemonEditScreen({
    super.key,
    required this.pokemon,
    required this.slot,
    required this.level,
    required this.evolutionData,
    required this.availableMoves,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final int level;
  final EvolutionData? evolutionData;
  final List<String> availableMoves;

  @override
  State<PokemonEditScreen> createState() => _PokemonEditScreenState();
}

class _PokemonEditScreenState extends State<PokemonEditScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _heldItemController;
  late final TextEditingController _movesController;
  late final TextEditingController _featsController;
  late final TextEditingController _skillsController;
  late bool _isShiny;
  late String? _gender;
  late String _nature;
  late Map<String, int> _customAbilityScores;

  bool get _canEvolve {
    final evolution = widget.evolutionData;
    return evolution != null &&
        evolution.canEvolve &&
        widget.level >= evolution.level!;
  }

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.slot.nickname ?? widget.pokemon.name,
    );
    _heldItemController = TextEditingController(
      text: widget.slot.heldItem ?? '',
    );
    _movesController = TextEditingController(
      text: widget.slot.selectedMoves.join(', '),
    );
    _featsController = TextEditingController(
      text: widget.slot.feats.join(', '),
    );
    _skillsController = TextEditingController(
      text: widget.slot.extraSkills.join(', '),
    );
    _isShiny = widget.slot.isShiny;
    _gender = widget.slot.gender;
    _nature = PokemonNature.names.contains(widget.slot.nature)
        ? widget.slot.nature
        : 'No Nature';
    _customAbilityScores = {
      'STR': 0,
      'DEX': 0,
      'CON': 0,
      'INT': 0,
      'WIS': 0,
      'CHA': 0,
      ...widget.slot.customAbilityScores,
    };
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heldItemController.dispose();
    _movesController.dispose();
    _featsController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> _csv(TextEditingController controller) {
    return controller.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  TeamSlot _updatedSlot() {
    final nickname = _nicknameController.text.trim();
    final heldItem = _heldItemController.text.trim();

    return widget.slot.copyWith(
      nickname: nickname.isEmpty || nickname == widget.pokemon.name
          ? null
          : nickname,
      isShiny: _isShiny,
      gender: _gender,
      nature: _nature,
      heldItem: heldItem.isEmpty ? null : heldItem,
      selectedMoves: _csv(_movesController).take(4).toList(),
      feats: _csv(_featsController),
      extraSkills: _csv(_skillsController),
      customAbilityScores: Map<String, int>.from(_customAbilityScores)
        ..removeWhere((_, value) => value == 0),
    );
  }

  void _save({bool evolveRequested = false}) {
    Navigator.of(context).pop(
      PokemonEditResult(slot: _updatedSlot(), evolveRequested: evolveRequested),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.slot.nickname ?? widget.pokemon.name;
    final evolutionLabel = _canEvolve
        ? 'FAI EVOLVERE'
        : widget.evolutionData?.level == null
        ? 'EVOLUZIONE NON DISPONIBILE'
        : 'EVOLVE AL LV. ${widget.evolutionData!.level}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica $title'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: 'Nome / nickname',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _nature,
                  decoration: const InputDecoration(
                    labelText: 'Natura',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final nature in PokemonNature.names)
                      DropdownMenuItem(value: nature, child: Text(nature)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _nature = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Sesso',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Qualsiasi')),
                    DropdownMenuItem(value: 'male', child: Text('Maschio')),
                    DropdownMenuItem(value: 'female', child: Text('Femmina')),
                    DropdownMenuItem(
                      value: 'genderless',
                      child: Text('Genderless'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Shiny'),
            value: _isShiny,
            onChanged: (value) => setState(() => _isShiny = value),
          ),
          TextField(
            controller: _heldItemController,
            decoration: const InputDecoration(
              labelText: 'Held item',
              hintText: 'Es. Leftovers',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _EditSection(
            title: 'Move set',
            child: TextField(
              controller: _movesController,
              decoration: InputDecoration(
                helperText:
                    'Massimo 4 mosse. Disponibili: ${widget.availableMoves.join(', ')}',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          _EditSection(
            title: 'Feat',
            child: TextField(
              controller: _featsController,
              decoration: const InputDecoration(
                helperText: 'Separali con una virgola.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _EditSection(
            title: 'Skill extra',
            child: TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                helperText: 'Separale con una virgola.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _EditSection(
            title: 'ASI personalizzati',
            child: Column(
              children: [
                for (final key in _customAbilityScores.keys)
                  _ScoreStepper(
                    label: key,
                    value: _customAbilityScores[key] ?? 0,
                    onChanged: (value) {
                      setState(() => _customAbilityScores[key] = value);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _save(),
                  child: const Text('SALVA'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _canEvolve
                      ? () => _save(evolveRequested: true)
                      : null,
                  child: Text(evolutionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  const _EditSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  const _ScoreStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('Bonus personalizzato: ${value >= 0 ? '+' : ''}$value'),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Diminuisci',
            onPressed: () => onChanged(value - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            tooltip: 'Aumenta',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
