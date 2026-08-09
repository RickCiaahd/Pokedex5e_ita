import '../localization/game_catalog_locale.dart';
import 'bag_item.dart';

class SpecialFormItemCatalog {
  const SpecialFormItemCatalog._();

  static List<BagItem> get items => [
    _mask(
      id: 'teal-mask',
      englishName: 'Teal Mask',
      italianName: 'Maschera Turchese',
      type: 'Grass',
    ),
    _mask(
      id: 'wellspring-mask',
      englishName: 'Wellspring Mask',
      italianName: 'Maschera Pozzo',
      type: 'Water',
    ),
    _mask(
      id: 'hearthflame-mask',
      englishName: 'Hearthflame Mask',
      italianName: 'Maschera Focolare',
      type: 'Fire',
    ),
    _mask(
      id: 'cornerstone-mask',
      englishName: 'Cornerstone Mask',
      italianName: 'Maschera Fondamenta',
      type: 'Rock',
    ),
  ];

  static BagItem _mask({
    required String id,
    required String englishName,
    required String italianName,
    required String type,
  }) {
    final isItalian = GameCatalogLocale.isItalian;
    return BagItem(
      id: id,
      name: isItalian ? italianName : englishName,
      sourceName: englishName,
      type: 'held-item',
      description: [
        isItalian
            ? 'Quando Ogerpon indossa questa maschera assume la forma associata e il tipo $type previsto dalla sua regola di cambio forma.'
            : 'While Ogerpon wears this mask, it assumes the associated form and the $type type defined by its form-change rule.',
      ],
      cost: null,
      spriteAssetPath: null,
    );
  }
}
