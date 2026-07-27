# Google Play Data Safety — bozza

Stato: **non pronta per l'invio**  
Ultimo aggiornamento: 27 luglio 2026

Questa checklist serve a preparare la dichiarazione nel Play Console. Le risposte finali devono essere confrontate con la build AAB effettivamente caricata, con tutte le dipendenze e con la documentazione Google Play aggiornata al momento della pubblicazione.

## Sintesi tecnica corrente

- nessun account online;
- dati di gioco salvati localmente tramite Hive;
- nessuna pubblicità;
- nessun SDK analytics o Crashlytics dichiarato nelle dipendenze correnti;
- esportazione e condivisione avviate volontariamente dall'utente;
- permesso Android `INTERNET` assente;
- fallback remoti delle immagini eliminati;
- immagini e dati di gioco risolti dagli asset inclusi nel pacchetto;
- test automatico dedicato al funzionamento locale e all'AssetManifest.

## Domanda: l'app raccoglie o condivide dati utente?

**Risposta finale sospesa.**

L'audit statico del codice applicativo ha eliminato i loader e gli host remoti noti e la build Android non richiede il permesso Internet. L'obiettivo resta poter dichiarare che lo sviluppatore non raccoglie dati, ma la risposta finale non va selezionata finché non sono stati completati:

1. audit delle dipendenze transitive e dei plugin di piattaforma;
2. verifica della build AAB release con traffico di rete osservato;
3. conferma che nessun servizio di terzi riceva identificatori o telemetria;
4. classificazione corretta nel Play Console delle operazioni di esportazione e condivisione avviate dall'utente;
5. verifica finale dei permessi e del manifest risultante dalla build caricata.

L'assenza di richieste automatiche nel codice verificato è un'evidenza importante, ma non sostituisce il controllo runtime della build definitiva.

## Dati inseriti e conservati localmente

L'app può elaborare sul dispositivo:

- nome e informazioni del profilo Allenatore;
- contenuti di gioco, progressi e preferenze;
- file importati dall'utente;
- backup e file esportati.

Nella versione corrente tali dati non risultano inviati automaticamente a un server dello sviluppatore.

## Condivisione avviata dall'utente

L'utente può scegliere di inviare un file tramite:

- menu di condivisione del sistema;
- email;
- messaggistica;
- cloud storage;
- altre app installate.

Queste operazioni sono avviate dall'utente e la destinazione viene scelta esplicitamente. Va verificato nel questionario Play Console come classificare le azioni user-initiated e se debbano essere dichiarate in base alla destinazione e alle API usate.

## Sicurezza

Elementi verificati o da confermare prima dell'invio:

- [x] permesso Android `INTERNET` rimosso dal manifest principale;
- [x] loader e host remoti noti eliminati dal codice applicativo verificato;
- [x] immagini degli oggetti incluse nell'AssetManifest;
- [ ] audit completo delle dipendenze transitive;
- [ ] nessun segreto incluso nell'app;
- [ ] backup esportati chiaramente identificati come file potenzialmente sensibili;
- [ ] test di cancellazione completa dei dati locali;
- [ ] verifica del comportamento dei backup di sistema Android;
- [ ] osservazione del traffico della build AAB release su dispositivo reale.

## Cancellazione dati

Stato previsto:

- cancellazione di singoli profili disponibile nell'app;
- cancellazione completa tramite rimozione dei dati dell'app o disinstallazione;
- nessun account remoto da eliminare;
- file esportati e copie condivise devono essere cancellati dall'utente nelle rispettive destinazioni.

## Pubblico e minori

Da definire prima della pubblicazione:

- fascia di età target nel Play Console;
- eventuale inclusione nella sezione Famiglie;
- necessità di una privacy policy specifica per minori;
- adeguatezza di contenuti, link esterni e meccanismi di condivisione.

## Dichiarazioni provvisorie

| Voce | Bozza | Condizione per conferma |
|---|---|---|
| Pubblicità | No | Nessun SDK o contenuto pubblicitario nella build |
| Analytics | No | Audit dipendenze e traffico completato |
| Account | No | Nessuna autenticazione o profilo server |
| Raccolta dallo sviluppatore | Probabilmente no | Verifica runtime della build AAB completata |
| Condivisione automatica | No nel codice verificato | Classificazione finale delle azioni avviate dall'utente |
| Dati locali | Sì, sul dispositivo | Privacy policy e funzioni di cancellazione verificate |
| Cifratura in transito | Non applicabile alle funzioni ordinarie verificate | Conferma tramite osservazione della build release |
| Cancellazione | Disponibile localmente | Test end-to-end e documentazione utente |

## Evidenze da allegare alla release

- report delle dipendenze e delle licenze;
- lista dei permessi Android della build finale;
- report statico delle URL nel codice e negli asset;
- audit del funzionamento offline e test AssetManifest;
- cattura del traffico della build release durante i flussi principali;
- test di esportazione, importazione e cancellazione;
- URL pubblico definitivo della privacy policy;
- commit e tag della build inviata al Play Console.
