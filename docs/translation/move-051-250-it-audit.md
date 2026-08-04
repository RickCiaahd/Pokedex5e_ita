# Audit della localizzazione italiana delle mosse 51-250

## Ambito

Questo blocco localizza le mosse dalla posizione **51** alla **250** del catalogo unificato restituito da `MoveRepository.getAllMoves()`, da `Behemoth Blade` a `Flatter`.

Sono state aggiunte **200 localizzazioni**, suddivise in 20 overlay da 10 elementi per mantenere leggibili differenze e controlli automatici.

## Nomi italiani

I nomi visualizzati sono stati confrontati con:

- Pokémon Central, pagina *Elenco delle mosse in altre lingue*;
- dati italiani di PokéAPI, file `move_names.csv`.

Risultato del blocco:

- **199 nomi ufficiali italiani** applicati alla UI;
- **1 voce personalizzata**, `Draco Power`, mantenuta con il nome tecnico perché non è stata trovata una mossa ufficiale corrispondente;
- `Blood Moon`, assente nel dump PokéAPI usato dall’audit iniziale, è stato verificato su Pokémon Central e localizzato come **Luna Rossa**.

Esempi verificati:

| Nome tecnico | Nome visualizzato |
| --- | --- |
| Behemoth Blade | Taglio Maestoso |
| Bitter Blade | Lama del Rimorso |
| Blood Moon | Luna Rossa |
| Ceaseless Edge | Lama Milleflutti |
| Dragon Energy | Dragoenergia |
| Esper Wing | Ali d’Aura |
| Fiery Wrath | Furia Ardente |
| Flash | Flash |

## Descrizioni 5e

Per ogni mossa sono stati conservati:

- numero e ordine dei blocchi descrittivi;
- presenza o assenza di `higherLevels`;
- dadi, valori numerici e modificatori;
- distanze, livelli, durate e formule;
- riferimenti tecnici come `STAB`, `PP`, `SR` e `FLINCHED`; il token sorgente `MOVE` viene mostrato come **modificatore di caratteristica della mossa**;
- caratteristiche, CA/CD e relativi alias italiani.

ID, slug, nome tecnico inglese, tipo, PP, potenza, TM, tiri salvezza, attacchi e dati di danno restano nei file sorgente originali e non vengono modificati dagli overlay.

## Compatibilità

Il nome inglese continua a essere usato come riferimento tecnico nei salvataggi, nei learnset, nei trasferimenti e nei Fakemon. Il repository permette di risolvere una mossa tramite ID, nome tecnico inglese o nome italiano visualizzato.

## Controlli

I test automatici verificano:

- copertura esatta delle prime 250 mosse in ordine di catalogo;
- assenza di ID duplicati o mancanti;
- corrispondenza del `sourceName` con il catalogo originale;
- conteggio invariato dei blocchi descrittivi;
- conservazione dei token meccanici;
- corrispondenza dei 250 nomi con le fixture italiane verificate.
