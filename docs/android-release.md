# Release Android

## Identità applicazione

- Nome visibile: `Pokédex 5e ITA`
- Application ID: `io.github.rickciaahd.pokedex5eita`
- Versione corrente: `1.0.1+2`

L'Application ID è definitivo: cambiarlo dopo la distribuzione farebbe installare Android una seconda applicazione invece di aggiornare quella esistente.

Le vecchie build di sviluppo usavano `com.example.pokedex_5e_ita`. Per trasferire i dati da quelle build bisogna esportare un backup dalla vecchia app e importarlo nella nuova.

## Creazione del keystore

Dalla radice del progetto:

```bash
keytool -genkeypair -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Conservare il file e le password in un luogo sicuro. Perdere il keystore impedisce di pubblicare aggiornamenti firmati con la stessa identità.

Copiare il modello:

```bash
cp android/key.properties.example android/key.properties
```

Su PowerShell:

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Compilare `android/key.properties` con password e alias reali. `android/key.properties` e i file `.jks` sono esclusi da Git e non devono essere caricati nel repository.

## Verifiche locali

```bash
flutter clean
flutter pub get
flutter analyze
flutter test test/data_integrity_test.dart --reporter expanded
flutter test --reporter expanded
flutter build apk --debug
```

## Build firmate

```bash
flutter build apk --release
flutter build appbundle --release
```

Output:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

L'APK serve per installazione diretta. L'AAB è il formato da conservare per una futura pubblicazione sul Play Store.

## GitHub Actions

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

Copiare il contenuto del file nel secret `ANDROID_KEYSTORE_BASE64`, poi eliminare il file testuale locale.

Il workflow può essere eseguito manualmente. Creando un tag come `v1.0.1`, pubblica inoltre una GitHub Release con APK e AAB firmati.

## Checklist dispositivo

1. Esportare un backup dalla build usata finora.
2. Installare l'APK release su un dispositivo Android reale.
3. Avviare l'app e verificare nome, icona e splash screen.
4. Importare il backup e controllare profilo, squadra, PC, zaino, uova e sessioni.
5. Provare condivisione, esportazione e importazione di un file.
6. Installare una build con `versionCode` maggiore sopra la release e verificare che i dati restino presenti.
7. Conservare APK, AAB, keystore e password in copie separate e sicure.
