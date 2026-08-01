# Stato corrente della pubblicazione Google Play

Ultimo aggiornamento: 1 agosto 2026

Questa pagina riassume lo stato reale del progetto e separa ciò che è già completato dalle attività che richiedono il proprietario dell'account.

## Completato

### Repository e build Android

- `main` contiene la preparazione tecnica della release Android delle PR #165 e #166;
- `compileSdk` e `targetSdk` sono impostati su API 36;
- il supporto alle pagine di memoria da 16 KiB è verificato dalla pipeline;
- APK e AAB release sono validati con `bundletool`;
- minificazione e resource shrinking sono stati collaudati, ma restano disattivati per impostazione predefinita;
- il test di aggiornamento su dispositivo reale è stato superato;
- persistenza Hive e compatibilità dei backup storici sono coperte da test automatici;
- logo, icona Android, splash, caratteri ingranditi e TalkBack sono stati collaudati nella PR #168;
- il nuovo branding è presente in `main` dal merge commit `4a52896686566f368f7b1e77464fa251d2bcdfc6`.

### Firma Android locale

- il keystore di upload definitivo `android/upload-keystore.jks` è stato creato localmente;
- l'alias è `upload` e la chiave è una RSA da 2048 bit;
- `android/upload-keystore.jks` e `android/key.properties` sono esclusi da Git;
- `git status --short` è rimasto pulito durante la verifica;
- una build locale `flutter build appbundle --release` è terminata correttamente;
- l'AAB prodotto è stato firmato con lo stesso certificato del keystore di upload;
- il collaudo locale ha prodotto un AAB di circa 271,3 MB, valore che non coincide con la dimensione effettivamente scaricata dagli utenti e deve essere interpretato tramite `bundletool`.

Il keystore, le password, `key.properties` e qualsiasi rappresentazione Base64 devono restare fuori dalla repository, dalle issue e dagli artefatti pubblici.

### Play Console

- account sviluppatore creato come account personale;
- app **Trainer Atlas 5e** creata come app senza costi;
- package configurato: `io.github.rickciaahd.traineratlas`;
- email pubblica per assistenza e privacy scelta: `rickciaahd.apps@gmail.com`;
- Privacy Policy pubblicata e inserita nella Play Console;
- URL pubblico della Privacy Policy: `https://rickciaahd.github.io/Pokedex5e_ita/privacy.html`;
- sito pubblico del progetto: `https://rickciaahd.github.io/Pokedex5e_ita/`;
- scheda Store italiana compilata con nome e descrizioni predisposte;
- icona Store, feature graphic e screenshot smartphone preparati nella Play Console;
- gli screenshot tablet non sono obbligatori per il salvataggio corrente e vengono rimandati a un collaudo reale su emulatore o dispositivo grande;
- la Dashboard indica il requisito del test chiuso con almeno 12 tester per 14 giorni consecutivi prima della richiesta di accesso alla produzione.

### Preparazione documentale

La PR #166, ora inclusa in `main`, contiene:

- guida operativa per beta interna e chiusa;
- Privacy Policy definitiva con data di entrata in vigore **1 agosto 2026**;
- bozze italiane e inglesi della scheda Store;
- piano per icona Store, feature graphic e screenshot;
- pagina pubblica di licenze e attribuzioni;
- modulo GitHub per il feedback dei tester;
- workflow per APK e AAB firmati con chiave di upload conservata fuori dalla repository.

## Attività ancora richieste al proprietario

### Account e sicurezza

- completare eventuali verifiche residue di identità, email, telefono e dispositivo mostrate dalla Play Console;
- verificare che l'autenticazione a due fattori sia attiva;
- controllare regolarmente la casella pubblica `rickciaahd.apps@gmail.com`;
- conservare almeno due copie cifrate del keystore in luoghi separati;
- salvare password, alias e impronta SHA-256 in un password manager.

### GitHub Actions Secrets

Configurare manualmente, senza pubblicarne i valori:

- `ANDROID_KEYSTORE_BASE64`;
- `ANDROID_STORE_PASSWORD`;
- `ANDROID_KEY_PASSWORD`;
- `ANDROID_KEY_ALIAS`.

Dopo aver creato il valore Base64, eliminare immediatamente il file temporaneo dal computer.

### Documenti e scheda Store

- completare e salvare tutte le dichiarazioni richieste dalla Play Console;
- controllare l'anteprima finale della scheda italiana;
- aggiungere la localizzazione inglese soltanto dopo il controllo di quella italiana;
- verificare che tutti gli screenshot mostrino una build reale, senza dati personali, banner di debug o funzioni non presenti;
- preparare screenshot tablet soltanto dopo un collaudo reale su schermo grande;
- completare o far revisionare l'audit su marchi, licenze e provenienza degli asset prima di una diffusione pubblica ampia.

### Prima beta Android

- aggiornare la versione da `1.3.2+8` a `1.4.0+9`;
- produrre l'AAB firmato definitivo dalla revisione approvata;
- eseguire l'audit `bundletool` sull'artefatto definitivo;
- caricare l'AAB prima nel test interno;
- accettare Play App Signing;
- verificare installazione, avvio, persistenza dei dati e aggiornamento tramite Play Store;
- preparare almeno 12 account Google di tester affidabili senza pubblicarli nella repository;
- avviare il test chiuso e mantenerlo attivo per almeno 14 giorni consecutivi;
- raccogliere feedback senza pubblicare email, backup o dati personali.

## Modello economico corrente

L'app è stata creata su Google Play come **senza costi**.

La build corrente non contiene Google Play Billing, acquisti in-app, abbonamenti o funzioni Premium. Di conseguenza:

- la scheda Store e le dichiarazioni non devono ancora indicare acquisti in-app;
- gli screenshot non devono mostrare o promettere funzioni Premium;
- un eventuale sblocco Premium una tantum dovrà essere progettato, implementato e collaudato in un blocco successivo;
- l'introduzione di pagamenti richiederà aggiornamenti a Privacy Policy, Data Safety, testi dello Store e test della fatturazione.

La scelta iniziale “senza costi” non impedisce in futuro di aggiungere prodotti digitali in-app, ma l'app non deve dichiararli prima che esistano realmente nella build.

## Blocco legale e di conformità

La distribuzione pubblica ampia resta subordinata alla verifica di marchi, regole, immagini e altri asset di terzi.

Per il nuovo branding esiste un registro in `docs/branding/provenance.md`, ma lo stato resta `project-created-pending-proof` finché il proprietario non archivia le evidenze richieste.

La presenza sullo Store di applicazioni simili non costituisce prova di autorizzazione. Prima di monetizzare o ampliare la distribuzione è opportuno far revisionare professionalmente gli aspetti irrisolti.

## Prossima sequenza operativa

1. configurare i quattro GitHub Actions Secrets;
2. aggiornare la versione a `1.4.0+9` nella branch di release;
3. completare CI e revisione della pull request;
4. produrre e verificare l'AAB firmato definitivo;
5. avviare il test interno;
6. collaudare installazione e aggiornamento dal Play Store;
7. avviare il test chiuso con i tester previsti.
