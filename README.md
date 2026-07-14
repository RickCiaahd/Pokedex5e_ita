# Pokédex 5e ITA

[![Flutter CI](https://github.com/RickCiaahd/Pokedex5e_ita/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/RickCiaahd/Pokedex5e_ita/actions/workflows/flutter-ci.yml)

Companion non ufficiale in italiano per campagne Pokémon 5e, sviluppato con Flutter per Web, Windows e Android.

L'app raccoglie in un unico progetto gli strumenti principali per giocatori e Master:

- Pokédex con specie, forme, statistiche, mosse, abilità e sprite;
- profili Allenatore, squadra attiva e Pokémon Center;
- inventario e calcolatore di cattura;
- Battle Companion per il giocatore;
- generatori di Pokémon, incontri e Allenatori PNG;
- librerie persistenti di incontri e Allenatori;
- Fight del Master con più Allenatori, iniziativa, PF, PP e status;
- backup completi del profilo e trasferimenti mirati di Pokémon e squadre.

## Stato del progetto

Il progetto è in sviluppo attivo. Le modifiche vengono controllate automaticamente tramite GitHub Actions con:

```bash
flutter analyze
flutter test test/data_integrity_test.dart
flutter test
```

Il test di integrità verifica i file sorgente del catalogo, gli identificatori, le statistiche minime, le forme e la presenza di almeno un'immagine utilizzabile per ogni specie.

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
```

Quando vengono aggiunti Pokémon, forme, mosse, abilità o asset, il test di integrità deve continuare a essere superato.

## Dati e salvataggi

I dati applicativi sono salvati localmente tramite Hive. La schermata Profili permette di esportare e importare backup JSON, compresi squadra, Pokémon Center, inventario, impostazioni e sessioni di combattimento supportate.

Dalla schermata Squadra è inoltre possibile esportare e importare singoli Pokémon o una formazione completa senza sostituire l'intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC.

## Avvertenza

Questo è un progetto amatoriale e non ufficiale. Pokémon e i relativi nomi, personaggi e immagini appartengono ai rispettivi titolari. Il progetto non è affiliato, sponsorizzato o approvato da Nintendo, Game Freak, Creatures Inc. o The Pokémon Company.
