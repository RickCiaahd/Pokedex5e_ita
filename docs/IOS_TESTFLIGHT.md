# Distribuzione iOS di test con TestFlight

Questo progetto dispone di due workflow separati:

- `iOS Build`: verifica che l'app compili su iOS e produce una `Runner.app` non firmata.
- `iOS TestFlight`: crea un archivio firmato tramite Apple Developer e lo carica su App Store Connect/TestFlight.

## Prerequisiti Apple

Per distribuire l'app a tester esterni tramite TestFlight serve un'iscrizione attiva all'Apple Developer Program.

Prima del primo upload:

1. registra un Bundle ID esplicito nella sezione Certificates, Identifiers & Profiles di Apple Developer;
2. crea in App Store Connect una nuova app iOS usando esattamente lo stesso Bundle ID;
3. annota il Team ID dell'account Apple Developer;
4. in App Store Connect, se necessario, richiedi/abilita l'accesso alle API;
5. crea una **Team API Key** in `Users and Access > Integrations` con privilegi adatti alla distribuzione e scarica una volta il file `.p8`.

Il Bundle ID attuale del progetto Flutter (`com.example.pokedex5eIta`) è solo un valore di sviluppo. Il workflow TestFlight lo sostituisce durante la build con il Bundle ID passato manualmente al workflow, senza richiedere di salvare dati Apple nella repository.

## GitHub Secrets richiesti

Nella repository apri `Settings > Secrets and variables > Actions` e crea questi Repository secrets:

- `APP_STORE_CONNECT_KEY_ID`: Key ID della Team API Key.
- `APP_STORE_CONNECT_ISSUER_ID`: Issuer ID mostrato in App Store Connect.
- `APP_STORE_CONNECT_PRIVATE_KEY_BASE64`: contenuto del file `.p8` codificato in Base64.

Non committare mai il file `.p8` nella repository.

### Codificare il file .p8 in Base64

Su PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8"))
```

Copia l'intera stringa risultante nel secret `APP_STORE_CONNECT_PRIVATE_KEY_BASE64`.

## Avviare il primo upload

Apri `Actions > iOS TestFlight > Run workflow`, seleziona il branch desiderato e inserisci:

- `bundle_id`: il Bundle ID registrato su Apple Developer, ad esempio `com.rickciaahd.pokedex5eita`;
- `team_id`: il Team ID Apple Developer.

Il workflow:

1. prepara Flutter 3.44.4 e le dipendenze;
2. verifica i report di conformità e prepara gli asset legali;
3. genera i file iOS Flutter;
4. usa `xcodebuild` con firma automatica e App Store Connect API key;
5. crea un archivio iOS Release;
6. esporta e carica direttamente l'archivio su App Store Connect.

Il build number iOS usa automaticamente il numero progressivo del run GitHub Actions, evitando di riutilizzare lo stesso build number nei successivi upload del workflow.

## Dare l'app a un amico

Dopo che il build è stato elaborato da App Store Connect:

1. apri l'app in App Store Connect;
2. vai su `TestFlight`;
3. crea prima un gruppo di tester interni se richiesto da App Store Connect;
4. crea un gruppo di `External Testing`;
5. aggiungi il build appena caricato;
6. compila le informazioni richieste per il beta testing e invia il build a TestFlight App Review;
7. dopo l'approvazione, invita il tester tramite email oppure crea un public link;
8. il tester installa l'app gratuita TestFlight dall'App Store e accetta l'invito.

I build TestFlight restano disponibili ai tester per il periodo previsto da Apple e possono essere sostituiti con nuovi build senza pubblicare l'app sull'App Store.

## Sicurezza

Nessun certificato, API key, password o provisioning profile deve essere aggiunto ai file versionati. Il workflow legge le credenziali esclusivamente dai GitHub Secrets e scrive la chiave privata solo nel filesystem temporaneo del runner macOS.
