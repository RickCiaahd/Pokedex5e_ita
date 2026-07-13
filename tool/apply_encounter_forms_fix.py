from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding="utf-8")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected one match, found {count}")
    return source.replace(old, new, 1)


# Shared labels/keys for exact Pokémon forms.
write(
    "lib/models/pokemon_form_choice.dart",
    r'''import 'pokedex_entry.dart';

String pokemonFormChoiceKey({
  required int pokemonId,
  required String speciesName,
  String? formName,
}) {
  final formKey = PokedexEntry.formKey(
    formName,
    speciesName: speciesName,
  );
  return '$pokemonId|$formKey';
}

String pokemonFormDisplayName(String speciesName, String? formName) {
  final raw = formName?.trim() ?? '';
  if (raw.isEmpty ||
      PokedexEntry.formKey(raw, speciesName: speciesName) == 'base') {
    return speciesName;
  }

  final normalized = raw.toLowerCase();
  if (normalized.contains('alola')) return '$speciesName di Alola';
  if (normalized.contains('galar')) return '$speciesName di Galar';
  if (normalized.contains('hisui')) return '$speciesName di Hisui';
  if (normalized.contains('paldea')) return '$speciesName di Paldea';

  return '$speciesName — $raw';
}

String pokemonFormSubtitle(String? formName) {
  final raw = formName?.trim() ?? '';
  return raw.isEmpty ? 'Forma base' : 'Forma selezionata: $raw';
}
''',
)

# Add exact-form generation to the shared Pokémon generator.
path = "lib/services/pokemon_generator_service.dart"
source = read(path)
source = replace_once(
    source,
    r'''  GeneratedPokemon? generateForPokemon({
    required Pokemon pokemon,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    if (filterPokemon([pokemon], filters).isEmpty) return null;
    return _generateCandidate(pokemon, filters, random ?? Random());
  }
''',
    r'''  GeneratedPokemon? generateForPokemon({
    required Pokemon pokemon,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    if (filterPokemon([pokemon], filters).isEmpty) return null;
    return _generateCandidate(pokemon, filters, random ?? Random());
  }

  GeneratedPokemon? generateForPokemonForm({
    required Pokemon pokemon,
    required String? formName,
    required PokemonGeneratorFilters filters,
    Random? random,
  }) {
    final requestedKey = PokedexEntry.formKey(
      formName,
      speciesName: pokemon.name,
    );
    String? matchedForm;
    var found = false;
    for (final eligibleForm in eligibleFormNames(pokemon, filters)) {
      final eligibleKey = PokedexEntry.formKey(
        eligibleForm,
        speciesName: pokemon.name,
      );
      if (eligibleKey != requestedKey) continue;
      matchedForm = eligibleForm;
      found = true;
      break;
    }
    if (!found) return null;

    return _generateCandidate(
      pokemon,
      filters,
      random ?? Random(),
      forceForm: true,
      forcedFormName: matchedForm,
    );
  }
''',
    "pokemon exact form method",
)
source = replace_once(
    source,
    r'''  GeneratedPokemon? _generateCandidate(
    Pokemon basePokemon,
    PokemonGeneratorFilters filters,
    Random random,
  ) {
    final eligibleForms = eligibleFormNames(basePokemon, filters);
    if (eligibleForms.isEmpty) return null;
    final formName = eligibleForms[random.nextInt(eligibleForms.length)];
''',
    r'''  GeneratedPokemon? _generateCandidate(
    Pokemon basePokemon,
    PokemonGeneratorFilters filters,
    Random random, {
    bool forceForm = false,
    String? forcedFormName,
  }) {
    final eligibleForms = eligibleFormNames(basePokemon, filters);
    if (eligibleForms.isEmpty) return null;
    final formName = forceForm
        ? forcedFormName
        : eligibleForms[random.nextInt(eligibleForms.length)];
''',
    "pokemon exact form generation",
)
write(path, source)

# Manual selections now carry a species plus an optional exact form.
path = "lib/models/generated_encounter.dart"
source = read(path)
source = replace_once(
    source,
    r'''class EncounterMember {
''',
    r'''class EncounterManualSelection {
  const EncounterManualSelection({
    required this.pokemonId,
    required this.quantity,
    this.formName,
  });

  final int pokemonId;
  final int quantity;
  final String? formName;
}

class EncounterMember {
''',
    "manual encounter selection model",
)
write(path, source)

