import 'package:flutter/material.dart';

import '../../models/pc_pokemon.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class PokemonPcScreen extends StatefulWidget {
  const PokemonPcScreen({super.key});

  @override
  State<PokemonPcScreen> createState() => _PokemonPcScreenState();
}

class _PokemonPcScreenState extends State<PokemonPcScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final TeamRepository _teamRepository = TeamRepository();

  UserProfile? _profile;
  List<Pokemon> _allPokemon = [];
  List<PcPokemon> _pcPokemon = [];
  List<TeamSlot> _team = [];
  bool _isLoading = true;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPc();
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
      final team = await _teamRepository.getTeam(profile.id);

      team.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _allPokemon = pokemon;
        _pcPokemon = pcPokemon;
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

  TeamSlot? get _firstFreeTeamSlot {
    for (final slot in _visibleTeam) {
      if (slot.pokemonId == null) return slot;
    }
    return null;
  }

  int get _filledTeamSlots {
    return _visibleTeam.where((slot) => slot.pokemonId != null).length;
  }

  Future<void> _depositTeamSlot(TeamSlot slot) async {
    final profile = _profile;
    final pokemon = _pokemonById(slot.pokemonId);
    if (profile == null || slot.pokemonId == null) return;

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

    await _pokemonPcRepository.depositTeamSlot(profileId: profile.id, slot: slot);
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
    final freeSlot = _firstFreeTeamSlot;
    final pokemon = _pokemonById(pcPokemon.pokemonId);
    if (profile == null) return;

    if (freeSlot == null) {
      setState(() => _errorMessage = 'Non ci sono slot squadra liberi. Deposita prima un Pokémon nel PC.');
      return;
    }

    final updatedSlot = pcPokemon.toTeamSlot(
      slotIndex: freeSlot.slotIndex,
      fallbackCurrentHp: pokemon?.hitPoints ?? 0,
    );

    await _teamRepository.updateSlot(profileId: profile.id, updatedSlot: updatedSlot);
    await _pokemonPcRepository.removePokemon(
      profileId: profile.id,
      pcPokemonId: pcPokemon.id,
    );

    await _loadPc(clearMessages: false);
    if (!mounted) return;
    setState(() {
      _successMessage = '${_pcDisplayName(pcPokemon, pokemon)} spostato nello slot ${freeSlot.slotIndex + 1}.';
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
    final hasFreeTeamSlot = _firstFreeTeamSlot != null;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('PC Pokémon'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPc(clearMessages: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && _allPokemon.isEmpty)
              _PcErrorState(message: _errorMessage!, onRetry: _loadPc)
            else ...[
              _PcHeader(
                profileName: profileName,
                storedCount: _pcPokemon.length,
                filledTeamSlots: _filledTeamSlots,
                totalTeamSlots: visibleTeam.length,
                hasFreeTeamSlot: hasFreeTeamSlot,
              ),
              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                _PcStatusMessage(message: _successMessage!),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Squadra',
                subtitle: 'Deposita nel PC senza perdere dati del Pokémon.',
              ),
              const SizedBox(height: 8),
              for (final slot in visibleTeam)
                _TeamStorageCard(
                  slot: slot,
                  pokemon: _pokemonById(slot.pokemonId),
                  onDeposit: slot.pokemonId == null ? null : () => _depositTeamSlot(slot),
                ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'PC',
                subtitle: 'Ritira in squadra o rilascia i Pokémon depositati.',
              ),
              const SizedBox(height: 8),
              if (_pcPokemon.isEmpty)
                const _PcEmptyState()
              else
                for (final item in _pcPokemon)
                  _PcPokemonCard(
                    pcPokemon: item,
                    pokemon: _pokemonById(item.pokemonId),
                    canMoveToTeam: hasFreeTeamSlot,
                    onMoveToTeam: () => _moveToTeam(item),
                    onRelease: () => _releaseFromPc(item),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PcHeader extends StatelessWidget {
  const _PcHeader({
    required this.profileName,
    required this.storedCount,
    required this.filledTeamSlots,
    required this.totalTeamSlots,
    required this.hasFreeTeamSlot,
  });

  final String profileName;
  final int storedCount;
  final int filledTeamSlots;
  final int totalTeamSlots;
  final bool hasFreeTeamSlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.computer, color: colorScheme.onSecondaryContainer, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PC di $profileName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$storedCount nel PC • $filledTeamSlots/$totalTeamSlots in squadra',
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFreeTeamSlot
                        ? 'Puoi ritirare un Pokémon dal PC.'
                        : 'Squadra piena: deposita prima un Pokémon.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TeamStorageCard extends StatelessWidget {
  const _TeamStorageCard({
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
    final title = pokemon == null
        ? 'Slot ${slot.slotIndex + 1} vuoto'
        : nickname.isEmpty
            ? pokemon.name
            : nickname;

    return Card(
      child: ListTile(
        leading: pokemon == null
            ? CircleAvatar(child: Text('${slot.slotIndex + 1}'))
            : PokemonAssetImage(
                pokemon: pokemon,
                size: 48,
                formName: slot.formName,
              ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: pokemon == null
            ? const Text('Nessun Pokémon in questo slot.')
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('#${pokemon.id.toString().padLeft(3, '0')}'),
                  for (final type in pokemon.types) PokemonTypeBadge(type: type, height: 18),
                  if (slot.nature != 'No Nature') _MiniChip(label: slot.nature),
                  if (slot.isShiny) const _MiniChip(label: 'Shiny'),
                ],
              ),
        trailing: OutlinedButton(
          onPressed: onDeposit,
          child: const Text('Deposita'),
        ),
        iconColor: colorScheme.primary,
      ),
    );
  }
}

class _PcPokemonCard extends StatelessWidget {
  const _PcPokemonCard({
    required this.pcPokemon,
    required this.pokemon,
    required this.canMoveToTeam,
    required this.onMoveToTeam,
    required this.onRelease,
  });

  final PcPokemon pcPokemon;
  final Pokemon? pokemon;
  final bool canMoveToTeam;
  final VoidCallback onMoveToTeam;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final pokemon = this.pokemon;
    final name = pcPokemon.displayName.isEmpty
        ? pokemon?.name ?? 'Pokémon sconosciuto'
        : pcPokemon.displayName;
    final number = pokemon == null ? '' : '#${pokemon.id.toString().padLeft(3, '0')}';

    return Card(
      child: ListTile(
        leading: pokemon == null
            ? const CircleAvatar(child: Icon(Icons.help_outline))
            : PokemonAssetImage(
                pokemon: pokemon,
                size: 48,
                formName: pcPokemon.formName,
              ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (number.isNotEmpty) Text(number),
            if (pokemon != null)
              for (final type in pokemon.types) PokemonTypeBadge(type: type, height: 18),
            if (pcPokemon.nature != 'No Nature') _MiniChip(label: pcPokemon.nature),
            if (pcPokemon.isShiny) const _MiniChip(label: 'Shiny'),
            _MiniChip(label: 'PC ${_formatDate(pcPokemon.capturedAt)}'),
          ],
        ),
        trailing: PopupMenuButton<_PcAction>(
          tooltip: 'Azioni PC',
          onSelected: (action) {
            switch (action) {
              case _PcAction.moveToTeam:
                onMoveToTeam();
                break;
              case _PcAction.release:
                onRelease();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _PcAction.moveToTeam,
              enabled: canMoveToTeam,
              child: const Text('Sposta in squadra'),
            ),
            const PopupMenuItem(
              value: _PcAction.release,
              child: Text('Rilascia'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
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
          'Nessun Pokémon nel PC. Quando catturi con la squadra piena o depositi dalla squadra, finirà qui.',
        ),
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
