import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/feat_repository.dart';
import '../../repositories/item_repository.dart';

class PokemonEditResult {
  const PokemonEditResult({required this.slot});

  final TeamSlot slot;
}

class PokemonEditScreen extends StatefulWidget {
  const PokemonEditScreen({
    super.key,
    required this.pokemon,
    required this.slot,
    required this.availableMoves,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final List<String> availableMoves;

  @override
  State<PokemonEditScreen> createState() => _PokemonEditScreenState();
}

class _PokemonEditScreenState extends State<PokemonEditScreen> {
  static const _skills = [
    'Acrobatics',
    'Animal Handling',
    'Arcana',
    'Athletics',
    'Deception',
    'History',
    'Insight',
    'Intimidation',
    'Investigation',
    'Medicine',
    'Nature',
    'Perception',
    'Performance',
    'Persuasion',
    'Religion',
    'Sleight of Hand',
    'Stealth',
    'Survival',
  ];

  final AbilityRepository _abilityRepository = AbilityRepository();
  final FeatRepository _featRepository = FeatRepository();
  final ItemRepository _itemRepository = ItemRepository();

  late final TextEditingController _nicknameController;
  late bool _isShiny;
  late String? _gender;
  late String _nature;
  late List<String> _selectedMoves;
  late List<String> _abilities;
  late List<String> _feats;
  late List<String> _extraSkills;
  late String? _heldItem;
  late Map<String, int> _customAbilityScores;
  Map<String, String> _abilityDescriptions = {};
  Map<String, String> _featDescriptions = {};
  Map<String, String> _itemDescriptions = {};
  bool _movesOpen = false;
  bool _abilitiesOpen = false;
  bool _featsOpen = false;
  bool _skillsOpen = false;
  bool _heldItemOpen = false;
  bool _extraAsiOpen = false;
  bool _isLoadingChoices = true;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.slot.nickname ?? widget.pokemon.name,
    );
    _isShiny = widget.slot.isShiny;
    _gender = widget.slot.gender;
    _nature = PokemonNature.names.contains(widget.slot.nature)
        ? widget.slot.nature
        : 'No Nature';
    _selectedMoves = _normalizedMoves(widget.slot.selectedMoves);
    _abilities = _normalizedAbilities(widget.slot.abilities);
    _feats = [...widget.slot.feats];
    _extraSkills = [...widget.slot.extraSkills];
    _heldItem = widget.slot.heldItem;
    _customAbilityScores = {
      'STR': 0,
      'DEX': 0,
      'CON': 0,
      'INT': 0,
      'WIS': 0,
      'CHA': 0,
      ...widget.slot.customAbilityScores,
    };
    _loadChoices();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadChoices() async {
    final results = await Future.wait([
      _abilityRepository.getAbilityDescriptions(),
      _featRepository.getFeatDescriptions(),
      _itemRepository.getItemDescriptions(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _abilityDescriptions = results[0];
      _featDescriptions = results[1];
      _itemDescriptions = results[2];
      _isLoadingChoices = false;
    });
  }

  List<String> _normalizedMoves(List<String> moves) {
    return moves.where((move) => move.trim().isNotEmpty).take(4).toList();
  }

  List<String> _normalizedAbilities(List<String> abilities) {
    final selected = abilities.where((ability) => ability.trim().isNotEmpty);
    final fallback = widget.pokemon.abilities;
    return _unique(selected.isEmpty ? fallback : selected).take(2).toList();
  }

  List<String> _availableAbilities() {
    return _unique([
      ...widget.pokemon.abilities,
      if (widget.pokemon.hiddenAbility != null) widget.pokemon.hiddenAbility!,
    ]);
  }

  List<String> _movesUpToLevel(int level) {
    final names = <String>[...widget.pokemon.moves.startingMoves];
    final entries =
        widget.pokemon.moves.levelMoves.entries
            .where((entry) => entry.key <= level)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      names.addAll(entry.value);
    }
    return _unique(names);
  }

  List<String> _tmMoves() {
    return _unique(
      widget.pokemon.moves.tmMoves
          .map((tm) => _tmMovesByNumber[tm])
          .whereType<String>(),
    );
  }

  List<String> _allMoveChoices() {
    return _unique([
      ..._movesUpToLevel(20),
      ..._tmMoves(),
      ...widget.availableMoves,
    ])..sort();
  }

  List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      if (seen.add(value)) {
        result.add(value);
      }
    }
    return result;
  }

  TeamSlot _updatedSlot() {
    final nickname = _nicknameController.text.trim();

    return widget.slot.copyWith(
      nickname: nickname.isEmpty || nickname == widget.pokemon.name
          ? null
          : nickname,
      isShiny: _isShiny,
      gender: _gender,
      nature: _nature,
      heldItem: _heldItem?.isEmpty == true ? null : _heldItem,
      selectedMoves: _normalizedMoves(_selectedMoves),
      abilities: _normalizedAbilities(_abilities),
      feats: _feats,
      extraSkills: _extraSkills,
      customAbilityScores: Map<String, int>.from(_customAbilityScores)
        ..removeWhere((_, value) => value == 0),
    );
  }

  void _save() {
    Navigator.of(context).pop(PokemonEditResult(slot: _updatedSlot()));
  }

  Future<void> _pickMove(int index) async {
    final blocked = _selectedMoves
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value)
        .toSet();

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _MovePickerScreen(
          currentLevelMoves: widget.availableMoves,
          level20Moves: _movesUpToLevel(20),
          tmMoves: _tmMoves(),
          allMoves: _allMoveChoices(),
          blockedMoves: blocked,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      while (_selectedMoves.length <= index) {
        _selectedMoves.add('');
      }
      _selectedMoves[index] = result;
      _selectedMoves = _selectedMoves.where((move) => move.isNotEmpty).toList();
    });
  }

  Future<void> _pickFeat([int? index]) async {
    final blocked = _feats
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value)
        .toSet();
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _ChoicePickerScreen(
          title: 'Scegli feat',
          options: _featDescriptions.keys.toList()..sort(),
          blockedOptions: blocked,
          descriptions: _featDescriptions,
        ),
      ),
    );

    if (result == null) {
      return;
    }
    setState(() {
      if (index == null) {
        _feats = [..._feats, result];
      } else {
        _feats[index] = result;
      }
    });
  }

  Future<void> _pickAbility([int? index]) async {
    final blocked = _abilities
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value)
        .toSet();
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _ChoicePickerScreen(
          title: 'Scegli abilita',
          options: _availableAbilities(),
          blockedOptions: blocked,
          descriptions: _abilityDescriptions,
        ),
      ),
    );

    if (result == null) {
      return;
    }
    setState(() {
      if (index == null) {
        _abilities = _normalizedAbilities([..._abilities, result]);
      } else {
        _abilities[index] = result;
      }
    });
  }

  Future<void> _pickSkill([int? index]) async {
    final blocked = _extraSkills
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value)
        .toSet();
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _ChoicePickerScreen(
          title: 'Scegli skill',
          options: _skills,
          blockedOptions: blocked,
        ),
      ),
    );

    if (result == null) {
      return;
    }
    setState(() {
      if (index == null) {
        _extraSkills = [..._extraSkills, result];
      } else {
        _extraSkills[index] = result;
      }
    });
  }

  Future<void> _pickItem() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _ChoicePickerScreen(
          title: 'Scegli item',
          options: _itemDescriptions.keys.toList()..sort(),
          descriptions: _itemDescriptions,
          includeNone: true,
        ),
      ),
    );

    if (result == null) {
      return;
    }
    setState(
      () => _heldItem = result == _ChoicePickerScreen.noneValue ? null : result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.slot.nickname ?? widget.pokemon.name;

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica $title'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingChoices
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nicknameController,
                  textAlign: TextAlign.center,
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
                            DropdownMenuItem(
                              value: nature,
                              child: Text(nature),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
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
                          DropdownMenuItem(
                            value: null,
                            child: Text('Qualsiasi'),
                          ),
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Maschio'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Femmina'),
                          ),
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
                _CollapsibleEditSection(
                  title: 'Move set',
                  isOpen: _movesOpen,
                  onToggle: () => setState(() => _movesOpen = !_movesOpen),
                  child: _MoveSlotGrid(
                    selectedMoves: _selectedMoves,
                    onPick: _pickMove,
                    onRemove: (index) {
                      setState(() {
                        if (index < _selectedMoves.length) {
                          _selectedMoves.removeAt(index);
                        }
                      });
                    },
                  ),
                ),
                _CollapsibleEditSection(
                  title: 'Abilities',
                  isOpen: _abilitiesOpen,
                  onToggle: () =>
                      setState(() => _abilitiesOpen = !_abilitiesOpen),
                  child: _ChipSlots(
                    values: _abilities,
                    emptyLabel: 'ABILITY',
                    onAdd: _abilities.length >= 2 ? null : _pickAbility,
                    onPick: _pickAbility,
                    onRemove: (index) {
                      setState(() => _abilities.removeAt(index));
                    },
                  ),
                ),
                _CollapsibleEditSection(
                  title: 'Feats',
                  isOpen: _featsOpen,
                  onToggle: () => setState(() => _featsOpen = !_featsOpen),
                  child: _ChipSlots(
                    values: _feats,
                    emptyLabel: 'FEAT',
                    onAdd: _pickFeat,
                    onPick: _pickFeat,
                    onRemove: (index) {
                      setState(() => _feats.removeAt(index));
                    },
                  ),
                ),
                _CollapsibleEditSection(
                  title: 'Skills',
                  isOpen: _skillsOpen,
                  onToggle: () => setState(() => _skillsOpen = !_skillsOpen),
                  child: _ChipSlots(
                    values: _extraSkills,
                    emptyLabel: 'SKILL',
                    onAdd: _pickSkill,
                    onPick: _pickSkill,
                    onRemove: (index) {
                      setState(() => _extraSkills.removeAt(index));
                    },
                  ),
                ),
                _CollapsibleEditSection(
                  title: 'Held item',
                  isOpen: _heldItemOpen,
                  onToggle: () =>
                      setState(() => _heldItemOpen = !_heldItemOpen),
                  child: _SingleSlot(
                    label: _heldItem ?? 'ITEM',
                    onTap: _pickItem,
                    onRemove: _heldItem == null
                        ? null
                        : () => setState(() => _heldItem = null),
                  ),
                ),
                _CollapsibleEditSection(
                  title: 'Extra ability score',
                  isOpen: _extraAsiOpen,
                  onToggle: () =>
                      setState(() => _extraAsiOpen = !_extraAsiOpen),
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
          child: FilledButton(onPressed: _save, child: const Text('SALVA')),
        ),
      ),
    );
  }
}

