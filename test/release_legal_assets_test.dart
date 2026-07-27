import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GPL e NOTICE generati corrispondono ai documenti sorgente', () {
    final pairs = <String, String>{
      'assets/data/GPL-3.0.txt': 'LICENSE',
      'assets/data/NOTICE.txt': 'NOTICE.md',
    };

    for (final entry in pairs.entries) {
      final generated = File(entry.key);
      final source = File(entry.value);
      expect(generated.existsSync(), isTrue, reason: '${entry.key} mancante');
      expect(generated.readAsBytesSync(), source.readAsBytesSync());
    }
  });

  test('GPL e NOTICE sono registrati nell AssetManifest Flutter', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    expect(assets, contains('assets/data/GPL-3.0.txt'));
    expect(assets, contains('assets/data/NOTICE.txt'));
  });
}
