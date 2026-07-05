import 'package:flutter/material.dart';

import '../../models/evolution_data.dart';
import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/evolution_repository.dart';
import '../../repositories/feat_repository.dart';
import '../../repositories/move_repository.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import 'pokemon_edit_screen.dart';

class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    this.teamSlot,
    this.allPokemon = const [],
    this.team = const [],
    this.onTeamSlotChanged,
  });

  final Pokemon pokemon;
  final TeamSlot? teamSlot;
  final List<Pokemon> allPokemon;
  final List<TeamSlot> team;
  final ValueChanged<TeamSlot>? onTeamSlotChanged;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final MoveRepository _moveRepository = MoveRepository();
  final AbilityRepository _abilityRepository = AbilityRepository();
  final EvolutionRepository _evolutionRepository = EvolutionRepository();
  final FeatRepository _featRepository = FeatRepository();

  late Pokemon _pokemon;
  late List<TeamSlot> _team;
  TeamSlot? _teamSlot;
  Map<String, MoveData?> _moves = {};
  Map<String, String> _abilities = {};
  Map<String, String> _featDescriptions = {};
  Map<String, EvolutionData> _evolutions = {};
  bool _isLoading = true;

  bool get _isPartyMode => _teamSlot != null;
  int get _experience => _teamSlot?.experience ?? 0;
  int get _level => _teamSlot == null
      ? _pokemon.minLevelFound
      : LevelProgression.levelFromExperience(_experience);
  int get _currentHp {
    final savedHp = _teamSlot?.currentHp ?? 0;
    return savedHp <= 0 ? _pokemon.hitPoints : savedHp;
  }

  int get _armorClass {
    final natureScores = PokemonNature.forName(
      _teamSlot?.nature ?? 'No Nature',
    );
    return _pokemon.armorClass + (natureScores['AC'] ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _pokemon = widget.pokemon;
    _team = [...widget.team];
    _teamSlot = widget.teamSlot;
    _ensureSelectedMovesIsSaved();
    _loadData();
  }

  void _replaceTeamSlot(TeamSlot updatedSlot) {
    final index = _team.indexWhere(
      (slot) => slot.slotIndex == updatedSlot.slotIndex,
    );
    if (index == -1) {
      _team = [..._team, updatedSlot];
      return;
    }

    _team = [..._team]..[index] = updatedSlot;
  }

  Future<void> _loadData() async {
    final moveNames = <String>{
      ..._pokemon.moves.startingMoves,
      ..._pokemon.moves.levelMoves.values.expand((moves) => moves),
      ...?_teamSlot?.selectedMoves,
      'Struggle',
    };

    final results = await Future.wait([
      _moveRepository.getMoves(moveNames),
      _abilityRepository.getAbilityDescriptions(),
      _evolutionRepository.getEvolutionData(),
      _featRepository.getFeatDescriptions(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _moves = results[0] as Map<String, MoveData?>;
      _abilities = results[1] as Map<String, String>;
      _evolutions = results[2] as Map<String, EvolutionData>;
      _featDescriptions = results[3] as Map<String, String>;
      _isLoading = false;
    });
  }

  List<String> _learnedMovesFor(Pokemon pokemon, int level) {
    final names = <String>[];
    names.addAll(pokemon.moves.startingMoves);

    final levelEntries =
        pokemon.moves.levelMoves.entries
            .where((entry) => entry.key <= level)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in levelEntries) {
      names.addAll(entry.value);
    }

    return names.toSet().toList();
  }

  List<String> _defaultSelectedMoves(Pokemon pokemon, int level) {
    return _learnedMovesFor(pokemon, level).take(4).toList();
  }

  List<String> _selectedMoves() {
    final slot = _teamSlot;
    if (slot == null) {
      return _defaultSelectedMoves(_pokemon, _level);
    }
    if (slot.selectedMoves.isEmpty) {
      return _defaultSelectedMoves(_pokemon, _level);
    }
    return slot.selectedMoves.take(4).toList();
  }

  void _ensureSelectedMovesIsSaved() {
    final slot = _teamSlot;
    if (slot == null || slot.selectedMoves.isNotEmpty) {
      return;
    }

    final updatedSlot = slot.copyWith(
      selectedMoves: _defaultSelectedMoves(_pokemon, _level),
      currentHp: slot.currentHp <= 0 ? _pokemon.hitPoints : slot.currentHp,
    );
    _teamSlot = updatedSlot;
    _replaceTeamSlot(updatedSlot);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTeamSlotChanged?.call(updatedSlot);
    });
  }

  Future<void> _editExperience() async {
    final slot = _teamSlot;
    if (slot == null) {
      return;
    }

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _ExperienceDialog(currentExperience: slot.experience),
    );

    if (input == null) {
      return;
    }

    final oldLevel = LevelProgression.levelFromExperience(slot.experience);
    final updatedExperience = LevelProgression.applyExperienceInput(
      currentExperience: slot.experience,
      input: input,
    );
    final newLevel = LevelProgression.levelFromExperience(updatedExperience);

    var updatedSlot = slot.copyWith(experience: updatedExperience);

    if (newLevel > oldLevel) {
      updatedSlot = await _applyLevelUpMoves(updatedSlot, oldLevel, newLevel);
    }

    setState(() {
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
  }

  Future<TeamSlot> _applyLevelUpMoves(
    TeamSlot slot,
    int oldLevel,
    int newLevel,
  ) async {
    var selectedMoves = slot.selectedMoves.isEmpty
        ? _defaultSelectedMoves(_pokemon, oldLevel)
        : slot.selectedMoves.take(4).toList();

    final learnedEntries =
        _pokemon.moves.levelMoves.entries
            .where((entry) => entry.key > oldLevel && entry.key <= newLevel)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in learnedEntries) {
      for (final move in entry.value) {
        if (selectedMoves.contains(move)) {
          continue;
        }

        if (selectedMoves.length < 4) {
          selectedMoves.add(move);
          continue;
        }

        final moveData = _moves[move] ?? await _moveRepository.getMove(move);
        final replacedMove = await _askMoveReplacement(
          move,
          selectedMoves,
          moveData,
        );
        if (replacedMove == null) {
          continue;
        }

        final replaceIndex = selectedMoves.indexOf(replacedMove);
        if (replaceIndex >= 0) {
          selectedMoves[replaceIndex] = move;
        }
      }
    }

    return slot.copyWith(selectedMoves: selectedMoves);
  }

  Future<String?> _askMoveReplacement(
    String newMove,
    List<String> selectedMoves,
    MoveData? moveData,
  ) async {
    return showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Vuoi imparare $newMove?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoveCard(
                name: newMove,
                move: moveData,
                stats: moveData == null ? null : _moveStats(moveData),
              ),
              const SizedBox(height: 8),
              const Text(
                'Il moveset e gia pieno. Scegli una mossa da dimenticare.',
              ),
            ],
          ),
        ),
        actions: [
          for (final move in selectedMoves)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(move);
              },
              child: Text('Dimentica $move'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Non imparare $newMove'),
          ),
        ],
      ),
    );
  }

  Pokemon? _pokemonById(int? pokemonId) {
    if (pokemonId == null) {
      return null;
    }

    for (final pokemon in widget.allPokemon) {
      if (pokemon.id == pokemonId) {
        return pokemon;
      }
    }

    return null;
  }

  Pokemon? _pokemonByName(String name) {
    for (final pokemon in widget.allPokemon) {
      if (pokemon.name == name) {
        return pokemon;
      }
    }

    return null;
  }

  Future<void> _openEditScreen() async {
    final slot = _teamSlot;
    if (slot == null) {
      return;
    }

    final result = await Navigator.of(context).push<PokemonEditResult>(
      MaterialPageRoute(
        builder: (_) => PokemonEditScreen(
          pokemon: _pokemon,
          slot: slot,
          availableMoves: _learnedMovesFor(_pokemon, _level),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final updatedSlot = result.slot;

    setState(() {
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
    await _loadData();
  }

  bool _canEvolveCurrentPokemon() {
    final evolution = _evolutions[_pokemon.name];
    return evolution != null &&
        evolution.canEvolve &&
        evolution.level != null &&
        _level >= evolution.level!;
  }

  String? _evolutionLabel() {
    final evolution = _evolutions[_pokemon.name];
    if (evolution == null || !evolution.canEvolve) {
      return null;
    }
    if (evolution.evolutions.isEmpty) {
      return null;
    }
    return 'FAI EVOLVERE IN ${evolution.evolutions.first.toUpperCase()}';
  }

  Future<void> _evolveCurrentPokemon() async {
    final slot = _teamSlot;
    if (slot == null) {
      return;
    }

    final updatedSlot = await _evolveSlot(slot);
    if (updatedSlot == null) {
      return;
    }

    widget.onTeamSlotChanged?.call(updatedSlot);
    await _loadData();
  }

  Future<TeamSlot?> _evolveSlot(TeamSlot slot) async {
    final evolution = _evolutions[_pokemon.name];
    if (evolution == null ||
        !evolution.canEvolve ||
        _level < evolution.level!) {
      return null;
    }

    final evolutionName = evolution.evolutions.first;
    final evolvedPokemon = _pokemonByName(evolutionName);
    if (evolvedPokemon == null) {
      return null;
    }

    final wasFullHp = _currentHp >= _pokemon.hitPoints;
    final oldName = _pokemon.name;
    final updatedSlot = slot.copyWith(
      pokemonId: evolvedPokemon.id,
      currentHp: wasFullHp ? evolvedPokemon.hitPoints : _currentHp,
      selectedMoves: List<String>.from(slot.selectedMoves),
    );

    if (!mounted) {
      return updatedSlot;
    }

    setState(() {
      _pokemon = evolvedPokemon;
      _teamSlot = updatedSlot;
      _replaceTeamSlot(updatedSlot);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$oldName si e evoluto in $evolutionName!')),
    );

    return updatedSlot;
  }

  Future<void> _switchPartySlot(TeamSlot slot) async {
    final pokemon = _pokemonById(slot.pokemonId);
    if (pokemon == null) {
      return;
    }

    setState(() {
      _pokemon = pokemon;
      _teamSlot = slot;
      _isLoading = true;
    });
    _ensureSelectedMovesIsSaved();
    await _loadData();
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _proficiency(int level) {
    if (level >= 17) {
      return 6;
    }
    if (level >= 13) {
      return 5;
    }
    if (level >= 9) {
      return 4;
    }
    if (level >= 5) {
      return 3;
    }
    return 2;
  }

  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot? slot) {
    final customScores = slot?.customAbilityScores ?? const <String, int>{};
    final natureScores = PokemonNature.forName(slot?.nature ?? 'No Nature');

    return {
      'STR':
          pokemon.attributes.strength +
          (customScores['STR'] ?? 0) +
          (natureScores['STR'] ?? 0),
      'DEX':
          pokemon.attributes.dexterity +
          (customScores['DEX'] ?? 0) +
          (natureScores['DEX'] ?? 0),
      'CON':
          pokemon.attributes.constitution +
          (customScores['CON'] ?? 0) +
          (natureScores['CON'] ?? 0),
      'INT':
          pokemon.attributes.intelligence +
          (customScores['INT'] ?? 0) +
          (natureScores['INT'] ?? 0),
      'WIS':
          pokemon.attributes.wisdom +
          (customScores['WIS'] ?? 0) +
          (natureScores['WIS'] ?? 0),
      'CHA':
          pokemon.attributes.charisma +
          (customScores['CHA'] ?? 0) +
          (natureScores['CHA'] ?? 0),
    };
  }

  int _bestMoveModifier(MoveData move) {
    final attributes = _attributeScores(_pokemon, _teamSlot);

    final modifiers = move.movePowers
        .where(attributes.containsKey)
        .map((power) => _modifier(attributes[power]!))
        .toList();

    if (modifiers.isEmpty) {
      return 0;
    }
    modifiers.sort();
    return modifiers.last;
  }

  String _moveStats(MoveData move) {
    final parts = <String>[];
    final moveModifier = _bestMoveModifier(move);
    final proficiency = _proficiency(_level);

    if (move.isAttack) {
      final attackBonus = moveModifier + proficiency;
      parts.add('AB: ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) {
      parts.add('DC: ${8 + proficiency + moveModifier}');
    }

    final damage = move.damageForLevel(_level);
    if (damage != null) {
      parts.add(damage.label);
    }
    if (move.range != '-') {
      parts.add(move.range);
    }
    if (move.duration != '-') {
      parts.add(move.duration);
    }

    return parts.join('  ||  ');
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _pokemon;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_teamSlot?.nickname ?? pokemon.name),
          actions: [
            if (_isPartyMode)
              IconButton(
                tooltip: 'Modifica',
                onPressed: _openEditScreen,
                icon: const Icon(Icons.edit),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _Header(
                    pokemon: pokemon,
                    level: _level,
                    armorClass: _armorClass,
                    experience: _experience,
                    currentHp: _currentHp,
                    isPartyMode: _isPartyMode,
                    onEditExperience: _editExperience,
                    canEvolve: _canEvolveCurrentPokemon(),
                    evolutionLabel: _evolutionLabel(),
                    onEvolve: _evolveCurrentPokemon,
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'MOSSE'),
                      Tab(text: 'FEATURES'),
                      Tab(text: 'TRAITS'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _MovesView(
                          selectedMoves: _selectedMoves(),
                          moves: _moves,
                          moveStatsBuilder: _moveStats,
                        ),
                        _FeaturesView(
                          pokemon: pokemon,
                          slot: _teamSlot,
                          abilityDescriptions: _abilities,
                          featDescriptions: _featDescriptions,
                        ),
                        _TraitsView(
                          pokemon: pokemon,
                          slot: _teamSlot,
                          attributes: _attributeScores(pokemon, _teamSlot),
                          modifierBuilder: _modifier,
                          proficiency: _proficiency(_level),
                        ),
                      ],
                    ),
                  ),
                  if (_isPartyMode)
                    _PartySwitcher(
                      team: _team,
                      currentSlotIndex: _teamSlot!.slotIndex,
                      pokemonById: _pokemonById,
                      onSelect: _switchPartySlot,
                    ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pokemon,
    required this.level,
    required this.armorClass,
    required this.experience,
    required this.currentHp,
    required this.isPartyMode,
    required this.onEditExperience,
    required this.canEvolve,
    required this.evolutionLabel,
    required this.onEvolve,
  });

  final Pokemon pokemon;
  final int level;
  final int armorClass;
  final int experience;
  final int currentHp;
  final bool isPartyMode;
  final VoidCallback onEditExperience;
  final bool canEvolve;
  final String? evolutionLabel;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final nextThreshold = LevelProgression.nextThresholdForLevel(level);
    final currentThreshold = LevelProgression.thresholdForLevel(level);
    final range = nextThreshold - currentThreshold;
    final progress = range <= 0
        ? 1.0
        : ((experience - currentThreshold) / range).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Center(
                  child: PokemonAssetImage(
                    pokemon: pokemon,
                    useLargeArtwork: true,
                    size: 104,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pokemon.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(number),
                        for (final type in pokemon.types)
                          PokemonTypeBadge(type: type, height: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(label: 'Lv.', value: '$level'),
                        _Pill(label: 'AC', value: '$armorClass'),
                        _Pill(
                          label: 'HP',
                          value: '$currentHp/${pokemon.hitPoints}',
                        ),
                        _Pill(label: 'SR', value: pokemon.sr.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPartyMode) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onEditExperience,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'EXP: $experience/$nextThreshold',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
              ),
            ),
            if (canEvolve && evolutionLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onEvolve,
                  child: Text(evolutionLabel!),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label $value'));
  }
}

class _MovesView extends StatelessWidget {
  const _MovesView({
    required this.selectedMoves,
    required this.moves,
    required this.moveStatsBuilder,
  });

  final List<String> selectedMoves;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MoveSection(
          title: 'Moveset',
          names: [...selectedMoves, 'Struggle'],
          moves: moves,
          moveStatsBuilder: moveStatsBuilder,
        ),
      ],
    );
  }
}

class _MoveSection extends StatelessWidget {
  const _MoveSection({
    required this.title,
    required this.names,
    required this.moves,
    required this.moveStatsBuilder,
  });

  final String title;
  final List<String> names;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(title.toUpperCase()),
        ),
        for (final name in names)
          _MoveCard(
            name: name,
            move: moves[name],
            stats: moves[name] == null ? null : moveStatsBuilder(moves[name]!),
          ),
      ],
    );
  }
}