class _CollapsibleEditSection extends StatelessWidget {
  const _CollapsibleEditSection({
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isOpen ? '-' : '+',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        if (isOpen) child,
      ],
    );
  }
}

class _MoveSlotGrid extends StatelessWidget {
  const _MoveSlotGrid({
    required this.selectedMoves,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> selectedMoves;
  final ValueChanged<int> onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final hasMove = index < selectedMoves.length;
        return _SingleSlot(
          label: hasMove ? selectedMoves[index] : 'MOVE',
          onTap: () => onPick(index),
          onRemove: hasMove ? () => onRemove(index) : null,
        );
      },
    );
  }
}

class _ChipSlots extends StatelessWidget {
  const _ChipSlots({
    required this.values,
    required this.emptyLabel,
    required this.onAdd,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> values;
  final String emptyLabel;
  final VoidCallback? onAdd;
  final ValueChanged<int> onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        for (final entry in values.asMap().entries)
          SizedBox(
            width: 150,
            child: _SingleSlot(
              label: entry.value,
              onTap: () => onPick(entry.key),
              onRemove: () => onRemove(entry.key),
            ),
          ),
        if (onAdd != null)
          SizedBox(
            width: 150,
            child: _SingleSlot(label: emptyLabel, onTap: onAdd!),
          ),
      ],
    );
  }
}

