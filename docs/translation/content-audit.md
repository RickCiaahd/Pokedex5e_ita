# Audit dei contenuti traducibili

Audit generato automaticamente a partire dai cataloghi correnti della repository.

## Cataloghi

| Categoria | Sorgente | Elementi | Testi non vuoti | Testi probabilmente inglesi | Campi traducibili |
| --- | --- | ---: | ---: | ---: | --- |
| Pokémon | `assets/data_webapp/pokemon.json` | 1151 | 1151 | 1151 | `description` |
| Mosse | `assets/data_webapp/moves.json` | 830 | 0 | 0 | `description` e altri campi testuali da validare |
| Abilità | `assets/data_webapp/abilities.json` | 330 | 330 | 330 | `description` |
| Oggetti | `assets/data_webapp/items.json` | 366 | 0 | 0 | campi descrittivi visualizzati |

## Vincoli tecnici

- ID, slug, chiavi JSON, nomi dei campi e struttura dei file devono restare invariati.
- Statistiche, formule, dadi, CD, portate, durate, PP, livelli e riferimenti alle regole non devono essere alterati.
- Le traduzioni devono essere applicate come valori localizzati caricati dal repository, senza duplicare o rinominare le entità tecniche.
- Ogni blocco deve superare `flutter analyze`, il test di integrità dei dati, la suite completa e la build Android.

## Primo blocco

- Estratte 151 descrizioni sorgente per i Pokémon dal #001 al #151.
- Il file `gen1-source-descriptions.json` è una base di revisione e non viene caricato dall’app.
