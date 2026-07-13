import 'package:flutter/material.dart';

import '../../widgets/navigation/home_leading_button.dart';
import 'encounter_generator_screen.dart';
import 'encounter_library_screen.dart';
import 'npc_trainer_generator_screen.dart';
import 'npc_trainer_library_screen.dart';
import 'pokemon_generator_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Strumenti'),
      ),
      body: ListView(
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
                          'Strumenti per giocatori e Master',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Genera Pokémon, incontri e Allenatori PNG completi per preparare rapidamente le sessioni.',
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
          const SizedBox(height: 16),
          _ToolCard(
            icon: Icons.catching_pokemon,
            title: 'Generatore Pokémon',
            subtitle:
                'Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.',
            actionLabel: 'APRI',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PokemonGeneratorScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ToolCard(
            icon: Icons.travel_explore,
            title: 'Generatore incontri',
            subtitle:
                'Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.',
            actionLabel: 'APRI',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EncounterGeneratorScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ToolCard(
            icon: Icons.bookmarks_outlined,
            title: 'Libreria incontri',
            subtitle:
                'Salva, riapri, duplica e modifica gli incontri preparati per le sessioni.',
            actionLabel: 'APRI',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EncounterLibraryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ToolCard(
            icon: Icons.groups_2_outlined,
            title: 'Allenatori PNG',
            subtitle:
                'Genera identità, specializzazione, squadra, personalità, tattiche e ricompense.',
            actionLabel: 'APRI',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NpcTrainerGeneratorScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ToolCard(
            icon: Icons.people_alt_outlined,
            title: 'Libreria Allenatori PNG',
            subtitle:
                'Salva, seleziona e controlla uno o più allenatori nello stesso fight.',
            actionLabel: 'APRI',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NpcTrainerLibraryScreen(),
                ),
              );
            },
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