class _SingleSlot extends StatelessWidget {
  const _SingleSlot({required this.label, required this.onTap, this.onRemove});

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -8,
            right: -8,
            child: IconButton.filled(
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
      ],
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
    return Card(
      child: ListTile(
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
      ),
    );
  }
}

class _MovePickerScreen extends StatefulWidget {
  const _MovePickerScreen({
    required this.currentLevelMoves,
    required this.level20Moves,
    required this.tmMoves,
    required this.allMoves,
    required this.blockedMoves,
  });

  final List<String> currentLevelMoves;
  final List<String> level20Moves;
  final List<String> tmMoves;
  final List<String> allMoves;
  final Set<String> blockedMoves;

  @override
  State<_MovePickerScreen> createState() => _MovePickerScreenState();
}

class _MovePickerScreenState extends State<_MovePickerScreen> {
  String _filter = 'current';
  String _search = '';

  List<String> get _activeMoves {
    final source = switch (_filter) {
      'tm' => widget.tmMoves,
      'lv20' => widget.level20Moves,
      'az' => widget.allMoves,
      _ => widget.currentLevelMoves,
    };

    return source
        .where((move) => !widget.blockedMoves.contains(move))
        .where((move) => move.toLowerCase().contains(_search.toLowerCase()))
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      title: 'Scegli mossa',
      searchLabel: 'Cerca',
      onSearchChanged: (value) => setState(() => _search = value),
      sideFilters: [
        _FilterButton(
          label: 'Lv.',
          selected: _filter == 'current',
          onTap: () => setState(() => _filter = 'current'),
        ),
        _FilterButton(
          label: 'TM',
          selected: _filter == 'tm',
          onTap: () => setState(() => _filter = 'tm'),
        ),
        _FilterButton(
          label: 'Lv.20',
          selected: _filter == 'lv20',
          onTap: () => setState(() => _filter = 'lv20'),
        ),
        _FilterButton(
          label: 'A-Z',
          selected: _filter == 'az',
          onTap: () => setState(() => _filter = 'az'),
        ),
      ],
      children: [
        for (final move in _activeMoves)
          _PickerTile(
            label: move,
            onTap: () => Navigator.of(context).pop(move),
          ),
        if (_activeMoves.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nessuna mossa disponibile.'),
          ),
      ],
    );
  }
}

