import 'package:flutter/material.dart';

import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_ability.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/tm_data.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/feat_repository.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/tm_repository.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

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
  final MoveRepository _moveRepository = MoveRepository();
  final TmRepository _tmRepository = TmRepository();

  late final TextEditingController _nicknameController;
  late bool _isShiny;
  late String? _gender;
  late String? _formName;
  late String _nature;
  late List<String> _selectedMoves;
  late List<String> _abilities;
  late List<String> _feats;
  late List<String> _extraSkills;
  late String? _heldItem;
  late Map<String, int> _customAbilityScores;

  List<PokemonFormChoice> _formChoices = const [];
  List<PokemonAbility> _abilityChoices = const [];
  Set<String> _deprecatedAbilityNames = const {};
  List<String> _tmMoveNames = const [];
  Map<String, String> _abilityDescriptions = {};
  Map<String, String> _featDescriptions = {};
  Map<String, MoveData?> _moveData = {};

  bool _formOpen = true;
  bool _movesOpen = false;
  bool _abilitiesOpen = false;
  bool _featsOpen = false;
  bool _skillsOpen = false;
  bool _extraAsiOpen = false;
  bool _isLoadingChoices = true;

  Pokemon get _formPokemon =>
      widget.pokemon.resolveVariant(formName: _formName, gender: _gender);

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.slot.nickname ?? widget.pokemon.name,
    );
    _isShiny = widget.slot.isShiny;
    _gender = widget.slot.gender;
    _formName = widget.slot.formName;
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
    final abilityDescriptionsFuture = _abilityRepository
        .getAbilityDescriptions();
    final abilityChoicesFuture = _abilityRepository.getWebAbilities();
    final deprecatedAbilitiesFuture = _abilityRepository
        .getDeprecatedAbilityNames();
    final featDescriptionsFuture = _featRepository.getFeatDescriptions();
    final formChoicesFuture = PokemonAssetPaths.formChoices(widget.pokemon);
    final tmMapFuture = _tmRepository.getTmMap();

    final abilityDescriptions = await abilityDescriptionsFuture;
    final abilityChoices = await abilityChoicesFuture;
    final deprecatedAbilities = await deprecatedAbilitiesFuture;
    final featDescriptions = await featDescriptionsFuture;
    final formChoices = await formChoicesFuture;
    final tmMap = await tmMapFuture;
    final tmMoveNames = await _tmMoveNamesFromRepository(tmMap);
    final moveData = await _moveRepository.getMoves(
      _allMoveChoices(tmMoveNames),
    );

    if (!mounted) return;

    var formName = _formName;
    if (formChoices.length <= 1) {
      formName = null;
    } else {
      final currentKey = Pokemon.formReferenceKey(
        formName ?? '',
        widget.pokemon.name,
      );
      PokemonFormChoice? matchingChoice;
      for (final choice in formChoices) {
        if (Pokemon.formReferenceKey(choice.name, widget.pokemon.name) ==
            currentKey) {
          matchingChoice = choice;
          break;
        }
      }
      formName = matchingChoice?.name ?? formChoices.first.name;
    }

    setState(() {
      _abilityDescriptions = abilityDescriptions;
      _abilityChoices = abilityChoices;
      _deprecatedAbilityNames = deprecatedAbilities;
      _featDescriptions = featDescriptions;
      _moveData = moveData;
      _tmMoveNames = tmMoveNames;
      _formChoices = formChoices;
      _formName = formName;
      _isLoadingChoices = false;
    });
  }

  Future<List<String>> _tmMoveNamesFromRepository(
    Map<int, TmData> tmMap,
  ) async {
    final tmMoveNames = <String>[];

    for (final tmNumber in _formPokemon.moves.tmMoves) {
      final tm = tmMap[tmNumber];
      if (tm == null) continue;

      final move = await _moveRepository.getMove(tm.moveId);
      tmMoveNames.add(move?.name ?? _labelFromId(tm.moveId));
    }

    return _unique(tmMoveNames);
  }

  List<String> _normalizedMoves(List<String> moves) {
    return moves.where((move) => move.trim().isNotEmpty).take(4).toList();
  }

  List<String> _normalizedAbilities(List<String> abilities) {
    final selected = abilities.where((ability) => ability.trim().isNotEmpty);
    final fallback = _formPokemon.abilities;
    return _unique(selected.isEmpty ? fallback : selected).take(2).toList();
  }

  List<String> _naturalAbilities() {
    return _unique([
      ..._formPokemon.abilities,
      if (_formPokemon.hiddenAbility != null) _formPokemon.hiddenAbility!,
    ]).where((ability) => !_deprecatedAbilityNames.contains(ability)).toList();
  }

  List<String> _availableAbilities() {
    final naturalAbilities = _naturalAbilities();
    final naturalSet = naturalAbilities.toSet();
    final catalogAbilities =
        _abilityChoices
            .map((ability) => ability.name)
            .where((ability) => !naturalSet.contains(ability))
            .toList(growable: false)
          ..sort();

    return _unique([...naturalAbilities, ...catalogAbilities]);
  }

  List<String> _movesUpToLevel(int level) {
    final names = <String>[..._formPokemon.moves.startingMoves];
    final entries =
        _formPokemon.moves.levelMoves.entries
            .where((entry) => entry.key <= level)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      names.addAll(entry.value);
    }

    return _unique(names);
  }

  List<String> _allMoveChoices([List<String>? tmMoves]) {
    return _unique([
      ..._movesUpToLevel(20),
      ...(tmMoves ?? _tmMoveNames),
      ...widget.availableMoves,
      ..._selectedMoves,
    ])..sort();
  }

  List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(MoveData.referenceKey(normalized))) result.add(normalized);
    }

    return result;
  }

  String _labelFromId(String id) {
    return id
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  TeamSlot _updatedSlot() {
    final nickname = _nicknameController.text.trim();
    final formName = _formChoices.length > 1 ? _formName : null;

    return widget.slot.copyWith(
      nickname: nickname.isEmpty || nickname == widget.pokemon.name
          ? null
          : nickname,
      isShiny: _isShiny,
      gender: _gender,
      formName: formName,
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

  Future<void> _reloadVariantDependentChoices() async {
    final tmMap = await _tmRepository.getTmMap();
    final tmMoveNames = await _tmMoveNamesFromRepository(tmMap);
    final moveData = await _moveRepository.getMoves(
      _allMoveChoices(tmMoveNames),
    );
    if (!mounted) return;

    setState(() {
      _tmMoveNames = tmMoveNames;
      _moveData = moveData;
    });
  }

  Future<void> _setGender(String? value) async {
    setState(() => _gender = value);
    await _reloadVariantDependentChoices();
  }

  Future<void> _pickForm() async {
    if (_formChoices.length <= 1) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _FormPickerSheet(
        pokemon: widget.pokemon,
        currentFormName: _formName,
        gender: _gender,
        isShiny: _isShiny,
        choices: _formChoices,
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _formName = result);
    await _reloadVariantDependentChoices();
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
          tmMoves: _tmMoveNames,
          allMoves: _allMoveChoices(),
          blockedMoves: blocked,
          moveData: _moveData,
        ),
      ),
    );

    if (!mounted || result == null) return;

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

    if (!mounted || result == null) return;

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
          title: 'Scegli abilità',
          options: _availableAbilities(),
          pinnedOptions: _naturalAbilities().toSet(),
          blockedOptions: blocked,
          descriptions: _abilityDescriptions,
          pinnedLabel: 'Abilità naturali del Pokémon',
        ),
      ),
    );

    if (!mounted || result == null) return;

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

    if (!mounted || result == null) return;

    setState(() {
      if (index == null) {
        _extraSkills = [..._extraSkills, result];
      } else {
        _extraSkills[index] = result;
      }
    });
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
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Qualsiasi'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'male',
                            child: Text('Maschio'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'female',
                            child: Text('Femmina'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'genderless',
                            child: Text('Genderless'),
                          ),
                        ],
                        onChanged: (value) {
                          _setGender(value);
                        },
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
                if (_formChoices.length > 1)
                  _CollapsibleEditSection(
                    title: 'Forma',
                    isOpen: _formOpen,
                    onToggle: () => setState(() => _formOpen = !_formOpen),
                    child: _FormSelector(
                      pokemon: widget.pokemon,
                      formName: _formName ?? _formChoices.first.name,
                      gender: _gender,
                      isShiny: _isShiny,
                      onTap: _pickForm,
                    ),
                  ),
                _CollapsibleEditSection(
                  title: 'Move set',
                  isOpen: _movesOpen,
                  onToggle: () => setState(() => _movesOpen = !_movesOpen),
                  child: _MoveSlotGrid(
                    selectedMoves: _selectedMoves,
                    moveData: _moveData,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChipSlots(
                        values: _abilities,
                        emptyLabel: 'ABILITY',
                        onAdd: _abilities.length >= 2
                            ? null
                            : () => _pickAbility(),
                        onPick: _pickAbility,
                        onRemove: (index) {
                          setState(() => _abilities.removeAt(index));
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puoi scegliere tra le abilità naturali del Pokémon o dal catalogo completo. Le abilità deprecated non sono selezionabili.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _CollapsibleEditSection(
                  title: 'Feats',
                  isOpen: _featsOpen,
                  onToggle: () => setState(() => _featsOpen = !_featsOpen),
                  child: _ChipSlots(
                    values: _feats,
                    emptyLabel: 'FEAT',
                    onAdd: () => _pickFeat(),
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
                    onAdd: () => _pickSkill(),
                    onPick: _pickSkill,
                    onRemove: (index) {
                      setState(() => _extraSkills.removeAt(index));
                    },
                  ),
                ),

                _CollapsibleEditSection(
                  title: 'Extra ability score',
                  isOpen: _extraAsiOpen,
                  onToggle: () =>
                      setState(() => _extraAsiOpen = !_extraAsiOpen),
                  child: Column(
                    children: [
                      for (final key in _customAbilityScores.keys.toList())
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

class _FormSelector extends StatelessWidget {
  const _FormSelector({
    required this.pokemon,
    required this.formName,
    required this.gender,
    required this.isShiny,
    required this.onTap,
  });

  final Pokemon pokemon;
  final String formName;
  final String? gender;
  final bool isShiny;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: PokemonAssetImage(
          pokemon: pokemon,
          formName: formName,
          gender: gender,
          isShiny: isShiny,
          size: 52,
        ),
        title: Text(formName.toUpperCase()),
        subtitle: const Text('Tocca per cambiare forma.'),
        trailing: const Icon(Icons.swap_horiz),
        onTap: onTap,
      ),
    );
  }
}

class _FormPickerSheet extends StatelessWidget {
  const _FormPickerSheet({
    required this.pokemon,
    required this.currentFormName,
    required this.gender,
    required this.isShiny,
    required this.choices,
  });

  final Pokemon pokemon;
  final String? currentFormName;
  final String? gender;
  final bool isShiny;
  final List<PokemonFormChoice> choices;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Scegli forma',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final choice in choices)
              Card(
                child: ListTile(
                  leading: PokemonAssetImage(
                    pokemon: pokemon,
                    formName: choice.name,
                    gender: gender,
                    isShiny: isShiny,
                    size: 52,
                  ),
                  title: Text(choice.name.toUpperCase()),
                  trailing: choice.name == currentFormName
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () => Navigator.of(context).pop(choice.name),
                ),
              ),
          ],
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
    required this.moveData,
    required this.onPick,
    required this.onRemove,
  });

  final List<String> selectedMoves;
  final Map<String, MoveData?> moveData;
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
        final moveName = hasMove ? selectedMoves[index] : 'MOVE';
        return _SingleSlot(
          label: hasMove ? (moveData[moveName]?.name ?? moveName) : moveName,
          type: hasMove ? moveData[moveName]?.type : null,
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
  const _SingleSlot({
    required this.label,
    required this.onTap,
    this.onRemove,
    this.type,
  });

  final String label;
  final String? type;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final type = this.type;

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type != null) ...[
                PokemonTypeBadge(type: type, height: 18),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
    required this.moveData,
  });

  final List<String> currentLevelMoves;
  final List<String> level20Moves;
  final List<String> tmMoves;
  final List<String> allMoves;
  final Set<String> blockedMoves;
  final Map<String, MoveData?> moveData;

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
    final search = _search.trim().toLowerCase();

    return source.where((move) => !widget.blockedMoves.contains(move)).where((
      move,
    ) {
      if (search.isEmpty) return true;
      final data = widget.moveData[move];
      return move.toLowerCase().contains(search) ||
          (data?.description.toLowerCase().contains(search) ?? false) ||
          (data?.type.toLowerCase().contains(search) ?? false);
    }).toList()..sort();
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
          label: 'MT',
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
            label: widget.moveData[move]?.name ?? move,
            type: widget.moveData[move]?.type,
            subtitle: widget.moveData[move]?.description,
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
    this.pinnedOptions = const {},
    this.pinnedLabel,
    this.blockedOptions = const {},
    this.descriptions = const {},
    this.includeNone = false,
  });

  static const noneValue = '__none__';

  final String title;
  final List<String> options;
  final Set<String> pinnedOptions;
  final String? pinnedLabel;
  final Set<String> blockedOptions;
  final Map<String, String> descriptions;
  final bool includeNone;

  @override
  State<_ChoicePickerScreen> createState() => _ChoicePickerScreenState();
}

