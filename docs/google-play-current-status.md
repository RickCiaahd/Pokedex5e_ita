# Stato corrente della pubblicazione Google Play

Ultimo aggiornamento: 1 agosto 2026

Questa pagina riassume lo stato reale del progetto e separa ciò che è già completato dalle attività che richiedono il proprietario dell'account.

## Completato

### Repository e build Android

- `main` contiene la preparazione tecnica della release Android della PR #165;
- `compileSdk` e `targetSdk` sono impostati su API 36;
- il supporto alle pagine di memoria da 16 KiB è verificato dalla pipeline;
- APK e AAB release sono validati con `bundletool`;
- minificazione e resource shrinking sono stati collaudati, ma restano disattivati per impostazione predefinita;
- il test di aggiornamento su dispositivo reale è stato superato;
- persistenza Hive e compatibilità dei backup storici sono coperte da test automatici;
- logo, icona Android, splash, caratteri ingranditi e TalkBack sono stati collaudati nella PR #168;
- il nuovo branding è presente in `main` dal merge commit `4a52896686566f368f7b1e77464fa251d2bcdfc6`.

### Play Console

- account sviluppatore creato come account personale;
- app **Trainer Atlas 5e** creata come app senza costi;
- package configurato: `io.github.rickciaahd.traineratlas`;
- email pubblica per assistenza e privacy scelta: `rickciaahd.apps@gmail.com`;
- la Dashboard indica il requisito del test chiuso con almeno 12 tester per 14 giorni consecutivi prima della richiesta di accesso alla produzione.

### Preparazione documentale

La PR #166 contiene:

- guida operativa per beta interna e chiusa;
- Privacy Policy predisposta per GitHub Pages e aggiornata con il contatto pubblico;
- bozze italiane e inglesi della scheda Store;
- piano per icona Store, feature graphic e screenshot;
- pagina pubblica di licenze e attribuzioni;
- modulo GitHub per il feedback dei tester;
- workflow per APK e AAB firmati con chiave di upload conservata fuori dalla repository.

Il branch della PR #166 è stato sincronizzato con il nuovo `main` tramite la PR #169 e la CI combinata è terminata con successo.

## Attività ancora richieste al proprietario

### Account e contatti

- completare eventuali verifiche residue di identità, email, telefono e dispositivo mostrate dalla Play Console;
- verificare che l'autenticazione a due fattori sia attiva;
- controllare regolarmente la casella pubblica `rickciaahd.apps@gmail.com`.

### Firma Android

- creare localmente il keystore di upload definitivo;
- conservarne almeno due copie cifrate in luoghi separati;
- salvare password, alias e impronta SHA-256 in un password manager;
- configurare i quattro GitHub Actions Secrets;
- non inserire mai keystore, password, file Base64 o `key.properties` nella repository.

### Documenti e scheda Store

- finalizzare la data di entrata in vigore della Privacy Policy;
- unire la PR #166 e pubblicare la cartella `/docs` tramite GitHub Pages;
- verificare l'URL pubblico da una finestra anonima;
- completare accesso all'app, annunci, pubblico di destinazione, classificazione IARC e Data Safety;
- esportare l'icona Store 512 × 512 dalla sorgente del branding;
- creare la feature graphic 1024 × 500;
- preparare screenshot italiani e inglesi da una build distribuita tramite Google Play.

### Beta

- generare l'AAB firmato definitivo con un nuovo `versionCode`;
- caricarlo prima nel test interno;
- verificare installazione e aggiornamento tramite Play Store;
- preparare almeno 12 account Google di tester affidabili;
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

1. finalizzare Privacy Policy e testi Store;
2. unire la PR #166 con autorizzazione esplicita;
3. abilitare GitHub Pages;
4. creare keystore e secret;
5. aggiornare versione e `versionCode`;
6. produrre l'AAB firmato;
7. avviare test interno e poi test chiuso.