class _ChoicePickerScreen extends StatefulWidget {
  const _ChoicePickerScreen({
    required this.title,
    required this.options,
    this.blockedOptions = const {},
    this.descriptions = const {},
    this.includeNone = false,
  });

  static const noneValue = '__none__';

  final String title;
  final List<String> options;
  final Set<String> blockedOptions;
  final Map<String, String> descriptions;
  final bool includeNone;

  @override
  State<_ChoicePickerScreen> createState() => _ChoicePickerScreenState();
}

class _ChoicePickerScreenState extends State<_ChoicePickerScreen> {
  String _search = '';

  List<String> get _options {
    return widget.options
        .where((option) => !widget.blockedOptions.contains(option))
        .where((option) => option.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      title: widget.title,
      searchLabel: 'Cerca',
      onSearchChanged: (value) => setState(() => _search = value),
      children: [
        if (widget.includeNone)
          _PickerTile(
            label: 'Nessuno',
            onTap: () {
              Navigator.of(context).pop(_ChoicePickerScreen.noneValue);
            },
          ),
        for (final option in _options)
          _PickerTile(
            label: option,
            subtitle: widget.descriptions[option],
            onTap: () => Navigator.of(context).pop(option),
          ),
        if (_options.isEmpty && !widget.includeNone)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nessun elemento disponibile.'),
          ),
      ],
    );
  }
}

