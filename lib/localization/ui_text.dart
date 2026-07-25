import 'package:flutter/widgets.dart';

import 'game_catalog_locale.dart';

String uiTextForLanguage(String italian, String english) {
  return GameCatalogLocale.isItalian ? italian : english;
}

/// Ponte leggero per migrare progressivamente le schermate secondarie.
///
/// Le nuove schermate continuano a preferire gli ARB. Questo helper permette di
/// rimuovere rapidamente le stringhe italiane hardcoded dalle aree storiche
/// senza cambiare ID tecnici, valori salvati o logica applicativa.
extension UiTextBuildContext on BuildContext {
  bool get usesItalianUi {
    final locale = Localizations.maybeLocaleOf(this);
    if (locale != null) return locale.languageCode.toLowerCase() == 'it';
    return GameCatalogLocale.isItalian;
  }

  String uiText(String italian, String english) {
    return usesItalianUi ? italian : english;
  }
}
