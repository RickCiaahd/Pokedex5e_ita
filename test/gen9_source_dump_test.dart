import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stampa temporaneamente le sorgenti della nona generazione', () async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/data_webapp/pokemon.json'),
    ) as Map<String, dynamic>;
    final items = List<dynamic>.from(raw['items'] ?? const []);
    final selected = <int, Map<String, dynamic>>{};

    for (final rawItem in items) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final number = (item['number'] as num?)?.toInt() ?? 0;
      if (number < 906 || number > 1025) continue;
      final candidate = <String, dynamic>{
        'number': number,
        'name': item['name']?.toString() ?? '',
        'id': item['id']?.toString() ?? '',
        'description': item['description']?.toString() ?? '',
      };
      final current = selected[number];
      if (current == null ||
          candidate['id'].toString().length < current['id'].toString().length) {
        selected[number] = candidate;
      }
    }

    for (var number = 906; number <= 1025; number++) {
      final item = selected[number];
      if (item == null) {
        print('GEN9_SOURCE_MISSING:$number');
      } else {
        print('GEN9_SOURCE:${jsonEncode(item)}');
      }
    }

    fail('Diagnostica temporanea: rimuovere questo test dopo aver acquisito le sorgenti.');
  });
}
