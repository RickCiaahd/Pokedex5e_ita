import 'package:flutter/material.dart';

import '../../models/pokemon.dart';

class PokemonDetailScreen extends StatelessWidget {
  const PokemonDetailScreen({
    super.key,
    required this.pokemon,
  });

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemon.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 48,
            child: Text(
              pokemon.id.toString(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            pokemon.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pokemon.types.join(' • '),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 32),

          _InfoCard(
            title: 'Statistiche base',
            children: [
              _InfoRow(label: 'CA', value: pokemon.armorClass.toString()),
              _InfoRow(label: 'PF', value: pokemon.hitPoints.toString()),
              _InfoRow(label: 'Taglia', value: pokemon.size),
              _InfoRow(label: 'Velocità', value: '${pokemon.speed} ft'),
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Caratteristiche',
            children: [
              _InfoRow(label: 'FOR', value: pokemon.attributes.strength.toString()),
              _InfoRow(label: 'DES', value: pokemon.attributes.dexterity.toString()),
              _InfoRow(label: 'COS', value: pokemon.attributes.constitution.toString()),
              _InfoRow(label: 'INT', value: pokemon.attributes.intelligence.toString()),
              _InfoRow(label: 'SAG', value: pokemon.attributes.wisdom.toString()),
              _InfoRow(label: 'CAR', value: pokemon.attributes.charisma.toString()),
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Abilità',
            children: [
              if (pokemon.abilities.isEmpty)
                const Text('Nessuna abilità indicata.')
              else
                ...pokemon.abilities.map(
                  (ability) => _BulletText(ability),
                ),
              if (pokemon.hiddenAbility != null) ...[
                const Divider(),
                _InfoRow(
                  label: 'Abilità nascosta',
                  value: pokemon.hiddenAbility!,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Competenze',
            children: [
              if (pokemon.skills.isEmpty)
                const Text('Nessuna competenza indicata.')
              else
                ...pokemon.skills.map(
                  (skill) => _BulletText(skill),
                ),
            ],
          ),

          const SizedBox(height: 16),

          _InfoCard(
            title: 'Tiri salvezza',
            children: [
              if (pokemon.savingThrows.isEmpty)
                const Text('Nessun tiro salvezza indicato.')
              else
                ...pokemon.savingThrows.map(
                  (savingThrow) => _BulletText(savingThrow),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('• $text'),
    );
  }
}