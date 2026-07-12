import 'package:flutter/material.dart';

import '../../models/generated_pokemon.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
import '../../services/pokemon_generator_service.dart';
import '../pokemon/pokemon_asset_image.dart';

class PokemonGeneratorCandidateSelector extends StatelessWidget {
  const PokemonGeneratorCandidateSelector({
    super.key,
    required this.candidates,
    required this.selectedIds,
    required this.filters,
    required this.generatorService,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  final List<Pokemon> candidates;
  final Set<int> selectedIds;
  final PokemonGeneratorFilters filters;
  final PokemonGeneratorService generatorService;
  final ValueChanged<int> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final selectedVisible = candidates
        .where((pokemon) => selectedIds.contains(pokemon.id))
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        maintainState: true,
        title: Text(
          'POKÉMON COMPATIBILI — ${candidates.length}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          selectedVisible == 0
              ? 'Apri l’elenco e scegli una o più specie.'
              : '$selectedVisible selezionati',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: candidates.isEmpty ? null : onSelectAll,
                  icon: const Icon(Icons.select_all),
                  label: const Text('Seleziona tutti'),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: selectedVisible == 0 ? null : onClearSelection,
                  icon: const Icon(Icons.deselect),
                  label: const Text('Deseleziona'),
                ),
                const Spacer(),
                Text(
                  '$selectedVisible/${candidates.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 20),
              child: Text(
                'Nessun Pokémon corrisponde ai filtri selezionati.',
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: (candidates.length * 92.0).clamp(120.0, 500.0),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pokemon = candidates[index];
                  return _CandidateRow(
                    pokemon: pokemon,
                    isSelected: selectedIds.contains(pokemon.id),
                    filters: filters,
                    generatorService: generatorService,
                    onTap: () => onToggle(pokemon.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.pokemon,
    required this.isSelected,
    required this.filters,
    required this.generatorService,
    required this.onTap,
  });

  final Pokemon pokemon;
  final bool isSelected;
  final PokemonGeneratorFilters filters;
  final PokemonGeneratorService generatorService;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formNames = generatorService.eligibleFormNames(pokemon, filters);
    final variants = [
      for (final formName in formNames)
        pokemon.resolveVariant(formName: formName),
    ];
    final typesByKey = <String, String>{};
    for (final variant in variants) {
      for (final type in variant.types) {
        final key = PokemonTypeLocalization.canonicalKey(type);
        typesByKey.putIfAbsent(
          key,
          () => PokemonTypeLocalization.englishValue(type),
        );
      }
    }
    final types = typesByKey.values.toList(growable: false)
      ..sort(PokemonTypeLocalization.compareByItalianLabel);
    final srValues = variants.map((variant) => variant.sr).toList();
    final minimumSr = srValues.isEmpty
        ? pokemon.sr
        : srValues.reduce((a, b) => a < b ? a : b);
    final maximumSr = srValues.isEmpty
        ? pokemon.sr
        : srValues.reduce((a, b) => a > b ? a : b);
    final previewForm = formNames.length == 1 ? formNames.single : null;
    final formLabel = formNames
        .map((name) => name ?? 'Base')
        .join(', ');
    final srLabel = minimumSr == maximumSr
        ? _formatSr(minimumSr)
        : '${_formatSr(minimumSr)}–${_formatSr(maximumSr)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(value: isSelected, onChanged: (_) => onTap()),
            PokemonAssetImage(
              pokemon: pokemon,
              formName: previewForm,
              size: 54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pokemon.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '#${pokemon.id.toString().padLeft(3, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final type in types)
                        PokemonTypeBadge(type: type, height: 18),
                      Text(
                        'SR $srLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Forme compatibili: $formLabel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSr(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