class _ChoiceShell extends StatelessWidget {
  const _ChoiceShell({
    required this.title,
    required this.searchLabel,
    required this.onSearchChanged,
    required this.children,
    this.sideFilters = const [],
  });

  final String title;
  final String searchLabel;
  final ValueChanged<String> onSearchChanged;
  final List<Widget> children;
  final List<Widget> sideFilters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title.toUpperCase()),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          if (sideFilters.isNotEmpty)
            SizedBox(
              width: 72,
              child: ListView(
                padding: const EdgeInsets.only(top: 96),
                children: sideFilters,
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: searchLabel,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: selected ? Colors.orange : null,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Text(label),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.label, required this.onTap, this.subtitle});

  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.radio_button_unchecked),
        title: Text(label.toUpperCase()),
        subtitle: subtitle == null || subtitle!.isEmpty
            ? null
            : Text(subtitle!),
        onTap: onTap,
      ),
    );
  }
}

const _tmMovesByNumber = <int, String>{
  1: 'Work Up',
  2: 'Dragon Claw',
  3: 'Psyshock',
  4: 'Calm Mind',
  5: 'Roar',
  6: 'Toxic',
  7: 'Hail',
  8: 'Bulk Up',
  9: 'Venoshock',
  10: 'Hidden Power',
  11: 'Sunny Day',
  12: 'Taunt',
  13: 'Ice Beam',
  14: 'Blizzard',
  15: 'Hyper Beam',
  16: 'Light Screen',
  17: 'Protect',
  18: 'Rain Dance',
  19: 'Roost',
  20: 'Safeguard',
  21: 'Frustration',
  22: 'Solar Beam',
  23: 'Smack Down',
  24: 'Thunderbolt',
  25: 'Thunder',
  26: 'Earthquake',
  27: 'Return',
  28: 'Leech Life',
  29: 'Psychic',
  30: 'Shadow Ball',
  31: 'Brick Break',
  32: 'Double Team',
  33: 'Reflect',
  34: 'Sludge Wave',
  35: 'Flamethrower',
  36: 'Sludge Bomb',
  37: 'Sandstorm',
  38: 'Fire Blast',
  39: 'Rock Tomb',
  40: 'Aerial Ace',
  41: 'Torment',
  42: 'Facade',
  43: 'Flame Charge',
  44: 'Rest',
  45: 'Attract',
  46: 'Thief',
  47: 'Low Sweep',
  48: 'Round',
  49: 'Echoed Voice',
  50: 'Overheat',
  51: 'Steel Wing',
  52: 'Focus Blast',
  53: 'Energy Ball',
  54: 'False Swipe',
  55: 'Scald',
  56: 'Fling',
  57: 'Charge Beam',
  58: 'Sky Drop',
  59: 'Brutal Swing',
  60: 'Quash',
  61: 'Will-O-Wisp',
  62: 'Acrobatics',
  63: 'Embargo',
  64: 'Explosion',
  65: 'Shadow Claw',
  66: 'Payback',
  67: 'Smart Strike',
  68: 'Giga Impact',
  69: 'Rock Polish',
  70: 'Aurora Veil',
  71: 'Stone Edge',
  72: 'Volt Switch',
  73: 'Thunder Wave',
  74: 'Gyro Ball',
  75: 'Swords Dance',
  76: 'Fly',
  77: 'Psych Up',
  78: 'Bulldoze',
  79: 'Frost Breath',
  80: 'Rock Slide',
  81: 'X-Scissor',
  82: 'Dragon Tail',
  83: 'Infestation',
  84: 'Poison Jab',
  85: 'Dream Eater',
  86: 'Grass Knot',
  87: 'Swagger',
  88: 'Sleep Talk',
  89: 'U-turn',
  90: 'Substitute',
  91: 'Flash Cannon',
  92: 'Trick Room',
  93: 'Wild Charge',
  94: 'Surf',
  95: 'Snarl',
  96: 'Nature Power',
  97: 'Dark Pulse',
  98: 'Waterfall',
  99: 'Dazzling Gleam',
  100: 'Confide',
};