class _ChoicePickerScreenState extends State<_ChoicePickerScreen> {
  String _search = '';

  List<String> get _options {
    final search = _search.trim().toLowerCase();

    return widget.options
        .where((option) => !widget.blockedOptions.contains(option))
        .where((option) {
          if (search.isEmpty) return true;
          return option.toLowerCase().contains(search) ||
              (widget.descriptions[option] ?? '').toLowerCase().contains(
                search,
              );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final pinnedOptions = options
        .where((option) => widget.pinnedOptions.contains(option))
        .toList(growable: false);
    final otherOptions = options
        .where((option) => !widget.pinnedOptions.contains(option))
        .toList(growable: false);

    return _ChoiceShell(
      title: widget.title,
      searchLabel: 'Cerca',
      onSearchChanged: (value) => setState(() => _search = value),
      children: [
        if (widget.includeNone)
          _PickerTile(
            label: 'Nessuno',
            onTap: () =>
                Navigator.of(context).pop(_ChoicePickerScreen.noneValue),
          ),
        if (pinnedOptions.isNotEmpty && widget.pinnedLabel != null)
          _PickerGroupLabel(label: widget.pinnedLabel!),
        for (final option in pinnedOptions)
          _PickerTile(
            label: option,
            subtitle: widget.descriptions[option],
            pinned: true,
            onTap: () => Navigator.of(context).pop(option),
          ),
        if (pinnedOptions.isNotEmpty && otherOptions.isNotEmpty)
          const _PickerGroupLabel(label: 'Catalogo completo'),
        for (final option in otherOptions)
          _PickerTile(
            label: option,
            subtitle: widget.descriptions[option],
            onTap: () => Navigator.of(context).pop(option),
          ),
        if (options.isEmpty && !widget.includeNone)
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

class _PickerGroupLabel extends StatelessWidget {
  const _PickerGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
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
  const _PickerTile({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.type,
    this.pinned = false,
  });

  final String label;
  final String? subtitle;
  final String? type;
  final bool pinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = this.type;

    return Card(
      child: ListTile(
        leading: type == null
            ? Icon(pinned ? Icons.star : Icons.radio_button_unchecked)
            : SizedBox(
                width: 74,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PokemonTypeBadge(type: type, height: 22),
                ),
              ),
        title: Text(label.toUpperCase()),
        subtitle: subtitle == null || subtitle!.isEmpty
            ? null
            : Text(subtitle!, maxLines: 5, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}
