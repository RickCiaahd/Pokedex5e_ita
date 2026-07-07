import 'package:flutter/material.dart';

class BagScreen extends StatelessWidget {
  const BagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zaino')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          _BagHeader(),
          SizedBox(height: 16),
          _BagCategoryCard(
            icon: Icons.catching_pokemon,
            title: 'Poké Ball',
            description: 'Sfere e strumenti usati durante la cattura.',
          ),
          _BagCategoryCard(
            icon: Icons.medical_services_outlined,
            title: 'Medicine',
            description: 'Pozioni, cure di stato e oggetti rapidi.',
          ),
          _BagCategoryCard(
            icon: Icons.backpack_outlined,
            title: 'Equipaggiamento',
            description: 'Oggetti da avventura, pack iniziali e strumenti.',
          ),
          _BagCategoryCard(
            icon: Icons.inventory_2_outlined,
            title: 'Oggetti chiave',
            description: 'Ricompense, strumenti speciali e note di campagna.',
          ),
        ],
      ),
    );
  }
}

class _BagHeader extends StatelessWidget {
  const _BagHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.backpack,
              color: colorScheme.onTertiaryContainer,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zaino allenatore',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Struttura pronta per separare equipaggiamento, cure e oggetti di cattura.',
                    style: TextStyle(color: colorScheme.onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BagCategoryCard extends StatelessWidget {
  const _BagCategoryCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title sara gestito in una prossima patch.')),
          );
        },
      ),
    );
  }
}
