import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('il codice applicativo non usa loader di immagini remoti', () {
    const sourcePaths = <String>[
      'lib/models/bag_item.dart',
      'lib/screens/bag/bag_screen.dart',
      'lib/screens/battle/battle_screen.dart',
      'lib/screens/pokemon/pokemon_detail_screen_legacy.dart',
    ];

    for (final path in sourcePaths) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('Image.network(')), reason: path);
      expect(source, isNot(contains('NetworkImage(')), reason: path);
      expect(source, isNot(contains('poke5e.app')), reason: path);
      expect(
        source,
        isNot(contains('raw.githubusercontent.com')),
        reason: path,
      );
      expect(source, isNot(contains('remoteSpriteUrl')), reason: path);
    }

    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });

  test('gli sprite locali degli oggetti sono inclusi nel bundle', () async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundledAssets = assetManifest.listAssets().toSet();
    final items = await ItemRepository().getWebItems();
    final errors = <String>[];

    for (final item in items) {
      final path = item.spriteAssetPath;
      if (path == null || path.trim().isEmpty) continue;
      if (!path.startsWith('assets/')) {
        errors.add('${item.id}: percorso non locale $path');
      } else if (!bundledAssets.contains(path)) {
        errors.add('${item.id}: asset non incluso $path');
      }
    }

    expect(errors, isEmpty, reason: errors.join('\n'));
  });
}
