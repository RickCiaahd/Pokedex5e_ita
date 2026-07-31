# Release Android e Google Play

## Stato corrente

- Nome visibile: `Trainer Atlas 5e`
- Application ID definitivo: `io.github.rickciaahd.traineratlas`
- Versione corrente: `1.3.2+8`
- `compileSdk`: Android 16 (API 36)
- `targetSdk`: Android 16 (API 36)
- Flutter bloccato in CI: `3.44.4`
- Java: 17

L'Application ID è definitivo: cambiarlo dopo la distribuzione farebbe installare Android una seconda applicazione invece di aggiornare quella esistente.

Le vecchie build di sviluppo che usavano `com.example.pokedex_5e_ita` non possono essere aggiornate direttamente dalla nuova applicazione. Per trasferire i dati da quelle build bisogna esportare un backup dalla vecchia app e importarlo in Trainer Atlas 5e.

## Requisiti Google Play verificati

Dal 31 agosto 2026 Google Play richiede che le nuove app e gli aggiornamenti abbiano come target Android 16, API 36. Il progetto imposta quindi esplicitamente sia `compileSdk` sia `targetSdk` a 36, senza dipendere dal valore predefinito della versione Flutter installata.

Google Play richiede inoltre il supporto alle pagine di memoria da 16 KiB per le app che includono codice nativo e hanno come target Android 15 o versioni successive. La configurazione Android usa il packaging moderno delle librerie native e la pipeline di preparazione release controlla:

- `PAGE_ALIGNMENT_16K` nella configurazione dell'App Bundle;
- l'allineamento ZIP a 16 KiB degli APK generati da `bundletool`;
- il manifest finale dell'AAB, incluso `targetSdkVersion=36`;
- la validità del bundle prima della pubblicazione.

Fonti ufficiali:

