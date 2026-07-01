import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../repositories/pokemon_repository.dart';
import '../../widgets/pokedex/pokemon_summary_dialog.dart';
import '../../widgets/pokedex/pokemon_tile.dart';
import '../../models/pokedex_entry.dart';

enum MarkMode {
  none,
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
  final TextEditingController _searchController = TextEditingController();
  final Map<int, PokedexEntry> _entries = {};

  MarkMode _markMode = MarkMode.none;

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

      setState(() {
        _allPokemon = pokemon;
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
    final range = _regions[_selectedRegion];

    if (range == null) {
      _filteredPokemon = _allPokemon;
      return;
    }

    final query = _searchController.text.toLowerCase();

    _filteredPokemon = _allPokemon.where((pokemon) {
      final inRegion = pokemon.id >= range.first && pokemon.id <= range.last;
      final matchesSearch = pokemon.name.toLowerCase().contains(query);

      return inRegion && matchesSearch;
    }).toList();
  }

  void _onSearchChanged(String _) {
    setState(_applyFilters);
  }

  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
      _applyFilters();
    });
  }

  void _openPokemonDialog(Pokemon pokemon) {
    showDialog(
      context: context,
      builder: (_) => PokemonSummaryDialog(
        pokemon: pokemon,
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
          _MarkModeSelector(
            selectedMode: _markMode,
            onChanged: (mode) {
              setState(() {
                _markMode = mode;
              });
            },
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: _filteredPokemon.length,
              itemBuilder: (context, index) {
                final pokemon = _filteredPokemon[index];

                return PokemonTile(
                  pokemon: pokemon,
                  entry: _entryFor(pokemon),
                  onTap: () => _handlePokemonTap(pokemon),
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

  PokedexEntry _entryFor(Pokemon pokemon) {
    return _entries[pokemon.id] ?? PokedexEntry(pokemonId: pokemon.id);
  }

  void _toggleSeen(Pokemon pokemon) {
    final entry = _entryFor(pokemon);

    setState(() {
      _entries[pokemon.id] = entry.copyWith(
        seen: !entry.seen,
        caught: entry.seen ? false : entry.caught,
      );
    });

    Navigator.of(context).pop();
  }

  void _toggleCaught(Pokemon pokemon) {
    final entry = _entryFor(pokemon);

    setState(() {
      _entries[pokemon.id] = entry.copyWith(
        seen: true,
        caught: !entry.caught,
      );
    });

    Navigator.of(context).pop();
  }

  List<Pokemon> get _currentRegionPokemon {
  final range = _regions[_selectedRegion];

  if (range == null) return _allPokemon;

  return _allPokemon.where((pokemon) {
    return pokemon.id >= range.first && pokemon.id <= range.last;
  }).toList();
  }

  int get _seenCount {
    return _currentRegionPokemon.where((pokemon) {
      return _entryFor(pokemon).seen;
    }).length;
  }

  int get _caughtCount {
    return _currentRegionPokemon.where((pokemon) {
      return _entryFor(pokemon).caught;
    }).length;
  }

  int get _regionTotal {
    return _currentRegionPokemon.length;
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

void _handlePokemonTap(Pokemon pokemon) {
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
  });

  final String label;
  final int value;
  final int total;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text('$value/$total'),
          ],
        ),
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
                      color: selected ? Theme.of(context).colorScheme.primary : null,
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