/// Lingua effettiva usata dai cataloghi di gioco.
///
/// I salvataggi continuano a usare ID e nomi tecnici indipendenti dalla lingua;
/// questa classe controlla soltanto i testi mostrati all'utente.
class GameCatalogLocale {
  GameCatalogLocale._();

  static String _languageCode = 'it';
  static int _revision = 0;

  static String get languageCode => _languageCode;
  static int get revision => _revision;
  static bool get isItalian => _languageCode == 'it';
  static bool get isEnglish => _languageCode == 'en';

  static bool setLanguageCode(String? value) {
    final normalizedValue = value?.trim().toLowerCase() ?? '';
    final normalized = RegExp(r'^it(?:[-_]|$)').hasMatch(normalizedValue)
        ? 'it'
        : 'en';
    if (_languageCode == normalized) return false;
    _languageCode = normalized;
    _revision++;
    return true;
  }
}
