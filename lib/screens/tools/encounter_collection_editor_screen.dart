import 'package:flutter/material.dart';

import '../../models/encounter_collection.dart';
import '../../models/pokemon.dart';
import '../../repositories/encounter_collection_repository.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _weights = <int, int>{};

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
        _weights[entry.pokemonId] = entry.weight;
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

  List<Pokemon> get _searchResults {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.catalog
        .where(
          (pokemon) =>
              !_weights.containsKey(pokemon.id) &&
              (pokemon.name.toLowerCase().contains(query) ||
                  pokemon.id.toString().contains(query)),
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

  void _addPokemon(Pokemon pokemon) {
    setState(() {
      _weights[pokemon.id] = 1;
      _query = '';
      _searchController.clear();
      _error = null;
    });
  }

  void _removePokemon(int pokemonId) {
    setState(() {
      _weights.remove(pokemonId);
      _error = null;
    });
  }

  void _setWeight(int pokemonId, String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return;
    setState(() {
      _weights[pokemonId] = parsed.clamp(1, 100).toInt();
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
        entries: [
          for (final entry in _weights.entries)
            EncounterCollectionEntry(pokemonId: entry.key, weight: entry.value),
        ]..sort((a, b) => b.weight.compareTo(a.weight)),
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
    final selectedIds = _weights.keys.toList()
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
                    'AGGIUNGI POKÉMON',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Nome o numero',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: (_searchResults.length * 64.0)
                          .clamp(64.0, 260.0)
                          .toDouble(),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final pokemon = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: PokemonAssetImage(
                              pokemon: pokemon,
                              size: 46,
                            ),
                            title: Text(pokemon.name),
                            subtitle: Text(
                              '#${pokemon.id.toString().padLeft(3, '0')}',
                            ),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () => _addPokemon(pokemon),
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
          if (selectedIds.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Cerca e aggiungi i Pokémon che possono apparire in questa raccolta.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final pokemonId in selectedIds) ...[
              Builder(
                builder: (context) {
                  final pokemon = _pokemonById(pokemonId);
                  if (pokemon == null) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        children: [
                          PokemonAssetImage(pokemon: pokemon, size: 52),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pokemon.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '#${pokemon.id.toString().padLeft(3, '0')}',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 82,
                            child: TextFormField(
                              key: ValueKey(
                                '$pokemonId-${_weights[pokemonId]}',
                              ),
                              initialValue: '${_weights[pokemonId]}',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                suffixText: '%',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) =>
                                  _setWeight(pokemonId, value),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removePokemon(pokemonId),
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
