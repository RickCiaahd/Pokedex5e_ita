# Audit dei nomi italiani degli strumenti da tenere

Questo blocco confronta i 163 oggetti di tipo `held item` presenti in `assets/data_webapp/items.json` con Pokémon Central e, come controllo incrociato, con i dati italiani di PokéAPI.

## Criteri

- Pokémon Central è il riferimento principale per il nome mostrato nell'interfaccia.
- ID, nomi inglesi tecnici, costi, tipi, asset e riferimenti interni restano invariati.
- Le 112 descrizioni 5e presenti nel catalogo sono tradotte conservando paragrafi, dadi, valori numerici, sigle e nomi tecnici.
- Le 51 voci con `description: null` mantengono una descrizione vuota: il campo `_ingameEffect` non viene introdotto nella UI da questo blocco.
- `Megalite Stone` è una voce generica personalizzata del catalogo 5e e mantiene il nome originale.
- La corrispondenza completa e verificata dei 163 nomi è conservata nei file `test/fixtures/item_held_names_it_*.dart` ed è controllata automaticamente.

## Casi verificati separatamente

- `Ability Shield` → **Scudo abilità**
- `Booster Energy` → **Capsula energetica**
- `Clear Amulet` → **Ciondolochiaro**
- `Covert Cloak` → **Anonimanto**
- `Loaded Dice` → **Dado truccato**
- `Punching Glove` → **Guantone**
- `Mirror Herb` → **Foglia carbone**
- `Fairy Feather` → **Piuma fatata**
- `Gracidea Flower` → **Gracidea**
- `Leek` → **Porro**
- `Blue Orb` e `Red Orb` → **Gemma blu** e **Gemma rossa**, usando le denominazioni moderne.
- I 17 Memory Disc usano i nomi italiani **ROM** del tipo corrispondente.

Le fonti usate sono `Elenco degli strumenti in altre lingue` e le pagine dedicate agli strumenti di Pokémon Central, con il catalogo italiano di PokéAPI come verifica aggiuntiva.
