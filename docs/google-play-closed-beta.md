# Beta chiusa Google Play — guida operativa

Ultimo aggiornamento: 31 luglio 2026

## Stato tecnico di partenza

Il repository è già predisposto per una prima distribuzione Android controllata:

- nome pubblico: **Trainer Atlas 5e**;
- Application ID: `io.github.rickciaahd.traineratlas`;
- versione corrente: `1.3.2+8`;
- `compileSdk` e `targetSdk`: Android 16 / API 36;
- supporto alle pagine di memoria da 16 KiB verificato nella pipeline;
- AAB validato con `bundletool`;
- test di aggiornamento sul dispositivo reale superato;
- persistenza Hive e compatibilità dei backup storici coperte da test automatici;
- icona e splash verificati sul dispositivo;
- minificazione e resource shrinking collaudati, ma ancora disattivati per impostazione predefinita;
- build release firmata predisposta tramite secret GitHub, senza credenziali nella repository.

La prima beta deve usare inizialmente la variante **non minificata**, già scelta come configurazione prudente di riferimento. Lo shrinking potrà essere rivalutato in una release successiva: nel test corrente il guadagno sul download simulato è stato circa dell'1%.

## Cosa richiede un intervento del proprietario

Le seguenti operazioni non possono essere automatizzate o conservate nella repository:

1. creare e verificare l'account Google Play Console;
2. definire un indirizzo email pubblico e stabile per assistenza e privacy;
3. creare e custodire la chiave di upload definitiva;
4. aggiungere le credenziali come GitHub Actions Secrets;
5. abilitare un URL pubblico stabile per la Privacy Policy;
6. prendere le decisioni dichiarative su pubblico di destinazione e classificazione dei contenuti;
7. fornire gli indirizzi Google dei tester;
8. caricare e inviare l'AAB in Play Console;
9. approvare le dichiarazioni legali e le condizioni di Play App Signing.

Nessun keystore, password, file `key.properties` o valore Base64 deve essere aggiunto a commit, issue, pull request, log o artefatti pubblici.

## 1. Account Play Console

### Tipo di account

Per questo progetto amatoriale, salvo diversa organizzazione giuridica, il tipo normalmente coerente è **account personale**. Google richiede comunque nome legale, indirizzo, recapiti e profilo pagamenti verificabili.

Gli account personali recenti possono dover:

- verificare l'identità;
- verificare un numero di telefono e un indirizzo email;
- dimostrare l'accesso a un dispositivo Android reale tramite l'app Play Console;
- completare un test chiuso prima di chiedere l'accesso alla produzione.

Non utilizzare dati fittizi o temporanei.

## 2. Creazione dell'app in Play Console

In Play Console selezionare **Home > Crea app** e usare:

- lingua predefinita: **Italiano — Italia**;
- nome: **Trainer Atlas 5e**;
- tipo: **App**;
- prezzo iniziale: **Gratis**;
- email di contatto: indirizzo pubblico e stabile dedicato al progetto;
- Play App Signing: accettare i termini e lasciare a Google la custodia della chiave di firma dell'app.

L'Application ID effettivo verrà letto dal primo AAB caricato e deve risultare:

```text
io.github.rickciaahd.traineratlas
```

Non creare una seconda app con un package diverso e non modificare l'Application ID dopo il primo caricamento.

## 3. Chiave di upload definitiva

### Creazione su Windows PowerShell

Dalla radice del repository:

```powershell
keytool -genkeypair -v `
  -keystore android/upload-keystore.jks `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload
```

Annotare in un password manager:

- password del keystore;
- password della chiave;
- alias, consigliato `upload`;
- data di creazione;
- impronta SHA-256 del certificato.

Visualizzare le impronte:

```powershell
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Conservare almeno due copie cifrate del file `android/upload-keystore.jks`, in luoghi separati. Il file locale è già escluso da Git, ma va comunque verificato con:

```powershell
git status --short
```

Il keystore non deve comparire nell'output.

### Configurazione locale

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Compilare `android/key.properties` esclusivamente in locale:

```properties
storePassword=PASSWORD_KEYSTORE
keyPassword=PASSWORD_CHIAVE
keyAlias=upload
storeFile=../upload-keystore.jks
```

Verificare nuovamente:

```powershell
git status --short
```

Né `android/key.properties` né il keystore devono apparire tra i file versionati.

## 4. Secret GitHub Actions

Generare il Base64 su Windows:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("android/upload-keystore.jks")
) | Set-Content -NoNewline android-keystore-base64.txt
```

Nel repository GitHub aprire:

**Settings > Secrets and variables > Actions > New repository secret**

Aggiungere esattamente:

