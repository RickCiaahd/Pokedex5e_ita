import 'package:flutter/material.dart';

import '../pokedex/pokedex_screen.dart';
import '../profile/profiles_screen.dart';
import '../team/team_selection_screen.dart';
import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../services/profile_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final ProfileStorageService _profileStorageService = ProfileStorageService();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  Map<int, PokedexEntry> _entries = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();
      final pokemon = await _pokemonRepository.getAllPokemon();
      final entries = await _profileStorageService.loadPokedexEntries();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _pokemon = pokemon;
        _entries = entries;
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

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final total = _pokemon.length;
    final seen = _pokemon.where((pokemon) {
      return _entries[pokemon.id]?.seen ?? false;
    }).length;
    final caught = _pokemon.where((pokemon) {
      return _entries[pokemon.id]?.caught ?? false;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex 5e ITA'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorState(
                message: _errorMessage!,
                onRetry: _loadDashboard,
              )
            else ...[
              _TrainerHeader(profileName: profile?.name ?? 'Allenatore'),
              const SizedBox(height: 20),
              _ProgressOverview(
                total: total,
                seen: seen,
                caught: caught,
              ),
              const SizedBox(height: 24),
              _HomeActionButton(
                icon: Icons.catching_pokemon,
                title: 'Apri Pokédex',
                subtitle: 'Consulta, filtra e marca i Pokémon.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PokedexScreen(),
                    ),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.groups,
                title: 'Squadra',
                subtitle: 'Scegli fino a 6 Pokémon per il profilo attivo.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeamSelectionScreen(
                        nickname: profile?.name ?? 'Allenatore',
                      ),
                    ),
                  );
                },
              ),
              _HomeActionButton(
                icon: Icons.person,
                title: 'Profili',
                subtitle: 'Crea, cambia o elimina profili allenatore.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfilesScreen(),
                    ),
                  );
                  await _loadDashboard();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerHeader extends StatelessWidget {
  const _TrainerHeader({required this.profileName});

  final String profileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ciao, $profileName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              const Text('Ecco il riepilogo della tua avventura.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({
    required this.total,
    required this.seen,
    required this.caught,
  });

  final int total;
  final int seen;
  final int caught;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progresso Pokédex',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : caught / total,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProgressStat(
                    label: 'Visti',
                    value: '$seen/$total',
                  ),
                ),
                Expanded(
                  child: _ProgressStat(
                    label: 'Catturati',
                    value: '$caught/$total',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
