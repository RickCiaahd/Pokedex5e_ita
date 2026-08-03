# Release Windows

La versione Windows di Trainer Atlas 5e può essere distribuita come archivio portatile x64 oppure come pacchetto MSIX destinato al Microsoft Store.

## Identità dell'applicazione

- Nome prodotto: `Trainer Atlas 5e`
- Eseguibile: `Pokedex5eITA.exe`
- Architettura: `Windows x64`
- Versione Flutter corrente: letta da `pubspec.yaml`
- Versione MSIX: conversione automatica `major.minor.patch+build` → `major.minor.patch.build`

## Build Windows locale

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

## Pacchetto MSIX per Microsoft Store

### 1. Riserva il prodotto

Nel Partner Center crea o riserva l'app `Trainer Atlas 5e`, quindi apri la pagina dell'identità del prodotto e annota esattamente:

- Package/Identity/Name;
- Package/Identity/Publisher;
- Publisher display name.

Questi valori sono assegnati da Microsoft e non devono essere inventati né salvati come credenziali.

### 2. Completa gli asset

Inserisci i PNG richiesti in `packaging/msix/Assets/` seguendo nomi e dimensioni documentati in `packaging/msix/README.md`.

Usa soltanto branding e immagini di cui sia verificata la possibilità di ridistribuzione. L'icona desktop tradizionale resta in `windows/runner/resources/app_icon.ico`.

### 3. Genera il pacchetto

Esegui dalla radice della repository:

```powershell
.\tool\build_msix_store.ps1 `
  -IdentityName "VALORE_PACKAGE_IDENTITY_NAME" `
  -Publisher "CN=VALORE_PACKAGE_IDENTITY_PUBLISHER" `
  -PublisherDisplayName "NOME_PUBLISHER_VISUALIZZATO"
```

Lo script:

1. esegue `flutter pub get`, analisi e test;
2. compila `flutter build windows --release`;
3. copia l'intera cartella release in un'area temporanea;
4. genera `AppxManifest.xml` dal template Store;
5. converte automaticamente, per esempio, `1.3.2+8` in `1.3.2.8`;
6. crea il pacchetto tramite `makeappx.exe` del Windows SDK;
7. genera il checksum SHA-256.

Il risultato viene scritto in:

```text
dist\microsoft-store\TrainerAtlas5e-<versione>-x64.msix
```

Per saltare i controlli già eseguiti nella stessa sessione:

```powershell
.\tool\build_msix_store.ps1 ... -SkipChecks
```

È possibile specificare esplicitamente una versione MSIX a quattro componenti con `-Version`, ma normalmente va lasciata derivare da `pubspec.yaml` per evitare disallineamenti.

### 4. Caricamento e certificazione

Il pacchetto generato usa l'identità del Partner Center ed è pensato per essere caricato nella submission dello Store. Non contiene certificati, password o chiavi private e non deve essere firmato con credenziali salvate nella repository.

Prima dell'invio definitivo:

- installa o verifica Windows App Certification Kit;
- esegui i test previsti sul pacchetto;
- prova aggiornamento, persistenza dei dati e disinstallazione;
- completa descrizione, screenshot, classificazione, privacy e contatti nel Partner Center.

Il pacchetto Store potrebbe non essere installabile direttamente con doppio clic prima della firma Microsoft. Per test locali fuori dallo Store usa un certificato di sviluppo separato e non versionato, oppure una submission privata/flight del Partner Center.

## Workflow GitHub Actions

Il workflow `.github/workflows/windows-release.yml` continua a generare lo ZIP portatile e il checksum per le GitHub Release. La generazione MSIX Store resta locale finché i valori d'identità e gli asset definitivi non saranno stati confermati nel Partner Center.

## Installazione dello ZIP portatile

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
- avvio su un secondo PC Windows senza ambiente Flutter installato;
- aggiornamento da una versione precedente senza perdita dei dati Hive;
- disinstallazione e reinstallazione dal canale Store di prova.
