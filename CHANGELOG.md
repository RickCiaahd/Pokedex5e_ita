# Changelog

Tutte le modifiche rilevanti al progetto vengono documentate in questo file.

## [Non rilasciato]

### Aggiunto

- workflow GitHub Actions permanente per `flutter analyze` e l'intera suite di test;
- test automatico di integrità per cataloghi Pokémon, mosse, abilità, forme e asset;
- documentazione iniziale del progetto, delle piattaforme supportate e dei controlli locali;
- avvio diretto degli incontri generati o salvati nel Fight del Master, senza creare Allenatori PNG nella libreria;
- accesso diretto dalla Home e dagli Strumenti al Fight del Master ancora in corso;
- pannello condiviso di assistenza agli status per Battle Companion e Fight del Master, con promemoria distinti per inizio turno, azione, mossa subita e fine turno.

### Modificato

- Home e Strumenti del Master divisi in sezioni più riconoscibili;
- navigazione interna corretta: la freccia torna alla schermata precedente e il comando Home resta separato;
- editor delle probabilità delle raccolte corretto per consentire la digitazione di percentuali a più cifre senza perdere il focus.
- controllo del combattimento semplificato: resta un solo pulsante `PROSSIMO TURNO`, che avanza automaticamente il round al termine dell’iniziativa.

### In programma

- automazione delle capacità e delle risorse del Trainer Path;
- sistema di allevamento, uova e incubazione;
- condivisione nativa ed esportazioni mirate.
