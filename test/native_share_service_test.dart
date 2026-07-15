import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/services/native_share_service.dart';

void main() {
  const service = NativeShareService();

  test('restituisce il messaggio di successo personalizzato', () {
    expect(
      service.feedback(
        NativeShareOutcome.completed,
        successMessage: 'Squadra condivisa.',
      ),
      'Squadra condivisa.',
    );
  });

  test('distingue annullamento ed esito non comunicato', () {
    expect(
      service.feedback(
        NativeShareOutcome.dismissed,
        successMessage: 'Contenuto condiviso.',
      ),
      'Condivisione annullata.',
    );
    expect(
      service.feedback(
        NativeShareOutcome.unavailable,
        successMessage: 'Contenuto condiviso.',
      ),
      'Condivisione avviata. Il sistema non comunica l’esito finale.',
    );
  });
}
