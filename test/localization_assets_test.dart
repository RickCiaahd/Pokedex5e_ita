import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i cataloghi ARB italiano e inglese espongono le stesse chiavi', () {
    Map<String, dynamic> read(String path) {
      return Map<String, dynamic>.from(
        jsonDecode(File(path).readAsStringSync()) as Map,
      );
    }

    final english = read('lib/l10n/app_en.arb');
    final italian = read('lib/l10n/app_it.arb');

    Set<String> publicKeys(Map<String, dynamic> values) {
      return values.keys.where((key) => !key.startsWith('@')).toSet();
    }

    expect(publicKeys(italian), publicKeys(english));
    expect(english['@@locale'], 'en');
    expect(italian['@@locale'], 'it');
  });
}
