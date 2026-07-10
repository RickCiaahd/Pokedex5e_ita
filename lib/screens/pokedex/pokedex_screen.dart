import 'package:flutter/material.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../repositories/pokemon_repository.dart';
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
  final TextEditingController _searchController = TextEditingController();

  final Map<int, PokedexEntry> _entries = {};
  final Map<int, PokemonFlavor> _pokemonFlavors = {};

  MarkMode _markMode = MarkMode.none;
  ViewFilter _viewFilter = ViewFilter.all;
  SortMode _sortMode = SortMode.numberAsc;
  final Set<String> _selectedTypes = {};

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
    try {
      final pokemon = await _repository.getAllPokemon();
      final flavors = await _repository.getPokemonFlavors();
      await _loadEntries();

      if (!mounted) return;
      setState(() {
        _allPokemon = pokemon;
        _pokemonFlavors
          ..clear()
          ..addAll(flavors);
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

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    final selectedRegion = _selectedRegion;

    _filteredPokemon = _allPokemon.where((pokemon) {
      final matchesSearch = query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));

      final entry = _entryFor(pokemon);
      final matchesFilter = switch (_viewFilter) {
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

      return matchesSearch && matchesFilter && matchesTypes && matchesRegion;
    }).toList(growable: false);

    _filteredPokemon.sort((a, b) {
      return switch (_sortMode) {
        SortMode.numberAsc => a.id.compareTo(b.id),
        SortMode.numberDesc => b.id.compareTo(a.id),
        SortMode.nameAsc => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
        SortMode.nameDesc => b.name.toLowerCase().compareTo(
              a.name.toLowerCase(),
            ),
      };
    });
  }

  void _onSearchChanged(String _) {
    setState(_applyFilters);
  }

  void _setRegionFilter(String? region) {
    setState(() {
      _selectedRegion = region;
      _applyFilters();
    });
  }

  List<String> get _visibleRegions {
    return _regions.keys.where((region) {
      return _pokemonForRegion(region).isNotEmpty;
    }).toList(growable: false);
  }

  List<String> get _availableTypes {
    final types = <String>{};
    for (final pokemon in _allPokemon) {
      types.addAll(pokemon.types.map(PokemonAssetPaths.localizedTypeLabel));
    }
    return types.toList()..sort((a, b) => a.compareTo(b));
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
    if (!_usesRegionSections) return _filteredPokemon;
    return _pokemonForRegion(section);
  }

  List<Pokemon> _pokemonForRegion(String region) {
    final range = _regions[region];
    if (range == null) return const [];

    return _filteredPokemon.where((pokemon) {
      return pokemon.id >= range.first && pokemon.id <= range.last;
    }).toList(growable: false);
  }

  String? _regionForPokemon(Pokemon pokemon) {
    for (final entry in _regions.entries) {
      final range = entry.value;
      if (pokemon.id >= range.first && pokemon.id <= range.last) {
        return entry.key;
      }
    }
    return null;
  }

  int _gridColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 6;
    if (width >= 700) return 5;
    if (width >= 500) return 4;
    return 3;
  }

  void _openPokemonDialog(Pokemon pokemon) {
    showDialog(
      context: context,
      builder: (_) => PokemonSummaryDialog(
        pokemon: pokemon,
        flavor: _pokemonFlavors[pokemon.id],
        entry: _entryFor(pokemon),
        onToggleSeen: () => _toggleSeen(pokemon),
        onToggleCaught: () => _toggleCaught(pokemon),
      ),
    );
  }

  void _setTypeFilters(Set<String> types) {
    setState(() {
      _selectedTypes
        ..clear()
        ..addAll(types);
      _applyFilters();
    });
  }

  void _clearTypeFilters() {
    setState(() {
      _selectedTypes.clear();
      _applyFilters();
    });
  }

  Future<void> _loadEntries() async {
    final entries = await _profileStorageService.loadPokedexEntries();
    _entries
      ..clear()
      ..addAll(entries);
  }

  Future<void> _saveEntries() async {
    try {
      await _profileStorageService.savePokedexEntries(_entries);
    } catch (error, stackTrace) {
      debugPrint('POKEDEX SCREEN: errore save: $error');
      debugPrint(stackTrace.toString());
    }
  }

  PokedexEntry _entryFor(Pokemon pokemon) {
    return _entries[pokemon.id] ?? PokedexEntry(pokemonId: pokemon.id);
  }

  Future<void> _toggleSeen(Pokemon pokemon) async {
    final entry = _entryFor(pokemon);

    setState(() {
      _entries[pokemon.id] = entry.copyWith(
        seen: !entry.seen,
        caught: entry.seen ? false : entry.caught,
      );
    });

    await _saveEntries();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _toggleCaught(Pokemon pokemon) async {
    final entry = _entryFor(pokemon);

    setState(() {
      _entries[pokemon.id] = entry.copyWith(seen: true, caught: !entry.caught);
    });

    await _saveEntries();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Map<String, int> _regionProgress(String region, bool caught) {
    final range = _regions[region]!;
    final regionPokemon = _allPokemon.where((pokemon) {
      return pokemon.id >= range.first && pokemon.id <= range.last;
    }).toList(growable: false);

    final count = regionPokemon.where((pokemon) {
      final entry = _entryFor(pokemon);
      return caught ? entry.caught : entry.seen;
    }).length;

    return {'count': count, 'total': regionPokemon.length};
  }

  Future<void> _handlePokemonTap(Pokemon pokemon) async {
    if (_markMode == MarkMode.none) {
      _openPokemonDialog(pokemon);
      return;
    }

    final entry = _entryFor(pokemon);
    setState(() {
      switch (_markMode) {
        case MarkMode.seen:
          _entries[pokemon.id] = entry.copyWith(seen: true);
          break;
        case MarkMode.unseen:
          _entries[pokemon.id] = entry.copyWith(seen: false, caught: false);
          break;
        case MarkMode.caught:
          _entries[pokemon.id] = entry.copyWith(seen: true, caught: true);
          break;
        case MarkMode.none:
          break;
      }
    });

    await _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(child: Text('Errore: $_errorMessage'));
    } else {
      content = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Cerca Pokémon...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SortModeSelector(
                        sortMode: _sortMode,
                        onChanged: (sortMode) {
                          setState(() {
                            _sortMode = sortMode;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ResultCounter(count: _filteredPokemon.length),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RegionFilterSelector(
                        regions: _visibleRegions,
                        selectedRegion: _selectedRegion,
                        progressBuilder: _regionProgress,
                        onChanged: _setRegionFilter,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeFilterSelector(
                        types: _availableTypes,
                        selectedTypes: _selectedTypes,
                        onChanged: _setTypeFilters,
                        onClear: _clearTypeFilters,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _ViewFilterSelector(
            selectedFilter: _viewFilter,
            onChanged: (filter) {
              setState(() {
                _viewFilter = filter;
                _applyFilters();
              });
            },
          ),
          _MarkModeSelector(
            selectedMode: _markMode,
            onChanged: (mode) => setState(() => _markMode = mode),
          ),
          Expanded(
            child: _visibleSections.isEmpty
                ? const Center(child: Text('Nessun Pokémon trovato.'))
                : ListView.builder(
                    itemCount: _visibleSections.length,
                    itemBuilder: (context, index) {
                      final section = _visibleSections[index];
                      final pokemonList = _pokemonForSection(section);

                      return _RegionSection(
                        region: section,
                        pokemon: pokemonList,
                        columns: _gridColumnCount(context),
                        entryFor: _entryFor,
                        onPokemonTap: _handlePokemonTap,
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: content,
    );
  }
}

class _RegionSection extends StatelessWidget {
  const _RegionSection({
    required this.region,
    required this.pokemon,
    required this.columns,
    required this.entryFor,
    required this.onPokemonTap,
  });

  final String region;
  final List<Pokemon> pokemon;
  final int columns;
  final PokedexEntry Function(Pokemon pokemon) entryFor;
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
                  color: Theme.of(context).colorScheme.onSurface,
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
              final currentPokemon = pokemon[index];
              return PokemonTile(
                pokemon: currentPokemon,
                entry: entryFor(currentPokemon),
                onTap: () => onPokemonTap(currentPokemon),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RegionFilterSelector extends StatelessWidget {
  const _RegionFilterSelector({
    required this.regions,
    required this.selectedRegion,
    required this.progressBuilder,
    required this.onChanged,
  });

  final List<String> regions;
  final String? selectedRegion;
  final Map<String, int> Function(String region, bool caught) progressBuilder;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final region = selectedRegion;
    final seen = region == null ? null : progressBuilder(region, false);
    final caught = region == null ? null : progressBuilder(region, true);
    final subtitle = region == null
        ? 'Tutte le regioni'
        : 'Visti ${seen!['count']}/${seen['total']} · Presi ${caught!['count']}/${caught['total']}';

    return OutlinedButton.icon(
      icon: const Icon(Icons.public),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(region ?? 'Regione'),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      onPressed: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (_) => _RegionFilterDialog(
            regions: regions,
            selectedRegion: region,
            progressBuilder: progressBuilder,
          ),
        );

        if (result == null || result == _RegionFilterDialog.cancelValue) return;
        onChanged(result == _RegionFilterDialog.allValue ? null : result);
      },
    );
  }
}

class _RegionFilterDialog extends StatefulWidget {
  const _RegionFilterDialog({
    required this.regions,
    required this.selectedRegion,
    required this.progressBuilder,
  });

  static const cancelValue = '__cancel__';
  static const allValue = '__all__';

  final List<String> regions;
  final String? selectedRegion;
  final Map<String, int> Function(String region, bool caught) progressBuilder;

  @override
  State<_RegionFilterDialog> createState() => _RegionFilterDialogState();
}

class _RegionFilterDialogState extends State<_RegionFilterDialog> {
  late String _selectedRegion = widget.selectedRegion ?? _RegionFilterDialog.allValue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtra per regione'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            _RegionOptionTile(
              title: 'Tutte',
              selected: _selectedRegion == _RegionFilterDialog.allValue,
              onTap: () => setState(
                () => _selectedRegion = _RegionFilterDialog.allValue,
              ),
            ),
            for (final region in widget.regions)
              _RegionOptionTile(
                title: region,
                selected: _selectedRegion == region,
                subtitle: _RegionProgressText(
                  seen: widget.progressBuilder(region, false),
                  caught: widget.progressBuilder(region, true),
                ),
                onTap: () => setState(() => _selectedRegion = region),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_RegionFilterDialog.cancelValue),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_RegionFilterDialog.allValue),
          child: const Text('Tutte'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedRegion),
          child: const Text('Applica'),
        ),
      ],
    );
  }
}

class _RegionOptionTile extends StatelessWidget {
  const _RegionOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(title),
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _RegionProgressText extends StatelessWidget {
  const _RegionProgressText({required this.seen, required this.caught});

  final Map<String, int> seen;
  final Map<String, int> caught;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Visti ${seen['count']}/${seen['total']} · Presi ${caught['count']}/${caught['total']}',
    );
  }
}

class _SortModeSelector extends StatelessWidget {
  const _SortModeSelector({required this.sortMode, required this.onChanged});

  final SortMode sortMode;
  final ValueChanged<SortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SortMode>(
      initialValue: sortMode,
      decoration: const InputDecoration(
        labelText: 'Ordina',
        prefixIcon: Icon(Icons.sort),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: SortMode.numberAsc,
          child: Text('Numero crescente'),
        ),
        DropdownMenuItem(
          value: SortMode.numberDesc,
          child: Text('Numero decrescente'),
        ),
        DropdownMenuItem(value: SortMode.nameAsc, child: Text('Nome A-Z')),
        DropdownMenuItem(value: SortMode.nameDesc, child: Text('Nome Z-A')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ResultCounter extends StatelessWidget {
  const _ResultCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _TypeFilterSelector extends StatelessWidget {
  const _TypeFilterSelector({
    required this.types,
    required this.selectedTypes,
    required this.onChanged,
    required this.onClear,
  });

  final List<String> types;
  final Set<String> selectedTypes;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) return const SizedBox.shrink();

    final label = selectedTypes.isEmpty ? 'Tipi' : 'Tipi (${selectedTypes.length})';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.category),
            label: Text(label),
            onPressed: () async {
              final result = await showDialog<Set<String>>(
                context: context,
                builder: (_) => _TypeFilterDialog(
                  types: types,
                  selectedTypes: selectedTypes,
                ),
              );

              if (result != null) onChanged(result);
            },
          ),
        ),
        if (selectedTypes.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Cancella tipi',
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
        ],
      ],
    );
  }
}

