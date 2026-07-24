import 'package:flutter/material.dart';

import '../services/app_locale_service.dart';

enum AppLocalePreference {
  system('system'),
  italian('it'),
  english('en');

  const AppLocalePreference(this.storageValue);

  final String storageValue;

  static AppLocalePreference fromStorage(String? value) {
    return AppLocalePreference.values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () => AppLocalePreference.system,
    );
  }
}

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({AppLocaleStore? store})
    : _store = store ?? AppLocaleService();

  final AppLocaleStore _store;

  AppLocalePreference _preference = AppLocalePreference.system;
  bool _isLoaded = false;

  AppLocalePreference get preference => _preference;
  bool get isLoaded => _isLoaded;

  Locale? get locale {
    return switch (_preference) {
      AppLocalePreference.system => null,
      AppLocalePreference.italian => const Locale('it'),
      AppLocalePreference.english => const Locale('en'),
    };
  }

  Future<void> load() async {
    try {
      _preference = AppLocalePreference.fromStorage(
        await _store.readLocalePreference(),
      );
    } catch (error) {
      debugPrint('Impossibile caricare la lingua dell’app: $error');
      _preference = AppLocalePreference.system;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPreference(AppLocalePreference preference) async {
    if (_preference == preference) return;
    _preference = preference;
    notifyListeners();

    try {
      await _store.writeLocalePreference(preference.storageValue);
    } catch (error) {
      debugPrint('Impossibile salvare la lingua dell’app: $error');
    }
  }

  Locale resolveDeviceLocale(Locale? deviceLocale) {
    final selectedLocale = locale;
    if (selectedLocale != null) return selectedLocale;
    if (deviceLocale?.languageCode.toLowerCase() == 'it') {
      return const Locale('it');
    }
    return const Locale('en');
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope non trovato nel widget tree.');
    return scope!.notifier!;
  }
}
