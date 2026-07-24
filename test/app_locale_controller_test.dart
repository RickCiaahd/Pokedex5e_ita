import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/app_locale_controller.dart';
import 'package:pokedex_5e_ita/services/app_locale_service.dart';

class _MemoryLocaleStore implements AppLocaleStore {
  _MemoryLocaleStore([this.value]);

  String? value;

  @override
  Future<String?> readLocalePreference() async => value;

  @override
  Future<void> writeLocalePreference(String value) async {
    this.value = value;
  }
}

void main() {
  test('una lingua dispositivo non supportata usa il fallback inglese', () {
    final controller = AppLocaleController(store: _MemoryLocaleStore());

    expect(
      controller.resolveDeviceLocale(const Locale('fr')),
      const Locale('en'),
    );
    expect(
      controller.resolveDeviceLocale(const Locale('de')),
      const Locale('en'),
    );
  });

  test('il sistema mantiene italiano e inglese quando supportati', () {
    final controller = AppLocaleController(store: _MemoryLocaleStore());

    expect(
      controller.resolveDeviceLocale(const Locale('it', 'IT')),
      const Locale('it'),
    );
    expect(
      controller.resolveDeviceLocale(const Locale('en', 'US')),
      const Locale('en'),
    );
  });

  test('la preferenza manuale prevale e viene salvata', () async {
    final store = _MemoryLocaleStore();
    final controller = AppLocaleController(store: store);

    await controller.load();
    await controller.setPreference(AppLocalePreference.italian);

    expect(controller.locale, const Locale('it'));
    expect(store.value, 'it');
    expect(
      controller.resolveDeviceLocale(const Locale('en')),
      const Locale('it'),
    );
  });
}
