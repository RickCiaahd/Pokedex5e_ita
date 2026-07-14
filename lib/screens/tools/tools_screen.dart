import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../repositories/master_battle_session_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../battle/npc_battle_screen.dart';
import 'encounter_generator_screen.dart';
import 'encounter_library_screen.dart';
import 'npc_trainer_generator_screen.dart';
import 'npc_trainer_library_screen.dart';
import 'pokemon_generator_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final MasterBattleSessionRepository _battleRepository =
      MasterBattleSessionRepository();

  String? _profileId;
  List<Pokemon> _catalog = const [];
  bool _hasActiveMasterFight = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await _profileRepository.getActiveProfile();
      final catalog = await _pokemonRepository.getAllPokemon();
      final hasActiveFight = await _battleRepository.hasSession(profile.id);
      if (!mounted) return;
      setState(() {
        _profileId = profile.id;
        _catalog = catalog;
        _hasActiveMasterFight = hasActiveFight;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resumeMasterFight() async {
    final profileId = _profileId;
    if (profileId == null) return;
    final session = await _battleRepository.getSession(profileId);
    if (!mounted) return;
    if (session == null) {
      await _load();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NpcBattleScreen(
          profileId: profileId,
          catalog: _catalog,
          initialSession: session,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Strumenti del Master'),
        actions: const [HomeAppBarAction()],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.construction,
                      size: 38,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preparazione e gestione della sessione',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Generatori, raccolte, contenuti salvati e Fight del Master sono divisi per funzione.',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            if (_hasActiveMasterFight) ...[
              const SizedBox(height: 18),
              const _ToolSectionTitle(
                icon: Icons.play_circle_outline,
                title: 'SESSIONE IN CORSO',
                subtitle: 'La sessione rimane salvata finché non viene sostituita.',
              ),
              Card(
                color: colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.sports_mma_outlined,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  title: const Text(
                    'Fight del Master in corso',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Riprendi PF, PP, status, round e iniziativa salvati.',
                  ),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: _isLoading ? null : _resumeMasterFight,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _ToolSectionTitle(
              icon: Icons.auto_awesome_outlined,
              title: 'GENERATORI',
              subtitle: 'Crea nuovi contenuti da usare o salvare.',
            ),
            _ToolCard(
              icon: Icons.catching_pokemon,
              title: 'Generatore Pokémon',
              subtitle:
                  'Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.',
              actionLabel: 'GENERA',
              onTap: () => _open(const PokemonGeneratorScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.travel_explore,
              title: 'Generatore incontri',
              subtitle:
                  'Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.',
              actionLabel: 'GENERA',
              onTap: () => _open(const EncounterGeneratorScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.groups_2_outlined,
              title: 'Generatore Allenatori PNG',
              subtitle:
                  'Crea identità, specializzazione, squadra, personalità, tattiche e ricompense.',
              actionLabel: 'GENERA',
              onTap: () => _open(const NpcTrainerGeneratorScreen()),
            ),
            const SizedBox(height: 22),
            const _ToolSectionTitle(
              icon: Icons.inventory_2_outlined,
              title: 'LIBRERIE',
              subtitle: 'Riapri, modifica e usa i contenuti già preparati.',
            ),
            _ToolCard(
              icon: Icons.bookmarks_outlined,
              title: 'Libreria incontri',
              subtitle:
                  'Incontri salvati, raccolte ponderate e avvio diretto nel Fight del Master.',
              actionLabel: 'APRI',
              onTap: () => _open(const EncounterLibraryScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.people_alt_outlined,
              title: 'Libreria Allenatori PNG',
              subtitle:
                  'Allenatori salvati, selezione multipla e gestione delle loro squadre nel fight.',
              actionLabel: 'APRI',
              onTap: () => _open(const NpcTrainerLibraryScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolSectionTitle extends StatelessWidget {
  const _ToolSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: enabled
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Icon(
                  icon,
                  color: enabled
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (enabled) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
