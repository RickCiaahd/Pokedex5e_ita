# Release Windows

La versione Windows di Trainer Atlas 5e viene distribuita come archivio portatile per sistemi Windows x64.

## Identità dell'applicazione

- Nome prodotto: `Trainer Atlas 5e`
- Eseguibile: `Pokedex5eITA.exe`
- Architettura: `Windows x64`
- Formato di distribuzione iniziale: archivio ZIP portatile

## Build locale

Requisiti:

- Windows 10 o 11 a 64 bit;
- Flutter sul canale `stable`;
- Visual Studio 2022 con il carico di lavoro **Sviluppo di applicazioni desktop con C++**;
- componenti CMake e Windows SDK installati tramite Visual Studio Installer.

Comandi:

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter analyze
flutter test test/data_integrity_test.dart
flutter test
flutter build windows --release
```

La cartella distribuibile viene generata in:

```text
build\windows\x64\runner\Release\
```

L'app non può essere distribuita copiando soltanto l'eseguibile: `Pokedex5eITA.exe`, la cartella `data` e tutte le DLL presenti nella cartella di build devono restare insieme.

## Workflow GitHub Actions

Il workflow `.github/workflows/windows-release.yml`:

1. esegue analisi e test su un runner Windows;
2. compila la build release x64;
3. crea `Pokedex5eITA-<versione>-Windows-x64.zip`;
4. genera il relativo checksum SHA-256;
5. carica entrambi come artefatti del workflow;
6. sui tag `v*`, allega i file alla GitHub Release corrispondente.

La versione del tag deve coincidere con la parte semantica della versione in `pubspec.yaml`. Per esempio:

```yaml
version: 1.0.2+3
```

richiede il tag:

```text
v1.0.2
```

## Installazione e avvio

1. scaricare lo ZIP dalla pagina Releases;
2. estrarre interamente la cartella;
3. avviare `Pokedex5eITA.exe`;
4. non spostare il solo eseguibile fuori dalla cartella estratta.

Se Windows segnala l'assenza di `VCRUNTIME` o `MSVCP`, installare Microsoft Visual C++ Redistributable 2015-2022 x64.

## Verifiche manuali

Dopo ogni release Windows controllare almeno:

- avvio dell'app e corretto titolo della finestra;
- nome, icona e proprietà dell'eseguibile;
- creazione e persistenza di un profilo;
- importazione ed esportazione dei backup;
- Pokédex, squadra, PC, Zaino e Battle Companion;
- selezione file e condivisione/esportazione nelle funzioni supportate;
- riapertura dell'app dopo la chiusura completa;
- avvio su un secondo PC Windows senza ambiente Flutter installato.

## Evoluzione futura

Dopo la validazione dello ZIP portatile si potrà aggiungere un installer MSIX firmato. La firma del pacchetto e l'eventuale distribuzione tramite Microsoft Store verranno gestite come passaggio separato.
