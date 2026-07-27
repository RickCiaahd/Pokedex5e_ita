# Inventario degli asset

Stato: **censimento tecnico completato, diritti di redistribuzione ancora bloccanti**  
Ultimo aggiornamento: 27 luglio 2026

Questo inventario raggruppa gli asset per famiglia. Non autorizza la redistribuzione: quando la licenza non è documentata, lo stato deve essere considerato **non verificato**.

## Report automatici

Il generatore `tooling/generate_compliance_reports.py` scansiona tutti i file sotto `assets/` e produce:

- `docs/compliance/asset-audit-summary.md` — conteggi, dimensioni e copertura per famiglia;
- `docs/compliance/asset-manifest.csv` — percorso, dimensione, SHA-256, estensione, classificazione prudenziale, evidenze vicine e azione richiesta per ogni file.

Il workflow `Compliance audit` rigenera questi documenti e fallisce quando i report salvati non corrispondono agli asset presenti.

### Risultato corrente

- **8.539 file** censiti;
- **332,1 MiB** complessivi;
- soltanto **2 file** con un'evidenza di attribuzione o licenza trovata nella cartella o in una cartella antenata;
- **8.537 file** senza evidenza vicina;
- 6.441 file classificati `not-cleared`;
- 1.643 file classificati `mixed`;
- 432 file classificati `unverified`;
- 23 file classificati `project-created-pending-proof`.

La presenza di un file di attribuzione non dimostra da sola una licenza di redistribuzione valida.

## Legenda

- **Verificato**: fonte e licenza archiviate nel repository.
- **Da confermare / unverified**: fonte probabile nota, ma licenza o catena di attribuzione incompleta.
- **Non pubblicabile / not-cleared**: nessuna base di redistribuzione verificata; sostituire, rimuovere o ottenere autorizzazione.
- **Mixed**: famiglia composta da dati o materiali provenienti da più fonti, da separare file per file.
- **Creato per il progetto, prova pendente**: prodotto specificamente per Trainer Atlas 5e, ma autore e termini devono essere archiviati.

## Inventario per famiglia

| Percorso o famiglia | File | Dimensione | Provenienza attuale | Stato | Azione richiesta |
|---|---:|---:|---|---|---|
| `assets/data/` | 1.643 | 3,0 MiB | Pokedex5E, manuali, lavoro del progetto | Mixed | Collegare ogni file alla sorgente e distinguere dati originali, trasformati e tradotti |
| `assets/data_webapp/` | 11 | 3,6 MiB | `poke5e.app` e conversioni interne | Unverified | Archiviare repository/licenza esatti della sorgente e data del prelievo |
| `assets/textures/pokemons/` | 861 | 17,8 MiB | Set storico dell'app originale e fonti Pokémon | Not-cleared | Sostituire con asset autorizzati o escludere dalla build pubblica |
| `assets/textures/sprites/` | 860 | 502,8 KiB | Set storico dell'app originale e fonti Pokémon | Not-cleared | Sostituire con asset autorizzati o escludere dalla build pubblica |
| `assets/textures/textures_webapp/pokemon/` | 4.719 | 304,9 MiB | `poke5e.app` e relative fonti | Not-cleared | Verificare ogni set; è anche la famiglia dominante per dimensione |
| `assets/textures/textures_webapp/pokemon_transforms/` | 1 | 778 B | Catalogo web | Not-cleared | Verificare la fonte o escludere il file |
| `assets/textures/textures_webapp/items/` | 316 | 374,7 KiB | Catalogo web e fonti eterogenee | Unverified | Completare attribuzioni e verificare i termini di redistribuzione |
| `assets/textures/type_names/` | 18 | 44,4 KiB | Generate/adattate per il progetto | Creato per il progetto, prova pendente | Archiviare sorgente grafica e dichiarazione dell'autore |
| `assets/textures/gui/` | 105 | 532,7 KiB | In larga parte ereditati dall'app originale | Unverified | Verificare se coperti dalla GPL del repository a monte o da licenze separate |
| `assets/textures/trainers/` | 5 | 1,5 MiB | Materiale creato per Trainer Atlas 5e | Creato per il progetto, prova pendente | Archiviare autore, consenso del soggetto e termini di utilizzo |

## Fonti storiche già dichiarate a monte

La README di `Jerakin/Pokedex5E` dichiara che:

- le immagini Pokémon ad alta risoluzione provenivano da Bulbapedia;
- le immagini a bassa risoluzione provenivano da PokémonDB;
- i contenuti Pokémon e Dungeons & Dragons appartengono ai rispettivi titolari.

Questa dichiarazione identifica una provenienza, ma non dimostra una licenza di ridistribuzione compatibile con una pubblicazione sul Play Store.

## Evidenze puntuali rilevate

Il censimento automatico ha trovato evidenze vicine soltanto per 2 file nella famiglia degli oggetti. Per sapere esattamente quali, filtrare la colonna `evidence_files` di `docs/compliance/asset-manifest.csv`.

Questa copertura estremamente bassa conferma che un semplice elenco di attribuzioni non è sufficiente: serve una classificazione legale e tecnica delle famiglie principali.

## Regola per nuovi asset

Ogni nuovo asset deve essere accompagnato da uno dei seguenti elementi:

1. file `attribution.txt` nella stessa cartella;
2. voce in un inventario machine-readable con autore, fonte, licenza e URL;
3. dichiarazione di creazione originale del progetto;
4. autorizzazione scritta archiviata fuori dal repository pubblico quando contiene dati personali.

Non aggiungere asset con diciture vaghe come “preso da internet” o con sola attribuzione senza licenza.

## Build pubblicabile proposta

Prima della beta va prodotta una variante di build che includa esclusivamente:

- codice GPLv3 e dipendenze con licenze compatibili;
- dati con provenienza e licenza documentate;
- grafica originale o esplicitamente autorizzata;
- nessun manuale PDF o materiale di riferimento non destinato alla redistribuzione.

La priorità tecnica è separare la famiglia `assets/textures/textures_webapp/pokemon/`, che da sola occupa circa 304,9 MiB, e predisporre una modalità pubblica che possa escludere gli asset non autorizzati senza rompere l'interfaccia.
