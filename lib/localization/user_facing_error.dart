import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'ui_text.dart';

enum UserFacingErrorAction {
  load,
  save,
  importFile,
  exportFile,
  share,
  generic,
}

extension UserFacingErrorBuildContext on BuildContext {
  String userFacingError(
    Object error, {
    UserFacingErrorAction action = UserFacingErrorAction.generic,
  }) {
    if (kDebugMode) {
      debugPrint('Technical error hidden from the UI (${action.name}): $error');
    }

    String localized(String italian, String english) {
      return mounted
          ? uiText(italian, english)
          : uiTextForLanguage(italian, english);
    }

    return switch (action) {
      UserFacingErrorAction.load => localized(
        'Non è stato possibile caricare i dati. Riprova.',
        'The data could not be loaded. Try again.',
      ),
      UserFacingErrorAction.save => localized(
        'Non è stato possibile salvare le modifiche. Riprova.',
        'The changes could not be saved. Try again.',
      ),
      UserFacingErrorAction.importFile => localized(
        'Non è stato possibile importare il file. Verifica che sia valido e riprova.',
        'The file could not be imported. Check that it is valid and try again.',
      ),
      UserFacingErrorAction.exportFile => localized(
        'Non è stato possibile esportare i dati. Riprova.',
        'The data could not be exported. Try again.',
      ),
      UserFacingErrorAction.share => localized(
        'Non è stato possibile condividere i dati. Riprova.',
        'The data could not be shared. Try again.',
      ),
      UserFacingErrorAction.generic => localized(
        'Non è stato possibile completare l’operazione. Riprova.',
        'The operation could not be completed. Try again.',
      ),
    };
  }
}
