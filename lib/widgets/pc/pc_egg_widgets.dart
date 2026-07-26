import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../models/breeding_egg.dart';
import '../../models/pokemon.dart';
import '../pokemon/egg_asset_image.dart';

enum PcEggAction { moveToTeam, openBreeding }

class PcEggGridCell extends StatelessWidget {
  const PcEggGridCell({
    super.key,
    required this.egg,
    required this.pokemon,
    required this.onTap,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            const Center(child: EggAssetImage(size: 46)),
            Positioned(
              left: 4,
              top: 4,
              child: Text(
                context.uiText('Uovo', 'Egg'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 3,
              child: Text(
                pokemon?.name ?? '#${egg.speciesId}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PcEggActionSheet extends StatelessWidget {
  const PcEggActionSheet({
    super.key,
    required this.egg,
    required this.pokemon,
    required this.teamIsFull,
  });

  final BreedingEgg egg;
  final Pokemon? pokemon;
  final bool teamIsFull;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const EggAssetImage(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.uiText(
                          'UOVO${pokemon == null ? '' : ' DI ${pokemon!.name.toUpperCase()}'}',
                          'EGG${pokemon == null ? '' : ' OF ${pokemon!.name.toUpperCase()}'}',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        egg.isReady
                            ? context.uiText(
                                'Incubazione completata',
                                'Incubation complete',
                              )
                            : context.uiText(
                                '${egg.incubationRemaining}/${egg.hatchTime} punti rimanenti',
                                '${egg.incubationRemaining}/${egg.hatchTime} points remaining',
                              ),
                      ),
                      Text(
                        context.uiText(
                          'Nel PC l’incubazione è in pausa.',
                          'Incubation is paused in the PC.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: teamIsFull
                  ? null
                  : () => Navigator.of(context).pop(PcEggAction.moveToTeam),
              icon: const Icon(Icons.swap_horiz),
              label: Text(
                teamIsFull
                    ? context.uiText(
                        'NESSUN POKÉSLOT LIBERO',
                        'NO FREE POKÉSLOT',
                      )
                    : context.uiText('SPOSTA IN SQUADRA', 'MOVE TO TEAM'),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(PcEggAction.openBreeding),
              icon: const Icon(Icons.egg_alt_outlined),
              label: Text(
                context.uiText('GESTISCI IN ALLEVAMENTO', 'MANAGE IN BREEDING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
