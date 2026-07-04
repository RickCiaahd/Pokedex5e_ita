import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../pokemon/pokemon_detail_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key, required this.nickname});

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

    await _teamRepository.updateSlot(profileId: profile.id, updatedSlot: slot);

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
          allPokemon: _allPokemon,
          team: _team,
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
    final filledSlots = _team.where((slot) => slot.pokemonId != null).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Squadra')),
      body: RefreshIndicator(
        onRefresh: _loadTeam,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _TeamErrorState(message: _errorMessage!, onRetry: _loadTeam)
            else ...[
              _TeamHeader(
                profileName: profileName,
                filledSlots: filledSlots,
                totalSlots: _team.length,
              ),
              const SizedBox(height: 16),
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

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.profileName,
    required this.filledSlots,
    required this.totalSlots,
  });

  final String profileName;
  final int filledSlots;
  final int totalSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.catching_pokemon,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Squadra di'.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$filledSlots/$totalSlots Pokémon in squadra',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final number = pokemon == null
        ? null
        : '#${pokemon!.id.toString().padLeft(3, '0')}';
    final nickname = slot.nickname?.trim() ?? '';
    final title = nickname.isEmpty ? pokemon?.name ?? 'Slot vuoto' : nickname;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _SlotAvatar(slotIndex: slot.slotIndex, hasPokemon: pokemon != null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (pokemon != null)
                          Text(
                            number!,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (pokemon == null)
                      Text(
                        'Tocca per scegliere un Pokémon',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      )
                    else ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final type in pokemon!.types)
                            _SmallChip(label: type.toUpperCase()),
                          _SmallChip(label: 'HP ${pokemon!.hitPoints}'),
                          _SmallChip(label: 'AC ${pokemon!.armorClass}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              pokemon == null
                  ? IconButton.filled(
                      tooltip: 'Scegli',
                      icon: const Icon(Icons.add),
                      onPressed: onChange,
                    )
                  : PopupMenuButton<_SlotAction>(
                      tooltip: 'Azioni slot',
                      onSelected: (action) {
                        switch (action) {
                          case _SlotAction.change:
                            onChange();
                            break;
                          case _SlotAction.remove:
                            onRemove?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _SlotAction.change,
                          child: Text('Cambia Pokémon'),
                        ),
                        PopupMenuItem(
                          value: _SlotAction.remove,
                          child: Text('Rimuovi dallo slot'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SlotAction { change, remove }

class _SlotAvatar extends StatelessWidget {
  const _SlotAvatar({required this.slotIndex, required this.hasPokemon});

  final int slotIndex;
  final bool hasPokemon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: hasPokemon ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: hasPokemon
            ? const Icon(Icons.catching_pokemon, color: Colors.white, size: 30)
            : Text(
                '${slotIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
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
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scegli Pokémon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cerca per nome, numero o tipo...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: filteredPokemon.length,
                itemBuilder: (context, index) {
                  final pokemon = filteredPokemon[index];
                  final number = '#${pokemon.id.toString().padLeft(3, '0')}';

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: const Icon(Icons.catching_pokemon),
                      title: Text(
                        pokemon.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '$number • ${pokemon.types.join(' / ')} • HP ${pokemon.hitPoints} • AC ${pokemon.armorClass}',
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        Navigator.of(context).pop(pokemon.id);
                      },
                    ),
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
  const _TeamErrorState({required this.message, required this.onRetry});

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
