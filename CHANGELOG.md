# Changelog

Tutte le modifiche rilevanti al progetto vengono documentate in questo file.

## [Non rilasciato]

### Aggiunto

- glossario italiano e audit delle sorgenti visualizzate per guidare i prossimi blocchi di traduzione;
- catalogo separato e validato per i testi italiani dei Pokémon, senza modificare ID, statistiche o file sorgente;
- test automatico di copertura e integrità delle localizzazioni Pokémon;
- riferimento verificabile delle categorie italiane ufficiali dei Pokémon #001-809 e controllo automatico contro i cataloghi localizzati.

### Modificato

- tradotti in italiano genere e descrizione Pokédex dei 151 Pokémon di prima generazione, mantenendo invariati altezza, peso e dati meccanici;
- tradotti in italiano genere e descrizione Pokédex dei 100 Pokémon di seconda generazione, dal #152 al #251, usando lo stesso livello di localizzazione separato dai dati originali;
- tradotti in italiano genere e descrizione Pokédex dei 135 Pokémon di terza generazione, dal #252 al #386, mantenendo invariati i JSON sorgente e tutti i dati meccanici;
- tradotti in italiano genere e descrizione Pokédex dei 107 Pokémon di quarta generazione, dal #387 al #493, senza alterare i dati originali;
- tradotti in italiano genere e descrizione Pokédex dei 156 Pokémon di quinta generazione, dal #494 al #649, mantenendo separati i cataloghi localizzati dai dati sorgente;
- tradotti in italiano genere e descrizione Pokédex dei 72 Pokémon di sesta generazione, dal #650 al #721, usando le categorie italiane del riferimento verificato;
- tradotti in italiano genere e descrizione Pokédex degli 88 Pokémon di settima generazione, dal #722 al #809, mantenendo invariati i dati originali e usando le categorie italiane verificate;
- corrette 198 categorie Pokémon delle prime cinque generazioni confrontandole con il riferimento italiano, tra cui Emboar da `Pokémon Granfuocomaiale` a `Pokémon Suincendio`.

## [1.0.0]

### Aggiunto

- catalogo globale dei Fakemon con scheda 5e, immagine caricata, mosse e abilità esclusive della specie, importazione, esportazione e condivisione portabile;
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
- uova come entità reali della squadra: occupano un Pokéslot, possono essere affidate alla Pensione Pokémon e alla schiusa vengono sostituite dal Pokémon nato nello stesso slot;
- deposito delle uova nel PC Pokémon, con incubazione in pausa, ritiro in squadra e visualizzazione nel PC Box;
- completamento del Trainer Path Pokémon Breeder: Good Genes assegna alla schiusa 2 punti caratteristica o un talento, mentre Master of Traits permette di scegliere sesso, natura, abilità e sostituzioni delle Egg Moves;
- incubatori Basic, Plus e Super già presenti nel catalogo consumati quando vengono assegnati a un uovo, secondo costi e dadi aggiuntivi del manuale;
- gestione della fragilità delle uova con CA 8, 10 PF e distruzione a 0 PF, mantenuta nei salvataggi e nei backup;
- pannello persistente di meteo e terreno nel Battle Companion, con tabella d100 stagionale, durate e contatori aggiornati a ogni nuovo round, regola opzionale sui danni, terreni creati dalle mosse e promemoria delle abilità ambientali;
- applicazione automatica di Terrain Adept, Weather Ball, bonus a CA/velocità/danni e danni di Grandine o Tempesta di sabbia secondo il manuale;
- guida alla firma Android, modello sicuro di `key.properties` e checklist per installazione, aggiornamento, backup e ripristino;
- workflow permanente `Android release` per generare APK e AAB firmati, checksum SHA-256 e GitHub Release dai tag `v*`;
- test automatico della configurazione Android release.

### Modificato

