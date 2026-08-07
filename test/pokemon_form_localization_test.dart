import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/pokemon_form_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'tutte le forme regionali del catalogo hanno testo italiano specifico',
    () async {
      final jsonString = await rootBundle.loadString(
        'assets/data_webapp/pokemon.json',
      );
      final decoded = Map<String, dynamic>.from(jsonDecode(jsonString));
      final items = List<dynamic>.from(decoded['items'] ?? const []);
      final regionalSlugs = <String>{};

      for (final rawItem in items) {
        if (rawItem is! Map) continue;
        final item = Map<String, dynamic>.from(rawItem);
        final slug = item['id']?.toString().trim().toLowerCase();
        if (slug == null || slug.isEmpty) continue;
        if (PokemonFormLocalization.isRegionalAssetSlug(slug)) {
          regionalSlugs.add(slug);
        }
      }

      expect(regionalSlugs, isNotEmpty);
      for (final slug in regionalSlugs) {
        expect(
          PokemonFormLocalization.hasSpecificItalianTextForAssetSlug(slug),
          isTrue,
          reason: 'Manca la localizzazione italiana della forma $slug',
        );
      }
    },
  );
}
