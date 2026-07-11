import 'package:flutter/material.dart';

import '../bag/bag_screen.dart';
import '../battle/battle_screen.dart';
import '../capture/capture_pokemon_screen.dart';
import '../pc/pokemon_pc_screen.dart';
import '../pokedex/pokedex_screen.dart';
import '../profile/profiles_screen.dart';
import '../team/team_selection_screen.dart';
import '../trainer/trainer_sheet_screen.dart';
import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/battle_session_repository.dart';
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
  final BattleSessionRepository _battleSessionRepository =
      BattleSessionRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final ProfileStorageService _profileStorageService = ProfileStorageService();

  UserProfile? _profile;
  List<Pokemon> _pokemon = [];
  Map<int, PokedexEntry> _entries = {};

  bool _isLoading = true;
  bool _hasActiveBattle = false;
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
      final hasActiveBattle = await _battleSessionRepository.hasSession(
        profile.id,
      );

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _pokemon = pokemon;
        _entries = entries;
        _hasActiveBattle = hasActiveBattle;
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
      appBar: AppBar(title: const Text('Pokédex 5e ITA')),
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
              _ErrorState(message: _errorMessage!, onRetry: _loadDashboard)
            else ...[
              _TrainerHeader(profile: profile),
              const SizedBox(height: 20),
              _ProgressOverview(total: total, seen: seen, caught: caught),
              const SizedBox(height: 24),
              _HomeActionButton(
                icon: Icons.flash_on,
                title: _hasActiveBattle
                    ? 'Riprendi battaglia'
                    : 'Battle Companion',
                subtitle: _hasActiveBattle
                    ? 'Continua dal round, turno, PP e status salvati.'
                    : 'Traccia round, HP, status e PP durante il combattimento.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BattleScreen()),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.badge_outlined,
                title: 'Scheda Allenatore',
                subtitle: 'Aggiorna livello, soldi e progressione campagna.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TrainerSheetScreen(),
                    ),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.catching_pokemon,
                title: 'Apri Pokédex',
                subtitle: 'Consulta, filtra e marca i Pokémon.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PokedexScreen()),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.add_circle_outline,
                title: 'Cattura Pokémon',
                subtitle:
                    'Scegli il Pokémon: va in squadra se c’è posto, altrimenti nel PC.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CapturePokemonScreen(),
                    ),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.groups,
                title: 'Squadra',
                subtitle: 'Scegli fino a 6 Pokémon per il profilo attivo.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TeamSelectionScreen(
                        nickname: profile?.name ?? 'Allenatore',
                      ),
                    ),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.computer,
                title: 'PC Pokémon',
                subtitle: 'Gestisci i Pokémon catturati fuori squadra.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PokemonPcScreen()),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.backpack_outlined,
                title: 'Zaino',
                subtitle: 'Equipaggiamento, cure e oggetti da cattura.',
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const BagScreen()));
                },
              ),
              _HomeActionButton(
                icon: Icons.person,
                title: 'Profili',
                subtitle: 'Crea, cambia o elimina profili allenatore.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilesScreen()),
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
  const _TrainerHeader({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final profileName = profile?.name ?? 'Allenatore';
    final trainerLevel = profile?.trainerLevel ?? 1;
    final money = profile?.money ?? 0;
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);

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
              Text(
                'Lv. $trainerLevel | ₽ $money | Pokéslot $pokeslots | SR max $maxSr',
              ),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                  child: _ProgressStat(label: 'Visti', value: '$seen/$total'),
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
  const _ProgressStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
  const _ErrorState({required this.message, required this.onRetry});

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
