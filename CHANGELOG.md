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
- scheda compatta delle sei caratteristiche del Pokémon nel Battle Companion, con valori effettivi e modificatori pronti per prove e tiri salvezza;
- sistema persistente di allevamento e uova integrato nei profili e nei backup, con compatibilità dei genitori, Gruppi Uova, Ditto, tiri di successo, incubazione, incubatori e schiusa in squadra o nel PC;
- uova come entità reali della squadra: occupano un Pokéslot, possono essere affidate alla Pensione Pokémon e alla schiusa vengono sostituite dal Pokémon nato nello stesso slot.
- deposito delle uova nel PC Pokémon, con incubazione in pausa, ritiro in squadra e visualizzazione nel PC Box.
- completamento del Trainer Path Pokémon Breeder: Good Genes assegna alla schiusa 2 punti caratteristica o un talento, mentre Master of Traits permette di scegliere sesso, natura, abilità e sostituzioni delle Egg Moves;
- incubatori Basic, Plus e Super già presenti nel catalogo consumati quando vengono assegnati a un uovo, secondo costi e dadi aggiuntivi del manuale;
- gestione della fragilità delle uova con CA 8, 10 PF e distruzione a 0 PF, mantenuta nei salvataggi e nei backup;
- pannello persistente di meteo e terreno nel Battle Companion, con tabella d100 stagionale, durate e contatori aggiornati a ogni nuovo round, regola opzionale sui danni, terreni creati dalle mosse e promemoria delle abilità ambientali;
- applicazione automatica di Terrain Adept, Weather Ball, bonus a CA/velocità/danni e danni di Grandine o Tempesta di sabbia secondo il manuale.

### Modificato

- Home e Strumenti del Master divisi in sezioni più riconoscibili;
- navigazione interna corretta: la freccia torna alla schermata precedente e il comando Home resta separato;
- editor delle probabilità delle raccolte corretto per consentire la digitazione di percentuali a più cifre senza perdere il focus;
- controllo del combattimento semplificato: resta un solo pulsante `PROSSIMO TURNO`, che avanza automaticamente il round al termine dell’iniziativa;
- i privilegi ottenuti ai livelli 5, 9 e 15 sono indicati come `Privilegio del Path`, distinguendoli dalla scelta iniziale del Trainer Path;
- il cambio di un Trainer Path già salvato richiede ora una conferma esplicita;
- corretto il salvataggio del primo uovo di un profilo, che prima poteva mostrare `Unsupported operation: insert`;
- la schiusa considera soltanto i Pokéslot sbloccati: con tutti gli slot disponibili occupati il Pokémon viene depositato nel PC, e gli esemplari finiti in slot bloccati vengono recuperati automaticamente.
- sprite delle uova ridimensionati e schede della squadra nel PC rese più alte per evitare overflow alle larghezze intermedie.
- lo sprite personalizzato dell’uovo viene ora usato nella Squadra, nel riepilogo del PC e nelle schede di incubazione;
- la Classe Armatura effettiva del Pokémon è ora visibile accanto al nome nel Battle Companion, con l’eventuale bonus ambientale evidenziato.

### In programma

- condivisione nativa ed esportazioni mirate.
