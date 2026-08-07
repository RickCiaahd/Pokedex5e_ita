import 'package:flutter/material.dart';

import '../../localization/pokemon_form_localization.dart';
import '../../localization/ui_text.dart';
import '../../models/item_driven_pokemon_form.dart';
import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../screens/pokemon/pokemon_detail_screen.dart';
import '../pokemon/pokemon_asset_image.dart';

typedef PokedexEntryChanged = Future<void> Function(PokedexEntry entry);

String _displayFormLabel(BuildContext context, String? formName) {
  if (formName == null || formName.trim().isEmpty) {
    return context.uiText('Base', 'Base');
  }

  final raw = formName.trim();
  final normalized = raw.toLowerCase();
  if (normalized.contains('combat breed')) {
    return context.uiText('Paldea · Lotta', 'Paldea · Combat');
  }
  if (normalized.contains('blaze breed')) {
    return context.uiText('Paldea · Fuoco', 'Paldea · Blaze');
  }
  if (normalized.contains('aqua breed')) {
    return context.uiText('Paldea · Acqua', 'Paldea · Aqua');
  }
  if (normalized.contains('alolan') || normalized == 'alola') {
    return context.uiText('Alola', 'Alolan');
  }
  if (normalized.contains('galarian') || normalized == 'galar') {
    return context.uiText('Galar', 'Galarian');
  }
  if (normalized.contains('hisuian') || normalized == 'hisui') {
    return context.uiText('Hisui', 'Hisuian');
  }
  if (normalized.contains('paldean') || normalized == 'paldea') {
    return context.uiText('Paldea', 'Paldean');
  }
  return raw;
}

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
  final PokedexEntryChanged onEntryChanged;

  @override
  State<PokemonSummaryDialog> createState() => _PokemonSummaryDialogState();
}

