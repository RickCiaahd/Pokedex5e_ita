# Verifica sviluppatore Android e registrazione del package

Ultimo aggiornamento: 31 luglio 2026

Google ha annunciato nuovi requisiti di verifica sviluppatore e registrazione dei package, con efficacia dal **30 settembre 2026**. Per le app distribuite tramite Google Play, le operazioni vengono gestite nella Play Console.

## Controlli da eseguire

1. Aprire Play Console con l'account proprietario.
2. Andare in **Impostazioni > Account sviluppatore**.
3. Verificare che identità, email, telefono e profilo pagamenti risultino completati e aggiornati.
4. Controllare nella Home della Console eventuali attività relative alla verifica sviluppatore Android.
5. Dopo aver creato l'app o caricato il primo AAB, verificare che il package seguente risulti registrato o idoneo alla registrazione automatica:

```text
io.github.rickciaahd.traineratlas
```

6. Non registrare package alternativi e non modificare l'Application ID dopo il primo caricamento.
7. Conservare prova della verifica e dei certificati associati alla release.

## Nota operativa

Google dichiara di tentare la registrazione automatica delle app Play esistenti e nuove quando rispettano le condizioni previste. Il proprietario deve comunque controllare la Home di Play Console e completare eventuali attività residue prima della scadenza.

## Fonti ufficiali

- Requisiti Play Console: <https://support.google.com/googleplay/android-developer/answer/10788890>
- Registrazione dei package Play: <https://support.google.com/googleplay/android-developer/answer/16984799>
- Informazioni richieste per l'account sviluppatore: <https://support.google.com/googleplay/android-developer/answer/13628312>