class _TypeFilterDialog extends StatefulWidget {
  const _TypeFilterDialog({required this.types, required this.selectedTypes});

  final List<String> types;
  final Set<String> selectedTypes;

  @override
  State<_TypeFilterDialog> createState() => _TypeFilterDialogState();
}

class _TypeFilterDialogState extends State<_TypeFilterDialog> {
  late final Set<String> _selectedTypes = {...widget.selectedTypes};

  void _toggle(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtra per tipo'),
      content: SizedBox(
        width: double.maxFinite,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in widget.types)
              _TypeFilterBadgeButton(
                type: type,
                selected: _selectedTypes.contains(type),
                onTap: () => _toggle(type),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(<String>{}),
          child: const Text('Cancella'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedTypes),
          child: const Text('Applica'),
        ),
      ],
    );
  }
}

class _TypeFilterBadgeButton extends StatelessWidget {
  const _TypeFilterBadgeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokemonTypeBadge(type: type, height: 22),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewFilterSelector extends StatelessWidget {
  const _ViewFilterSelector({
    required this.selectedFilter,
    required this.onChanged,
  });

  final ViewFilter selectedFilter;
  final ValueChanged<ViewFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Tutti'),
            selected: selectedFilter == ViewFilter.all,
            onSelected: (_) => onChanged(ViewFilter.all),
          ),
          ChoiceChip(
            label: const Text('Visti'),
            selected: selectedFilter == ViewFilter.seen,
            onSelected: (_) => onChanged(ViewFilter.seen),
          ),
          ChoiceChip(
            label: const Text('Non visti'),
            selected: selectedFilter == ViewFilter.unseen,
            onSelected: (_) => onChanged(ViewFilter.unseen),
          ),
          ChoiceChip(
            label: const Text('Catturati'),
            selected: selectedFilter == ViewFilter.caught,
            onSelected: (_) => onChanged(ViewFilter.caught),
          ),
        ],
      ),
    );
  }
}

class _MarkModeSelector extends StatelessWidget {
  const _MarkModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final MarkMode selectedMode;
  final ValueChanged<MarkMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('MARK OFF'),
            selected: selectedMode == MarkMode.none,
            onSelected: (_) => onChanged(MarkMode.none),
          ),
          ChoiceChip(
            label: const Text('Visto'),
            selected: selectedMode == MarkMode.seen,
            onSelected: (_) => onChanged(MarkMode.seen),
          ),
          ChoiceChip(
            label: const Text('Non visto'),
            selected: selectedMode == MarkMode.unseen,
            onSelected: (_) => onChanged(MarkMode.unseen),
          ),
          ChoiceChip(
            label: const Text('Catturato'),
            selected: selectedMode == MarkMode.caught,
            onSelected: (_) => onChanged(MarkMode.caught),
          ),
        ],
      ),
    );
  }
}