class _PokemonSummaryDialogState extends State<PokemonSummaryDialog> {
  late PokedexEntry _entry;
  late String? _selectedFormName;
  List<String?> _forms = const [null];
  bool _loadingForms = true;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _selectedFormName =
        ItemDrivenPokemonForm.usesHeldItemForm(widget.pokemon.id)
        ? null
        : widget.entry.preferredFormName;
    _loadForms();
  }

  Future<void> _loadForms() async {
    final formsByKey = <String, String?>{'base': null};

    void addForm(String? rawName) {
      if (!PokedexEntry.isTrackableForm(
        rawName,
        speciesName: widget.pokemon.name,
      )) {
        return;
      }
      final key = PokedexEntry.formKey(
        rawName,
        speciesName: widget.pokemon.name,
      );
      formsByKey.putIfAbsent(
        key,
        () => PokedexEntry.displayNameFor(
          rawName,
          speciesName: widget.pokemon.name,
        ),
      );
    }

    List<String?> sortedForms() => formsByKey.values.toList(growable: false)
      ..sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    for (final definition in widget.pokemon.formDefinitions) {
      if (definition.gender != null) continue;
      addForm(definition.displayName);
    }
    addForm(_selectedFormName);

    // Le forme già note dai dati del Pokémon sono sufficienti per rendere il
    // popup immediatamente utilizzabile. Le eventuali forme scoperte dagli
    // asset vengono aggiunte in seguito senza bloccare il contenuto con uno
    // spinner, cosa particolarmente importante sui dispositivi più lenti.
    if (!mounted) return;
    setState(() {
      _forms = sortedForms();
      _loadingForms = false;
    });

    final assetChoices = await PokemonAssetPaths.formChoices(widget.pokemon);
    for (final choice in assetChoices) {
      addForm(choice.name);
    }
    if (!mounted) return;
    setState(() => _forms = sortedForms());
  }

  PokedexFormEntry get _selectedFormEntry =>
      _entry.formFor(_selectedFormName, speciesName: widget.pokemon.name);

  PokedexEntry get _selectedEntry =>
      _entry.viewForForm(_selectedFormName, speciesName: widget.pokemon.name);

  Pokemon get _selectedPokemon =>
      widget.pokemon.resolveVariant(formName: _selectedFormName);

  Future<void> _toggleSeen() async {
    final current = _selectedFormEntry;
    final updated = _entry.setFormState(
      formName: _selectedFormName,
      speciesName: widget.pokemon.name,
      seen: !current.seen,
      caught: current.seen ? false : current.caught,
    );
    setState(() => _entry = updated);
    await widget.onEntryChanged(updated);
  }

  Future<void> _toggleCaught() async {
    final current = _selectedFormEntry;
    final updated = _entry.setFormState(
      formName: _selectedFormName,
      speciesName: widget.pokemon.name,
      seen: true,
      caught: !current.caught,
    );
    setState(() => _entry = updated);
    await widget.onEntryChanged(updated);
  }

  Widget _buildFormCard(String? formName) {
    final key = PokedexEntry.formKey(
      formName,
      speciesName: widget.pokemon.name,
    );
    final selectedKey = PokedexEntry.formKey(
      _selectedFormName,
      speciesName: widget.pokemon.name,
    );
    final state = _entry.viewForForm(
      formName,
      speciesName: widget.pokemon.name,
    );

    return _FormCard(
      pokemon: widget.pokemon,
      formName: formName,
      entry: state,
      selected: key == selectedKey,
      onTap: () => setState(() {
        _selectedFormName = formName;
      }),
    );
  }

  void _openSheet(Pokemon pokemon) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PokemonDetailScreen(pokemon: pokemon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = _selectedPokemon;
    final formEntry = _selectedFormEntry;
    final number = '#${widget.pokemon.id.toString().padLeft(3, '0')}';
    final isBase = _selectedFormName == null;
    final localizedForm = isBase
        ? null
        : PokemonFormLocalization.textFor(pokemon);
    final webDescription =
        localizedForm?.description.trim() ?? pokemon.description?.trim() ?? '';
    final baseDescription = widget.flavor?.flavor.trim() ?? '';
    final description = isBase
        ? (baseDescription.isNotEmpty ? baseDescription : webDescription)
        : (webDescription.isNotEmpty ? webDescription : baseDescription);
    final webGenus = localizedForm?.genus.trim() ?? pokemon.genus?.trim() ?? '';
    final baseGenus = widget.flavor?.genus.trim() ?? '';
    final genus = isBase
        ? (baseGenus.isNotEmpty ? baseGenus : webGenus)
        : (webGenus.isNotEmpty ? webGenus : baseGenus);
    final heightMeters = pokemon.heightMeters ?? widget.flavor?.heightMeters;
    final weightKg = pokemon.weightKg ?? widget.flavor?.weightKg;
    final hasFormSelector = !_loadingForms && _forms.length > 1;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxDialogHeight = screenHeight > 0 ? screenHeight * 0.9 : 720.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.pokemon.name} $number',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: context.uiText('Chiudi', 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: formEntry.caught
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: PokemonAssetImage(
                          pokemon: widget.pokemon,
                          entry: _selectedEntry,
                          formName: _selectedFormName,
                          useLargeArtwork: true,
                          size: 128,
                        ),
                      ),
                    ),
                    if (_loadingForms) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ] else if (hasFormSelector) ...[
                      const SizedBox(height: 10),
                      Text(
                        _displayFormLabel(
                          context,
                          _selectedFormName,
                        ).toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < _forms.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(width: 8),
                                _buildFormCard(_forms[index]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (formEntry.seen) ...[
                      if (genus.isNotEmpty) ...[
                        Text(
                          genus,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (heightMeters != null && weightKg != null) ...[
                        Text(
                          context.uiText(
                            'Altezza: ${heightMeters.toStringAsFixed(1)} m · Peso: ${weightKg.toStringAsFixed(1)} kg',
                            'Height: ${heightMeters.toStringAsFixed(1)} m · Weight: ${weightKg.toStringAsFixed(1)} kg',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (description.isNotEmpty) ...[
                        Text(description, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                            label: context.uiText('CA', 'AC'),
                            value: pokemon.armorClass,
                          ),
                          _StatChip(
                            label: context.uiText('PF', 'HP'),
                            value: pokemon.hitPoints,
                          ),
                          _StatChip(
                            label: context.uiText('FOR', 'STR'),
                            value: pokemon.attributes.strength,
                          ),
                          _StatChip(
                            label: context.uiText('DES', 'DEX'),
                            value: pokemon.attributes.dexterity,
                          ),
                          _StatChip(
                            label: context.uiText('COS', 'CON'),
                            value: pokemon.attributes.constitution,
                          ),
                          _StatChip(
                            label: 'INT',
                            value: pokemon.attributes.intelligence,
                          ),
                          _StatChip(
                            label: context.uiText('SAG', 'WIS'),
                            value: pokemon.attributes.wisdom,
                          ),
                          _StatChip(
                            label: context.uiText('CAR', 'CHA'),
                            value: pokemon.attributes.charisma,
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        context.uiText(
                          'Forma non ancora vista.',
                          'Form not seen yet.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: formEntry.seen
                          ? context.uiText(
                              'Segna come non visto',
                              'Mark as unseen',
                            )
                          : context.uiText('Segna come visto', 'Mark as seen'),
                      child: TextButton(
                        onPressed: _toggleSeen,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formEntry.seen
                                ? context.uiText('VISTO', 'SEEN')
                                : context.uiText('NON VISTO', 'UNSEEN'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Tooltip(
                      message: formEntry.caught
                          ? context.uiText(
                              'Segna come non catturato',
                              'Mark as uncaught',
                            )
                          : context.uiText(
                              'Segna come catturato',
                              'Mark as caught',
                            ),
                      child: TextButton(
                        onPressed: _toggleCaught,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formEntry.caught
                                ? context.uiText('CATTURATO', 'CAUGHT')
                                : context.uiText(
                                    'NON CATTURATO',
                                    'NOT CAUGHT',
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton(
                      onPressed: formEntry.seen
                          ? () => _openSheet(pokemon)
                          : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(context.uiText('SCHEDA', 'SHEET')),
                      ),
                    ),
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

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.pokemon,
    required this.formName,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final Pokemon pokemon;
  final String? formName;
  final PokedexEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _displayFormLabel(context, formName);
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(5),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PokemonAssetImage(
                    pokemon: pokemon,
                    entry: entry,
                    formName: formName,
                    useLargeArtwork: true,
                    size: 64,
                  ),
                  if (entry.caught || entry.seen)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        entry.caught
                            ? Icons.catching_pokemon
                            : Icons.visibility,
                        size: 15,
                        color: entry.caught
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
