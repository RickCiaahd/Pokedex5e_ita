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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPc();
  }

  Future<void> _loadPc() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final pcPokemon = await _pokemonPcRepository.getPokemon(profile.id);
      final team = await _teamRepository.getTeam(profile.id);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _allPokemon = pokemon;
        _pcPokemon = pcPokemon;
        _team = team..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Pokemon? _pokemonById(int pokemonId) {
    for (final pokemon in _allPokemon) {
      if (pokemon.id == pokemonId) {
        return pokemon;
      }
    }

    return null;
  }

  int get _unlockedPokeslots {
    final level = _profile?.trainerLevel ?? TrainerProgression.minLevel;

    return TrainerProgression.pokeslotsForLevel(level);
  }

  TeamSlot? get _firstFreeTeamSlot {
    final unlockedSlots = _team
        .where((slot) => slot.slotIndex < _unlockedPokeslots)
        .toList()
      ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    for (final slot in unlockedSlots) {
      if (slot.pokemonId == null) {
        return slot;
      }
    }

    return null;
  }

  Future<void> _moveToTeam(PcPokemon pcPokemon) async {
    final profile = _profile;
    final freeSlot = _firstFreeTeamSlot;
    final pokemon = _pokemonById(pcPokemon.pokemonId);
    if (profile == null || freeSlot == null) return;

    await _teamRepository.setPokemonInSlot(
      profileId: profile.id,
      slotIndex: freeSlot.slotIndex,
      pokemonId: pcPokemon.pokemonId,
    );
    await _pokemonPcRepository.removePokemon(
      profileId: profile.id,
      pcPokemonId: pcPokemon.id,
    );
    await _loadPc();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${pokemon?.name ?? 'Pokemon'} spostato nello slot ${freeSlot.slotIndex + 1}.',
        ),
      ),
    );
  }

  Future<void> _releaseFromPc(PcPokemon pcPokemon) async {
    final profile = _profile;
    if (profile == null) return;

    final pokemon = _pokemonById(pcPokemon.pokemonId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rilasciare Pokemon?'),
        content: Text(
          'Vuoi rimuovere ${pokemon?.name ?? 'questo Pokemon'} dal PC?',
        ),
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
    await _loadPc();
  }

  @override
  Widget build(BuildContext context) {
    final profileName = _profile?.name ?? 'Allenatore';
    final hasFreeTeamSlot = _firstFreeTeamSlot != null;

    return Scaffold(
      appBar: AppBar(title: const Text('PC Pokemon')),
      body: RefreshIndicator(
        onRefresh: _loadPc,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _PcErrorState(message: _errorMessage!, onRetry: _loadPc)
            else ...[
              _PcHeader(
                profileName: profileName,
                storedCount: _pcPokemon.length,
                hasFreeTeamSlot: hasFreeTeamSlot,
              ),
              const SizedBox(height: 16),
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
    required this.hasFreeTeamSlot,
  });

  final String profileName;
  final int storedCount;
  final bool hasFreeTeamSlot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
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
                  '$storedCount Pokemon depositati',
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFreeTeamSlot
                      ? 'Puoi spostare un Pokemon in squadra.'
                      : 'Squadra piena o senza slot sbloccati liberi.',
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final name = pcPokemon.displayName.isEmpty
        ? pokemon?.name ?? 'Pokemon sconosciuto'
        : pcPokemon.displayName;
    final number = pokemon == null
        ? ''
        : '#${pokemon!.id.toString().padLeft(3, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.catching_pokemon,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if (number.isNotEmpty) number,
            if (pokemon != null) pokemon!.types.join(' / '),
            'Catturato ${_formatDate(pcPokemon.capturedAt)}',
          ].join(' - '),
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

enum _PcAction { moveToTeam, release }

class _PcEmptyState extends StatelessWidget {
  const _PcEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Nessun Pokemon nel PC. Quando catturi con la squadra piena, finira qui.',
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
