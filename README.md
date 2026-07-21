# Pokédex 5e ITA

[![Flutter CI](https://github.com/RickCiaahd/Pokedex5e_ita/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/RickCiaahd/Pokedex5e_ita/actions/workflows/flutter-ci.yml)

Companion non ufficiale in italiano per campagne Pokémon 5e, sviluppato con Flutter per Web, Windows e Android.

L'app raccoglie in un unico progetto gli strumenti principali per giocatori e Master:

- Pokédex con specie, forme, statistiche, mosse, abilità e sprite;
- profili Allenatore, squadra attiva e Pokémon Center;
- inventario, gestione delle Poké Ball e registrazione delle catture;
- Battle Companion per il giocatore;
- generatori di Pokémon, incontri e Allenatori PNG;
- librerie persistenti di incontri e Allenatori;
- Fight del Master con più Allenatori, iniziativa, PF, PP e status;
- backup e ripristino dei dati del profilo;
- esportazione, importazione e condivisione nativa di Pokémon, squadre, incontri e Allenatori PNG, oltre al riepilogo testuale del Fight del Master.

## Stato del progetto

Il progetto è in sviluppo attivo. Le modifiche vengono controllate automaticamente tramite GitHub Actions con:

```bash
flutter analyze
flutter test test/data_integrity_test.dart
flutter test
flutter build apk --debug
flutter build windows --release
```

Il test di integrità verifica i file sorgente del catalogo, gli identificatori, le statistiche minime, le forme e la presenza di almeno un'immagine utilizzabile per ogni specie. Le pipeline verificano inoltre che il progetto continui a compilare come applicazione Android e Windows.

## Requisiti

- Flutter sul canale `stable`;
- SDK Dart compatibile con il vincolo dichiarato in `pubspec.yaml`;
- toolchain della piattaforma che si vuole compilare.

## Avvio locale

```bash
git clone https://github.com/RickCiaahd/Pokedex5e_ita.git
cd Pokedex5e_ita
flutter pub get
flutter run
```

Per scegliere una piattaforma specifica:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d <id-dispositivo-android>
```

## Controlli prima di una modifica

```bash
flutter analyze
flutter test test/data_integrity_test.dart
flutter test
flutter build apk --debug
```

Su un computer Windows con Visual Studio e il workload desktop C++ configurato:

```powershell
flutter build windows --release
```

Quando vengono aggiunti Pokémon, forme, mosse, abilità o asset, il test di integrità deve continuare a essere superato.

## Release Android

L'app Android usa il nome `Pokédex 5e ITA` e l'Application ID definitivo `io.github.rickciaahd.pokedex5eita`.

La guida completa per creare il keystore, configurare i secret GitHub e generare APK/AAB firmati è disponibile in [`docs/android-release.md`](docs/android-release.md).

Il workflow `Android release` può essere avviato manualmente dopo la configurazione dei secret. Un tag `v*` genera APK, AAB e checksum SHA-256 e li allega alla GitHub Release.

## Release Windows

L'app Windows usa il titolo `Pokédex 5e ITA` e l'eseguibile `Pokedex5eITA.exe`. Viene distribuita inizialmente come archivio ZIP portatile x64 contenente l'intera cartella necessaria all'avvio.

La guida di compilazione e distribuzione è disponibile in [`docs/windows-release.md`](docs/windows-release.md).

Il workflow `Windows release` esegue analisi, test e build su Windows, crea lo ZIP portatile e il checksum SHA-256 e, sui tag `v*`, li allega alla stessa GitHub Release delle build Android.

## Dati e salvataggi

I dati applicativi sono salvati localmente tramite Hive. La schermata Profili permette di esportare e importare backup JSON, compresi squadra, Pokémon Center, inventario, impostazioni e sessioni di combattimento supportate.

Dalla schermata Squadra è inoltre possibile esportare, importare e condividere singoli Pokémon o una formazione completa senza sostituire l’intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC. Le librerie del Master supportano file portabili e condivisione diretta per incontri e Allenatori PNG, mentre il Fight del Master può salvare o condividere un riepilogo testuale con round, iniziativa, PF, status e PP. Sul Web, quando il menu nativo non è disponibile, il file viene scaricato dal browser.

## Avvertenza

Questo è un progetto amatoriale e non ufficiale. Pokémon e i relativi nomi, personaggi e immagini appartengono ai rispettivi titolari. Il progetto non è affiliato, sponsorizzato o approvato da Nintendo, Game Freak, Creatures Inc. o The Pokémon Company.
