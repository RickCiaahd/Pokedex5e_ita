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
- permesso Android `INTERNET` presente;
- fallback remoti per alcune immagini ancora da eliminare o censire.

## Domanda: l'app raccoglie o condivide dati utente?

**Risposta finale sospesa.**

L'obiettivo è poter dichiarare che lo sviluppatore non raccoglie dati, ma questa risposta non va selezionata finché non sono stati completati:

1. audit di tutte le chiamate di rete;
2. rimozione o documentazione dei fallback remoti delle immagini;
3. audit delle dipendenze transitive;
4. verifica della build release con traffico di rete osservato;
5. conferma che nessun servizio di terzi riceva identificatori o telemetria.

Le richieste tecniche a host esterni possono costituire trasmissione fuori dal dispositivo anche quando non esiste un backend dello sviluppatore.

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

Elementi da confermare prima dell'invio:

- [ ] traffico di rete cifrato esclusivamente tramite HTTPS;
- [ ] nessun endpoint HTTP non cifrato;
- [ ] nessun segreto incluso nell'app;
- [ ] backup esportati chiaramente identificati come file potenzialmente sensibili;
- [ ] test di cancellazione completa dei dati locali;
- [ ] verifica del comportamento dei backup di sistema Android.

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
| Raccolta dallo sviluppatore | Probabilmente no | Rimozione/audit rete completati |
| Condivisione automatica | Probabilmente no | Verifica di `share_plus`, file picker e fallback remoti |
| Dati locali | Sì, sul dispositivo | Privacy policy e funzioni di cancellazione verificate |
| Cifratura in transito | Da verificare | Nessuna richiesta HTTP e controllo runtime |
| Cancellazione | Disponibile localmente | Test end-to-end e documentazione utente |

## Evidenze da allegare alla release

- report delle dipendenze e delle licenze;
- lista dei permessi Android;
- report statico delle URL nel codice e negli asset;
- cattura del traffico della build release durante i flussi principali;
- test di esportazione, importazione e cancellazione;
- URL pubblico definitivo della privacy policy;
- commit e tag della build inviata al Play Console.
