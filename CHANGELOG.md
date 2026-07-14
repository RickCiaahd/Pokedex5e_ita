# Changelog

Tutte le modifiche rilevanti al progetto vengono documentate in questo file.

## [Non rilasciato]

### Aggiunto

- workflow GitHub Actions permanente per `flutter analyze` e l'intera suite di test;
- test automatico di integrità per cataloghi Pokémon, mosse, abilità, forme e asset;
- documentazione iniziale del progetto, delle piattaforme supportate e dei controlli locali;
- avvio diretto degli incontri generati o salvati nel Fight del Master, senza creare Allenatori PNG nella libreria;
- accesso diretto dalla Home e dagli Strumenti al Fight del Master ancora in corso;
- pannello condiviso di assistenza agli status per Battle Companion e Fight del Master, con promemoria distinti per inizio turno, azione, mossa subita e fine turno;
- gestione automatica delle risorse numeriche del Trainer Path, con contatori persistenti e recupero da riposo breve o lungo;
- selettori persistenti per le scelte specifiche di Researcher, Ace Trainer, Hobbyist, Type Master e Ranger;
- applicazione automatica dei bonus passivi principali dei Trainer Path a caratteristiche, PF, tiri per colpire, danni, STAB, tiri salvezza e Lealtà;
- scheda compatta delle sei caratteristiche del Pokémon nel Battle Companion, con valori effettivi e modificatori pronti per prove e tiri salvezza.
- sistema persistente di allevamento e uova con compatibilità dei genitori, Gruppi Uova, Ditto, tiri di successo, incubazione, incubatori e schiusa in squadra o nel PC.

### Modificato

- Home e Strumenti del Master divisi in sezioni più riconoscibili;
- navigazione interna corretta: la freccia torna alla schermata precedente e il comando Home resta separato;
- editor delle probabilità delle raccolte corretto per consentire la digitazione di percentuali a più cifre senza perdere il focus;
- controllo del combattimento semplificato: resta un solo pulsante `PROSSIMO TURNO`, che avanza automaticamente il round al termine dell’iniziativa;
- i privilegi ottenuti ai livelli 5, 9 e 15 sono indicati come `Privilegio del Path`, distinguendoli dalla scelta iniziale del Trainer Path;
- il cambio di un Trainer Path già salvato richiede ora una conferma esplicita.

### In programma

- condivisione nativa ed esportazioni mirate.
