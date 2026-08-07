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

  test(
    'la modalità sistema usa la prima lingua supportata del dispositivo',
    () {
      final controller = AppLocaleController(store: _MemoryLocaleStore());

      expect(
        controller.resolveDeviceLocales(const [
          Locale('fr', 'FR'),
          Locale('it', 'IT'),
          Locale('en', 'US'),
        ]),
        const Locale('it'),
      );
      expect(
        controller.resolveDeviceLocales(const [
          Locale('de', 'DE'),
          Locale('en', 'GB'),
          Locale('it', 'IT'),
        ]),
        const Locale('en'),
      );
    },
  );

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

  test(
    'tornando a sistema viene ripristinata la lingua del dispositivo',
    () async {
      final store = _MemoryLocaleStore();
      final controller = AppLocaleController(store: store);

      await controller.load();
      await controller.setPreference(AppLocalePreference.english);
      expect(controller.locale, const Locale('en'));

      await controller.setPreference(AppLocalePreference.system);

      expect(controller.locale, isNull);
      expect(store.value, 'system');
      expect(
        controller.resolveDeviceLocales(const [Locale('it', 'IT')]),
        const Locale('it'),
      );
    },
  );
}
