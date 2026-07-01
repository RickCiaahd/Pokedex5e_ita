import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../repositories/pokemon_repository.dart';
import '../../widgets/pokedex/pokemon_summary_dialog.dart';
import '../../widgets/pokedex/pokemon_tile.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokemonRepository _repository = PokemonRepository();
  final TextEditingController _searchController = TextEditingController();

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
    final range = _regions[_selectedRegion]!;
    final query = _searchController.text.toLowerCase();

    _filteredPokemon = _allPokemon.where((pokemon) {
      final inRegion = pokemon.id >= range[0] && pokemon.id <= range[1];
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
      builder: (_) => PokemonSummaryDialog(pokemon: pokemon),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredPokemon.length,
              itemBuilder: (context, index) {
                final pokemon = _filteredPokemon[index];

                return PokemonTile(
                  pokemon: pokemon,
                  onTap: () => _openPokemonDialog(pokemon),
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