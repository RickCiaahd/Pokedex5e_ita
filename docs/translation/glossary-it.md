# Glossario italiano dei contenuti

Questo glossario definisce la terminologia da usare nelle descrizioni visualizzate da **Pokédex 5e ITA**. I nomi propri di Pokémon, mosse, abilità e oggetti restano invariati finché non viene approvata esplicitamente una localizzazione separata dei nomi.

## Regole generali

- Tradurre soltanto il testo destinato all'utente.
- Non modificare ID, slug, chiavi JSON, nomi dei campi o struttura dei file.
- Non modificare valori numerici, formule, dadi, CD, PP, portate, durate, livelli o riferimenti alle regole.
- Conservare maiuscole e abbreviazioni tecniche: **CA**, **PF**, **PP**, **CD**, **SR**, **FOR**, **DES**, **COS**, **INT**, **SAG**, **CAR**, **STAB**, **TM**.
- Usare **Pokémon** con accento e forma invariabile al singolare e al plurale.
- Preferire frasi naturali in italiano senza aggiungere, rimuovere o reinterpretare effetti meccanici.

## Termini di gioco

| Inglese | Italiano approvato |
| --- | --- |
| action | azione |
| bonus action | azione bonus |
| reaction | reazione |
| attack roll | tiro per colpire |
| damage roll | tiro per i danni |
| saving throw | tiro salvezza |
| ability check | prova di caratteristica |
| skill check | prova di abilità |
| target | bersaglio |
| creature | creatura |
| range | gittata, quando indica la distanza di una mossa |
| reach | portata, quando indica la distanza in mischia |
| duration | durata |
| concentration | concentrazione |
| advantage | vantaggio |
| disadvantage | svantaggio |
| resistance | resistenza |
| vulnerability | vulnerabilità |
| immunity | immunità |
| hit points | punti ferita / PF |
| temporary hit points | punti ferita temporanei / PF temporanei |
| Armor Class | Classe Armatura / CA |
| proficiency bonus | bonus di competenza |
| proficiency | competenza |
| expertise | maestria |
| movement speed | velocità di movimento |
| walking speed | velocità base |
| flying speed | velocità di volo |
| swimming speed | velocità di nuoto |
| burrowing speed | velocità di scavo |
| long rest | riposo lungo |
| short rest | riposo breve |
| fainted | svenuto, quando indica un Pokémon a 0 PF |
| restrained | trattenuto |
| prone | prono |
| incapacitated | incapacitato |
| frightened | spaventato |
| poisoned | avvelenato |
| paralyzed | paralizzato |
| confused | confuso |
| asleep | addormentato |
| burned / burning | scottato / in fiamme secondo il contesto |
| frozen | congelato |
| flinched | tentennante; mantenere `FLINCHED` quando è il nome tecnico dello status nell'interfaccia |

## Terminologia Pokémon 5e

| Inglese | Italiano approvato |
| --- | --- |
| Trainer | Allenatore |
| Pokémon Trainer | Allenatore di Pokémon |
| Active Pokémon | Pokémon attivo |
| Trainer Path | Trainer Path, finché il nome tecnico non viene localizzato in modo globale |
| Specialization | Specializzazione |
| Loyalty | Lealtà |
| Species Rating | Grado Specie / SR; mantenere **SR** nelle formule |
| Move Power | Caratteristica della mossa |
| Starting Moves | Mosse iniziali |
| Egg Moves | Egg Moves, finché i nomi tecnici delle sezioni non vengono localizzati globalmente |
| Egg Group | Gruppo Uova |
| Hidden Ability | Abilità nascosta |
| held item | strumento tenuto |
| Pokéslot | Pokéslot |
| Poké Ball | Poké Ball |
| Pokémon Center | Pokémon Center |
| Pokédex entry | voce del Pokédex |

## Stile delle descrizioni del Pokédex

- Il genere viene scritto come **Pokémon Seme**, **Pokémon Fiamma**, **Pokémon Topo**, ecc.
- Le descrizioni usano il presente e mantengono il nome proprio della specie.
- Le unità presenti nel testo sorgente possono essere convertite nel sistema metrico soltanto quando la conversione è esatta e non costituisce un valore di regola. In caso di dubbio, mantenere il valore originale.
- Non introdurre informazioni provenienti da altre voci del Pokédex o da altre generazioni.

## Controllo di qualità

Per ogni blocco verificare:

1. corrispondenza uno-a-uno tra entità sorgente e traduzioni;
2. assenza di campi tecnici modificati;
3. validità JSON e caricamento tramite `rootBundle`;
4. test di integrità, suite completa, analisi statica e build Android;
5. revisione manuale di punteggiatura, apostrofi, accenti e terminologia.
