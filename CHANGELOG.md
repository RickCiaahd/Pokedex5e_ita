# Changelog

Tutte le modifiche rilevanti al progetto vengono documentate in questo file.

## [Non rilasciato]

### Aggiunto

- documentazione GPLv3, NOTICE, Privacy, Data Safety e inventari riproducibili di dipendenze, asset e duplicati;
- controlli automatici per licenze, funzionamento offline, completezza delle release e integrità delle immagini;
- etichette grafiche inglesi per tutti i 18 tipi Pokémon;
- test di regressione per layout mobile, localizzazione delle origini, residui bilingui e messaggi d’errore;
- scelta tra creazione rapida e creazione guidata dei nuovi profili dalla schermata Profili;
- riordino persistente dei Pokémon in squadra tramite trascinamento.

### Modificato

- immagini e dati di gioco resi completamente local-first, con rimozione del permesso Internet Android;
- 2.386 immagini convertite in WebP lossless, senza rimuovere varianti e con circa 118 MiB risparmiati;
- tour guidati, scelta dello starter e tessere dei tipi adattati meglio agli schermi mobili;
- nomi italiani delle origini regionali uniformati ai nomi delle regioni;
- Flutter bloccato alla versione 3.44.4 nei workflow di CI e release;
- messaggi d’errore visibili centralizzati e localizzati, senza esporre eccezioni tecniche;
- metadati delle mosse e azioni dello Zaino completati anche in inglese;
- creazione di profilo, starter, squadra e Pokédex resa atomica, con attivazione soltanto dopo il salvataggio completo.

### Corretto

- sovrapposizione tra Professore e fumetto nei tour su smartphone;
- disposizione dei due tipi nella schermata Aggiungi Pokémon;
- residui italiani nel flusso delle MT, nella sostituzione delle mosse e nella gestione degli strumenti tenuti;
- possibili profili parziali o cambi di profilo attivo in caso di errore durante la creazione guidata;
- overflow orizzontale dei titoli lunghi nella schermata Modifica Pokémon su smartphone.

## [1.3.2] - 2026-07-26

### Aggiunto

- interfaccia bilingue italiano/inglese con selezione automatica o manuale della lingua;
- cataloghi di Pokémon, mosse, abilità e oggetti sensibili alla lingua;
- onboarding e schermate secondarie localizzati;
- tour guidati per Home, Scheda Allenatore, Battle Companion e Strumenti del Master.

### Modificato

- nome pubblico uniformato a **Trainer Atlas 5e**;
- Application ID Android impostato su `io.github.rickciaahd.traineratlas`;

### Corretto

- primi audit dei testi italiani residui nell’interfaccia inglese;
- ripristino corretto delle schermate e dello scroll al termine dei tour guidati.

## [1.3.1] - 2026-07-23

### Modificato

- onboarding iniziale ridisegnato con il Professore e layout mobile più compatto;
- manifest degli asset ripristinato per mantenere completi i pacchetti distribuiti.

## [1.3.0] - 2026-07-23

### Aggiunto

- onboarding al primo avvio per creare il profilo Allenatore e scegliere lo starter;
- flusso di pubblicazione multipiattaforma aggiornato per Android e Windows.

### Modificato

- identità pubblica e nomi dei pacchetti di release aggiornati a **Trainer Atlas 5e**.

## [1.2.0] - 2026-07-22

### Aggiunto

- possibilità di collegare un Fakemon come forma alternativa permanente o momentanea di una specie esistente;
- selettori ricercabili per oggetti e mosse richiesti dalle evoluzioni personalizzate;
- artwork shiny facoltativo accanto all’immagine principale nell’editor Fakemon.

### Corretto

- rimozione delle evoluzioni duplicate nel selettore;
- localizzazione italiana delle nature e di varie etichette residue dell’editor Pokémon;
- visualizzazione e comportamento delle forme Fakemon collegate a Pokémon ufficiali.

## [1.1.0] - 2026-07-22

### Aggiunto

- evoluzioni personalizzate tra Pokémon ufficiali e Fakemon, comprese catene ramificate;
- forme Fakemon permanenti e momentanee di battaglia con artwork e statistiche dedicate;
- artwork shiny separato per specie e forme;
- esportazione sigillata e scoperta per profilo dei Fakemon segreti;
- editor avanzato per condizioni evolutive, indizi e visibilità Pokédex.

### Corretto

- preservazione dei collegamenti avanzati durante importazione, duplicazione e rimappatura degli ID.

### Corretto

- aggiornamento immediato della scheda dopo un’evoluzione;
- sincronizzazione della specie mostrata dopo la modifica di un altro membro della squadra;
- disponibilità delle evoluzioni regionali con regione in forma prefissa o suffissa, compresi gli starter di Hisui;
- sprite della barra squadra coerenti con forma, sesso e variante cromatica dell’esemplare;
- esclusione delle evoluzioni non canoniche di Eevee dal selettore.

## [1.0.2] - 2026-07-21

### Aggiunto

- workflow GitHub Actions dedicato a Windows con analisi, test e build release su `windows-latest`;
- pacchetto portatile `Pokedex5eITA-1.0.2-Windows-x64.zip` con checksum SHA-256;
- pubblicazione automatica degli artefatti Windows nella GitHub Release associata ai tag `v*`;
- documentazione completa per compilazione, distribuzione e verifica manuale della versione Windows.

### Modificato

- nome dell'eseguibile Windows impostato su `Pokedex5eITA.exe`;
- titolo della finestra e metadati del prodotto uniformati a `Trainer Atlas 5e`;
- nome autore/editore Windows impostato su `RickCiaahd`;
- versione applicativa aggiornata a `1.0.2+3` per la release multipiattaforma.

## [1.0.1] - 2026-07-21

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
- identità Android impostata su `Trainer Atlas 5e` con Application ID definitivo `io.github.rickciaahd.traineratlas`;
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

## [1.0.0]

Tag storico creato durante lo sviluppo, precedente al consolidamento della localizzazione completa, delle forme e delle correzioni pre-release.
