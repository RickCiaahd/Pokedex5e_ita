import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';

import '../../models/custom_pokemon_definition.dart';
import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../repositories/pokedex_repositry.dart';
import '../../repositories/pokemon_pc_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/team_repository.dart';
import '../../services/profile_storage_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/pokedex/pokemon_summary_dialog.dart';
import '../../widgets/pokedex/pokemon_tile.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../pokemon/custom_pokemon_library_screen.dart';

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
  final PokedexRepository _pokedexRepository = PokedexRepository();
  final PokemonPcRepository _pokemonPcRepository = PokemonPcRepository();
  final TeamRepository _teamRepository = TeamRepository();
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
    'Fakemon': [CustomPokemonDefinition.firstCustomPokemonId, 2147483647],
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
      await _syncOwnedPokemon();
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

  Future<void> _syncOwnedPokemon() async {
    final profile = await _profileStorageService.getDefaultProfile();
    final team = await _teamRepository.getTeam(profile.id);
    final pcPokemon = await _pokemonPcRepository.getPokemon(profile.id);

    await _pokedexRepository.registerCaughtMany(
      profileId: profile.id,
      pokemon: [
        for (final slot in team)
          if (slot.pokemonId != null)
            PokedexOwnedForm(
              pokemonId: slot.pokemonId!,
              formName: slot.formName,
            ),
        for (final item in pcPokemon)
          PokedexOwnedForm(pokemonId: item.pokemonId, formName: item.formName),
      ],
    );
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    final selectedRegion = _selectedRegion;

    _filteredPokemon = _allPokemon
        .where((pokemon) {
          final entry = _entryFor(pokemon);
          final previewPokemon = pokemon.resolveVariant(
            formName: entry.preferredFormName,
          );
          final matchesSearch =
              query.isEmpty ||
              pokemon.name.toLowerCase().contains(query) ||
              pokemon.id.toString().contains(query) ||
              previewPokemon.types.any(
                (type) => type.toLowerCase().contains(query),
              );

          final matchesFilter = switch (_viewFilter) {
            ViewFilter.all => true,
            ViewFilter.seen => entry.seen,
            ViewFilter.unseen => !entry.seen,
            ViewFilter.caught => entry.caught,
          };

          final localizedTypes = previewPokemon.types
              .map(PokemonAssetPaths.localizedTypeLabel)
              .toSet();
          final matchesTypes =
              _selectedTypes.isEmpty ||
              _selectedTypes.every(localizedTypes.contains);

          final matchesRegion =
              selectedRegion == null ||
              _regionForPokemon(pokemon) == selectedRegion;

          return matchesSearch &&
              matchesFilter &&
              matchesTypes &&
              matchesRegion;
        })
        .toList(growable: false);

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

  void _clearSearch() {
    _searchController.clear();
    setState(_applyFilters);
  }

  void _setRegionFilter(String? region) {
    setState(() {
      _selectedRegion = region;
      _applyFilters();
    });
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

  bool get _hasCustomOptions {
    return _sortMode != SortMode.numberAsc ||
        _selectedRegion != null ||
        _selectedTypes.isNotEmpty ||
        _viewFilter != ViewFilter.all ||
        _markMode != MarkMode.none;
  }

  String get _filterSummary {
    final details = <String>[];

    switch (_sortMode) {
      case SortMode.numberAsc:
        break;
      case SortMode.numberDesc:
        details.add(context.uiText('Numero decrescente', 'Number descending'));
        break;
      case SortMode.nameAsc:
        details.add(context.uiText('Nome A-Z', 'Name A-Z'));
        break;
      case SortMode.nameDesc:
        details.add(context.uiText('Nome Z-A', 'Name Z-A'));
        break;
    }

    if (_selectedRegion != null) details.add(_selectedRegion!);
    if (_selectedTypes.isNotEmpty) {
      details.add('${_selectedTypes.length} tipi');
    }

    switch (_viewFilter) {
      case ViewFilter.all:
        break;
      case ViewFilter.seen:
        details.add(context.uiText('Visti', 'Seen'));
        break;
      case ViewFilter.unseen:
        details.add(context.uiText('Non visti', 'Unseen'));
        break;
      case ViewFilter.caught:
        details.add(context.uiText('Catturati', 'Caught'));
        break;
    }

    switch (_markMode) {
      case MarkMode.none:
        break;
      case MarkMode.seen:
        details.add(context.uiText('Segna visto', 'Mark seen'));
        break;
      case MarkMode.unseen:
        details.add(context.uiText('Segna non visto', 'Mark unseen'));
        break;
      case MarkMode.caught:
        details.add(context.uiText('Segna catturato', 'Mark caught'));
        break;
    }

    final resultLabel = '${_filteredPokemon.length} risultati';
    return details.isEmpty
        ? resultLabel
        : '$resultLabel · ${details.join(' · ')}';
  }

  void _resetOptions() {
    setState(() {
      _sortMode = SortMode.numberAsc;
      _selectedRegion = null;
      _selectedTypes.clear();
      _viewFilter = ViewFilter.all;
      _markMode = MarkMode.none;
      _applyFilters();
    });
  }

  List<String> get _visibleRegions {
    return _regions.keys
        .where((region) => _pokemonForRegion(region).isNotEmpty)
        .toList(growable: false);
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

    return _filteredPokemon
        .where(
          (pokemon) => pokemon.id >= range.first && pokemon.id <= range.last,
        )
        .toList(growable: false);
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

  Future<void> _openPokemonDialog(Pokemon pokemon) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PokemonSummaryDialog(
        pokemon: pokemon,
        flavor: _pokemonFlavors[pokemon.id],
        entry: _entryFor(pokemon),
        onEntryChanged: (entry) async {
          if (!mounted) return;
          setState(() {
            _entries[pokemon.id] = entry;
            _applyFilters();
          });
          await _saveEntries();
        },
      ),
    );
  }

  Future<void> _openCustomPokemonLibrary() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CustomPokemonLibraryScreen()),
    );
    if (!mounted) return;
    PokemonRepository.clearCache();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadPokemon();
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

  Map<String, int> _regionProgress(String region, bool caught) {
    final range = _regions[region]!;
    final regionPokemon = _allPokemon
        .where(
          (pokemon) => pokemon.id >= range.first && pokemon.id <= range.last,
        )
        .toList(growable: false);

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
          final base = entry.formFor(null, speciesName: pokemon.name);
          _entries[pokemon.id] = entry.setFormState(
            formName: null,
            speciesName: pokemon.name,
            seen: true,
            caught: base.caught,
          );
          break;
        case MarkMode.unseen:
          _entries[pokemon.id] = entry.clearAllForms();
          break;
        case MarkMode.caught:
          _entries[pokemon.id] = entry.setFormState(
            formName: null,
            speciesName: pokemon.name,
            seen: true,
            caught: true,
          );
          break;
        case MarkMode.none:
          break;
      }
    });

    await _saveEntries();
  }

  Widget _buildFilterControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final sortSelector = _SortModeSelector(
          sortMode: _sortMode,
          onChanged: (sortMode) {
            setState(() {
              _sortMode = sortMode;
              _applyFilters();
            });
          },
        );
        final regionSelector = _RegionFilterSelector(
          regions: _visibleRegions,
          selectedRegion: _selectedRegion,
          progressBuilder: _regionProgress,
          onChanged: _setRegionFilter,
        );
        final typeSelector = _TypeFilterSelector(
          types: _availableTypes,
          selectedTypes: _selectedTypes,
          onChanged: _setTypeFilters,
          onClear: _clearTypeFilters,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sortSelector,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: regionSelector),
                  const SizedBox(width: 8),
                  Expanded(child: typeSelector),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: sortSelector),
            const SizedBox(width: 8),
            Expanded(child: regionSelector),
            const SizedBox(width: 8),
            Expanded(child: typeSelector),
          ],
        );
      },
    );
  }

  Widget _buildFilterPanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const PageStorageKey<String>('pokedex-filter-panel'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(Icons.tune),
          title: const Text(
            'Filtri e modalità',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _filterSummary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            if (_hasCustomOptions)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resetOptions,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Ripristina'),
                ),
              ),
            _buildFilterControls(),
            const SizedBox(height: 12),
            const _FilterGroupTitle(
              icon: Icons.visibility_outlined,
              label: 'Mostra',
            ),
            const SizedBox(height: 6),
            _ViewFilterSelector(
              selectedFilter: _viewFilter,
              onChanged: (filter) {
                setState(() {
                  _viewFilter = filter;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 12),
            _FilterGroupTitle(
              icon: Icons.touch_app_outlined,
              label: context.uiText(
                'Quando tocchi un Pokémon',
                'When you tap a Pokémon',
              ),
            ),
            const SizedBox(height: 6),
            _MarkModeSelector(
              selectedMode: _markMode,
              onChanged: (mode) => setState(() => _markMode = mode),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      content = Center(
        child: Text(
          context.uiText('Errore: $_errorMessage', 'Error: $_errorMessage'),
        ),
      );
    } else {
      content = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.uiText(
                      'Cerca Pokémon...',
                      'Search Pokémon...',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.uiText(
                              'Cancella ricerca',
                              'Clear search',
                            ),
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                _buildFilterPanel(),
              ],
            ),
          ),
          Expanded(
            child: _visibleSections.isEmpty
                ? Center(
                    child: Text(
                      context.uiText(
                        'Nessun Pokémon trovato.',
                        'No Pokémon found.',
                      ),
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _visibleSections.length,
                    itemBuilder: (context, index) {
                      final section = _visibleSections[index];
                      final pokemonList = _pokemonForSection(section);

                      return _RegionSection(
                        region: section,
                        pokemon: pokemonList,
                        columns: _gridColumnCount(context),
                        entryFor: _entryFor,
                        previewFormFor: (pokemon) =>
                            _entryFor(pokemon).preferredFormName,
                        onPokemonTap: _handlePokemonTap,
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.uiText('Pokédex', 'Pokédex')),
        actions: [
          IconButton(
            tooltip: context.uiText('I miei Fakemon', 'My Fakémon'),
            onPressed: _openCustomPokemonLibrary,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: ResponsiveContent(maxWidth: 1440, child: content),
    );
  }
}

class _FilterGroupTitle extends StatelessWidget {
  const _FilterGroupTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RegionSection extends StatelessWidget {
  const _RegionSection({
    required this.region,
    required this.pokemon,
    required this.columns,
    required this.entryFor,
    required this.previewFormFor,
    required this.onPokemonTap,
  });

  final String region;
  final List<Pokemon> pokemon;
  final int columns;
  final PokedexEntry Function(Pokemon pokemon) entryFor;
  final String? Function(Pokemon pokemon) previewFormFor;
  final ValueChanged<Pokemon> onPokemonTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${region.toUpperCase()} · ${pokemon.length}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pokemon.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final currentPokemon = pokemon[index];
              return PokemonTile(
                pokemon: currentPokemon,
                entry: entryFor(currentPokemon),
                previewFormName: previewFormFor(currentPokemon),
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
        ? 'Tutte'
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
  late String _selectedRegion =
      widget.selectedRegion ?? _RegionFilterDialog.allValue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.uiText('Filtra per regione', 'Filter by region')),
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
          onPressed: () =>
              Navigator.of(context).pop(_RegionFilterDialog.cancelValue),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_RegionFilterDialog.allValue),
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
      decoration: InputDecoration(
        labelText: context.uiText('Ordina', 'Sort'),
        prefixIcon: Icon(Icons.sort),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(
          value: SortMode.numberAsc,
          child: Text(context.uiText('Numero crescente', 'Number ascending')),
        ),
        DropdownMenuItem(
          value: SortMode.numberDesc,
          child: Text(
            context.uiText('Numero decrescente', 'Number descending'),
          ),
        ),
        DropdownMenuItem(
          value: SortMode.nameAsc,
          child: Text(context.uiText('Nome A-Z', 'Name A-Z')),
        ),
        DropdownMenuItem(
          value: SortMode.nameDesc,
          child: Text(context.uiText('Nome Z-A', 'Name Z-A')),
        ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
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

    final label = selectedTypes.isEmpty
        ? context.uiText('Tipi', 'Types')
        : context.uiText(
            'Tipi (${selectedTypes.length})',
            'Types (${selectedTypes.length})',
          );

    return OutlinedButton.icon(
      icon: Icon(selectedTypes.isEmpty ? Icons.category : Icons.close),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onLongPress: selectedTypes.isEmpty ? null : onClear,
      onPressed: () async {
        final result = await showDialog<Set<String>>(
          context: context,
          builder: (_) =>
              _TypeFilterDialog(types: types, selectedTypes: selectedTypes),
        );

        if (result != null) onChanged(result);
      },
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
      title: Text(context.uiText('Filtra per tipo', 'Filter by type')),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(context.uiText('Tutti', 'All')),
          selected: selectedFilter == ViewFilter.all,
          onSelected: (_) => onChanged(ViewFilter.all),
        ),
        ChoiceChip(
          label: Text(context.uiText('Visti', 'Seen')),
          selected: selectedFilter == ViewFilter.seen,
          onSelected: (_) => onChanged(ViewFilter.seen),
        ),
        ChoiceChip(
          label: Text(context.uiText('Non visti', 'Unseen')),
          selected: selectedFilter == ViewFilter.unseen,
          onSelected: (_) => onChanged(ViewFilter.unseen),
        ),
        ChoiceChip(
          label: Text(context.uiText('Catturati', 'Caught')),
          selected: selectedFilter == ViewFilter.caught,
          onSelected: (_) => onChanged(ViewFilter.caught),
        ),
      ],
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(context.uiText('Apri scheda', 'Open sheet')),
          selected: selectedMode == MarkMode.none,
          onSelected: (_) => onChanged(MarkMode.none),
        ),
        ChoiceChip(
          label: Text(context.uiText('Segna visto', 'Mark seen')),
          selected: selectedMode == MarkMode.seen,
          onSelected: (_) => onChanged(MarkMode.seen),
        ),
        ChoiceChip(
          label: Text(context.uiText('Segna non visto', 'Mark unseen')),
          selected: selectedMode == MarkMode.unseen,
          onSelected: (_) => onChanged(MarkMode.unseen),
        ),
        ChoiceChip(
          label: Text(context.uiText('Segna catturato', 'Mark caught')),
          selected: selectedMode == MarkMode.caught,
          onSelected: (_) => onChanged(MarkMode.caught),
        ),
      ],
    );
  }
}