# Make manual and weighted generation respect the chosen form.
path = "lib/services/encounter_generator_service.dart"
source = read(path)
source = replace_once(
    source,
    r'''  GeneratedEncounter? generateManual({
    required List<Pokemon> catalog,
    required Map<int, int> quantities,
    required EncounterPartyProfile party,
    required EncounterGeneratorFilters filters,
    required EncounterDifficulty targetDifficulty,
    Random? random,
  }) {
    final rng = random ?? Random();
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final generated = <GeneratedPokemon>[];

    for (final entry in quantities.entries) {
      final pokemon = byId[entry.key];
      if (pokemon == null || entry.value <= 0) continue;
      for (var index = 0; index < entry.value.clamp(0, 12).toInt(); index++) {
        final result = _pokemonGeneratorService.generateForPokemon(
          pokemon: pokemon,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
        if (result != null) generated.add(result);
      }
    }
''',
    r'''  GeneratedEncounter? generateManual({
    required List<Pokemon> catalog,
    required Iterable<EncounterManualSelection> selections,
    required EncounterPartyProfile party,
    required EncounterGeneratorFilters filters,
    required EncounterDifficulty targetDifficulty,
    Random? random,
  }) {
    final rng = random ?? Random();
    final byId = {for (final pokemon in catalog) pokemon.id: pokemon};
    final generated = <GeneratedPokemon>[];

    for (final selection in selections) {
      final pokemon = byId[selection.pokemonId];
      if (pokemon == null || selection.quantity <= 0) continue;
      for (
        var index = 0;
        index < selection.quantity.clamp(0, 12).toInt();
        index++
      ) {
        final result = _pokemonGeneratorService.generateForPokemonForm(
          pokemon: pokemon,
          formName: selection.formName,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
        if (result != null) generated.add(result);
      }
    }
''',
    "manual encounter exact forms",
)
source = replace_once(
    source,
    r'''        final result = _pokemonGeneratorService.generateForPokemon(
          pokemon: pokemon,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
''',
    r'''        final result = _pokemonGeneratorService.generateForPokemonForm(
          pokemon: pokemon,
          formName: selected.formName,
          filters: _explicitPokemonFilters(filters),
          random: rng,
        );
''',
    "collection exact forms",
)
write(path, source)

# Preserve exact forms when regenerating encounter members.
path = "lib/screens/tools/encounter_result_screen.dart"
source = read(path)
source = source.replace(
    r'''      final generated = _pokemonGeneratorService.generateForPokemon(
        pokemon: current.pokemon.basePokemon,
        filters: _generationFilters,
      );
''',
    r'''      final generated = _pokemonGeneratorService.generateForPokemonForm(
        pokemon: current.pokemon.basePokemon,
        formName: current.pokemon.formName,
        filters: _generationFilters,
      );
''',
)
source = source.replace(
    r'''        final generated = _pokemonGeneratorService.generateForPokemon(
          pokemon: member.pokemon.basePokemon,
          filters: _generationFilters,
        );
''',
    r'''        final generated = _pokemonGeneratorService.generateForPokemonForm(
          pokemon: member.pokemon.basePokemon,
          formName: member.pokemon.formName,
          filters: _generationFilters,
        );
''',
)
write(path, source)