class _MoveCard extends StatelessWidget {
  const _MoveCard({
    required this.name,
    required this.move,
    required this.stats,
  });

  final String name;
  final MoveData? move;
  final String? stats;

  @override
  Widget build(BuildContext context) {
    final move = this.move;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_unchecked, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (move != null) Text('PP ${move.pp}'),
              ],
            ),
            const SizedBox(height: 8),
            if (move == null)
              const Text('Dettagli mossa non disponibili.')
            else ...[
              if (stats != null && stats!.isNotEmpty) Text(stats!),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  PokemonTypeBadge(type: move.type, height: 24),
                  Chip(label: Text(move.moveTime)),
                ],
              ),
              if (move.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(move.description),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturesView extends StatelessWidget {
  const _FeaturesView({
    required this.pokemon,
    required this.slot,
    required this.abilityDescriptions,
    required this.featDescriptions,
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final Map<String, String> abilityDescriptions;
  final Map<String, String> featDescriptions;

  @override
  Widget build(BuildContext context) {
    final feats = slot?.feats ?? const <String>[];
    final abilities = slot?.abilities.isNotEmpty == true
        ? slot!.abilities
        : [
            ...pokemon.abilities,
            if (pokemon.hiddenAbility != null && feats.contains('Hidden Ability'))
              pokemon.hiddenAbility!,
          ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final ability in abilities)
          _InfoCard(
            title: ability,
            child: Text(
              abilityDescriptions[ability] ?? 'Descrizione non disponibile.',
            ),
          ),
        for (final feat in feats)
          _InfoCard(
            title: feat,
            child: Text(
              featDescriptions[feat] ?? 'Descrizione non disponibile.',
            ),
          ),
        if (abilities.isEmpty && feats.isEmpty)
          const _InfoCard(
            title: 'Features',
            child: Text('Nessuna feature disponibile.'),
          ),
      ],
    );
  }
}

class _TraitsView extends StatelessWidget {
  const _TraitsView({
    required this.pokemon,
    required this.slot,
    required this.attributes,
    required this.modifierBuilder,
    required this.proficiency,
  });

  final Pokemon pokemon;
  final TeamSlot? slot;
  final Map<String, int> attributes;
  final int Function(int score) modifierBuilder;
  final int proficiency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                for (final entry in attributes.entries)
                  _AttributeBox(
                    label: entry.key,
                    score: entry.value,
                    modifier: modifierBuilder(entry.value),
                  ),
              ],
            ),
          ),
        ),
        _InfoCard(
          title: 'Dettagli',
          child: Column(
            children: [
              _InfoRow(label: 'Taglia', value: pokemon.size),
              _InfoRow(label: 'Velocità', value: '${pokemon.speed} ft'),
              _InfoRow(label: 'Dado vita', value: 'd${pokemon.hitDice}'),
              _InfoRow(label: 'Competenza', value: '+$proficiency'),
              _InfoRow(
                label: 'Livello minimo',
                value: '${pokemon.minLevelFound}',
              ),
              _InfoRow(
                label: 'Tiri salvezza',
                value: pokemon.savingThrows.join(', '),
              ),
              _InfoRow(
                label: 'Competenze',
                value: [...pokemon.skills, ...?slot?.extraSkills].join(', '),
              ),
              _InfoRow(label: 'Natura', value: slot?.nature ?? 'No Nature'),
              _InfoRow(
                label: 'Shiny',
                value: slot?.isShiny == true ? 'Si' : 'No',
              ),
              _InfoRow(label: 'Sesso', value: slot?.gender ?? '-'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttributeBox extends StatelessWidget {
  const _AttributeBox({
    required this.label,
    required this.score,
    required this.modifier,
  });

  final String label;
  final int score;
  final int modifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label $score'),
        Text(
          '${modifier >= 0 ? '+' : ''}$modifier',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _PartySwitcher extends StatelessWidget {
  const _PartySwitcher({
    required this.team,
    required this.currentSlotIndex,
    required this.pokemonById,
    required this.onSelect,
  });

  final List<TeamSlot> team;
  final int currentSlotIndex;
  final Pokemon? Function(int? pokemonId) pokemonById;
  final ValueChanged<TeamSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedTeam = [...team]
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final slot in sortedTeam)
              Expanded(
                child: _PartySlotButton(
                  slot: slot,
                  pokemon: pokemonById(slot.pokemonId),
                  isActive: slot.slotIndex == currentSlotIndex,
                  onTap: slot.pokemonId == null ? null : () => onSelect(slot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartySlotButton extends StatelessWidget {
  const _PartySlotButton({
    required this.slot,
    required this.pokemon,
    required this.isActive,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pokemon == null
                ? Icon(Icons.radio_button_unchecked, color: colorScheme.outline)
                : PokemonAssetImage(pokemon: pokemon, size: 30),
            const SizedBox(height: 2),
            Text(
              pokemon == null
                  ? '${slot.slotIndex + 1}'
                  : '#${pokemon.id.toString().padLeft(3, '0')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({required this.currentExperience});

  final int currentExperience;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica esperienza'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Esperienza',
          helperText: 'Usa +2000 per aggiungere, 2000 per impostare.',
          hintText: widget.currentExperience.toString(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salva')),
      ],
    );
  }
}