- `ANDROID_KEYSTORE_BASE64`: contenuto completo di `android-keystore-base64.txt`;
- `ANDROID_STORE_PASSWORD`: password del keystore;
- `ANDROID_KEY_PASSWORD`: password della chiave;
- `ANDROID_KEY_ALIAS`: `upload`, salvo alias differente scelto in creazione.

Dopo aver salvato il secret Base64:

```powershell
Remove-Item android-keystore-base64.txt
```

Non incollare mai i valori in chat, issue o pull request.

## 5. Versione della prima beta

La versione attuale è `1.3.2+8`. Prima della generazione del candidato definitivo va scelta una versione dedicata alla beta.

Proposta:

```yaml
version: 1.4.0+9
```

Regole:

- la parte prima di `+` è la versione visibile;
- il numero dopo `+` è il `versionCode` Android;
- ogni AAB successivo caricato su Google Play deve usare un `versionCode` maggiore;
- non riutilizzare `+9` dopo averlo caricato, anche se la release viene scartata.

L'aggiornamento del numero versione deve avvenire in una PR dedicata o nella PR finale della beta, soltanto quando la configurazione Play Console e la chiave definitiva sono pronte.

## 6. Generazione dell'AAB firmato

Dopo aver configurato i quattro secret:

1. aprire la scheda **Actions** del repository;
2. scegliere il workflow **Android release**;
3. selezionare **Run workflow**;
4. scegliere il branch della release;
5. attendere il completamento di analisi, test e build;
6. scaricare l'artefatto Android firmato;
7. conservare AAB, APK, `SHA256SUMS.txt`, `LICENSE` e `NOTICE.md`.

L'AAB da caricare in Play Console è quello prodotto dalla pipeline con la chiave definitiva, non gli AAB o APK firmati con la chiave temporanea dei workflow di audit.

Prima del caricamento verificare:

```powershell
keytool -printcert -jarfile percorso\TrainerAtlas5e-1.4.0.aab
```

Confrontare l'impronta del certificato con quella annotata durante la creazione della chiave di upload.

## 7. Privacy Policy pubblica

Google Play richiede una Privacy Policy accessibile pubblicamente e coerente con la sezione Data Safety.

Il testo sorgente è in:

```text
docs/privacy-policy.md
```

Per pubblicarlo tramite GitHub Pages:

1. completare nel documento l'indirizzo email privacy/assistenza;
2. unire la configurazione Pages preparata nella repository;
3. aprire **Settings > Pages**;
4. in **Build and deployment** scegliere **Deploy from a branch**;
5. selezionare `main` e cartella `/docs`;
6. salvare e attendere il deployment;
7. aprire l'URL pubblicato in una finestra anonima;
8. verificare che non richieda login e che sia leggibile da telefono;
9. inserire quell'URL nel campo Privacy Policy della Play Console e nella documentazione di release.

Prima della beta va eliminata dal testo la dicitura di bozza e va inserita una data di entrata in vigore reale.

## 8. Scheda dello Store

Usare le bozze italiane e inglesi presenti nella repository. I limiti correnti sono:

- titolo: massimo 30 caratteri;
- descrizione breve: massimo 80 caratteri;
- descrizione completa: massimo 4000 caratteri.

Risorse grafiche principali:

- icona Play Store: PNG 32 bit, 512 × 512 px, massimo 1024 KB;
- grafica in primo piano: JPEG o PNG 24 bit senza trasparenza, 1024 × 500 px;
- screenshot telefono: catture reali dell'app, senza cornici o dichiarazioni ingannevoli.

Le grafiche devono evitare di suggerire che l'app sia ufficiale o affiliata a titolari di marchi terzi. La natura non ufficiale deve risultare chiara nei testi e nelle attribuzioni.

## 9. Contenuti app e dichiarazioni

In **Norme > Contenuti app** completare almeno:

- Privacy Policy;
- presenza di annunci: **No**, finché la build non integra pubblicità;
- accesso all'app: nessun account o credenziale richiesta;
- pubblico di destinazione e contenuti;
- classificazione dei contenuti IARC;
- Data Safety;
- eventuali dichiarazioni aggiuntive mostrate dalla Console.

### Pubblico di destinazione

Selezionare soltanto fasce d'età per cui l'app è realmente progettata. Non includere automaticamente bambini sotto i 13 anni soltanto perché i contenuti richiamano creature tascabili: includere minori può attivare obblighi aggiuntivi delle norme Famiglie.

La scelta finale spetta al proprietario e deve essere coerente con:

- interfaccia e linguaggio;
- possibilità di esportare o condividere file;
- contenuti delle immagini;
- modalità di utilizzo in campagne da tavolo;
- Privacy Policy e classificazione IARC.