# Encounter generator UI: readable tabs and form-specific manual choices.
path = "lib/screens/tools/encounter_generator_screen.dart"
source = read(path)
source = replace_once(
    source,
    "import '../../models/pokemon.dart';\n",
    "import '../../models/pokemon.dart';\nimport '../../models/pokemon_form_choice.dart';\n",
    "encounter screen form helpers import",
)
source = replace_once(
    source,
    "  final Map<int, int> _manualQuantities = <int, int>{};\n",
    "  final Map<String, int> _manualQuantities = <String, int>{};\n",
    "manual quantity key type",
)
source = replace_once(
    source,
    r'''  List<Pokemon> get _manualCandidates {
    final query = _manualQuery.trim().toLowerCase();
    final filtered = _filteredCandidates;
    if (query.isEmpty) return filtered;
    return filtered
        .where(
          (pokemon) =>
              pokemon.name.toLowerCase().contains(query) ||
              pokemon.id.toString().contains(query),
        )
        .toList(growable: false);
  }
''',
    r'''  PokemonGeneratorFilters get _manualPokemonFilters =>
      PokemonGeneratorFilters(
        type: _filters.type,
        minSr: _filters.minSr,
        maxSr: _filters.maxSr,
        minGeneration: _filters.minGeneration,
        maxGeneration: _filters.maxGeneration,
        level: _filters.level,
        includeForms: _filters.includeForms,
        shinyChance: 0.01,
      );

  List<_ManualEncounterCandidate> get _manualCandidates {
    final query = _manualQuery.trim().toLowerCase();
    final candidates = <_ManualEncounterCandidate>[];
    for (final basePokemon in _filteredCandidates) {
      final forms = _pokemonGeneratorService.eligibleFormNames(
        basePokemon,
        _manualPokemonFilters,
      );
      for (final formName in forms) {
        final resolved = basePokemon.resolveVariant(formName: formName);
        final candidate = _ManualEncounterCandidate(
          basePokemon: basePokemon,
          pokemon: resolved,
          formName: formName,
        );
        if (query.isNotEmpty && !candidate.matches(query)) continue;
        candidates.add(candidate);
      }
    }
    return candidates;
  }
''',
    "manual form candidates getter",
)
source = replace_once(
    source,
    r'''      final encounter = _encounterService.generateManual(
        catalog: _catalog,
        quantities: _manualQuantities,
        party: _party,
        filters: _filters,
        targetDifficulty: _difficulty,
      );
''',
    r'''      final candidatesByKey = {
        for (final candidate in _manualCandidates) candidate.key: candidate,
      };
      final selections = <EncounterManualSelection>[
        for (final entry in _manualQuantities.entries)
          if (candidatesByKey[entry.key] case final candidate?)
            EncounterManualSelection(
              pokemonId: candidate.basePokemon.id,
              formName: candidate.formName,
              quantity: entry.value,
            ),
      ];
      final encounter = _encounterService.generateManual(
        catalog: _catalog,
        selections: selections,
        party: _party,
        filters: _filters,
        targetDifficulty: _difficulty,
      );
''',
    "manual encounter selections call",
)
source = replace_once(
    source,
    r'''  void _changeManualQuantity(int pokemonId, int delta) {
    setState(() {
      final next = (_manualQuantities[pokemonId] ?? 0) + delta;
      if (next <= 0) {
        _manualQuantities.remove(pokemonId);
      } else {
        _manualQuantities[pokemonId] = next.clamp(1, 12).toInt();
      }
      _error = null;
    });
  }
''',
    r'''  void _changeManualQuantity(String choiceKey, int delta) {
    setState(() {
      final next = (_manualQuantities[choiceKey] ?? 0) + delta;
      if (next <= 0) {
        _manualQuantities.remove(choiceKey);
      } else {
        _manualQuantities[choiceKey] = next.clamp(1, 12).toInt();
      }
      _error = null;
    });
  }
''',
    "manual quantity method",
)
source = replace_once(
    source,
    r'''  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
''',
    r'''  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tabForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? colors.onPrimary;
    return DefaultTabController(
''',
    "tab theme variables",
)
source = replace_once(
    source,
    r'''          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.auto_awesome), text: 'AUTOMATICO'),
              Tab(icon: Icon(Icons.tune), text: 'MANUALE'),
              Tab(icon: Icon(Icons.library_books_outlined), text: 'RACCOLTE'),
            ],
          ),
''',
    r'''          bottom: TabBar(
            isScrollable: true,
            labelColor: tabForeground,
            unselectedLabelColor: tabForeground.withValues(alpha: 0.72),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: tabForeground, width: 3),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(icon: Icon(Icons.auto_awesome), text: 'AUTOMATICO'),
              Tab(icon: Icon(Icons.tune), text: 'MANUALE'),
              Tab(icon: Icon(Icons.library_books_outlined), text: 'RACCOLTE'),
            ],
          ),
''',
    "readable encounter tabs",
)
source = replace_once(
    source,
    r'''    final selectedTotal = _manualQuantities.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
''',
    r'''    final visibleKeys = candidates.map((candidate) => candidate.key).toSet();
    final selectedTotal = _manualQuantities.entries
        .where((entry) => visibleKeys.contains(entry.key))
        .fold<int>(0, (sum, entry) => sum + entry.value);
''',
    "manual selected total",
)
source = replace_once(
    source,
    r'''          for (final pokemon in visible) ...[
            _ManualCandidateCard(
              pokemon: pokemon,
              quantity: _manualQuantities[pokemon.id] ?? 0,
              onDecrease: () => _changeManualQuantity(pokemon.id, -1),
              onIncrease: () => _changeManualQuantity(pokemon.id, 1),
            ),
''',
    r'''          for (final candidate in visible) ...[
            _ManualCandidateCard(
              candidate: candidate,
              quantity: _manualQuantities[candidate.key] ?? 0,
              onDecrease: () => _changeManualQuantity(candidate.key, -1),
              onIncrease: () => _changeManualQuantity(candidate.key, 1),
            ),
''',
    "manual candidate cards",
)
source = replace_once(
    source,
    r'''class _ManualCandidateCard extends StatelessWidget {
  const _ManualCandidateCard({
    required this.pokemon,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final Pokemon pokemon;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            PokemonAssetImage(pokemon: pokemon, size: 54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pokemon.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '#${pokemon.id.toString().padLeft(3, '0')} · SR ${pokemon.sr} · min. Lv ${pokemon.minLevelFound}',
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: quantity == 0 ? null : onDecrease,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: quantity >= 12 ? null : onIncrease,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
''',
    r'''class _ManualEncounterCandidate {
  const _ManualEncounterCandidate({
    required this.basePokemon,
    required this.pokemon,
    required this.formName,
  });

  final Pokemon basePokemon;
  final Pokemon pokemon;
  final String? formName;

  String get key => pokemonFormChoiceKey(
    pokemonId: basePokemon.id,
    speciesName: basePokemon.name,
    formName: formName,
  );

  String get displayName => pokemonFormDisplayName(basePokemon.name, formName);

  bool matches(String query) {
    return displayName.toLowerCase().contains(query) ||
        basePokemon.id.toString().contains(query) ||
        pokemon.types.any(
          (type) =>
              type.toLowerCase().contains(query) ||
              PokemonTypeLocalization.italianLabel(type)
                  .toLowerCase()
                  .contains(query),
        );
  }
}

class _ManualCandidateCard extends StatelessWidget {
  const _ManualCandidateCard({
    required this.candidate,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final _ManualEncounterCandidate candidate;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final pokemon = candidate.pokemon;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            PokemonAssetImage(
              pokemon: candidate.basePokemon,
              formName: candidate.formName,
              size: 54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${pokemonFormSubtitle(candidate.formName)} · '
                    'SR ${pokemon.sr} · min. Lv ${pokemon.minLevelFound}',
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: quantity == 0 ? null : onDecrease,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              onPressed: quantity >= 12 ? null : onIncrease,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
''',
    "manual form candidate widget",
)
source = replace_once(
    source,
    r'''                      if (pokemon != null)
                        PokemonAssetImage(pokemon: pokemon, size: 38),
                      if (pokemon != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(pokemon?.name ?? '#${entry.pokemonId}'),
                      ),
''',
    r'''                      if (pokemon != null)
                        PokemonAssetImage(
                          pokemon: pokemon,
                          formName: entry.formName,
                          size: 38,
                        ),
                      if (pokemon != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pokemon == null
                              ? '#${entry.pokemonId}'
                              : pokemonFormDisplayName(
                                  pokemon.name,
                                  entry.formName,
                                ),
                        ),
                      ),
''',
    "collection card exact form display",
)
write(path, source)

