import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../repositories/pokemon_repository.dart';

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
        _filteredPokemon = pokemon;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterPokemon(String query) {
    final text = query.toLowerCase();

    setState(() {
      _filteredPokemon = _allPokemon.where((pokemon) {
        return pokemon.name.toLowerCase().contains(text);
      }).toList();
    });
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPokemon,
              decoration: const InputDecoration(
                hintText: 'Cerca Pokémon...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPokemon.length,
              itemBuilder: (context, index) {
                final pokemon = _filteredPokemon[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${pokemon.id}'),
                    ),
                    title: Text(pokemon.name),
                    subtitle: Text(pokemon.types.join(' • ')),
                    trailing: Text('PF ${pokemon.hitPoints}'),
                    onTap: () {
                      // Qui dopo apriremo la schermata dettaglio.
                    },
                  ),
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