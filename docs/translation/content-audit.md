# Audit dei contenuti traducibili

Audit delle sorgenti caricate dall'app e dei valori localizzabili senza cambiare la struttura tecnica dei dati.

## Precedenza delle descrizioni Pokémon

La scheda riepilogativa del Pokédex usa due sorgenti:

1. per la forma base preferisce `assets/data/pokemon_flavor.json`;
2. per le forme alternative preferisce `description` in `assets/data_webapp/pokemon.json`;
3. quando la sorgente preferita è vuota, usa l'altra come fallback.

Il primo blocco riguarda quindi `genus` e `flavor` della sorgente mostrata per i Pokémon base di prima generazione. Le forme alternative saranno trattate separatamente.

## Cataloghi

| Categoria | Sorgente principale | Elementi rilevati | Campi visualizzati traducibili | Note |
| --- | --- | ---: | --- | --- |
| Pokémon base | `assets/data/pokemon_flavor.json` | almeno 151 nel primo blocco | `genus`, `flavor` | altezza e peso restano invariati |
| Pokémon e forme | `assets/data_webapp/pokemon.json` | 1151 | `description` | contiene anche i testi delle forme alternative |
| Mosse | `assets/data_webapp/moves.json` | 830 | `description[]`, `higherLevels`, `time`, `duration`, `range` | dadi, formule, PP, tipo, attacchi e CD restano invariati |
| Abilità | `assets/data_webapp/abilities.json` | 330 | `description` | ID, nome tecnico e stato restano invariati |
| Oggetti | `assets/data_webapp/items.json` | 366 | `description[]` | ID, nome tecnico, tipo, costo e asset restano invariati |
| Mosse legacy | `assets/data/moves/*.json` | catalogo per file | `Description`, `Scaling` e campi testuali | struttura e meccaniche restano identiche |
| Abilità legacy | `assets/data/abilities.json` | catalogo unico | `Description` | il catalogo web può sostituirne il testo a runtime |

## Strategia adottata

- Le traduzioni sono raccolte in cataloghi italiani separati, indicizzati dallo stesso ID numerico del Pokémon.
- `PokemonLocalizationRepository` unisce i blocchi italiani e convalida ID, duplicati e testi obbligatori.
- `PokemonRepository` applica soltanto genere e descrizione, conservando altezza, peso, statistiche, forme e riferimenti.
- I file sono divisi negli intervalli `001-050`, `051-100` e `101-151`.

## Vincoli tecnici

- ID, slug, chiavi JSON, nomi dei campi e struttura dei file sorgente restano invariati.
- Statistiche, formule, dadi, CD, portate, durate, PP, livelli e riferimenti alle regole non vengono alterati.
- Ogni traduzione corrisponde a una singola entità sorgente e contiene soltanto valori visualizzati dall'utente.
- Ogni blocco deve superare `flutter analyze`, test di integrità, suite completa e build Android.
- Web, Windows e Android continuano a leggere gli asset tramite `rootBundle`.

## Primo blocco: Generazione I

- Estratte e revisionate le 151 descrizioni mostrate per i Pokémon dal #001 al #151.
- Tradotti genere e descrizione senza cambiare altezza, peso o altri dati.
- Aggiunto `test/pokemon_localization_integrity_test.dart` per controllare copertura, unicità, struttura e conservazione dei valori originali.
- `gen1-source-descriptions.json` resta una base di confronto e non viene caricato dall'app.