# Replace the collection editor with a form-aware implementation.
write(
    "lib/screens/tools/encounter_collection_editor_screen.dart",
    r'''import 'package:flutter/material.dart';

import '../../models/encounter_collection.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_choice.dart';
import '../../repositories/encounter_collection_repository.dart';
import '../../services/pokemon_generator_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

class EncounterCollectionEditorScreen extends StatefulWidget {
  const EncounterCollectionEditorScreen({
    super.key,
    required this.profileId,
    required this.catalog,
    this.collection,
  });

  final String profileId;
  final List<Pokemon> catalog;
  final EncounterCollection? collection;

  @override
  State<EncounterCollectionEditorScreen> createState() =>
      _EncounterCollectionEditorScreenState();
}

class _EncounterCollectionEditorScreenState
    extends State<EncounterCollectionEditorScreen> {
  final EncounterCollectionRepository _repository =
      EncounterCollectionRepository();
  final PokemonGeneratorService _generatorService =
      const PokemonGeneratorService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _weights = <String, int>{};

  bool _isSaving = false;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final collection = widget.collection;
    if (collection != null) {
      _nameController.text = collection.name;
      _notesController.text = collection.notes;
      for (final entry in collection.entries) {
        final pokemon = _pokemonById(entry.pokemonId);
        final key = pokemonFormChoiceKey(
          pokemonId: entry.pokemonId,
          speciesName: pokemon?.name ?? '#${entry.pokemonId}',
          formName: entry.formName,
        );
        _weights[key] = entry.weight;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _total => _weights.values.fold(0, (sum, value) => sum + value);

  PokemonGeneratorFilters get _formFilters => const PokemonGeneratorFilters(
    minSr: 0,
    maxSr: 100,
    minGeneration: 1,
    maxGeneration: 9,
    level: 0,
    includeForms: true,
  );

  List<_CollectionFormChoice> get _allChoices {
    final choices = <_CollectionFormChoice>[];
    for (final basePokemon in widget.catalog) {
      final forms = _generatorService.eligibleFormNames(
        basePokemon,
        _formFilters,
      );
      for (final formName in forms) {
        choices.add(
          _CollectionFormChoice(
            basePokemon: basePokemon,
            pokemon: basePokemon.resolveVariant(formName: formName),
            formName: formName,
          ),
        );
      }
    }
    return choices;
  }

  List<_CollectionFormChoice> get _searchResults {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _allChoices
        .where(
          (choice) =>
              !_weights.containsKey(choice.key) && choice.matches(query),
        )
        .take(30)
        .toList(growable: false);
  }

  Pokemon? _pokemonById(int id) {
    for (final pokemon in widget.catalog) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  void _addChoice(_CollectionFormChoice choice) {
    setState(() {
      _weights[choice.key] = 1;
      _query = '';
      _searchController.clear();
      _error = null;
    });
  }

  void _removeChoice(String key) {
    setState(() {
      _weights.remove(key);
      _error = null;
    });
  }

  void _setWeight(String key, String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return;
    setState(() {
      _weights[key] = parsed.clamp(1, 100).toInt();
      _error = null;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Inserisci un nome per la raccolta.');
      return;
    }
    if (_weights.isEmpty) {
      setState(() => _error = 'Aggiungi almeno un Pokémon.');
      return;
    }
    if (_total != 100) {
      setState(() {
        _error = _total < 100
            ? 'Il totale è $_total%: mancano ${100 - _total}%.'
            : 'Il totale è $_total%: supera il 100% di ${_total - 100}%.';
      });
      return;
    }

    final choicesByKey = {for (final choice in _allChoices) choice.key: choice};
    final entries = <EncounterCollectionEntry>[];
    for (final entry in _weights.entries) {
      final choice = choicesByKey[entry.key];
      if (choice == null) continue;
      entries.add(
        EncounterCollectionEntry(
          pokemonId: choice.basePokemon.id,
          formName: choice.formName,
          weight: entry.value,
        ),
      );
    }
    if (entries.length != _weights.length) {
      setState(() {
        _error =
            'Una forma selezionata non è più disponibile nel catalogo. Rimuovila e aggiungila di nuovo.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final existing = widget.collection;
      final collection = EncounterCollection(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        notes: _notesController.text.trim(),
        updatedAt: DateTime.now(),
        entries: entries..sort((a, b) => b.weight.compareTo(a.weight)),
      );
      await _repository.saveCollection(
        profileId: widget.profileId,
        collection: collection,
      );
      if (!mounted) return;
      Navigator.of(context).pop(collection);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final choicesByKey = {for (final choice in _allChoices) choice.key: choice};
    final selectedKeys = _weights.keys.toList()
      ..sort((a, b) {
        final weightCompare = (_weights[b] ?? 0).compareTo(_weights[a] ?? 0);
        return weightCompare != 0 ? weightCompare : a.compareTo(b);
      });
    final totalColor = _total == 100
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(
          widget.collection == null ? 'Nuova raccolta' : 'Modifica raccolta',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome raccolta',
              hintText: 'Es. Percorso 24',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note facoltative',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'AGGIUNGI POKÉMON O FORMA',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'La forma base e ogni forma permanente sono selezionabili separatamente.',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Nome, forma o numero',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: (_searchResults.length * 68.0)
                          .clamp(68.0, 300.0)
                          .toDouble(),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final choice = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: PokemonAssetImage(
                              pokemon: choice.basePokemon,
                              formName: choice.formName,
                              size: 46,
                            ),
                            title: Text(choice.displayName),
                            subtitle: Text(
                              '${pokemonFormSubtitle(choice.formName)} · '
                              '#${choice.basePokemon.id.toString().padLeft(3, '0')}',
                            ),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => _addChoice(choice),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'PROBABILITÀ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Totale: $_total%',
                style: TextStyle(
                  color: totalColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedKeys.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Cerca e aggiungi i Pokémon o le forme che possono apparire in questa raccolta.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final key in selectedKeys) ...[
              Builder(
                builder: (context) {
                  final choice = choicesByKey[key];
                  if (choice == null) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        children: [
                          PokemonAssetImage(
                            pokemon: choice.basePokemon,
                            formName: choice.formName,
                            size: 52,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  choice.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(pokemonFormSubtitle(choice.formName)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 82,
                            child: TextFormField(
                              key: ValueKey('$key-${_weights[key]}'),
                              initialValue: '${_weights[key]}',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                suffixText: '%',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) => _setWeight(key, value),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeChoice(key),
                            tooltip: 'Rimuovi',
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
            ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'SALVATAGGIO...' : 'SALVA RACCOLTA'),
          ),
          const SizedBox(height: 6),
          const Text(
            'La generazione è disponibile solo quando il totale è esattamente 100%.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CollectionFormChoice {
  const _CollectionFormChoice({
    required this.basePokemon,
    required this.pokemon,
    required this.formName,
  });

  final Pokemon basePokemon;
  final Pokemon pokemon;
  final String? formName;

  String get key => pokemonFormChoiceKey(
    pokemonId: basePokemon.id,
    speciesName: basePokemon.name,
    formName: formName,
  );

  String get displayName => pokemonFormDisplayName(basePokemon.name, formName);

  bool matches(String query) {
    return displayName.toLowerCase().contains(query) ||
        basePokemon.id.toString().contains(query) ||
        pokemon.types.any((type) => type.toLowerCase().contains(query));
  }
}
''',
)