### Data Safety

La bozza tecnica attuale indica:

- nessun account online;
- nessuna pubblicità;
- nessun analytics o Crashlytics;
- dati di gioco conservati localmente;
- nessun permesso Android `INTERNET` nella build corrente;
- condivisione ed esportazione avviate esplicitamente dall'utente.

La risposta finale deve essere confrontata con l'AAB effettivamente caricato, i plugin inclusi e un controllo runtime del traffico. Non selezionare risposte definitive basandosi soltanto sul codice Dart.

## 10. Test interno

È consigliato iniziare dal canale **Test interno**:

1. aprire **Test e release > Test > Test interno**;
2. creare una release;
3. caricare l'AAB firmato;
4. aggiungere un piccolo gruppo di account Google affidabili;
5. pubblicare la release interna;
6. installarla esclusivamente tramite il link Play Store fornito dalla Console;
7. verificare installazione, aggiornamento, lingua, profili, backup, immagini offline, condivisione, icona e splash.

Il test interno supporta fino a 100 tester ed è normalmente il modo più rapido per verificare la consegna effettiva di Google Play.

## 11. Test chiuso

Dopo il test interno:

1. aprire **Test e release > Test > Test chiuso**;
2. creare un canale, ad esempio `beta-chiusa`;
3. aggiungere tester tramite elenco email o Google Group;
4. caricare una nuova release con `versionCode` maggiore se l'AAB è cambiato;
5. compilare le note di rilascio in italiano e inglese;
6. distribuire il link di adesione;
7. verificare che i tester risultino effettivamente registrati e abbiano installato l'app dal Play Store;
8. raccogliere feedback e problemi in issue separate, senza dati personali o backup allegati pubblicamente.

Per gli account personali creati dopo il 13 novembre 2023, l'accesso alla produzione richiede attualmente almeno **12 tester aderenti ininterrottamente per 14 giorni**. Non rimuovere tester e non interrompere il canale durante il periodo obbligatorio.

## 12. Checklist del tester

Ogni tester dovrebbe verificare almeno:

- installazione e primo avvio;
- selezione italiano/inglese;
- creazione rapida e guidata del profilo;
- chiusura e riapertura dell'app;
- creazione e gestione della squadra;
- Pokédex, mosse, abilità e oggetti;
- aggiunta e modifica di un Pokémon;
- PC, zaino, incontri e strumenti Master usati abitualmente;
- esportazione e importazione backup;
- aggiornamento dalla build precedente senza perdita dei dati;
- uso completamente offline e in modalità aereo;
- font grandi, TalkBack e schermo piccolo, quando disponibili;
- icona, splash, rotazione e ritorno dall'app in background;
- eventuali crash, schermate bianche, immagini mancanti o testi non tradotti.

Per ogni problema annotare:

- versione app e `versionCode`;
- modello dispositivo;
- versione Android;
- lingua selezionata;
- passaggi esatti per riprodurre;
- risultato atteso e risultato ottenuto;
- screenshot senza informazioni personali.

## 13. Condizioni per chiedere l'accesso alla produzione

Non procedere finché non risultano completati:

- periodo di test chiuso eventualmente richiesto dall'account;
- nessun crash bloccante noto;
- Privacy Policy pubblica e definitiva;
- Data Safety coerente con l'AAB;
- classificazione IARC e pubblico di destinazione completati;
- scheda Store italiana e inglese completa;
- audit di licenze e provenienza degli asset portato a un livello ritenuto accettabile dal proprietario e, prima di una diffusione ampia, sottoposto a revisione professionale;
- backup e aggiornamento verificati tramite build distribuita dal Play Store;
- chiave di upload e accesso all'account recuperabili da copie sicure.

## Fonti ufficiali da ricontrollare prima dell'invio

- Requisiti di test per nuovi account personali: <https://support.google.com/googleplay/android-developer/answer/14151465>
- Configurazione di test interno e chiuso: <https://support.google.com/googleplay/android-developer/answer/9845334?hl=it>
- Creazione e configurazione dell'app: <https://support.google.com/googleplay/android-developer/answer/9859152>
- Play App Signing: <https://support.google.com/googleplay/android-developer/answer/9842756>
- Requisiti delle risorse grafiche: <https://support.google.com/googleplay/android-developer/answer/9866151?hl=it>
- Data Safety: <https://support.google.com/googleplay/android-developer/answer/10787469>
- Dati utente e Privacy Policy: <https://support.google.com/googleplay/android-developer/answer/10144311>
- API target Google Play: <https://developer.android.com/google/play/requirements/target-sdk>
