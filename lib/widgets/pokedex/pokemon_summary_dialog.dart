import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../screens/pokemon/pokemon_detail_screen.dart';
import '../../services/pokedex_form_catalog.dart';
import '../pokemon/pokemon_asset_image.dart';

class PokemonSummaryDialog extends StatefulWidget {
  const PokemonSummaryDialog({
    super.key,
    required this.pokemon,
    this.flavor,
    required this.entry,
    required this.onEntryChanged,
  });

  final Pokemon pokemon;
  final PokemonFlavor? flavor;
  final PokedexEntry entry;
  final Future<void> Function(PokedexEntry entry) onEntryChanged;

  @override
  State<PokemonSummaryDialog> createState() => _PokemonSummaryDialogState();
}

class _PokemonSummaryDialogState extends State<PokemonSummaryDialog> {
  late PokedexEntry _entry;
  late List<PokedexFormOption> _forms;
  late PokedexFormOption _selectedForm;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _forms = PokedexFormCatalog.optionsFor(widget.pokemon);
    _selectedForm = PokedexFormCatalog.preferredFor(widget.pokemon, _entry);
  }

  PokedexFormEntry get _selectedStatus => _selectedForm.statusFor(_entry);

  Future<void> _updateSelectedStatus({
    required bool seen,
    required bool caught,
  }) async {
    final updated = _entry.withFormStatus(
      formKey: _selectedForm.key,
      formName: _selectedForm.name,
      aliases: _selectedForm.aliases,
      seen: seen,
      caught: caught,
    );

    setState(() => _entry = updated);
    await widget.onEntryChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _selectedForm.pokemon;
    final status = _selectedStatus;
    final number = '#${widget.pokemon.id.toString().padLeft(3, '0')}';
    final webDescription = pokemon.description?.trim() ?? '';
    final description = webDescription.isNotEmpty
        ? webDescription
        : widget.flavor?.flavor.trim() ?? '';
    final visibilityEntry = PokedexEntry(
      pokemonId: widget.pokemon.id,
      seen: status.seen,
      caught: status.caught,
    );

    return AlertDialog(
      title: Text('${widget.pokemon.name} $number'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_forms.length > 1) ...[
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final form = _forms[index];
                      final formStatus = form.statusFor(_entry);
                      final selected = form.key == _selectedForm.key;
                      return _FormThumbnail(
                        pokemon: widget.pokemon,
                        form: form,
                        status: formStatus,
                        selected: selected,
                        onTap: () => setState(() => _selectedForm = form),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DecoratedBox(
                decoration: BoxDecoration(
                  color: status.caught
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: PokemonAssetImage(
                    pokemon: widget.pokemon,
                    entry: visibilityEntry,
                    formName: _selectedForm.formName,
                    useLargeArtwork: true,
                    size: 112,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedForm.isBase
                    ? widget.pokemon.name
                    : '${widget.pokemon.name} · ${_selectedForm.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (!status.seen)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Forma non ancora vista.',
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                if (widget.flavor != null) ...[
                  Text(
                    widget.flavor!.genus,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Altezza: ${widget.flavor!.heightMeters.toStringAsFixed(1)} m · '
                    'Peso: ${widget.flavor!.weightKg.toStringAsFixed(1)} kg',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                if (description.isNotEmpty) ...[
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final type in pokemon.types)
                      PokemonTypeBadge(type: type, height: 24),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('CA: ${pokemon.armorClass}')),
                    Expanded(child: Text('PF: ${pokemon.hitPoints}')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _updateSelectedStatus(
            seen: !status.seen,
            caught: status.seen ? false : status.caught,
          ),
          child: Text(status.seen ? 'Non visto' : 'Visto'),
        ),
        TextButton(
          onPressed: () =>
              _updateSelectedStatus(seen: true, caught: !status.caught),
          child: Text(status.caught ? 'Non catturato' : 'Catturato'),
        ),
        FilledButton(
          onPressed: status.seen
              ? () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PokemonDetailScreen(pokemon: pokemon),
                    ),
                  );
                }
              : null,
          child: const Text('Scheda'),
        ),
      ],
    );
  }
}

class _FormThumbnail extends StatelessWidget {
  const _FormThumbnail({
    required this.pokemon,
    required this.form,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final Pokemon pokemon;
  final PokedexFormOption form;
  final PokedexFormEntry status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibilityEntry = PokedexEntry(
      pokemonId: pokemon.id,
      seen: status.seen,
      caught: status.caught,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 96,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PokemonAssetImage(
                pokemon: pokemon,
                entry: visibilityEntry,
                formName: form.formName,
                useLargeArtwork: true,
                size: 68,
              ),
            ),
            Text(
              form.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            Icon(
              status.caught
                  ? Icons.catching_pokemon
                  : status.seen
                  ? Icons.visibility
                  : Icons.lock_outline,
              size: 14,
              color: status.caught
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