- [Requisiti relativi al livello API target di Google Play](https://developer.android.com/google/play/requirements/target-sdk?hl=it)
- [Supportare dimensioni pagina di 16 KB](https://developer.android.com/guide/practices/page-sizes?hl=it)
- [Documentazione di bundletool](https://developer.android.com/tools/bundletool)

I requisiti devono essere ricontrollati immediatamente prima del caricamento in Play Console, perché Google può aggiornarli nel tempo.

## Firma release

### Creazione del keystore di upload

Dalla radice del progetto:

```bash
keytool -genkeypair -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Conservare il file e le password in almeno due luoghi sicuri e separati. Il keystore di upload non deve mai essere inserito nella repository, allegato a issue o PR, copiato nei log o distribuito con gli artefatti.

Copiare il modello:

```bash
cp android/key.properties.example android/key.properties
```

Su PowerShell:

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Compilare `android/key.properties` con password, alias e percorso reali. `android/key.properties`, `*.jks` e `*.keystore` sono esclusi da Git.

Per Google Play è consigliato usare Play App Signing: il keystore locale o configurato nei secret GitHub resta la chiave di upload, mentre Google custodisce la chiave con cui vengono firmati gli APK distribuiti agli utenti. Prima della prima pubblicazione bisogna conservare anche i certificati e le informazioni richieste dalla Play Console.

### GitHub Actions

Il workflow `Android release` richiede questi repository secret:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Per creare il contenuto Base64 su PowerShell:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("android/upload-keystore.jks")
) | Set-Content -NoNewline android-keystore-base64.txt
```

Copiare il contenuto nel secret `ANDROID_KEYSTORE_BASE64`, poi eliminare il file testuale locale. Le chiavi temporanee create dai workflow di audit servono soltanto a collaudare la build e non devono essere usate per una release pubblica.

## Verifiche locali di base

```bash
flutter clean
flutter pub get
python tooling/generate_compliance_reports.py --check
python tooling/prepare_release_legal_assets.py
python tooling/prepare_release_legal_assets.py --check
flutter analyze
flutter test test/data_integrity_test.dart --reporter expanded
flutter test --reporter expanded
flutter build apk --debug
```

## Build release non minificata

La configurazione di produzione mantiene inizialmente disattivati R8 e resource shrinking. Questa è la variante di riferimento già collaudata funzionalmente:

```bash
flutter build apk --release
flutter build appbundle --release
```

Output:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

L'APK serve per il collaudo diretto. L'AAB è il formato da caricare su Google Play.

## Test sicuro di minificazione e resource shrinking

R8 e resource shrinking sono configurati, ma restano **opt-in** finché la variante ottimizzata non supera CI e collaudo di aggiornamento sul telefono. Non sono presenti regole globali che conservino indiscriminatamente tutte le classi, perché renderebbero il test poco significativo.

Linux o macOS:

```bash
export ORG_GRADLE_PROJECT_trainerAtlasEnableReleaseShrinking=true
flutter clean
flutter pub get
python tooling/prepare_release_legal_assets.py
flutter build apk --release
flutter build appbundle --release
```

PowerShell:

```powershell
$env:ORG_GRADLE_PROJECT_trainerAtlasEnableReleaseShrinking = 'true'
flutter clean
flutter pub get
python tooling/prepare_release_legal_assets.py
flutter build apk --release
flutter build appbundle --release
Remove-Item Env:ORG_GRADLE_PROJECT_trainerAtlasEnableReleaseShrinking
```

L'attivazione non va salvata stabilmente prima del collaudo finale. Una build che compila non è sufficiente: devono funzionare apertura dell'app, profili, cataloghi, condivisione, importazione/esportazione, selezione file e tutte le funzioni che passano attraverso plugin Android.

## Audit automatico con bundletool

Il workflow `Android release readiness` usa `bundletool 1.18.3`, costruisce sia la variante di riferimento sia quella ottimizzata e riproduce la consegna di Google Play per un dispositivo Android API 36 arm64. Il report pubblicato come artefatto contiene:

- dimensione reale dell'APK release;
- dimensione reale dell'AAB;
- stima `bundletool get-size total` per il dispositivo simulato;
- manifest finale e configurazione del bundle;
- confronto tra build non minificata e minificata.

La dimensione scaricata varia in base ad ABI, densità, lingua e versione Android: per questo il semplice peso dell'AAB non rappresenta da solo ciò che riceverà ogni utente.

Comandi principali eseguiti dalla pipeline:

```bash
java -jar bundletool.jar validate --bundle=app-release.aab
java -jar bundletool.jar dump manifest --bundle=app-release.aab --module=base
java -jar bundletool.jar dump config --bundle=app-release.aab
java -jar bundletool.jar build-apks \
  --bundle=app-release.aab \
  --output=trainer-atlas.apks \
  --device-spec=device-spec-api36-arm64.json \
  --ks=upload-keystore.jks \
  --ks-key-alias=upload
java -jar bundletool.jar get-size total \
  --apks=trainer-atlas.apks \
  --device-spec=device-spec-api36-arm64.json
```

Le password non vanno inserite nei comandi salvati nella repository. In CI vengono usate soltanto credenziali temporanee per l'audit o secret protetti per la release reale.

## Icona e splash screen

La configurazione comprende:

- icona adattiva Android con sfondo rosso e simbolo Poké Ball vettoriale;
- icona tonda collegata alla stessa risorsa;
- splash legacy bianco con icona centrata;
- splash di sistema Android 12 e successivi coerente con la stessa icona e gli stessi colori.

La pipeline verifica la presenza e i riferimenti delle risorse, ma non può sostituire il controllo visivo su un telefono reale. Prima del merge bisogna verificare che icona e splash non risultino tagliati, troppo piccoli, deformati o circondati da margini inattesi sul launcher del dispositivo.

## Aggiornamento e persistenza dei dati

I test automatici coprono due aspetti distinti:

1. chiusura e riapertura dello stesso archivio Hive, verificando che profilo attivo, squadra, zaino e impostazioni rimangano invariati;
2. decodifica dei formati backup storici da 1 a 5, oltre al formato corrente 6, con valori predefiniti per le sezioni introdotte successivamente.

L'importazione è transazionale a livello applicativo: se la scrittura fallisce, il servizio tenta di ripristinare il profilo precedente o elimina il profilo parziale appena creato.

Restano obbligatori due collaudi reali prima del merge:

- installare una build con `versionCode` maggiore sopra una release precedente con lo stesso Application ID e la stessa firma, senza disinstallare l'app;
- importare almeno un backup reale creato da una vecchia versione e verificare tutte le sezioni presenti.

## Checklist dispositivo Android

1. Conservare un backup esportato dalla versione installata e annotare versione, Application ID e firma usata.
2. Creare un profilo di prova con squadra, PC, zaino, impostazioni, uova, incontri, Allenatori PNG ed eventuale battaglia salvata.
3. Installare l'APK release di riferimento senza disinstallare la versione precedente.
4. Verificare che profilo attivo e dati locali siano rimasti presenti.
5. Controllare nome, icona adattiva, icona tonda e splash screen.
6. Provare cataloghi, ricerca, immagini offline, selezione file, condivisione, esportazione e importazione.
7. Importare un vecchio backup reale prima come nuovo profilo e poi, dopo un secondo backup di sicurezza, come sostituzione di un profilo esistente.
8. Ripetere i punti 3–7 con la variante minificata e confrontare il comportamento.
9. Verificare che la versione con `versionCode` maggiore venga riconosciuta come aggiornamento.
10. Conservare APK, AAB, report `bundletool`, checksum, keystore e password in copie separate e sicure.

## Criteri per abilitare definitivamente lo shrinking

R8 e resource shrinking possono diventare la configurazione predefinita soltanto quando:

- la pipeline `Android release readiness` è verde;
- il report mostra una riduzione utile o almeno nessuna regressione anomala;
- il collaudo di aggiornamento non perde dati;
- i backup storici reali vengono importati correttamente;
- non mancano immagini, risorse native, schermate o funzioni basate su plugin;
- icona e splash sono stati approvati sul dispositivo.

Fino ad allora la release pubblicabile resta quella non minificata.
