# Changelog

Tutte le modifiche rilevanti al progetto vengono documentate in questo file.

## [Non rilasciato]

Nessuna modifica successiva alla prima release.

## [1.0.0] - 2026-07-21

### Aggiunto

- Pokédex completo con specie, forme, statistiche, mosse, abilità, sprite e localizzazione italiana separata dai dati meccanici;
- profili Allenatore, squadra, PC Pokémon, Zaino, cattura, evoluzione, Lealtà, status e Pokémon Center;
- Battle Companion del giocatore e Fight del Master con iniziativa, PF, PP, status, meteo, terreno e trasformazioni temporanee;
- generatori di Pokémon, incontri e Allenatori PNG, con librerie persistenti ed esportazione portabile;
- catalogo globale dei Fakemon con scheda 5e, immagini, mosse e abilità esclusive;
- sistema persistente di allevamento, uova, incubatori, Pensione Pokémon e schiusa in squadra o nel PC;
- applicazione automatica dei principali bonus passivi e delle risorse numeriche dei Trainer Path;
- backup e ripristino dei profili, oltre a importazione, esportazione e condivisione di Pokémon, squadre, incontri e Allenatori PNG;
- cataloghi italiani per descrizioni e categorie dei Pokémon, 330 abilità, 366 oggetti e 830 mosse;
- test automatici di integrità per cataloghi, localizzazioni, forme e asset;
- workflow GitHub Actions permanente per analisi, test e build Android di debug;
- workflow Android release per APK e AAB firmati, checksum SHA-256 e pubblicazione automatica della GitHub Release dai tag `v*`;
- documentazione del progetto, della firma Android e delle verifiche pre-release.

### Modificato

- interfaccia resa responsiva e leggibile su Android, Web e Windows, con layout specifici per smartphone e desktop;
- navigazione interna uniformata, mantenendo separati i comandi Indietro e Home;
- schermate Home e Strumenti del Master organizzate in sezioni più riconoscibili;
- Pokédex dotato di ricerca, ordinamento, filtri per regione, tipo e stato, oltre alla gestione delle forme;
- dettaglio Pokémon e selettori delle mosse adattati alle larghezze ridotte e ai cataloghi completi;
- trasferimenti e backup resi sicuri anche in presenza di Fakemon, uova, slot bloccati ed elementi sostituiti;
- Battle Companion e Fight del Master resi più compatti e coerenti nella gestione di round, status e azioni;
- localizzati nomi, categorie e descrizioni preservando ID, valori meccanici e compatibilità dei salvataggi;
- identità Android impostata su `Pokédex 5e ITA` con Application ID definitivo `io.github.rickciaahd.pokedex5eita`;
- firma release separata dalla chiave di debug e resa obbligatoria per le build firmate;
- rimossi prototipi, test, schermate e inizializzatori non più raggiungibili dall’app;
- eliminati i log verbosi delle operazioni ordinarie di persistenza, mantenendo le segnalazioni degli errori effettivi.

### Corretto

- variazioni grafiche legate al sesso, compresi i percorsi asset maschio e femmina;
- differenze meccaniche dipendenti dal sesso, come learnset e abilità di Meowstic;
- forme cromatiche e Forma Meteora di Minior, inclusi nomi italiani e sprite predefiniti;
- duplicati tra forma Base e forma predefinita nei selettori;
- salvataggio del primo uovo, gestione degli slot sbloccati e recupero degli esemplari in slot non disponibili;
- overflow e problemi di area sicura nelle principali schermate Android;
- editor delle probabilità, cambio Trainer Path, avanzamento dei turni e visualizzazione della CA effettiva.

### Avvertenza

Il progetto è amatoriale e non ufficiale. Pokémon e i relativi nomi, personaggi e immagini appartengono ai rispettivi titolari. Il progetto non è affiliato, sponsorizzato o approvato da Nintendo, Game Freak, Creatures Inc. o The Pokémon Company.
