import 'package:flutter/material.dart';

import '../../models/level_progression.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final MoveRepository _moveRepository = MoveRepository();

  late Future<_BattleData> _dataFuture;
  final Map<int, Map<String, int>> _remainingPpBySlot = {};

  int? _activeSlotIndex;
  int _round = 1;
  String? _message;

  static const List<String> _statusOptions = [
    'Asleep',
    'Burned',
    'Confused',
    'Frozen',
    'Paralyzed',
    'Poisoned',
  ];

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadBattleData();
  }

  Future<_BattleData> _loadBattleData() async {
    final profile = await _profileRepository.getActiveProfile();
    final team = await _teamRepository.getTeam(profile.id);
    team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    final pokemonList = await _pokemonRepository.getAllPokemon();
    final pokemonById = {for (final pokemon in pokemonList) pokemon.id: pokemon};
    final moveReferences = <String>{'Struggle'};

    for (final slot in team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;

      final pokemon = pokemonById[pokemonId];
      if (pokemon == null) continue;

      moveReferences.addAll(_movesForSlot(slot, pokemon));
    }

    final moves = await _moveRepository.getMoves(moveReferences);

    return _BattleData(
      profile: profile,
      team: team,
      pokemonById: pokemonById,
      moves: moves,
    );
  }

  Future<void> _reload({String? message}) async {
    if (!mounted) return;

    setState(() {
      _message = message;
      _dataFuture = _loadBattleData();
    });
  }

  TeamSlot? _activeSlotFor(_BattleData data) {
    if (data.occupiedSlots.isEmpty) return null;

    for (final slot in data.occupiedSlots) {
      if (slot.slotIndex == _activeSlotIndex) return slot;
    }

    return data.occupiedSlots.first;
  }

  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    return data.pokemonById[pokemonId];
  }

  List<String> _movesForSlot(TeamSlot slot, Pokemon pokemon) {
    if (slot.selectedMoves.isNotEmpty) {
      return slot.selectedMoves.take(4).toList(growable: false);
    }

    return _defaultSelectedMoves(pokemon, _levelForSlot(slot));
  }

  List<String> _defaultSelectedMoves(Pokemon pokemon, int level) {
    final names = <String>[...pokemon.moves.startingMoves];
    final levelEntries = pokemon.moves.levelMoves.entries
        .where((entry) => entry.key <= level)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in levelEntries) {
      names.addAll(entry.value);
    }

    return names.toSet().take(4).toList(growable: false);
  }

  int _levelForSlot(TeamSlot slot) {
    return LevelProgression.levelFromExperience(slot.experience);
  }

  int _maxPpFor(MoveData? move) {
    if (move == null) return 0;

    final direct = int.tryParse(move.pp.trim());
    if (direct != null) return direct;

    final match = RegExp(r'\d+').firstMatch(move.pp);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  String _ppKey(String reference, MoveData? move) {
    return move?.id ?? MoveData.referenceKey(reference);
  }

  int _remainingPp(TeamSlot slot, String reference, MoveData? move) {
    final maxPp = _maxPpFor(move);
    final slotPp = _remainingPpBySlot.putIfAbsent(slot.slotIndex, () => {});
    return slotPp.putIfAbsent(_ppKey(reference, move), () => maxPp);
  }

  void _changePp(TeamSlot slot, String reference, MoveData? move, int delta) {
    final maxPp = _maxPpFor(move);
    if (maxPp <= 0) return;

    final slotPp = _remainingPpBySlot.putIfAbsent(slot.slotIndex, () => {});
    final key = _ppKey(reference, move);
    final current = slotPp[key] ?? maxPp;

    setState(() {
      slotPp[key] = (current + delta).clamp(0, maxPp).toInt();
    });
  }

  bool _hasNoPpLeft(
    TeamSlot slot,
    List<String> moveReferences,
    Map<String, MoveData?> moves,
  ) {
    final trackableMoves = moveReferences.where((reference) {
      return _maxPpFor(moves[reference]) > 0;
    }).toList(growable: false);

    if (trackableMoves.isEmpty) return false;

    return trackableMoves.every((reference) {
      return _remainingPp(slot, reference, moves[reference]) <= 0;
    });
  }

  Future<void> _changeHp(_BattleData data, TeamSlot slot, int delta) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    final maxHp = _maxHpFor(pokemon, slot);
    final updatedHp = (_currentHpFor(slot, pokemon) + delta).clamp(0, maxHp).toInt();

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(currentHp: updatedHp),
    );
    await _reload();
  }

  Future<void> _healFull(_BattleData data, TeamSlot slot) async {
    final pokemon = _pokemonForSlot(data, slot);
    if (pokemon == null) return;

    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(
        currentHp: _maxHpFor(pokemon, slot),
        statusEffects: const [],
      ),
    );
    await _reload(message: '${_displayName(slot, pokemon)} è pronto a combattere.');
  }

  Future<void> _setStatusEffects(
    _BattleData data,
    TeamSlot slot,
    List<String> statuses,
  ) async {
    await _teamRepository.updateSlot(
      profileId: data.profile.id,
      updatedSlot: slot.copyWith(statusEffects: statuses),
    );
    await _reload();
  }

  Future<void> _openStatusPicker(_BattleData data, TeamSlot slot) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final selected = slot.statusEffects.toSet();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Text(
                      'STATUS IN COMBATTIMENTO',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  for (final status in _statusOptions)
                    CheckboxListTile(
                      title: Text(status.toUpperCase()),
                      value: selected.contains(status),
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            selected.add(status);
                          } else {
                            selected.remove(status);
                          }
                        });
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.save_outlined),
                    title: const Text('SALVA STATUS'),
                    onTap: () => Navigator.of(context).pop(selected.toList()),
                  ),
                  if (selected.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('RIMUOVI TUTTI'),
                      onTap: () => Navigator.of(context).pop(const []),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    await _setStatusEffects(data, slot, result);
  }

  void _nextRound() {
    setState(() {
      _round += 1;
      _message = 'Round $_round iniziato.';
    });
  }

  void _resetBattle() {
    setState(() {
      _round = 1;
      _remainingPpBySlot.clear();
      _message = 'Tracker combattimento azzerato.';
    });
  }

  int _currentHpFor(TeamSlot slot, Pokemon pokemon) {
    return slot.currentHp.clamp(0, _maxHpFor(pokemon, slot)).toInt();
  }

  int _loyaltyHpBonus(int loyalty, int level) {
    if (loyalty == 2) return (level / 2).ceil();
    if (loyalty == 3) return level;
    return 0;
  }

  int _maxHpFor(Pokemon pokemon, TeamSlot slot) {
    final level = _levelForSlot(slot).clamp(1, LevelProgression.maxLevel).toInt();
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (level - minimumLevel).clamp(0, LevelProgression.maxLevel).toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final attributes = _attributeScores(pokemon, slot);
    final constitutionModifier = _modifier(attributes['CON'] ?? 10);
    final toughBonus = slot.feats.contains('Tough') ? level * 2 : 0;
    final loyaltyBonus = _loyaltyHpBonus(slot.loyalty, level);
    final scaledHp = pokemon.hitPoints +
        (hitDieAverage * levelsGained) +
        (constitutionModifier * level) +
        toughBonus +
        loyaltyBonus;

    return scaledHp < 1 ? 1 : scaledHp;
  }

  Map<String, int> _attributeScores(Pokemon pokemon, TeamSlot slot) {
    final customScores = slot.customAbilityScores;
    final natureScores = PokemonNature.forName(slot.nature);

    return {
      'STR': pokemon.attributes.strength +
          (customScores['STR'] ?? 0) +
          (natureScores['STR'] ?? 0),
      'DEX': pokemon.attributes.dexterity +
          (customScores['DEX'] ?? 0) +
          (natureScores['DEX'] ?? 0),
      'CON': pokemon.attributes.constitution +
          (customScores['CON'] ?? 0) +
          (natureScores['CON'] ?? 0),
      'INT': pokemon.attributes.intelligence +
          (customScores['INT'] ?? 0) +
          (natureScores['INT'] ?? 0),
      'WIS': pokemon.attributes.wisdom +
          (customScores['WIS'] ?? 0) +
          (natureScores['WIS'] ?? 0),
      'CHA': pokemon.attributes.charisma +
          (customScores['CHA'] ?? 0) +
          (natureScores['CHA'] ?? 0),
    };
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _proficiency(int level) {
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _bestMoveModifier(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final attributes = _attributeScores(pokemon, slot);
    final modifiers = move.movePowers
        .where(attributes.containsKey)
        .map((power) => _modifier(attributes[power]!))
        .toList();

    if (modifiers.isEmpty) return 0;
    modifiers.sort();
    return modifiers.last;
  }

  String _moveStats(MoveData move, Pokemon pokemon, TeamSlot slot) {
    final level = _levelForSlot(slot);
    final moveModifier = _bestMoveModifier(move, pokemon, slot);
    final proficiency = _proficiency(level);
    final parts = <String>[];

    if (move.isAttack) {
      final attackBonus = moveModifier + proficiency;
      parts.add('AB: ${attackBonus >= 0 ? '+' : ''}$attackBonus');
    }
    if (move.save != null) {
      parts.add('DC: ${8 + proficiency + moveModifier}');
    }

    final damage = move.damageForLevel(level);
    if (damage != null) parts.add(damage.label);
    if (move.range != '-') parts.add(move.range);
    if (move.duration != '-') parts.add(move.duration);

    return parts.join('  ||  ');
  }

  String _displayName(TeamSlot slot, Pokemon pokemon) {
    final nickname = slot.nickname?.trim();
    return nickname == null || nickname.isEmpty ? pokemon.name : nickname;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Battle Companion'),
        actions: [
          IconButton(
            tooltip: 'Reset combattimento',
            onPressed: _resetBattle,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_BattleData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _BattleEmptyState(
              icon: Icons.error_outline,
              title: 'Errore caricando il combattimento',
              message: snapshot.error.toString(),
              actionLabel: 'Riprova',
              onAction: () => _reload(),
            );
          }

          final data = snapshot.data;
          if (data == null || data.occupiedSlots.isEmpty) {
            return _BattleEmptyState(
              icon: Icons.groups_outlined,
              title: 'Nessun Pokémon in squadra',
              message:
                  'Aggiungi almeno un Pokémon alla squadra prima di aprire il tracker.',
              actionLabel: 'Ricarica',
              onAction: () => _reload(),
            );
          }

          final activeSlot = _activeSlotFor(data)!;
          final pokemon = _pokemonForSlot(data, activeSlot)!;
          final moveReferences = _movesForSlot(activeSlot, pokemon);
          final noPpLeft = _hasNoPpLeft(activeSlot, moveReferences, data.moves);

          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _BattleHeader(
                  round: _round,
                  profile: data.profile,
                  activeSlot: activeSlot,
                  occupiedSlots: data.occupiedSlots,
                  pokemonForSlot: (slot) => _pokemonForSlot(data, slot),
                  onActiveSlotChanged: (slotIndex) {
                    setState(() {
                      _activeSlotIndex = slotIndex;
                      _message = null;
                    });
                  },
                  onNextRound: _nextRound,
                  onReset: _resetBattle,
                ),
                const SizedBox(height: 12),
                _ActivePokemonCard(
                  pokemon: pokemon,
                  slot: activeSlot,
                  displayName: _displayName(activeSlot, pokemon),
                  level: _levelForSlot(activeSlot),
                  currentHp: _currentHpFor(activeSlot, pokemon),
                  maxHp: _maxHpFor(pokemon, activeSlot),
                  statuses: activeSlot.statusEffects,
                  message: _message,
                  onMinusFive: () => _changeHp(data, activeSlot, -5),
                  onMinusOne: () => _changeHp(data, activeSlot, -1),
                  onPlusOne: () => _changeHp(data, activeSlot, 1),
                  onPlusFive: () => _changeHp(data, activeSlot, 5),
                  onHeal: () => _healFull(data, activeSlot),
                  onStatus: () => _openStatusPicker(data, activeSlot),
                ),
                const SizedBox(height: 12),
                Text(
                  'MOSSE DA COMBATTIMENTO',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                if (noPpLeft) ...[
                  _StruggleWarning(move: data.moves['Struggle']),
                  const SizedBox(height: 8),
                ],
                for (final reference in moveReferences)
                  _BattleMoveCard(
                    reference: reference,
                    move: data.moves[reference],
                    remainingPp: _remainingPp(activeSlot, reference, data.moves[reference]),
                    maxPp: _maxPpFor(data.moves[reference]),
                    stats: data.moves[reference] == null
                        ? null
                        : _moveStats(data.moves[reference]!, pokemon, activeSlot),
                    onUse: () => _changePp(
                      activeSlot,
                      reference,
                      data.moves[reference],
                      -1,
                    ),
                    onRestore: () => _changePp(
                      activeSlot,
                      reference,
                      data.moves[reference],
                      1,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BattleData {
  const _BattleData({
    required this.profile,
    required this.team,
    required this.pokemonById,
    required this.moves,
  });

  final UserProfile profile;
  final List<TeamSlot> team;
  final Map<int, Pokemon> pokemonById;
  final Map<String, MoveData?> moves;

  List<TeamSlot> get occupiedSlots {
    return team
        .where(
          (slot) => slot.pokemonId != null && pokemonById[slot.pokemonId] != null,
        )
        .toList(growable: false);
  }
}

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({
    required this.round,
    required this.profile,
    required this.activeSlot,
    required this.occupiedSlots,
    required this.pokemonForSlot,
    required this.onActiveSlotChanged,
    required this.onNextRound,
    required this.onReset,
  });

  final int round;
  final UserProfile profile;
  final TeamSlot activeSlot;
  final List<TeamSlot> occupiedSlots;
  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final ValueChanged<int> onActiveSlotChanged;
  final VoidCallback onNextRound;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Round $round',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text('Allenatore Lv. ${profile.trainerLevel}'),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(activeSlot.slotIndex),
              initialValue: activeSlot.slotIndex,
              decoration: const InputDecoration(labelText: 'Pokémon attivo'),
              items: [
                for (final slot in occupiedSlots)
                  DropdownMenuItem<int>(
                    value: slot.slotIndex,
                    child: Text(
                      '${slot.slotIndex + 1}. ${_slotLabel(slot, pokemonForSlot(slot))}',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onActiveSlotChanged(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNextRound,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('NUOVO ROUND'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('RESET PP'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _slotLabel(TeamSlot slot, Pokemon? pokemon) {
    if (pokemon == null) return 'Slot ${slot.slotIndex + 1}';

    final nickname = slot.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return '$nickname (${pokemon.name})';
    }

    return pokemon.name;
  }
}

class _ActivePokemonCard extends StatelessWidget {
  const _ActivePokemonCard({
    required this.pokemon,
    required this.slot,
    required this.displayName,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.statuses,
    required this.message,
    required this.onMinusFive,
    required this.onMinusOne,
    required this.onPlusOne,
    required this.onPlusFive,
    required this.onHeal,
    required this.onStatus,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final String displayName;
  final int level;
  final int currentHp;
  final int maxHp;
  final List<String> statuses;
  final String? message;
  final VoidCallback onMinusFive;
  final VoidCallback onMinusOne;
  final VoidCallback onPlusOne;
  final VoidCallback onPlusFive;
  final VoidCallback onHeal;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    final hpProgress = maxHp <= 0
        ? 0.0
        : (currentHp / maxHp).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PokemonAssetImage(
                  pokemon: pokemon,
                  useLargeArtwork: true,
                  size: 96,
                  formName: slot.formName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('#${pokemon.id.toString().padLeft(3, '0')}  |  Lv. $level'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final type in pokemon.types)
                            PokemonTypeBadge(type: type, height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'HP $currentHp/$maxHp',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: hpProgress,
                      minHeight: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _SmallBattleButton(label: '-5', onTap: onMinusFive),
                _SmallBattleButton(label: '-1', onTap: onMinusOne),
                _SmallBattleButton(label: '+1', onTap: onPlusOne),
                _SmallBattleButton(label: '+5', onTap: onPlusFive),
                FilledButton(
                  onPressed: onHeal,
                  child: const Text('POKÉMON CENTER'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onStatus,
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: statuses.isEmpty
                      ? const Text('STATUS: nessuno')
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            const Text('STATUS:'),
                            for (final status in statuses)
                              Chip(label: Text(status.toUpperCase())),
                          ],
                        ),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              _InlineBattleMessage(message: message!),
            ],
          ],
        ),
      ),
    );
  }
}

class _BattleMoveCard extends StatelessWidget {
  const _BattleMoveCard({
    required this.reference,
    required this.move,
    required this.remainingPp,
    required this.maxPp,
    required this.stats,
    required this.onUse,
    required this.onRestore,
  });

  final String reference;
  final MoveData? move;
  final int remainingPp;
  final int maxPp;
  final String? stats;
  final VoidCallback onUse;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final move = this.move;
    final title = move?.name ?? reference;
    final type = move?.type ?? 'Sconosciuto';
    final canTrackPp = maxPp > 0;

    return Card(
      child: ExpansionTile(
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            type,
            if (stats != null && stats!.isNotEmpty) stats!,
            if (canTrackPp) 'PP $remainingPp/$maxPp',
          ].join('  |  '),
        ),
        trailing: canTrackPp
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Recupera PP',
                    onPressed: remainingPp >= maxPp ? null : onRestore,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Usa mossa',
                    onPressed: remainingPp <= 0 ? null : onUse,
                    icon: const Icon(Icons.remove),
                  ),
                ],
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (move == null)
            const Text('Dettagli mossa non disponibili.')
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tempo: ${move.moveTime}  |  Durata: ${move.duration}'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(move.description),
            ),
          ],
        ],
      ),
    );
  }
}

class _StruggleWarning extends StatelessWidget {
  const _StruggleWarning({required this.move});

  final MoveData? move;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STRUGGLE DISPONIBILE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              move?.description ??
                  'Tutti i PP delle mosse tracciabili sono a zero. Usa Struggle.',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBattleButton extends StatelessWidget {
  const _SmallBattleButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _InlineBattleMessage extends StatelessWidget {
  const _InlineBattleMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}

class _BattleEmptyState extends StatelessWidget {
  const _BattleEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
