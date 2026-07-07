import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokedex_repositry.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/team_repository.dart';
import '../pc/pokemon_pc_screen.dart';
import '../team/team_selection_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  List<TeamSlot> _team = [];
  bool _isLoading = true;
  bool _isCapturing = false;
  String _query = '';
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

  Future<void> _loadCaptureData() async {
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
        _pokemon = pokemon;
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

  List<Pokemon> get _filteredPokemon {
    final query = _query.toLowerCase().trim();
    final filtered = _pokemon.where((pokemon) {
      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return filtered;
  }

  Future<void> _capturePokemon(Pokemon pokemon) async {
    final profile = _profile;
    if (profile == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final teamSlot = _firstFreeTeamSlot;
      final bool sentToTeam;
      final String destination;

      if (teamSlot != null) {
        await _teamRepository.setPokemonInSlot(
          profileId: profile.id,
          slotIndex: teamSlot.slotIndex,
          pokemonId: pokemon.id,
        );
        sentToTeam = true;
        destination = 'aggiunto allo slot ${teamSlot.slotIndex + 1}';
      } else {
        await _pokemonPcRepository.depositPokemon(
          profileId: profile.id,
          pokemonId: pokemon.id,
        );
        sentToTeam = false;
        destination = 'inviato al PC';
      }

      await _pokedexRepository.updateMarkMode(
        profileId: profile.id,
        pokemonId: pokemon.id,
        seen: true,
        caught: true,
      );
      await _loadCaptureData();

      if (!mounted) return;

      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        SnackBar(
          content: Text('${pokemon.name} catturato e $destination.'),
          action: SnackBarAction(
            label: sentToTeam ? 'Squadra' : 'PC',
            onPressed: () {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => sentToTeam
                      ? TeamSelectionScreen(nickname: profile.name)
                      : const PokemonPcScreen(),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPokemon = _filteredPokemon;
    final freeSlot = _firstFreeTeamSlot;

    return Scaffold(
      appBar: AppBar(title: const Text('Cattura Pokemon')),
      body: RefreshIndicator(
        onRefresh: _loadCaptureData,
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
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cerca per nome, numero o tipo...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              for (final pokemon in filteredPokemon)
                _CapturePokemonCard(
                  pokemon: pokemon,
                  isCapturing: _isCapturing,
                  onCapture: () => _capturePokemon(pokemon),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({
    required this.freeSlotIndex,
    required this.unlockedSlots,
  });

  final int? freeSlotIndex;
  final int unlockedSlots;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = freeSlotIndex == null
        ? 'La squadra e piena: le catture andranno al PC.'
        : 'Prossima cattura nello slot squadra ${freeSlotIndex! + 1}.';

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                    'Scegli il Pokemon catturato',
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
      ),
    );
  }
}

class _CapturePokemonCard extends StatelessWidget {
  const _CapturePokemonCard({
    required this.pokemon,
    required this.isCapturing,
    required this.onCapture,
  });

  final Pokemon pokemon;
  final bool isCapturing;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final number = '#${pokemon.id.toString().padLeft(3, '0')}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.catching_pokemon),
        title: Text(
          pokemon.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '$number - ${pokemon.types.join(' / ')} - HP ${pokemon.hitPoints} - CA ${pokemon.armorClass}',
        ),
        trailing: FilledButton(
          onPressed: isCapturing ? null : onCapture,
          child: const Text('Cattura'),
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
