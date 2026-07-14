import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/widgets/pokemon/egg_asset_image.dart';

void main() {
  testWidgets('EggAssetImage usa lo sprite caricato nel progetto', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: EggAssetImage(size: 48))),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, EggAssetImage.assetPath);
    expect(image.width, 48);
    expect(image.height, 48);
    expect(image.filterQuality, FilterQuality.none);
  });
}