- i backup profilo includono automaticamente i Fakemon utilizzati e ne rimappano i riferimenti durante l'importazione; il catalogo globale può essere esportato e importato in blocco e l'eliminazione di una specie è bloccata finché esistono riferimenti nei profili;
- i trasferimenti di singoli Pokémon, squadre, incontri e Allenatori PNG includono automaticamente le definizioni complete dei Fakemon usati e le installano o rimappano durante l'importazione;
- le mosse esclusive dei Fakemon vengono aggiunte al moveset iniziale quando create e le vecchie mosse esclusive non assegnate diventano comunque selezionabili nei dettagli della specie;
- nell'editor Pokémon il selettore mosse distingue disponibilità attuale, learnset completo e catalogo globale, con ricerca e filtri;
- su smartphone il dettaglio Pokémon scorre fino alle schede Mosse, Features e Traits, mantenendo le tab accessibili;
- Battle Companion usa intestazione, squadra e iniziativa più compatte, con i comandi secondari richiudibili;
- la scelta di uno status nel Battle Companion viene applicata e salvata subito, chiudendo il pannello;
- i generatori e i risultati degli Strumenti del Master rispettano l'area sicura inferiore di Android;
- rimossi prototipi, test e schermate non più raggiungibili dall'app, mantenendo invariati dati e funzionalità attive;
- ultimo passaggio della review pre-release: Battle Companion, Fight del Master e Strumenti del Master usano larghezze leggibili su desktop; le AppBar espongono Home in modo uniforme, le azioni del fight sono raccolte in menu meno affollati e dialog/bottom sheet critici gestiscono meglio smartphone e testo ingrandito;
- secondo passaggio della review pre-release: Home, Pokédex, PC Pokémon e Zaino usano larghezze leggibili su desktop; i filtri del Pokédex si impilano su smartphone, il riepilogo Allenatore evita overflow e lo Zaino dispone gli oggetti su due colonne quando lo spazio lo consente;
- primo passaggio della review pre-release: Squadra, Profili e librerie del Master ora mantengono una larghezza leggibile su Web e Windows; la Squadra usa due colonne sulle finestre ampie e una colonna su smartphone;
- Home e Strumenti del Master divisi in sezioni più riconoscibili;
- navigazione interna corretta: la freccia torna alla schermata precedente e il comando Home resta separato;
- editor delle probabilità delle raccolte corretto per consentire la digitazione di percentuali a più cifre senza perdere il focus;
- controllo del combattimento semplificato: resta un solo pulsante `PROSSIMO TURNO`, che avanza automaticamente il round al termine dell'iniziativa;
- i privilegi ottenuti ai livelli 5, 9 e 15 sono indicati come `Privilegio del Path`, distinguendoli dalla scelta iniziale del Trainer Path;
- il cambio di un Trainer Path già salvato richiede ora una conferma esplicita;
- corretto il salvataggio del primo uovo di un profilo, che prima poteva mostrare `Unsupported operation: insert`;
- la schiusa considera soltanto i Pokéslot sbloccati: con tutti gli slot disponibili occupati il Pokémon viene depositato nel PC, e gli esemplari finiti in slot bloccati vengono recuperati automaticamente;
- sprite delle uova ridimensionati e schede della squadra nel PC rese più alte per evitare overflow alle larghezze intermedie;
- lo sprite personalizzato dell'uovo viene ora usato nella Squadra, nel riepilogo del PC e nelle schede di incubazione;
- la Classe Armatura effettiva del Pokémon è ora visibile accanto al nome nel Battle Companion, con l'eventuale bonus ambientale evidenziato;
- aggiunti file JSON portabili per esportare e importare un singolo Pokémon o l'intera squadra, preservando mosse, esperienza, natura, abilità, talenti, forma, sesso, Lealtà e personalizzazioni;
- durante l'importazione i Pokémon sostituiti e gli esuberi vengono trasferiti automaticamente nel PC, mentre le uova restano nei propri Pokéslot;
- incontri salvati e Allenatori PNG possono essere esportati e importati singolarmente senza sostituire il profilo, con nuovi identificativi e nomi non distruttivi in caso di duplicati;
- il Fight del Master può esportare un riepilogo testuale con round, ordine d'iniziativa, PF, status, PP, ricompense e Pokémon attivi;
- Pokémon, squadre, incontri, Allenatori PNG e riepiloghi del Fight del Master possono essere condivisi tramite il menu nativo del dispositivo, con fallback al download sul Web;
- le azioni di condivisione principali sono ora visibili direttamente nelle barre e nelle schede, senza dover aprire il menu con i tre puntini;
- identità Android impostata su `Pokédex 5e ITA` con Application ID definitivo `io.github.rickciaahd.pokedex5eita`;
- la build release non usa più la chiave di debug e richiede un keystore configurato esplicitamente;
- la CI compila anche un APK Android di debug per intercettare regressioni native.
