import 'package:flutter/material.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({
    super.key,
    required this.nickname,
  });

  final String nickname;

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final List<String> _availablePokemon = [
    'Bulbasaur',
    'Charmander',
    'Squirtle',
    'Pikachu',
    'Eevee',
    'Snorlax',
  ];

  final List<String> _selectedPokemon = [];

  void _togglePokemon(String pokemon) {
    setState(() {
      if (_selectedPokemon.contains(pokemon)) {
        _selectedPokemon.remove(pokemon);
      } else {
        if (_selectedPokemon.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Puoi scegliere massimo 6 Pokémon.'),
            ),
          );
          return;
        }

        _selectedPokemon.add(pokemon);
      }
    });
  }

  void _confirmTeam() {
    if (_selectedPokemon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scegli almeno un Pokémon.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profilo ${widget.nickname} creato con ${_selectedPokemon.length} Pokémon!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scegli il tuo team'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Ciao ${widget.nickname}, scegli fino a 6 Pokémon.',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _availablePokemon.length,
                itemBuilder: (context, index) {
                  final pokemon = _availablePokemon[index];
                  final isSelected = _selectedPokemon.contains(pokemon);

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.catching_pokemon,
                      ),
                      title: Text(pokemon),
                      trailing: Text(
                        isSelected ? 'Selezionato' : 'Aggiungi',
                      ),
                      onTap: () => _togglePokemon(pokemon),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _confirmTeam,
                child: Text(
                  'Conferma team (${_selectedPokemon.length}/6)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}