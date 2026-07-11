import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../repositories/pokemon_repository.dart';
import '../../services/pokedex_form_catalog.dart';
import '../../services/pokedex_ownership_service.dart';
import '../../services/profile_storage_service.dart';
import '../../widgets/pokedex/pokemon_summary_dialog.dart';
import '../../widgets/pokedex/pokemon_tile.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';

enum MarkMode { none, seen, unseen, caught }

enum ViewFilter { all, seen, unseen, caught }

enum SortMode { numberAsc, numberDesc, nameAsc, nameDesc }

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokemonRepository _repository = PokemonRepository();
  final ProfileStorageService _profileStorageService = ProfileStorageService();
  final PokedexOwnershipService _ownershipService = PokedexOwnershipService();
  final TextEditingController _searchController = TextEditingController();

  final Map<int, PokedexEntry> _entries = {};
  final Map<int, PokemonFlavor> _pokemonFlavors = {};
  final Set<String> _selectedTypes = {};

  MarkMode _markMode = MarkMode.none;
  ViewFilter _viewFilter = ViewFilter.all;
  SortMode _sortMode = SortMode.numberAsc;
  List<Pokemon> _allPokemon = [];
  List<Pokemon> _filteredPokemon = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedRegion;

  static const Map<String, List<int>> _regions = {
    'Kanto': [1, 151],
    'Johto': [152, 251],
    'Hoenn': [252, 386],
    'Sinnoh': [387, 493],
    'Unova': [494, 649],
    'Kalos': [650, 721],
    'Alola': [722, 809],
    'Galar': [810, 898],
    'Hisui': [899, 905],
    'Paldea': [906, 1025],
    'Altri': [1026, 9999],
  };

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final profile = await _profileStorageService.getDefaultProfile();
      await _ownershipService.syncOwnedCollection(profile.id);
      final results = await Future.wait([
        _repository.getAllPokemon(),
        _repository.getPokemonFlavors(),
        _profileStorageService.loadPokedexEntries(),
      ]);
      final pokemon = results[0] as List<Pokemon>;
      final flavors = results[1] as Map<int, PokemonFlavor>;
      final entries = results[2] as Map<int, PokedexEntry>;

      if (!mounted) return;
      setState(() {
        _allPokemon = pokemon;
        _pokemonFlavors
          ..clear()
          ..addAll(flavors);
        _entries
          ..clear()
          ..addAll(entries);
        _applyFilters();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  PokedexEntry _entryFor(Pokemon pokemon) {
    return _entries[pokemon.id] ?? PokedexEntry.empty(pokemon.id);
  }

  PokedexFormOption _previewFormFor(Pokemon pokemon) {
    return PokedexFormCatalog.preferredFor(pokemon, _entryFor(pokemon));
  }

  Future<void> _saveEntry(PokedexEntry entry) async {
    _entries[entry.pokemonId] = entry;
    await _profileStorageService.savePokedexEntries(_entries);
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    final selectedRegion = _selectedRegion;

    _filteredPokemon = _allPokemon.where((pokemon) {
      final entry = _entryFor(pokemon);
      final matchesSearch = query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
      final matchesView = switch (_viewFilter) {
        ViewFilter.all => true,
        ViewFilter.seen => entry.seen,
        ViewFilter.unseen => !entry.seen,
        ViewFilter.caught => entry.caught,
      };
      final localizedTypes = pokemon.types
          .map(PokemonAssetPaths.localizedTypeLabel)
          .toSet();
      final matchesTypes = _selectedTypes.isEmpty ||
          _selectedTypes.every(localizedTypes.contains);
      final matchesRegion = selectedRegion == null ||
          _regionForPokemon(pokemon) == selectedRegion;

      return matchesSearch && matchesView && matchesTypes && matchesRegion;
    }).toList(growable: false);

    _filteredPokemon.sort((a, b) {
      return switch (_sortMode) {
        SortMode.numberAsc => a.id.compareTo(b.id),
        SortMode.numberDesc => b.id.compareTo(a.id),
        SortMode.nameAsc =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        SortMode.nameDesc =>
          b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      };
    });
  }

  Future<void> _openPokemonDialog(Pokemon pokemon) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PokemonSummaryDialog(
        pokemon: pokemon,
        flavor: _pokemonFlavors[pokemon.id],
        entry: _entryFor(pokemon),
        onEntryChanged: (entry) async {
          if (mounted) {
            setState(() {
              _entries[pokemon.id] = entry;
              _applyFilters();
            });
          }
          await _saveEntry(entry);
        },
      ),
    );
  }

  Future<void> _handlePokemonTap(Pokemon pokemon) async {
    if (_markMode == MarkMode.none) {
      await _openPokemonDialog(pokemon);
      return;
    }

    final entry = _entryFor(pokemon);
    final preview = _previewFormFor(pokemon);
    final status = preview.statusFor(entry);
    late final PokedexEntry updated;

    switch (_markMode) {
      case MarkMode.seen:
        updated = entry.withFormStatus(
          formKey: preview.key,
          formName: preview.name,
          seen: true,
          caught: status.caught,
        );
        break;
      case MarkMode.unseen:
        updated = entry.clearAllForms();
        break;
      case MarkMode.caught:
        updated = entry.withFormStatus(
          formKey: preview.key,
          formName: preview.name,
          seen: true,
          caught: true,
        );
        break;
      case MarkMode.none:
        return;
    }

    if (!mounted) return;
    setState(() {
      _entries[pokemon.id] = updated;
      _applyFilters();
    });
    await _saveEntry(updated);
  }

  List<String> get _availableTypes {
    final result = <String>{};
    for (final pokemon in _allPokemon) {
      result.addAll(pokemon.types.map(PokemonAssetPaths.localizedTypeLabel));
      for (final form in PokedexFormCatalog.optionsFor(pokemon)) {
        result.addAll(
          form.pokemon.types.map(PokemonAssetPaths.localizedTypeLabel),
        );
      }
    }
    return result.toList()..sort();
  }

  String? _regionForPokemon(Pokemon pokemon) {
    for (final entry in _regions.entries) {
      if (pokemon.id >= entry.value.first && pokemon.id <= entry.value.last) {
        return entry.key;
      }
    }
    return null;
  }

  List<String> get _visibleRegions {
    return _regions.keys
        .where((region) => _pokemonForRegion(region).isNotEmpty)
        .toList(growable: false);
  }

  List<Pokemon> _pokemonForRegion(String region) {
    final range = _regions[region];
    if (range == null) return const [];
    return _filteredPokemon
        .where(
          (pokemon) =>
              pokemon.id >= range.first && pokemon.id <= range.last,
        )
        .toList(growable: false);
  }

  bool get _usesRegionSections {
    return _sortMode == SortMode.numberAsc || _sortMode == SortMode.numberDesc;
  }

  List<String> get _visibleSections {
    if (!_usesRegionSections) {
      return _filteredPokemon.isEmpty ? const [] : const ['Risultati'];
    }
    return _visibleRegions;
  }

  List<Pokemon> _pokemonForSection(String section) {
    return _usesRegionSections ? _pokemonForRegion(section) : _filteredPokemon;
  }

  int _gridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return 7;
    if (width >= 800) return 6;
    if (width >= 600) return 5;
    if (width >= 430) return 4;
    return 3;
  }

  Map<String, int> _regionProgress(String region, bool caught) {
    final range = _regions[region]!;
    final regionPokemon = _allPokemon.where(
      (pokemon) => pokemon.id >= range.first && pokemon.id <= range.last,
    );
    final count = regionPokemon.where((pokemon) {
      final entry = _entryFor(pokemon);
      return caught ? entry.caught : entry.seen;
    }).length;
    return {'count': count, 'total': regionPokemon.length};
  }

  Future<void> _pickTypeFilters() async {
    final working = Set<String>.from(_selectedTypes);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filtra per tipo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type in _availableTypes)
                            FilterChip(
                              label: Text(type),
                              selected: working.contains(type),
                              onSelected: (selected) {
                                setSheetState(() {
                                  if (selected) {
                                    working.add(type);
                                  } else {
                                    working.remove(type);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(<String>{}),
                        child: const Text('Azzera'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(working),
                        child: const Text('Applica'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedTypes
        ..clear()
        ..addAll(result);
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Errore: $_errorMessage'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadPokemon,
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(_applyFilters),
                            decoration: const InputDecoration(
                              hintText: 'Cerca Pokémon...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              DropdownButton<SortMode>(
                                value: _sortMode,
                                items: const [
                                  DropdownMenuItem(
                                    value: SortMode.numberAsc,
                                    child: Text('Numero crescente'),
                                  ),
                                  DropdownMenuItem(
                                    value: SortMode.numberDesc,
                                    child: Text('Numero decrescente'),
                                  ),
                                  DropdownMenuItem(
                                    value: SortMode.nameAsc,
                                    child: Text('Nome A-Z'),
                                  ),
                                  DropdownMenuItem(
                                    value: SortMode.nameDesc,
                                    child: Text('Nome Z-A'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _sortMode = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Regione',
                                onSelected: (value) {
                                  setState(() {
                                    _selectedRegion =
                                        value == '__all__' ? null : value;
                                    _applyFilters();
                                  });
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: '__all__',
                                    child: Text('Tutte le regioni'),
                                  ),
                                  for (final region in _regions.keys)
                                    PopupMenuItem(
                                      value: region,
                                      child: Text(region),
                                    ),
                                ],
                                child: Chip(
                                  avatar: const Icon(Icons.public, size: 18),
                                  label: Text(_selectedRegion ?? 'Regione'),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.filter_alt, size: 18),
                                label: Text(
                                  _selectedTypes.isEmpty
                                      ? 'Tipi'
                                      : 'Tipi (${_selectedTypes.length})',
                                ),
                                onPressed: _pickTypeFilters,
                              ),
                              Chip(
                                label: Text('${_filteredPokemon.length} risultati'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _FilterChips<ViewFilter>(
                            values: ViewFilter.values,
                            selected: _viewFilter,
                            label: _viewFilterLabel,
                            onSelected: (value) {
                              setState(() {
                                _viewFilter = value;
                                _applyFilters();
                              });
                            },
                          ),
                          const SizedBox(height: 6),
                          _FilterChips<MarkMode>(
                            values: MarkMode.values,
                            selected: _markMode,
                            label: _markModeLabel,
                            onSelected: (value) =>
                                setState(() => _markMode = value),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPokemon,
                        child: _visibleSections.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 160),
                                  Center(child: Text('Nessun Pokémon trovato.')),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _visibleSections.length,
                                itemBuilder: (context, index) {
                                  final section = _visibleSections[index];
                                  return _RegionSection(
                                    region: section,
                                    pokemon: _pokemonForSection(section),
                                    columns: _gridColumnCount(context),
                                    entryFor: _entryFor,
                                    formFor: _previewFormFor,
                                    onPokemonTap: _handlePokemonTap,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _viewFilterLabel(ViewFilter value) {
    return switch (value) {
      ViewFilter.all => 'Tutti',
      ViewFilter.seen => 'Visti',
      ViewFilter.unseen => 'Non visti',
      ViewFilter.caught => 'Catturati',
    };
  }

  String _markModeLabel(MarkMode value) {
    return switch (value) {
      MarkMode.none => 'Apri',
      MarkMode.seen => 'Segna visto',
      MarkMode.unseen => 'Azzera',
      MarkMode.caught => 'Segna catturato',
    };
  }
}

class _RegionSection extends StatelessWidget {
  const _RegionSection({
    required this.region,
    required this.pokemon,
    required this.columns,
    required this.entryFor,
    required this.formFor,
    required this.onPokemonTap,
  });

  final String region;
  final List<Pokemon> pokemon;
  final int columns;
  final PokedexEntry Function(Pokemon pokemon) entryFor;
  final PokedexFormOption Function(Pokemon pokemon) formFor;
  final ValueChanged<Pokemon> onPokemonTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${region.toUpperCase()} · ${pokemon.length}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pokemon.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final current = pokemon[index];
              return PokemonTile(
                pokemon: current,
                entry: entryFor(current),
                form: formFor(current),
                onTap: () => onPokemonTap(current),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChips<T> extends StatelessWidget {
  const _FilterChips({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final value = values[index];
          return ChoiceChip(
            label: Text(label(value)),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }
}
