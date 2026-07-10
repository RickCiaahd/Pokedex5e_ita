import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/bag_inventory_entry.dart';
import '../../models/bag_item.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/bag_inventory_repository.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/pokedex_repositry.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class CapturePokemonScreen extends StatefulWidget {
  const CapturePokemonScreen({super.key});

  @override
  State<CapturePokemonScreen> createState() => _CapturePokemonScreenState();
}

class _CapturePokemonScreenState extends State<CapturePokemonScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final PokedexRepository _pokedexRepository = PokedexRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final BagInventoryRepository _bagRepository = BagInventoryRepository();
  final TextEditingController _searchController = TextEditingController();
  final Random _random = Random();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  List<TeamSlot> _team = [];
  List<BagItem> _items = [];
  List<BagInventoryEntry> _inventory = [];

  Pokemon? _target;
  bool _isGmMode = false;
  bool _isLoading = true;
  bool _isResolvingCapture = false;
  String _query = '';
  String? _selectedBallId;
  String? _wildStatus;
  int _wildLevel = 1;
  int _wildMaxHp = 1;
  int _wildCurrentHp = 1;
  int _manualDcReduction = 0;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCaptureData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCaptureData({bool clearMessages = true}) async {
    setState(() {
      _isLoading = true;
      if (clearMessages) {
        _successMessage = null;
        _errorMessage = null;
      }
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final team = await _teamRepository.getTeam(profile.id);
      final items = await _itemRepository.getWebItems();
      final inventory = await _bagRepository.getInventory(profile.id);

      team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _pokemon = pokemon;
        _team = team;
        _items = items;
        _inventory = inventory;
        _selectedBallId ??= _ownedPokeballs.isEmpty ? null : _ownedPokeballs.first.item.id;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  int get _unlockedPokeslots {
    final level = _profile?.trainerLevel ?? TrainerProgression.minLevel;
    return TrainerProgression.pokeslotsForLevel(level);
  }

  TeamSlot? get _firstFreeTeamSlot {
    final unlockedSlots = _team
        .where((slot) => slot.slotIndex < _unlockedPokeslots)
        .toList(growable: true)
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    for (final slot in unlockedSlots) {
      if (slot.pokemonId == null) return slot;
    }

    return null;
  }

  List<Pokemon> get _filteredPokemon {
    final query = _query.toLowerCase().trim();
    final filtered = _pokemon.where((pokemon) {
      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList(growable: true)
      ..sort((a, b) => a.id.compareTo(b.id));

    return filtered;
  }

  List<_OwnedPokeball> get _ownedPokeballs {
    final balls = <_OwnedPokeball>[];
    for (final entry in _inventory) {
      final item = _itemById(entry.itemId);
      if (item != null && item.type == 'pokeball') {
        balls.add(_OwnedPokeball(item: item, quantity: entry.quantity));
      }
    }
    balls.sort((a, b) => a.item.name.compareTo(b.item.name));
    return balls;
  }

  BagItem? _itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  BagItem? get _selectedBall {
    final selectedId = _selectedBallId;
    if (selectedId == null) return null;
    return _itemById(selectedId);
  }

  void _selectPokemon(Pokemon pokemon) {
    final level = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final maxHp = _wildMaxHpFor(pokemon, level);

    setState(() {
      _target = pokemon;
      _wildLevel = level;
      _wildMaxHp = maxHp;
      _wildCurrentHp = maxHp;
      _wildStatus = null;
      _manualDcReduction = 0;
      _successMessage = null;
      _errorMessage = null;
      _selectedBallId = _ownedPokeballs.isEmpty ? null : _ownedPokeballs.first.item.id;
    });
  }

  void _setWildLevel(Pokemon pokemon, int level) {
    final clampedLevel = level.clamp(1, 20).toInt();
    final maxHp = _wildMaxHpFor(pokemon, clampedLevel);
    setState(() {
      _wildLevel = clampedLevel;
      _wildMaxHp = maxHp;
      _wildCurrentHp = _wildCurrentHp.clamp(0, maxHp).toInt();
    });
  }

  void _changeWildHp(int delta) {
    setState(() {
      _wildCurrentHp = (_wildCurrentHp + delta).clamp(0, _wildMaxHp).toInt();
    });
  }

  int _wildMaxHpFor(Pokemon pokemon, int level) {
    final minimumLevel = pokemon.minLevelFound <= 0 ? 1 : pokemon.minLevelFound;
    final levelsGained = (level - minimumLevel).clamp(0, 20).toInt();
    final hitDieAverage = ((pokemon.hitDice + 1) / 2).ceil();
    final constitutionModifier = _modifier(pokemon.attributes.constitution);
    final hp = pokemon.hitPoints + (hitDieAverage * levelsGained) + (constitutionModifier * level);
    return hp < 1 ? 1 : hp;
  }

  int _modifier(int score) => ((score - 10) / 2).floor();

  int _trainerCaptureBonus(UserProfile profile) {
    final level = profile.trainerLevel;
    if (level >= 17) return 6;
    if (level >= 13) return 5;
    if (level >= 9) return 4;
    if (level >= 5) return 3;
    return 2;
  }

  int _baseCaptureDc(Pokemon pokemon) {
    final profile = _profile;
    final trainerLevel = profile?.trainerLevel ?? 1;
    final levelPressure = max(0, _wildLevel - trainerLevel);
    return 15 + (pokemon.sr * 2).round() + levelPressure;
  }

  int get _hpDcReduction {
    if (_wildMaxHp <= 0) return 0;
    final ratio = _wildCurrentHp / _wildMaxHp;
    if (ratio <= 0.25) return 10;
    if (ratio <= 0.50) return 5;
    if (ratio <= 0.75) return 2;
    return 0;
  }

  int _statusDcReduction(String? status) => status == null ? 0 : 5;

  int _ballDcReduction(BagItem? ball, Pokemon pokemon) {
    if (ball == null) return 0;

    switch (ball.id) {
      case 'great-ball':
        return 5;
      case 'ultra-ball':
        return 10;
      case 'net-ball':
        return pokemon.types.any((type) => type == 'Water' || type == 'Bug') ? 10 : 0;
      case 'heavy-ball':
        return _isMediumOrLarger(pokemon.size) ? 10 : 0;
      case 'level-ball':
        return (_profile?.trainerLevel ?? 1) > _wildLevel ? 5 : 0;
      case 'nest-ball':
        return _wildLevel <= 5 ? 5 : 0;
      case 'dream-ball':
        return _wildStatus == 'Asleep' ? 5 : 0;
      default:
        return 0;
    }
  }

  bool _isMediumOrLarger(String size) {
    final normalized = size.toLowerCase();
    return normalized.contains('medium') ||
        normalized.contains('large') ||
        normalized.contains('huge') ||
        normalized.contains('gargantuan');
  }

  int _captureDc(Pokemon pokemon, BagItem? ball) {
    final dc = _baseCaptureDc(pokemon) -
        _hpDcReduction -
        _statusDcReduction(_wildStatus) -
        _ballDcReduction(ball, pokemon) -
        _manualDcReduction;
    return dc.clamp(2, 99).toInt();
  }

  String get _hpConditionLabel {
    if (_wildMaxHp <= 0) return 'Sconosciuto';
    final ratio = _wildCurrentHp / _wildMaxHp;
    if (_wildCurrentHp <= 0) return 'KO / esausto';
    if (ratio <= 0.25) return 'Quasi KO';
    if (ratio <= 0.50) return 'Molto ferito';
    if (ratio <= 0.75) return 'Ferito';
    return 'In salute';
  }

  Future<void> _attemptCapture() async {
    final profile = _profile;
    final target = _target;
    final ball = _selectedBall;
    if (profile == null || target == null || ball == null || _isResolvingCapture) return;

    setState(() {
      _isResolvingCapture = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final consumed = await _bagRepository.consumeItem(
        profileId: profile.id,
        itemId: ball.id,
      );
      if (!consumed) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Non hai più ${ball.name} nello zaino.');
        return;
      }

      await _pokedexRepository.updateMarkMode(
        profileId: profile.id,
        pokemonId: target.id,
        seen: true,
        caught: false,
      );

      final autoSuccess = ball.id == 'master-ball';
      final roll = _random.nextInt(20) + 1;
      final bonus = _trainerCaptureBonus(profile);
      final dc = _captureDc(target, ball);
      final total = roll + bonus;
      final success = autoSuccess || total >= dc;

      if (success) {
        final destination = await _registerCapturedPokemon(profile, target);
        await _loadCaptureData(clearMessages: false);
        if (!mounted) return;
        setState(() {
          _target = null;
          _successMessage = autoSuccess
              ? '${target.name} catturato con ${ball.name} e $destination.'
              : '${target.name} catturato con ${ball.name} e $destination.';
        });
      } else {
        await _loadCaptureData(clearMessages: false);
        if (!mounted) return;
        setState(() {
          _successMessage = _isGmMode
              ? '${ball.name} fallita. Tiro $roll + $bonus = $total contro DC $dc.'
              : '${ball.name} fallita. Il Pokémon non è stato catturato.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isResolvingCapture = false);
    }
  }

  Future<void> _manualCapture() async {
    final profile = _profile;
    final target = _target;
    if (profile == null || target == null || _isResolvingCapture) return;

    setState(() {
      _isResolvingCapture = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final destination = await _registerCapturedPokemon(profile, target);
      await _loadCaptureData(clearMessages: false);
      if (!mounted) return;
      setState(() {
        _target = null;
        _successMessage = '${target.name} registrato come catturato e $destination.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isResolvingCapture = false);
    }
  }

  Future<void> _markSeen() async {
    final profile = _profile;
    final target = _target;
    if (profile == null || target == null) return;

    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: target.id,
      seen: true,
      caught: false,
    );
    if (!mounted) return;
    setState(() => _successMessage = '${target.name} registrato come visto.');
  }

  Future<String> _registerCapturedPokemon(UserProfile profile, Pokemon pokemon) async {
    final teamSlot = _firstFreeTeamSlot;
    final destination = teamSlot == null
        ? 'inviato al PC'
        : 'aggiunto allo slot squadra ${teamSlot.slotIndex + 1}';

    if (teamSlot != null) {
      await _teamRepository.setPokemonInSlot(
        profileId: profile.id,
        slotIndex: teamSlot.slotIndex,
        pokemonId: pokemon.id,
      );
    } else {
      await _pokemonPcRepository.depositPokemon(
        profileId: profile.id,
        pokemonId: pokemon.id,
      );
    }

    await _pokedexRepository.updateMarkMode(
      profileId: profile.id,
      pokemonId: pokemon.id,
      seen: true,
      caught: true,
    );

    return destination;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPokemon = _filteredPokemon;
    final freeSlot = _firstFreeTeamSlot;
    final target = _target;
    final profile = _profile;
    final ownedPokeballs = _ownedPokeballs;
    final selectedBall = _selectedBall;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Cattura Pokémon'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadCaptureData(clearMessages: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && _pokemon.isEmpty)
              _CaptureErrorState(
                message: _errorMessage!,
                onRetry: _loadCaptureData,
              )
            else ...[
              _CaptureHeader(
                freeSlotIndex: freeSlot?.slotIndex,
                unlockedSlots: _unlockedPokeslots,
                isGmMode: _isGmMode,
                onModeChanged: (value) => setState(() => _isGmMode = value),
              ),
              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                _InlineStatusMessage(
                  icon: Icons.info_outline,
                  message: _successMessage!,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (target != null && profile != null) ...[
                const SizedBox(height: 12),
                _CaptureAttemptPanel(
                  pokemon: target,
                  profile: profile,
                  isGmMode: _isGmMode,
                  ownedPokeballs: ownedPokeballs,
                  selectedBallId: _selectedBallId,
                  selectedBall: selectedBall,
                  wildLevel: _wildLevel,
                  wildCurrentHp: _wildCurrentHp,
                  wildMaxHp: _wildMaxHp,
                  wildStatus: _wildStatus,
                  manualDcReduction: _manualDcReduction,
                  hpConditionLabel: _hpConditionLabel,
                  baseDc: _baseCaptureDc(target),
                  hpDcReduction: _hpDcReduction,
                  statusDcReduction: _statusDcReduction(_wildStatus),
                  ballDcReduction: _ballDcReduction(selectedBall, target),
                  finalDc: _captureDc(target, selectedBall),
                  captureBonus: _trainerCaptureBonus(profile),
                  isResolving: _isResolvingCapture,
                  onBallChanged: (value) => setState(() => _selectedBallId = value),
                  onLevelChanged: (value) => _setWildLevel(target, value),
                  onHpDelta: _changeWildHp,
                  onHpSet: (value) => setState(() {
                    _wildCurrentHp = value.clamp(0, _wildMaxHp).toInt();
                  }),
                  onStatusChanged: (value) => setState(() => _wildStatus = value),
                  onManualDcReductionChanged: (value) => setState(() {
                    _manualDcReduction = value.clamp(0, 20).toInt();
                  }),
                  onAttemptCapture: _attemptCapture,
                  onManualCapture: _manualCapture,
                  onMarkSeen: _markSeen,
                  onClose: () => setState(() => _target = null),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cerca per nome, numero o tipo...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              for (final pokemon in filteredPokemon)
                _CapturePokemonCard(
                  pokemon: pokemon,
                  selected: target?.id == pokemon.id,
                  onSelect: () => _selectPokemon(pokemon),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnedPokeball {
  const _OwnedPokeball({required this.item, required this.quantity});

  final BagItem item;
  final int quantity;
}

class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({
    required this.freeSlotIndex,
    required this.unlockedSlots,
    required this.isGmMode,
    required this.onModeChanged,
  });

  final int? freeSlotIndex;
  final int unlockedSlots;
  final bool isGmMode;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = freeSlotIndex == null
        ? 'La squadra è piena: le catture andranno al PC.'
        : 'Prossima cattura nello slot squadra ${freeSlotIndex! + 1}.';

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.catching_pokemon,
                  color: colorScheme.onPrimaryContainer,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cattura da tavolo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$destination Pokeslot sbloccati: $unlockedSlots.',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: isGmMode,
              onChanged: onModeChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(
                isGmMode ? 'Vista GM attiva' : 'Vista giocatore attiva',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                isGmMode
                    ? 'Mostra HP reali, livello, DC e modificatori.'
                    : 'Nasconde HP e DC, mostrando solo condizioni narrative.',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureAttemptPanel extends StatelessWidget {
  const _CaptureAttemptPanel({
    required this.pokemon,
    required this.profile,
    required this.isGmMode,
    required this.ownedPokeballs,
    required this.selectedBallId,
    required this.selectedBall,
    required this.wildLevel,
    required this.wildCurrentHp,
    required this.wildMaxHp,
    required this.wildStatus,
    required this.manualDcReduction,
    required this.hpConditionLabel,
    required this.baseDc,
    required this.hpDcReduction,
    required this.statusDcReduction,
    required this.ballDcReduction,
    required this.finalDc,
    required this.captureBonus,
    required this.isResolving,
    required this.onBallChanged,
    required this.onLevelChanged,
    required this.onHpDelta,
    required this.onHpSet,
    required this.onStatusChanged,
    required this.onManualDcReductionChanged,
    required this.onAttemptCapture,
    required this.onManualCapture,
    required this.onMarkSeen,
    required this.onClose,
  });

  final Pokemon pokemon;
  final UserProfile profile;
  final bool isGmMode;
  final List<_OwnedPokeball> ownedPokeballs;
  final String? selectedBallId;
  final BagItem? selectedBall;
  final int wildLevel;
  final int wildCurrentHp;
  final int wildMaxHp;
  final String? wildStatus;
  final int manualDcReduction;
  final String hpConditionLabel;
  final int baseDc;
  final int hpDcReduction;
  final int statusDcReduction;
  final int ballDcReduction;
  final int finalDc;
  final int captureBonus;
  final bool isResolving;
  final ValueChanged<String?> onBallChanged;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<int> onHpDelta;
  final ValueChanged<int> onHpSet;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onManualDcReductionChanged;
  final VoidCallback onAttemptCapture;
  final VoidCallback onManualCapture;
  final VoidCallback onMarkSeen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAttemptCapture = selectedBall != null && !isResolving;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PokemonAssetImage(
                  pokemon: pokemon,
                  useLargeArtwork: true,
                  size: 96,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pokemon.name.toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('#${pokemon.id.toString().padLeft(3, '0')} • Lv. $wildLevel'),
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
                IconButton(
                  tooltip: 'Chiudi bersaglio',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedBallId),
              initialValue: selectedBallId,
              decoration: const InputDecoration(labelText: 'Poké Ball'),
              items: [
                for (final ball in ownedPokeballs)
                  DropdownMenuItem(
                    value: ball.item.id,
                    child: Text('${ball.item.name}  x${ball.quantity}'),
                  ),
              ],
              onChanged: isResolving ? null : onBallChanged,
            ),
            if (ownedPokeballs.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nessuna Poké Ball nello zaino: compra o aggiungi una ball prima del tiro.',
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            _PlayerCaptureSummary(
              hpConditionLabel: hpConditionLabel,
              wildStatus: wildStatus,
              selectedBall: selectedBall,
            ),
            if (isGmMode) ...[
              const SizedBox(height: 12),
              _GmCaptureControls(
                wildLevel: wildLevel,
                wildCurrentHp: wildCurrentHp,
                wildMaxHp: wildMaxHp,
                wildStatus: wildStatus,
                manualDcReduction: manualDcReduction,
                baseDc: baseDc,
                hpDcReduction: hpDcReduction,
                statusDcReduction: statusDcReduction,
                ballDcReduction: ballDcReduction,
                finalDc: finalDc,
                captureBonus: captureBonus,
                onLevelChanged: onLevelChanged,
                onHpDelta: onHpDelta,
                onHpSet: onHpSet,
                onStatusChanged: onStatusChanged,
                onManualDcReductionChanged: onManualDcReductionChanged,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: canAttemptCapture ? onAttemptCapture : null,
                  icon: const Icon(Icons.catching_pokemon),
                  label: const Text('TENTA CATTURA'),
                ),
                OutlinedButton.icon(
                  onPressed: isResolving ? null : onMarkSeen,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('SEGNA VISTO'),
                ),
                if (isGmMode)
                  OutlinedButton.icon(
                    onPressed: isResolving ? null : onManualCapture,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('CATTURA MANUALE'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCaptureSummary extends StatelessWidget {
  const _PlayerCaptureSummary({
    required this.hpConditionLabel,
    required this.wildStatus,
    required this.selectedBall,
  });

  final String hpConditionLabel;
  final String? wildStatus;
  final BagItem? selectedBall;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InfoPill(label: 'Condizione', value: hpConditionLabel),
            _InfoPill(label: 'Status', value: wildStatus ?? 'Nessuno'),
            _InfoPill(label: 'Ball', value: selectedBall?.name ?? 'Nessuna'),
          ],
        ),
      ),
    );
  }
}

class _GmCaptureControls extends StatelessWidget {
  const _GmCaptureControls({
    required this.wildLevel,
    required this.wildCurrentHp,
    required this.wildMaxHp,
    required this.wildStatus,
    required this.manualDcReduction,
    required this.baseDc,
    required this.hpDcReduction,
    required this.statusDcReduction,
    required this.ballDcReduction,
    required this.finalDc,
    required this.captureBonus,
    required this.onLevelChanged,
    required this.onHpDelta,
    required this.onHpSet,
    required this.onStatusChanged,
    required this.onManualDcReductionChanged,
  });

  final int wildLevel;
  final int wildCurrentHp;
  final int wildMaxHp;
  final String? wildStatus;
  final int manualDcReduction;
  final int baseDc;
  final int hpDcReduction;
  final int statusDcReduction;
  final int ballDcReduction;
  final int finalDc;
  final int captureBonus;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<int> onHpDelta;
  final ValueChanged<int> onHpSet;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int> onManualDcReductionChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PANNELLO GM',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text('Livello selvatico: $wildLevel')),
                IconButton(
                  onPressed: wildLevel <= 1 ? null : () => onLevelChanged(wildLevel - 1),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: wildLevel >= 20 ? null : () => onLevelChanged(wildLevel + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('HP selvatico: $wildCurrentHp/$wildMaxHp'),
            Slider(
              value: wildCurrentHp.toDouble(),
              min: 0,
              max: wildMaxHp.toDouble(),
              divisions: wildMaxHp,
              label: '$wildCurrentHp HP',
              onChanged: (value) => onHpSet(value.round()),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _SmallButton(label: '-10', onTap: () => onHpDelta(-10)),
                _SmallButton(label: '-5', onTap: () => onHpDelta(-5)),
                _SmallButton(label: '-1', onTap: () => onHpDelta(-1)),
                _SmallButton(label: '+1', onTap: () => onHpDelta(1)),
                _SmallButton(label: '+5', onTap: () => onHpDelta(5)),
                _SmallButton(label: '+10', onTap: () => onHpDelta(10)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(wildStatus ?? 'none'),
              initialValue: wildStatus,
              decoration: const InputDecoration(labelText: 'Status visibile'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Nessuno')),
                DropdownMenuItem(value: 'Asleep', child: Text('Asleep')),
                DropdownMenuItem(value: 'Burned', child: Text('Burned')),
                DropdownMenuItem(value: 'Frozen', child: Text('Frozen')),
                DropdownMenuItem(value: 'Paralyzed', child: Text('Paralyzed')),
                DropdownMenuItem(value: 'Poisoned', child: Text('Poisoned')),
              ],
              onChanged: onStatusChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Riduzione DC manuale: $manualDcReduction')),
                IconButton(
                  onPressed: manualDcReduction <= 0
                      ? null
                      : () => onManualDcReductionChanged(manualDcReduction - 1),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: manualDcReduction >= 20
                      ? null
                      : () => onManualDcReductionChanged(manualDcReduction + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(label: 'DC base', value: '$baseDc'),
                _InfoPill(label: 'HP', value: '-$hpDcReduction'),
                _InfoPill(label: 'Status', value: '-$statusDcReduction'),
                _InfoPill(label: 'Ball', value: '-$ballDcReduction'),
                _InfoPill(label: 'Manuale', value: '-$manualDcReduction'),
                _InfoPill(label: 'DC finale', value: '$finalDc'),
                _InfoPill(label: 'Tiro', value: 'd20 + $captureBonus'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePokemonCard extends StatelessWidget {
  const _CapturePokemonCard({
    required this.pokemon,
    required this.selected,
    required this.onSelect,
  });

  final Pokemon pokemon;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: selected ? colorScheme.primaryContainer : null,
      child: ListTile(
        leading: PokemonAssetImage(pokemon: pokemon, size: 48),
        title: Text(
          pokemon.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(number),
            for (final type in pokemon.types) PokemonTypeBadge(type: type, height: 18),
          ],
        ),
        trailing: FilledButton(
          onPressed: onSelect,
          child: Text(selected ? 'Scelto' : 'Prepara'),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _InlineStatusMessage extends StatelessWidget {
  const _InlineStatusMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureErrorState extends StatelessWidget {
  const _CaptureErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Errore: $message', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}
