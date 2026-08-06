part of 'bag_screen.dart';

class _BagError extends StatelessWidget {
  const _BagError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              context.uiText(
                'Non riesco a caricare gli oggetti dello zaino.',
                'Could not load Bag items.',
              ),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _BagEmpty extends StatelessWidget {
  const _BagEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          context.uiText('Nessun oggetto nello zaino.', 'No items in the Bag.'),
        ),
      ),
    );
  }
}

String _itemReferenceKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

IconData _useIconForItemType(String type) {
  switch (type) {
    case 'tm':
      return Icons.school_outlined;
    case 'medicine':
      return Icons.medical_services_outlined;
    case 'held-item':
      return Icons.inventory_2_outlined;
    case 'berry':
      return Icons.eco_outlined;
    default:
      return Icons.play_arrow;
  }
}

String _useLabelForItemType(String type) {
  switch (type) {
    case 'tm':
      return uiTextForLanguage('Usa MT', 'Use TM');
    case 'medicine':
      return uiTextForLanguage('Usa oggetto', 'Use item');
    case 'held-item':
      return uiTextForLanguage('Dai a Pokémon', 'Give to Pokémon');
    case 'berry':
      return uiTextForLanguage('Usa bacca', 'Use Berry');
    default:
      return uiTextForLanguage('Usa', 'Use');
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'pokeball':
      return Icons.catching_pokemon;
    case 'medicine':
      return Icons.medical_services_outlined;
    case 'berry':
      return Icons.eco_outlined;
    case 'held-item':
      return Icons.inventory_2_outlined;
    case 'evolution':
      return Icons.auto_awesome;
    case 'trainer-gear':
      return Icons.hiking_outlined;
    case 'key-item':
      return Icons.vpn_key_outlined;
    case 'tm':
      return Icons.album_outlined;
    default:
      return Icons.category_outlined;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'pokeball':
      return 'Poké Ball';
    case 'medicine':
      return 'Medicine';
    case 'vitamin':
      return uiTextForLanguage('Vitamine', 'Vitamins');
    case 'berry':
      return uiTextForLanguage('Bacche', 'Berries');
    case 'held-item':
      return uiTextForLanguage('Oggetti tenuti', 'Held items');
    case 'evolution':
      return uiTextForLanguage('Evoluzione', 'Evolution');
    case 'trainer-gear':
      return uiTextForLanguage('Equipaggiamento', 'Trainer gear');
    case 'key-item':
      return uiTextForLanguage('Oggetti chiave', 'Key items');
    case 'tm':
      return 'MT';
    default:
      return type
          .split('-')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
  }
}
