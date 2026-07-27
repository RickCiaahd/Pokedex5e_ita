# Inventario preliminare degli asset

Stato: **incompleto e bloccante per la pubblicazione**  
Ultimo aggiornamento: 27 luglio 2026

Questo inventario raggruppa gli asset per famiglia. Non autorizza la redistribuzione: quando la licenza non è documentata, lo stato deve essere considerato **non verificato**.

## Legenda

- **Verificato**: fonte e licenza archiviate nel repository.
- **Da confermare**: fonte probabile nota, ma licenza o catena di attribuzione incompleta.
- **Non pubblicabile**: nessuna base di redistribuzione verificata; sostituire, rimuovere o ottenere autorizzazione.
- **Creato per il progetto**: prodotto specificamente per Trainer Atlas 5e; archiviare comunque autore e termini.

## Inventario per famiglia

| Percorso o famiglia | Contenuto | Provenienza attuale | Stato | Azione richiesta |
|---|---|---|---|---|
| `assets/data/` | Dati legacy, overlay italiani, mappe e metadati | Pokedex5E, manuali, lavoro del progetto | Da confermare | Collegare ogni file alla sorgente e distinguere dati originali, trasformati e tradotti |
| `assets/data_webapp/` | Cataloghi Pokémon, mosse, abilità e oggetti recenti | `poke5e.app` e conversioni interne | Da confermare | Archiviare repository/licenza esatti della sorgente e data del prelievo |
| `assets/textures/pokemons/` | Artwork grandi | Set storico dell'app originale e fonti Pokémon | Non pubblicabile | Sostituire con asset autorizzati o escludere dalla build pubblica |
| `assets/textures/sprites/` | Sprite e miniature | Set storico dell'app originale e fonti Pokémon | Non pubblicabile | Sostituire con asset autorizzati o escludere dalla build pubblica |
| `assets/textures/textures_webapp/pokemon/` | Artwork e sprite del catalogo web | `poke5e.app` e relative fonti | Da confermare / non pubblicabile | Verificare licenza per ogni famiglia; non presumere che il sito conceda redistribuzione |
| `assets/textures/textures_webapp/pokemon_transforms/` | Mega, Dynamax, Gigamax, Terastal e altre trasformazioni | Catalogo web | Da confermare / non pubblicabile | Verificare fonte e licenza per ciascun set |
| `assets/textures/textures_webapp/items/` | Icone degli oggetti | Catalogo web e fonti eterogenee | Da confermare | Conservare gli `attribution.txt`, completarli e verificare i file privi di attribuzione |
| `assets/textures/type_names/` | Etichette grafiche italiane dei tipi | Generate/adattate per il progetto | Creato per il progetto, da documentare | Archiviare sorgente grafica e dichiarazione dell'autore; mantenere fallback testuali inglesi |
| `assets/textures/gui/` | Bordi, pulsanti, icone e status | In larga parte ereditati dall'app originale | Da confermare | Verificare se coperti dalla GPL del repository a monte o da licenze separate |
| `assets/textures/trainers/` | Professore e sfondi onboarding | Materiale creato per Trainer Atlas 5e | Creato per il progetto | Archiviare autore, consenso del soggetto e termini di utilizzo dell'immagine |
| Icone Material/Cupertino | Icone dell'interfaccia | Flutter e pacchetti | Verificato tramite licenze pacchetti | Mantenere gli avvisi generati da `LicenseRegistry` |
| Testi tradotti italiani | Overlay e stringhe UI | Lavoro del progetto, con terminologia verificata | Creato per il progetto | Attribuire i contributori e conservare fonti terminologiche |
| Manuali PDF e materiali di riferimento | Regole Pokémon 5e e D&D | Autori e titolari esterni | Non distribuire nell'app | Usare solo come riferimento interno salvo licenza esplicita |

## Fonti storiche già dichiarate a monte

La README di `Jerakin/Pokedex5E` dichiara che:

- le immagini Pokémon ad alta risoluzione provenivano da Bulbapedia;
- le immagini a bassa risoluzione provenivano da PokémonDB;
- i contenuti Pokémon e Dungeons & Dragons appartengono ai rispettivi titolari.

Questa dichiarazione identifica una provenienza, ma non dimostra una licenza di ridistribuzione compatibile con una pubblicazione sul Play Store.

## Attribuzioni puntuali già presenti

Il repository contiene almeno alcuni file `attribution.txt`, per esempio sotto le cartelle degli oggetti. Devono essere censiti automaticamente e confrontati con il numero totale di asset prima della release.

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
- nessun fallback remoto non documentato;
- nessun manuale PDF o materiale di riferimento non destinato alla redistribuzione.

## Attività automatiche da aggiungere

- scansione di tutti i file sotto `assets/`;
- report dei file senza attribuzione o record inventario;
- rilevazione di URL remoti nel codice;
- report dimensioni per famiglia di asset;
- confronto tra manifest Flutter e inventario;
- blocco CI della release quando un nuovo asset non ha una classificazione.
