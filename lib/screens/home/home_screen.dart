import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex 5e ITA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.catching_pokemon,
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Benvenuto nel Pokédex 5e',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Consulta creature, statistiche, abilità e mosse in italiano.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  // Qui in futuro apriremo la lista Pokémon.
                },
                child: const Text('Apri Pokédex'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}