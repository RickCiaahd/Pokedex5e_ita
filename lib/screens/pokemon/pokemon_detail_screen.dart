import 'package:flutter/material.dart';

import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../repositories/ability_repository.dart';
import '../../repositories/move_repository.dart';

class PokemonDetailScreen extends StatefulWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
    this.teamSlot,
    this.onTeamSlotChanged,
  });

  final Pokemon pokemon;
  final TeamSlot? teamSlot;
  final ValueChanged<TeamSlot>? onTeamSlotChanged;

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final MoveRepository _moveRepository = MoveRepository();
  final AbilityRepository _abilityRepository = AbilityRepository();

  TeamSlot? _teamSlot;
  Map<String, MoveData?> _moves = {};
  Map<String, String> _abilities = {};
  bool _isLoading = true;

  bool get _isPartyMode => _teamSlot != null;
  int get _experience => _teamSlot?.experience ?? 0;
  int get _level => _teamSlot == null
      ? widget.pokemon.minLevelFound
      : LevelProgression.levelFromExperience(_experience);
  int get _currentHp {
    final savedHp = _teamSlot?.currentHp ?? 0;
    return savedHp <= 0 ? widget.pokemon.hitPoints : savedHp;
  }

  @override
  void initState() {
    super.initState();
    _teamSlot = widget.teamSlot;
    _loadData();
  }

  Future<void> _loadData() async {
    final moveNames = <String>{
      ...widget.pokemon.moves.startingMoves,
      ...widget.pokemon.moves.levelMoves.values.expand((moves) => moves),
      'Struggle',
    };

    final moves = await _moveRepository.getMoves(moveNames);
    final abilities = await _abilityRepository.getAbilityDescriptions();

    if (!mounted) return;

    setState(() {
      _moves = moves;
      _abilities = abilities;
      _isLoading = false;
    });
  }

  Future<void> _editExperience() async {
    final slot = _teamSlot;
    if (slot == null) return;

    final input = await showDialog<String>(
      context: context,
      builder: (_) => _ExperienceDialog(currentExperience: slot.experience),
    );

    if (input == null) return;

    final updatedSlot = slot.copyWith(
      experience: LevelProgression.applyExperienceInput(
        currentExperience: slot.experience,
        input: input,
      ),
    );

    setState(() {
      _teamSlot = updatedSlot;
    });
    widget.onTeamSlotChanged?.call(updatedSlot);
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _bestMoveModifier(MoveData move) {
    final attributes = {
      'STR': widget.pokemon.attributes.strength,
      'DEX': widget.pokemon.attributes.dexterity,
      'CON': widget.pokemon.attributes.constitution,
      'INT': widget.pokemon.attributes.intelligence,
      'WIS': widget.pokemon.attributes.wisdom,
      'CHA': widget.pokemon.attributes.charisma,
    };

    final modifiers = move.movePowers
        .where(attributes.containsKey)
        .map((power) => _modifier(attributes[power]!))
        .toList();

    if (modifiers.isEmpty) return 0;
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
    if (damage != null) parts.add(damage.label);
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);

    return parts.join('  ||  ');
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text(pokemon.name)),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _Header(
                    pokemon: pokemon,
                    level: _level,
                    experience: _experience,
                    currentHp: _currentHp,
                    isPartyMode: _isPartyMode,
                    onEditExperience: _editExperience,
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
                          pokemon: pokemon,
                          level: _level,
                          moves: _moves,
                          moveStatsBuilder: _moveStats,
                        ),
                        _FeaturesView(
                          pokemon: pokemon,
                          abilityDescriptions: _abilities,
                        ),
                        _TraitsView(
                          pokemon: pokemon,
                          modifierBuilder: _modifier,
                          proficiency: _proficiency(_level),
                        ),
                      ],
                    ),
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
    required this.experience,
    required this.currentHp,
    required this.isPartyMode,
    required this.onEditExperience,
  });

  final Pokemon pokemon;
  final int level;
  final int experience;
  final int currentHp;
  final bool isPartyMode;
  final VoidCallback onEditExperience;

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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.catching_pokemon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 60,
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
                    Text('$number ${pokemon.types.join(' / ')}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(label: 'Lv.', value: '$level'),
                        _Pill(label: 'AC', value: '${pokemon.armorClass}'),
                        _Pill(label: 'HP', value: '$currentHp/${pokemon.hitPoints}'),
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
    required this.pokemon,
    required this.level,
    required this.moves,
    required this.moveStatsBuilder,
  });

  final Pokemon pokemon;
  final int level;
  final Map<String, MoveData?> moves;
  final String Function(MoveData move) moveStatsBuilder;

  @override
  Widget build(BuildContext context) {
    final unlocked = pokemon.moves.levelMoves.entries
        .where((entry) => entry.key <= level)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final future = pokemon.moves.levelMoves.entries
        .where((entry) => entry.key > level)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _MoveSection(
          title: 'Mosse iniziali',
          names: pokemon.moves.startingMoves,
          moves: moves,
          moveStatsBuilder: moveStatsBuilder,
        ),
        for (final entry in unlocked)
          _MoveSection(
            title: 'Livello ${entry.key}',
            names: entry.value,
            moves: moves,
            moveStatsBuilder: moveStatsBuilder,
          ),
        _MoveSection(
          title: 'Sempre disponibile',
          names: const ['Struggle'],
          moves: moves,
          moveStatsBuilder: moveStatsBuilder,
        ),
        if (future.isNotEmpty)
          _InfoCard(
            title: 'Prossime mosse',
            child: Text(
              future
                  .map((entry) => 'Lv. ${entry.key}: ${entry.value.join(', ')}')
                  .join('\n'),
            ),
          ),
        if (pokemon.moves.tmMoves.isNotEmpty)
          _InfoCard(
            title: 'TM compatibili',
            child: Text(pokemon.moves.tmMoves.map((tm) => 'TM$tm').join(', ')),
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
    if (names.isEmpty) return const SizedBox.shrink();

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
  const _MoveCard({required this.name, required this.move, required this.stats});

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
                  Chip(label: Text(move.type)),
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
    required this.abilityDescriptions,
  });

  final Pokemon pokemon;
  final Map<String, String> abilityDescriptions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final ability in pokemon.abilities)
          _InfoCard(
            title: ability,
            child: Text(abilityDescriptions[ability] ?? 'Descrizione non disponibile.'),
          ),
        if (pokemon.hiddenAbility != null)
          _InfoCard(
            title: 'Nascosta: ${pokemon.hiddenAbility}',
            child: Text(
              abilityDescriptions[pokemon.hiddenAbility!] ??
                  'Descrizione non disponibile.',
            ),
          ),
      ],
    );
  }
}

class _TraitsView extends StatelessWidget {
  const _TraitsView({
    required this.pokemon,
    required this.modifierBuilder,
    required this.proficiency,
  });

  final Pokemon pokemon;
  final int Function(int score) modifierBuilder;
  final int proficiency;

  @override
  Widget build(BuildContext context) {
    final attributes = {
      'STR': pokemon.attributes.strength,
      'DEX': pokemon.attributes.dexterity,
      'CON': pokemon.attributes.constitution,
      'INT': pokemon.attributes.intelligence,
      'WIS': pokemon.attributes.wisdom,
      'CHA': pokemon.attributes.charisma,
    };

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
              _InfoRow(label: 'Livello minimo', value: '${pokemon.minLevelFound}'),
              _InfoRow(label: 'Tiri salvezza', value: pokemon.savingThrows.join(', ')),
              _InfoRow(label: 'Competenze', value: pokemon.skills.join(', ')),
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
