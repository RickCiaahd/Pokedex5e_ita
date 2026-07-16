# Audit di pulizia del progetto

Audit eseguito prima della release Android `1.0.0`.

## Risultato

- analizzati 129 file Dart in `lib/`;
- individuati tre file non raggiungibili da `lib/main.dart`;
- rimossi l'inizializzatore Hive duplicato, la vecchia schermata di creazione profilo e il prototipo del calcolatore di cattura con il relativo test;
- aggiornata la descrizione del pacchetto Flutter, eliminando il testo generico del progetto iniziale;
- nessun file di build, cache, keystore o configurazione privata risulta versionato;
- nessun `TODO`, `FIXME`, `HACK` o `XXX` è presente nel codice applicativo e nei test;
- verificati 8.222 asset per circa 317,6 MiB.

## Asset

Sono presenti otto piccoli gruppi di file byte-identici, per circa 315,7 KiB complessivi. Non sono stati eliminati perché i percorsi degli sprite e delle forme vengono spesso costruiti dinamicamente dai cataloghi JSON. Tra i duplicati figurano varianti di Minior, alias di Nidoran e Oricorio e immagini segnaposto: rimuoverli senza normalizzare prima dati, alias e fallback potrebbe introdurre immagini mancanti.

La dimensione dell'APK dipende quindi soprattutto dal catalogo grafico completo, non da file temporanei o copie chiaramente inutili. Un'eventuale riduzione sostanziale richiederà un intervento dedicato di ottimizzazione o distribuzione selettiva degli asset, separato dalla pulizia conservativa del codice.

## Regola di manutenzione

Dopo ogni rimozione o riorganizzazione devono continuare a passare:

```bash
flutter analyze
flutter test test/data_integrity_test.dart --reporter expanded
flutter test --reporter expanded
flutter build apk --debug
```
