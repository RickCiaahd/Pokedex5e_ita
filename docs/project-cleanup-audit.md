# Audit di pulizia del progetto

Audit aggiornato in preparazione della prima release GitHub `1.0.0`.

## Risultato

- la versione applicativa è coerente con la release prevista: `1.0.0+1`;
- sono presenti soltanto i due workflow permanenti `Flutter CI` e `Android release`;
- il workflow temporaneo usato per validare Minior e le variazioni di genere è stato rimosso dopo l'esecuzione;
- la CI permanente esegue `flutter analyze`, il test di integrità, l'intera suite e una build APK Android di debug;
- la pipeline release ripete analisi e test, quindi genera APK e AAB firmati con checksum SHA-256;
- nessun file di build, cache, keystore o configurazione privata risulta versionato;
- eliminati i log informativi ripetitivi dalle operazioni ordinarie di caricamento e salvataggio del Pokédex;
- mantenuti i log relativi agli errori effettivi di caricamento dati e persistenza;
- il changelog è stato consolidato nella prima release `1.0.0`, includendo localizzazioni, Minior e differenze di genere;
- non risultano `TODO`, `FIXME`, `HACK` o `XXX` applicativi da risolvere prima della release.

## Asset

Il progetto include il catalogo grafico completo e supera i 300 MiB soprattutto per gli sprite. I piccoli gruppi di file byte-identici non vengono rimossi in questa fase perché i percorsi delle forme e i fallback sono costruiti dinamicamente dai cataloghi JSON. Una deduplicazione senza prima normalizzare alias e riferimenti potrebbe introdurre immagini mancanti.

La riduzione sostanziale delle dimensioni deve quindi essere trattata come intervento separato, successivo alla release, con test dedicati sugli asset.

## Debito tecnico non bloccante

Il file `lib/repositories/pokedex_repositry.dart` conserva un refuso storico nel nome. La correzione richiederebbe l'aggiornamento coordinato di numerosi import senza modificare alcun comportamento. Per minimizzare il rischio immediatamente prima della release, il rinominamento viene rimandato a una modifica isolata successiva.

## Regola di manutenzione

Prima di pubblicare o integrare modifiche devono continuare a passare:

```bash
flutter analyze
flutter test test/data_integrity_test.dart --reporter expanded
flutter test --reporter expanded
flutter build apk --debug
```

Per la release firmata devono inoltre essere configurati i quattro secret Android descritti in `docs/android-release.md`.
