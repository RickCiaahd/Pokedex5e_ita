import 'package:flutter/material.dart';

import '../../models/breeding_egg.dart';
import '../../models/pc_pokemon.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/breeding_egg_repository.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/egg_asset_image.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../../widgets/pc/pc_egg_widgets.dart';
import '../breeding/breeding_screen.dart';

class PokemonPcScreen extends StatefulWidget {
  const PokemonPcScreen({super.key});

  @override
  State<PokemonPcScreen> createState() => _PokemonPcScreenState();
}

class _PokemonPcScreenState extends State<PokemonPcScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final BreedingEggRepository _eggRepository = BreedingEggRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TextEditingController _pcSearchController = TextEditingController();

  UserProfile? _profile;
  List<Pokemon> _allPokemon = [];
  List<PcPokemon> _pcPokemon = [];
  List<BreedingEgg> _eggs = [];
  List<TeamSlot> _team = [];
  bool _isLoading = true;
  bool _showPcSearch = false;
  String _pcQuery = '';
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPc();
  }

  @override
  void dispose() {
    _pcSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPc({bool clearMessages = true}) async {
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
      final pcPokemon = await _pokemonPcRepository.getPokemon(profile.id);
      final eggs = await _eggRepository.getEggs(profile.id);
      final team = await _teamRepository.getTeam(profile.id);

      team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _allPokemon = pokemon;
        _pcPokemon = pcPokemon;
        _eggs = eggs;
        _team = team;
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

  Pokemon? _pokemonById(int? pokemonId) {
    if (pokemonId == null) return null;

    for (final pokemon in _allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }

    return null;
  }

  int get _unlockedPokeslots {
    final level = _profile?.trainerLevel ?? TrainerProgression.minLevel;
    return TrainerProgression.pokeslotsForLevel(level);
  }

  List<TeamSlot> get _visibleTeam {
    return [
      for (final slot in _team)
        if (slot.slotIndex < _unlockedPokeslots) slot,
    ]..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  }

  List<PcPokemon> get _filteredPcPokemon {
    final query = _pcQuery.trim().toLowerCase();
    if (query.isEmpty) return _pcPokemon;

    return _pcPokemon
        .where((item) {
          final pokemon = _pokemonById(item.pokemonId);
          final baseName = pokemon?.name.toLowerCase() ?? '';
          final nickname = item.displayName.toLowerCase();
          final number = item.pokemonId.toString();
          final types =
              pokemon?.types.any(
                (type) => type.toLowerCase().contains(query),
              ) ??
              false;

          return baseName.contains(query) ||
              nickname.contains(query) ||
              number.contains(query) ||
              types;
        })
        .toList(growable: false);
  }

  List<BreedingEgg> get _pcEggs =>
      _eggs.where((egg) => egg.isInPc).toList(growable: false);

  List<BreedingEgg> get _filteredPcEggs {
    final query = _pcQuery.trim().toLowerCase();
    if (query.isEmpty) return _pcEggs;
    return _pcEggs
        .where((egg) {
          final pokemon = _pokemonById(egg.speciesId);
          return 'uovo'.contains(query) ||
              (pokemon?.name.toLowerCase().contains(query) ?? false) ||
              egg.parentNames.any((name) => name.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  BreedingEgg? _eggById(String? eggId) {
    if (eggId == null) return null;
    for (final egg in _eggs) {
      if (egg.id == eggId) return egg;
    }
    return null;
  }

  TeamSlot? get _firstFreeTeamSlot {
    for (final slot in _visibleTeam) {
      if (slot.isEmpty) return slot;
    }
    return null;
  }

  int get _filledTeamSlots {
    return _visibleTeam.where((slot) => !slot.isEmpty).length;
  }

  Future<void> _depositTeamSlot(TeamSlot slot) async {
    final profile = _profile;
    if (profile == null) return;

    if (slot.isEgg) {
      final egg = _eggById(slot.eggId);
      if (egg == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Deposita l’uovo nel PC?'),
          content: const Text(
            'L’uovo libererà il Pokéslot. Nel PC l’incubazione resterà in pausa e il bonus di Lealtà +2 non sarà più disponibile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Deposita'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _teamRepository.clearSlot(
        profileId: profile.id,
        slotIndex: slot.slotIndex,
      );
      await _eggRepository.saveEgg(
        profile.id,
        egg.copyWith(
          isInDayCare: false,
          isInPc: true,
          carriedEntireIncubation: false,
        ),
      );
      await _loadPc(clearMessages: false);
      if (!mounted) return;
      setState(() => _successMessage = 'Uovo depositato nel PC.');
      return;
    }

    final pokemon = _pokemonById(slot.pokemonId);
    if (slot.pokemonId == null) return;
    final displayName = _slotDisplayName(slot, pokemon);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deposita nel PC?'),
        content: Text(
          '$displayName verrà rimosso dalla squadra e salvato nel PC mantenendo nickname, natura, mosse, esperienza, oggetto e status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deposita'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _pokemonPcRepository.depositTeamSlot(
      profileId: profile.id,
      slot: slot,
    );
    await _teamRepository.setPokemonInSlot(
      profileId: profile.id,
      slotIndex: slot.slotIndex,
      pokemonId: null,
    );

    await _loadPc(clearMessages: false);
    if (!mounted) return;
    setState(() => _successMessage = '$displayName depositato nel PC.');
  }

  Future<void> _moveToTeam(PcPokemon pcPokemon) async {
    final profile = _profile;
    final pokemon = _pokemonById(pcPokemon.pokemonId);
    if (profile == null) return;

    final freeSlot = _firstFreeTeamSlot;
    final targetSlot = freeSlot ?? await _chooseReplacementSlot(pcPokemon);
    if (!mounted || targetSlot == null) return;

    final replacingPokemon = _pokemonById(targetSlot.pokemonId);
    final replacingExisting = targetSlot.pokemonId != null;

    if (replacingExisting) {
      await _pokemonPcRepository.depositTeamSlot(
        profileId: profile.id,
        slot: targetSlot,
      );
    }

    final updatedSlot = pcPokemon.toTeamSlot(
      slotIndex: targetSlot.slotIndex,
      fallbackCurrentHp: pokemon?.hitPoints ?? 0,
    );

    await _teamRepository.updateSlot(
      profileId: profile.id,
      updatedSlot: updatedSlot,
    );
    await _pokemonPcRepository.removePokemon(
      profileId: profile.id,
      pcPokemonId: pcPokemon.id,
    );

    await _loadPc(clearMessages: false);
    if (!mounted) return;

    final pcName = _pcDisplayName(pcPokemon, pokemon);
    final replacedName = replacingExisting
        ? _slotDisplayName(targetSlot, replacingPokemon)
        : null;
    setState(() {
      _successMessage = replacedName == null
          ? '$pcName spostato nello slot ${targetSlot.slotIndex + 1}.'
          : '$pcName è entrato in squadra. $replacedName è stato depositato nel PC.';
    });
  }

  Future<TeamSlot?> _chooseReplacementSlot(PcPokemon pcPokemon) async {
    return showModalBottomSheet<TeamSlot>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ReplacementSlotSheet(
        pcPokemon: pcPokemon,
        pokemon: _pokemonById(pcPokemon.pokemonId),
        team: _visibleTeam.where((slot) => slot.isPokemon).toList(),
        pokemonForSlot: _pokemonById,
        displayNameForSlot: _slotDisplayName,
      ),
    );
  }

  Future<void> _moveEggToTeam(BreedingEgg egg) async {
    final profile = _profile;
    final freeSlot = _firstFreeTeamSlot;
    if (profile == null || freeSlot == null) return;
    await _teamRepository.setEggInSlot(
      profileId: profile.id,
      slotIndex: freeSlot.slotIndex,
      eggId: egg.id,
    );
    await _eggRepository.saveEgg(
      profile.id,
      egg.copyWith(isInDayCare: false, isInPc: false),
    );
    await _loadPc(clearMessages: false);
    if (!mounted) return;
    setState(() {
      _successMessage =
          'Uovo spostato nello slot squadra ${freeSlot.slotIndex + 1}.';
    });
  }

  Future<void> _releaseFromPc(PcPokemon pcPokemon) async {
    final profile = _profile;
    if (profile == null) return;

    final pokemon = _pokemonById(pcPokemon.pokemonId);
    final name = _pcDisplayName(pcPokemon, pokemon);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rilasciare Pokémon?'),
        content: Text('Vuoi rimuovere definitivamente $name dal PC?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rilascia'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _pokemonPcRepository.removePokemon(
      profileId: profile.id,
      pcPokemonId: pcPokemon.id,
    );
    await _loadPc(clearMessages: false);
    if (!mounted) return;
    setState(() => _successMessage = '$name rimosso dal PC.');
  }

  void _togglePcSearch() {
    setState(() {
      _showPcSearch = !_showPcSearch;
      if (!_showPcSearch) {
        _pcQuery = '';
        _pcSearchController.clear();
      }
    });
  }

  String _slotDisplayName(TeamSlot slot, Pokemon? pokemon) {
    final nickname = slot.nickname?.trim() ?? '';
    return nickname.isEmpty ? pokemon?.name ?? 'Pokémon' : nickname;
  }

  String _pcDisplayName(PcPokemon pcPokemon, Pokemon? pokemon) {
    return pcPokemon.displayName.isEmpty
        ? pokemon?.name ?? 'Pokémon sconosciuto'
        : pcPokemon.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final profileName = _profile?.name ?? 'Allenatore';
    final visibleTeam = _visibleTeam;
    final filteredPcPokemon = _filteredPcPokemon;
    final filteredPcEggs = _filteredPcEggs;
    final storedCount = _pcPokemon.length + _pcEggs.length;
    final filteredCount = filteredPcPokemon.length + filteredPcEggs.length;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('PC Pokémon'),
        actions: [
          IconButton(
            tooltip: 'Ricarica',
            onPressed: () => _loadPc(clearMessages: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _allPokemon.isEmpty
          ? _PcErrorState(message: _errorMessage!, onRetry: _loadPc)
          : ResponsiveContent(
              maxWidth: 1280,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          _PcHeader(
                            profileName: profileName,
                            storedCount: storedCount,
                            filledTeamSlots: _filledTeamSlots,
                            totalTeamSlots: visibleTeam.length,
                          ),
                          if (_successMessage != null) ...[
                            const SizedBox(height: 8),
                            _PcStatusMessage(message: _successMessage!),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          _SectionTitle(
                            title: 'Squadra',
                            subtitle:
                                'Fissa: deposita o scegli chi sostituire quando ritiri dal PC.',
                          ),
                          const SizedBox(height: 8),
                          _FixedTeamPanel(
                            team: visibleTeam,
                            pokemonForSlot: _pokemonById,
                            onDeposit: _depositTeamSlot,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PcToolbar(
                        storedCount: filteredCount,
                        totalCount: storedCount,
                        showSearch: _showPcSearch,
                        controller: _pcSearchController,
                        onSearchTap: _togglePcSearch,
                        onQueryChanged: (value) =>
                            setState(() => _pcQuery = value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: storedCount == 0
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: _PcEmptyState(),
                            )
                          : filteredCount == 0
                          ? const _PcNoSearchResults()
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        MediaQuery.sizeOf(context).width >= 900
                                        ? 112
                                        : 92,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: filteredCount,
                              itemBuilder: (context, index) {
                                if (index < filteredPcPokemon.length) {
                                  final item = filteredPcPokemon[index];
                                  return _PcGridCell(
                                    pcPokemon: item,
                                    pokemon: _pokemonById(item.pokemonId),
                                    onTap: () => _openPcPokemonActions(item),
                                  );
                                }
                                final egg =
                                    filteredPcEggs[index -
                                        filteredPcPokemon.length];
                                return PcEggGridCell(
                                  egg: egg,
                                  pokemon: _pokemonById(egg.speciesId),
                                  onTap: () => _openPcEggActions(egg),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _openPcEggActions(BreedingEgg egg) async {
    final action = await showModalBottomSheet<PcEggAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => PcEggActionSheet(
        egg: egg,
        pokemon: _pokemonById(egg.speciesId),
        teamIsFull: _firstFreeTeamSlot == null,
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case PcEggAction.moveToTeam:
        await _moveEggToTeam(egg);
        break;
      case PcEggAction.openBreeding:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BreedingScreen()));
        await _loadPc(clearMessages: false);
        break;
    }
  }

  Future<void> _openPcPokemonActions(PcPokemon item) async {
    final action = await showModalBottomSheet<_PcAction>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PcPokemonActionSheet(
        pcPokemon: item,
        pokemon: _pokemonById(item.pokemonId),
        displayName: _pcDisplayName(item, _pokemonById(item.pokemonId)),
        teamIsFull: _firstFreeTeamSlot == null,
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _PcAction.moveToTeam:
        await _moveToTeam(item);
        break;
      case _PcAction.release:
        await _releaseFromPc(item);
        break;
    }
  }
}

class _PcHeader extends StatelessWidget {
  const _PcHeader({
    required this.profileName,
    required this.storedCount,
    required this.filledTeamSlots,
    required this.totalTeamSlots,
  });

  final String profileName;
  final int storedCount;
  final int filledTeamSlots;
  final int totalTeamSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.computer,
              color: colorScheme.onSecondaryContainer,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PC di $profileName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$storedCount nel PC • $filledTeamSlots/$totalTeamSlots Pokéslot occupati',
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _FixedTeamPanel extends StatelessWidget {
  const _FixedTeamPanel({
    required this.team,
    required this.pokemonForSlot,
    required this.onDeposit,
  });

  final List<TeamSlot> team;
  final Pokemon? Function(int? pokemonId) pokemonForSlot;
  final ValueChanged<TeamSlot> onDeposit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final veryCompact = constraints.maxWidth < 420;
        final crossAxisCount = compact ? 3 : 6;
        const spacing = 8.0;
        final rows = (team.length / crossAxisCount).ceil();
        final safeRows = rows <= 0 ? 1 : rows;
        final availableWidth =
            constraints.maxWidth - (spacing * (crossAxisCount - 1));
        final cellWidth = availableWidth / crossAxisCount;
        final childAspectRatio = veryCompact
            ? 0.95
            : compact
            ? 1.05
            : 1.25;
        final cellHeight = cellWidth / childAspectRatio;
        final height = (cellHeight * safeRows) + (spacing * (safeRows - 1));

        return SizedBox(
          height: height,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: team.length,
            itemBuilder: (context, index) {
              final slot = team[index];
              return _TeamMiniCard(
                slot: slot,
                pokemon: pokemonForSlot(slot.pokemonId),
                onDeposit: slot.isEmpty ? null : () => onDeposit(slot),
              );
            },
          ),
        );
      },
    );
  }
}

class _TeamMiniCard extends StatelessWidget {
  const _TeamMiniCard({
    required this.slot,
    required this.pokemon,
    required this.onDeposit,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final VoidCallback? onDeposit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;
    final nickname = slot.nickname?.trim() ?? '';
    final name = slot.isEgg
        ? 'Uovo'
        : pokemon == null
        ? 'Slot ${slot.slotIndex + 1}'
        : nickname.isEmpty
        ? pokemon.name
        : nickname;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = constraints.maxWidth < 128;
        final spriteSize = dense ? 34.0 : 42.0;
        final eggSpriteSize = dense ? 26.0 : 30.0;
        final gap = dense ? 5.0 : 8.0;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(dense ? 5 : 7),
            child: Row(
              children: [
                slot.isEgg
                    ? EggAssetImage(size: eggSpriteSize)
                    : pokemon == null
                    ? CircleAvatar(
                        radius: spriteSize / 2,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Text('${slot.slotIndex + 1}'),
                      )
                    : PokemonAssetImage(
                        pokemon: pokemon,
                        size: spriteSize,
                        formName: slot.formName,
                        gender: slot.gender,
                        isShiny: slot.isShiny,
                      ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: dense ? 12 : null,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        slot.isEgg
                            ? 'In incubazione'
                            : pokemon == null
                            ? 'Vuoto'
                            : '#${pokemon.id.toString().padLeft(3, '0')}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (onDeposit != null)
                        TextButton(
                          onPressed: onDeposit,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: Theme.of(context).textTheme.labelSmall,
                          ),
                          child: const Text('Deposita'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PcToolbar extends StatelessWidget {
  const _PcToolbar({
    required this.storedCount,
    required this.totalCount,
    required this.showSearch,
    required this.controller,
    required this.onSearchTap,
    required this.onQueryChanged,
  });

  final int storedCount;
  final int totalCount;
  final bool showSearch;
  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PC BOX',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text('$storedCount/$totalCount'),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: showSearch ? 'Chiudi ricerca' : 'Cerca nel PC',
              onPressed: onSearchTap,
              icon: Icon(showSearch ? Icons.close : Icons.search),
            ),
          ],
        ),
        if (showSearch) ...[
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Cerca per nome, numero o tipo...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onQueryChanged,
          ),
        ],
      ],
    );
  }
}

class _PcGridCell extends StatelessWidget {
  const _PcGridCell({
    required this.pcPokemon,
    required this.pokemon,
    required this.onTap,
  });

  final PcPokemon pcPokemon;
  final Pokemon? pokemon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pokemon = this.pokemon;
    final selectedName = pcPokemon.displayName.isEmpty
        ? pokemon?.name ?? 'Sconosciuto'
        : pcPokemon.displayName;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: pokemon == null
                  ? Icon(
                      Icons.help_outline,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : PokemonAssetImage(
                      pokemon: pokemon,
                      size: 58,
                      formName: pcPokemon.formName,
                      gender: pcPokemon.gender,
                      isShiny: pcPokemon.isShiny,
                    ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: Text(
                '#${pcPokemon.pokemonId.toString().padLeft(3, '0')}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (pcPokemon.isShiny)
              const Positioned(
                right: 5,
                top: 4,
                child: Icon(Icons.auto_awesome, size: 14),
              ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 3,
              child: Text(
                selectedName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PcPokemonActionSheet extends StatelessWidget {
  const _PcPokemonActionSheet({
    required this.pcPokemon,
    required this.pokemon,
    required this.displayName,
    required this.teamIsFull,
  });

  final PcPokemon pcPokemon;
  final Pokemon? pokemon;
  final String displayName;
  final bool teamIsFull;

  @override
  Widget build(BuildContext context) {
    final pokemon = this.pokemon;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                pokemon == null
                    ? const CircleAvatar(child: Icon(Icons.help_outline))
                    : PokemonAssetImage(
                        pokemon: pokemon,
                        size: 58,
                        formName: pcPokemon.formName,
                        gender: pcPokemon.gender,
                        isShiny: pcPokemon.isShiny,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        pokemon == null
                            ? '#${pcPokemon.pokemonId.toString().padLeft(3, '0')}'
                            : '#${pokemon.id.toString().padLeft(3, '0')} • ${pokemon.types.join(' / ')}',
                      ),
                      if (teamIsFull)
                        const Text('Squadra piena: sceglierai chi sostituire.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_PcAction.moveToTeam),
              icon: const Icon(Icons.swap_horiz),
              label: Text(
                teamIsFull ? 'SOSTITUISCI IN SQUADRA' : 'SPOSTA IN SQUADRA',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(_PcAction.release),
              icon: const Icon(Icons.delete_outline),
              label: const Text('RILASCIA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacementSlotSheet extends StatelessWidget {
  const _ReplacementSlotSheet({
    required this.pcPokemon,
    required this.pokemon,
    required this.team,
    required this.pokemonForSlot,
    required this.displayNameForSlot,
  });

  final PcPokemon pcPokemon;
  final Pokemon? pokemon;
  final List<TeamSlot> team;
  final Pokemon? Function(int? pokemonId) pokemonForSlot;
  final String Function(TeamSlot slot, Pokemon? pokemon) displayNameForSlot;

  @override
  Widget build(BuildContext context) {
    final name = pcPokemon.displayName.isEmpty
        ? pokemon?.name ?? 'Pokémon'
        : pcPokemon.displayName;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          Text(
            'Sostituisci chi?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '$name entrerà in squadra. Il Pokémon sostituito verrà depositato nel PC.',
          ),
          const SizedBox(height: 12),
          for (final slot in team)
            _ReplacementSlotTile(
              slot: slot,
              pokemon: pokemonForSlot(slot.pokemonId),
              displayName: displayNameForSlot(
                slot,
                pokemonForSlot(slot.pokemonId),
              ),
              onTap: () => Navigator.of(context).pop(slot),
            ),
        ],
      ),
    );
  }
}

class _ReplacementSlotTile extends StatelessWidget {
  const _ReplacementSlotTile({
    required this.slot,
    required this.pokemon,
    required this.displayName,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pokemon = this.pokemon;

    return Card(
      child: ListTile(
        leading: pokemon == null
            ? CircleAvatar(child: Text('${slot.slotIndex + 1}'))
            : PokemonAssetImage(
                pokemon: pokemon,
                size: 48,
                formName: slot.formName,
                gender: slot.gender,
                isShiny: slot.isShiny,
              ),
        title: Text(
          pokemon == null ? 'Slot ${slot.slotIndex + 1} vuoto' : displayName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: pokemon == null
            ? const Text('Slot libero')
            : Text(
                '#${pokemon.id.toString().padLeft(3, '0')} • ${pokemon.types.join(' / ')}',
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _PcStatusMessage extends StatelessWidget {
  const _PcStatusMessage({required this.message});

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
            Icon(
              Icons.check_circle_outline,
              color: colorScheme.onSecondaryContainer,
            ),
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

enum _PcAction { moveToTeam, release }

class _PcEmptyState extends StatelessWidget {
  const _PcEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Nessun Pokémon o uovo nel PC. Quando catturi con la squadra piena o depositi dalla squadra, finirà qui.',
        ),
      ),
    );
  }
}

class _PcNoSearchResults extends StatelessWidget {
  const _PcNoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nessun Pokémon trovato nel PC.'),
      ),
    );
  }
}

class _PcErrorState extends StatelessWidget {
  const _PcErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
