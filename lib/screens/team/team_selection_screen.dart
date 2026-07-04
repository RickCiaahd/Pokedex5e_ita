import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../pokemon/pokemon_detail_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({
    super.key,
    required this.nickname,
  });

  final String nickname;

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final TeamRepository _teamRepository = TeamRepository();

  UserProfile? _profile;
  List<Pokemon> _allPokemon = [];
  List<TeamSlot> _team = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final team = await _teamRepository.getTeam(profile.id);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _allPokemon = pokemon;
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

  Pokemon? _pokemonById(int? pokemonId) {
    if (pokemonId == null) return null;

    for (final pokemon in _allPokemon) {
      if (pokemon.id == pokemonId) return pokemon;
    }

    return null;
  }

  Future<void> _setPokemonInSlot(int slotIndex, int? pokemonId) async {
    final profile = _profile;
    if (profile == null) return;

    await _teamRepository.setPokemonInSlot(
      profileId: profile.id,
      slotIndex: slotIndex,
      pokemonId: pokemonId,
    );

    await _loadTeam();
  }

  Future<void> _updateSlot(TeamSlot slot) async {
    final profile = _profile;
    if (profile == null) return;

    await _teamRepository.updateSlot(
      profileId: profile.id,
      updatedSlot: slot,
    );

    await _loadTeam();
  }

  Future<void> _openPokemonDetail(TeamSlot slot) async {
    final pokemon = _pokemonById(slot.pokemonId);
    if (pokemon == null) {
      await _openPokemonPicker(slot);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          pokemon: pokemon,
          teamSlot: slot,
          onTeamSlotChanged: (updatedSlot) {
            _updateSlot(updatedSlot);
          },
        ),
      ),
    );

    await _loadTeam();
  }

  Future<void> _openPokemonPicker(TeamSlot slot) async {
    final selectedPokemonId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PokemonPickerSheet(pokemon: _allPokemon),
    );

    if (selectedPokemonId == null) return;

    await _setPokemonInSlot(slot.slotIndex, selectedPokemonId);
  }

  @override
  Widget build(BuildContext context) {
    final profileName = _profile?.name ?? widget.nickname;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squadra'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTeam,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _TeamErrorState(
                message: _errorMessage!,
                onRetry: _loadTeam,
              )
            else ...[
              Text(
                'Squadra di $profileName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tocca uno slot pieno per aprire la scheda del Pokémon.',
              ),
              const SizedBox(height: 20),
              for (final slot in _team)
                _TeamSlotCard(
                  slot: slot,
                  pokemon: _pokemonById(slot.pokemonId),
                  onOpen: () => _openPokemonDetail(slot),
                  onChange: () => _openPokemonPicker(slot),
                  onRemove: slot.pokemonId == null
                      ? null
                      : () => _setPokemonInSlot(slot.slotIndex, null),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamSlotCard extends StatelessWidget {
  const _TeamSlotCard({
    required this.slot,
    required this.pokemon,
    required this.onOpen,
    required this.onChange,
    required this.onRemove,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final number = pokemon == null
        ? null
        : '#${pokemon!.id.toString().padLeft(3, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${slot.slotIndex + 1}'),
        ),
        title: Text(pokemon?.name ?? 'Slot vuoto'),
        subtitle: Text(
          pokemon == null
              ? 'Scegli un Pokémon'
              : '$number • ${pokemon!.types.join(' / ')}',
        ),
        trailing: pokemon == null
            ? IconButton(
                tooltip: 'Scegli',
                icon: const Icon(Icons.add),
                onPressed: onChange,
              )
            : Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Cambia',
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: onChange,
                  ),
                  IconButton(
                    tooltip: 'Rimuovi',
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
                ],
              ),
        onTap: onOpen,
      ),
    );
  }
}

class _PokemonPickerSheet extends StatefulWidget {
  const _PokemonPickerSheet({required this.pokemon});

  final List<Pokemon> pokemon;

  @override
  State<_PokemonPickerSheet> createState() => _PokemonPickerSheetState();
}

class _PokemonPickerSheetState extends State<_PokemonPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPokemon = widget.pokemon.where((pokemon) {
      final query = _query.toLowerCase().trim();

      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cerca Pokémon...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPokemon.length,
                itemBuilder: (context, index) {
                  final pokemon = filteredPokemon[index];
                  final number = '#${pokemon.id.toString().padLeft(3, '0')}';

                  return ListTile(
                    leading: const Icon(Icons.catching_pokemon),
                    title: Text(pokemon.name),
                    subtitle: Text('$number • ${pokemon.types.join(' / ')}'),
                    onTap: () {
                      Navigator.of(context).pop(pokemon.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamErrorState extends StatelessWidget {
  const _TeamErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Errore: $message',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}
