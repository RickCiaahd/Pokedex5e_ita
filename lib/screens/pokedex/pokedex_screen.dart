import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../models/pokedex_entry.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_flavor.dart';
import '../../repositories/pokemon_repository.dart';
import '../../widgets/pokedex/pokemon_summary_dialog.dart';
import '../../widgets/pokedex/pokemon_tile.dart';
import '../../services/profile_storage_service.dart';

enum MarkMode {
  none,
  seen,
  unseen,
  caught,
}

enum ViewFilter {
  all,
  seen,
  unseen,
  caught,
}

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokemonRepository _repository = PokemonRepository();
  final ProfileStorageService _profileStorageService = ProfileStorageService();
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final Map<int, PokedexEntry> _entries = {};
  final Map<int, PokemonFlavor> _pokemonFlavors = {};

  MarkMode _markMode = MarkMode.none;
  ViewFilter _viewFilter = ViewFilter.all;

  List<Pokemon> _allPokemon = [];
  List<Pokemon> _filteredPokemon = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedRegion = 'Kanto';

  final Map<String, List<int>> _regions = {
    'Kanto': [1, 151],
    'Johto': [152, 251],
    'Hoenn': [252, 386],
    'Sinnoh': [387, 493],
    'Unova': [494, 649],
    'Kalos': [650, 721],
    'Alola': [722, 809],
    'Others': [810, 9999],
  };

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onSectionScroll);
    _loadPokemon();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onSectionScroll);
    super.dispose();
  }

  Future<void> _loadPokemon() async {
    try {
      final pokemon = await _repository.getAllPokemon();
      final flavors = await _repository.getPokemonFlavors();
      await _loadEntries();

      setState(() {
        _allPokemon = pokemon;
        _pokemonFlavors.addAll(flavors);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    _filteredPokemon = _allPokemon.where((pokemon) {
      final matchesSearch = query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query);

      final entry = _entryFor(pokemon);

      final matchesFilter = switch (_viewFilter) {
        ViewFilter.all => true,
        ViewFilter.seen => entry.seen,
        ViewFilter.unseen => !entry.seen,
        ViewFilter.caught => entry.caught,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String _) {
    setState(_applyFilters);
  }

  void _selectRegion(String region) {
    final index = _visibleRegions.indexOf(region);

    if (index == -1) return;

    setState(() {
      _selectedRegion = region;
    });

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _onSectionScroll() {
    final positions = _itemPositionsListener.itemPositions.value;

    if (positions.isEmpty) return;

    final visibleIndexes = positions
        .where((position) => position.itemTrailingEdge > 0)
        .map((position) => position.index)
        .toList();

    if (visibleIndexes.isEmpty) return;

    final firstVisibleIndex = visibleIndexes.reduce((a, b) => a < b ? a : b);
    final regions = _visibleRegions;

    if (firstVisibleIndex < 0 || firstVisibleIndex >= regions.length) return;

    final region = regions[firstVisibleIndex];

    if (region != _selectedRegion) {
      setState(() {
        _selectedRegion = region;
      });
    }
  }

  List<String> get _visibleRegions {
    return _regions.keys.where((region) {
      return _pokemonForRegion(region).isNotEmpty;
    }).toList();
  }

  List<Pokemon> _pokemonForRegion(String region) {
    final range = _regions[region];

    if (range == null) return [];

    return _filteredPokemon.where((pokemon) {
      return pokemon.id >= range.first && pokemon.id <= range.last;
    }).toList();
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
          _RegionSelector(
            regions: _regions.keys.toList(),
            selectedRegion: _selectedRegion,
            onSelected: _selectRegion,
          ),
          _RegionProgressGrid(
            regions: _regions.keys.toList(),
            selectedRegion: _selectedRegion,
            progressBuilder: _regionProgress,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Cerca Pokémon...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
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
            onChanged: (mode) {
              setState(() {
                _markMode = mode;
              });
            },
          ),
          Expanded(
            child: _visibleRegions.isEmpty
                ? const Center(child: Text('Nessun Pokémon trovato.'))
                : ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    itemCount: _visibleRegions.length,
                    itemBuilder: (context, index) {
                      final region = _visibleRegions[index];
                      final pokemonList = _pokemonForRegion(region);

                      return _RegionSection(
                        region: region,
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
      appBar: AppBar(
        title: const Text('Pokédex'),
      ),
      body: content,
    );
  }

  Future<void> _loadEntries() async {
    final entries = await _profileStorageService.loadPokedexEntries();

    _entries
      ..clear()
      ..addAll(entries);
  }

  Future<void> _saveEntries() async {
    debugPrint('POKEDEX SCREEN: chiamo save con ${_entries.length} entries');
  
    try {
      await _profileStorageService.savePokedexEntries(_entries);
      debugPrint('POKEDEX SCREEN: save completato');
    } catch (e, stackTrace) {
      debugPrint('POKEDEX SCREEN: errore save: $e');
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
      _entries[pokemon.id] = entry.copyWith(
        seen: true,
        caught: !entry.caught,
      );
    });

    await _saveEntries();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Map<String, int> _regionProgress(String region, bool caught) {
    final range = _regions[region]!;

    final regionPokemon = _allPokemon.where((pokemon) {
      return pokemon.id >= range.first && pokemon.id <= range.last;
    }).toList();

    final count = regionPokemon.where((pokemon) {
      final entry = _entryFor(pokemon);
      return caught ? entry.caught : entry.seen;
    }).length;

    return {
      'count': count,
      'total': regionPokemon.length,
    };
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
          _entries[pokemon.id] = entry.copyWith(
            seen: false,
            caught: false,
          );
          break;
        case MarkMode.caught:
          _entries[pokemon.id] = entry.copyWith(
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
            region.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
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

class _RegionSelector extends StatelessWidget {
  const _RegionSelector({
    required this.regions,
    required this.selectedRegion,
    required this.onSelected,
  });

  final List<String> regions;
  final String selectedRegion;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: regions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final region = regions[index];
          final selected = region == selectedRegion;

          return ChoiceChip(
            label: Text(region),
            selected: selected,
            onSelected: (_) => onSelected(region),
          );
        },
      ),
    );
  }
}

class _RegionProgressGrid extends StatelessWidget {
  const _RegionProgressGrid({
    required this.regions,
    required this.selectedRegion,
    required this.progressBuilder,
  });

  final List<String> regions;
  final String selectedRegion;
  final Map<String, int> Function(String region, bool caught) progressBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: regions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final region = regions[index];
          final seen = progressBuilder(region, false);
          final caught = progressBuilder(region, true);
          final selected = region == selectedRegion;

          return Card(
            elevation: selected ? 3 : 1,
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Visti: ${seen['count']}/${seen['total']}'),
                  Text('Presi: ${caught['count']}/${caught['total']}'),
                ],
              ),
            ),
          );
        },
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