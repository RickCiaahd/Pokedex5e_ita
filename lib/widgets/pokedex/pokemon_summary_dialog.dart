import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../screens/pokemon/pokemon_detail_screen.dart';
import '../pokemon/pokemon_asset_image.dart';

typedef PokedexEntryChanged = Future<void> Function(PokedexEntry entry);

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
    _selectedFormName = widget.entry.preferredFormName;
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

    for (final definition in widget.pokemon.formDefinitions) {
      if (definition.gender != null) continue;
      addForm(definition.displayName);
    }
    for (final choice in await PokemonAssetPaths.formChoices(widget.pokemon)) {
      addForm(choice.name);
    }
    addForm(_selectedFormName);

    final forms = formsByKey.values.toList(growable: false)
      ..sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    if (!mounted) return;
    setState(() {
      _forms = forms;
      _loadingForms = false;
    });
  }

  PokedexFormEntry get _selectedFormEntry =>
      _entry.formFor(_selectedFormName, speciesName: widget.pokemon.name);

  PokedexEntry get _selectedEntry =>
      _entry.viewForForm(_selectedFormName, speciesName: widget.pokemon.name);

  Pokemon get _selectedPokemon =>
      widget.pokemon.resolveVariant(formName: _selectedFormName);

  String get _selectedLabel => _selectedFormName ?? 'Base';

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

  @override
  Widget build(BuildContext context) {
    final pokemon = _selectedPokemon;
    final formEntry = _selectedFormEntry;
    final number = '#${widget.pokemon.id.toString().padLeft(3, '0')}';
    final isBase = _selectedFormName == null;
    final webDescription = pokemon.description?.trim() ?? '';
    final baseDescription = widget.flavor?.flavor.trim() ?? '';
    final description = isBase
        ? (baseDescription.isNotEmpty ? baseDescription : webDescription)
        : (webDescription.isNotEmpty ? webDescription : baseDescription);
    final webGenus = pokemon.genus?.trim() ?? '';
    final baseGenus = widget.flavor?.genus.trim() ?? '';
    final genus = isBase
        ? (baseGenus.isNotEmpty ? baseGenus : webGenus)
        : (webGenus.isNotEmpty ? webGenus : baseGenus);
    final heightMeters = pokemon.heightMeters ?? widget.flavor?.heightMeters;
    final weightKg = pokemon.weightKg ?? widget.flavor?.weightKg;

    return AlertDialog(
      title: Text('${widget.pokemon.name} $number'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: formEntry.caught
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: PokemonAssetImage(
                    pokemon: widget.pokemon,
                    entry: _selectedEntry,
                    formName: _selectedFormName,
                    useLargeArtwork: true,
                    size: 132,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedLabel.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (_loadingForms)
                const LinearProgressIndicator()
              else
                SizedBox(
                  height: 116,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 0; index < _forms.length; index++) ...[
                          if (index > 0) const SizedBox(width: 10),
                          _buildFormCard(_forms[index]),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
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
                    'Altezza: ${heightMeters.toStringAsFixed(1)} m · '
                    'Peso: ${weightKg.toStringAsFixed(1)} kg',
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
                    _StatChip(label: 'CA', value: pokemon.armorClass),
                    _StatChip(label: 'PF', value: pokemon.hitPoints),
                    _StatChip(label: 'FOR', value: pokemon.attributes.strength),
                    _StatChip(
                      label: 'DES',
                      value: pokemon.attributes.dexterity,
                    ),
                    _StatChip(
                      label: 'COS',
                      value: pokemon.attributes.constitution,
                    ),
                    _StatChip(
                      label: 'INT',
                      value: pokemon.attributes.intelligence,
                    ),
                    _StatChip(label: 'SAG', value: pokemon.attributes.wisdom),
                    _StatChip(label: 'CAR', value: pokemon.attributes.charisma),
                  ],
                ),
              ] else
                const Text(
                  'Forma non ancora vista.',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _toggleSeen,
          child: Text(formEntry.seen ? 'Non visto' : 'Visto'),
        ),
        TextButton(
          onPressed: _toggleCaught,
          child: Text(formEntry.caught ? 'Non catturato' : 'Catturato'),
        ),
        FilledButton(
          onPressed: formEntry.seen
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
    final label = formName ?? 'Base';
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PokemonAssetImage(
                    pokemon: pokemon,
                    entry: entry,
                    formName: formName,
                    useLargeArtwork: true,
                    size: 72,
                  ),
                  if (entry.caught || entry.seen)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        entry.caught
                            ? Icons.catching_pokemon
                            : Icons.visibility,
                        size: 16,
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