# Update encounter tests for the new API and exact forms.
path = "test/encounter_generator_service_test.dart"
source = read(path)
source = replace_once(
    source,
    r'''      quantities: const {19: 2, 16: 1},
''',
    r'''      selections: const [
        EncounterManualSelection(pokemonId: 19, quantity: 2),
        EncounterManualSelection(pokemonId: 16, quantity: 1),
      ],
''',
    "test manual selection API",
)
source = replace_once(
    source,
    r'''  test('a 100 percent collection always selects its only species', () {
''',
    r'''  test('manual generation preserves the selected permanent form', () {
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final alolan = PokemonFormDefinition(
      key: 'Alolan',
      displayName: 'Alolan',
      pokemon: rattata.copyWith(types: const ['Dark', 'Normal']),
    );
    final formCatalog = [
      rattata.copyWith(formDefinitions: [alolan]),
      ...catalog.where((pokemon) => pokemon.id != 19),
    ];

    final encounter = service.generateManual(
      catalog: formCatalog,
      selections: const [
        EncounterManualSelection(
          pokemonId: 19,
          formName: 'Alolan',
          quantity: 2,
        ),
      ],
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 3),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(8),
    );

    expect(encounter, isNotNull);
    expect(encounter!.members, hasLength(2));
    expect(
      encounter.members.every((member) => member.pokemon.formName == 'Alolan'),
      isTrue,
    );
    expect(
      encounter.members.every(
        (member) => member.pokemon.pokemon.types.contains('Dark'),
      ),
      isTrue,
    );
  });

  test('a 100 percent collection always selects its only species', () {
''',
    "manual form test",
)
source = replace_once(
    source,
    r'''  test('collection generation without duplicates returns unique species', () {
''',
    r'''  test('weighted collections preserve an explicitly selected form', () {
    final rattata = catalog.firstWhere((pokemon) => pokemon.id == 19);
    final alolan = PokemonFormDefinition(
      key: 'Alolan',
      displayName: 'Alolan',
      pokemon: rattata.copyWith(types: const ['Dark', 'Normal']),
    );
    final formCatalog = [
      rattata.copyWith(formDefinitions: [alolan]),
      ...catalog.where((pokemon) => pokemon.id != 19),
    ];

    final encounter = service.generateFromCollection(
      catalog: formCatalog,
      collection: EncounterCollection(
        id: 'alola-route',
        name: 'Percorso Alola',
        entries: const [
          EncounterCollectionEntry(
            pokemonId: 19,
            formName: 'Alolan',
            weight: 100,
          ),
        ],
        updatedAt: DateTime(2026),
      ),
      count: 3,
      allowDuplicates: true,
      party: const EncounterPartyProfile(),
      filters: const EncounterGeneratorFilters(level: 4),
      targetDifficulty: EncounterDifficulty.medium,
      random: Random(11),
    );

    expect(encounter, isNotNull);
    expect(
      encounter!.members.every(
        (member) => member.pokemon.formName == 'Alolan',
      ),
      isTrue,
    );
  });

  test('collection generation without duplicates returns unique species', () {
''',
    "collection form test",
)
write(path, source)
