# Audit della localizzazione italiana delle mosse 251-450

## Ambito

Questo blocco localizza le mosse dalla posizione **251** alla **450** del catalogo unificato restituito da `MoveRepository.getAllMoves()`, da `Fleur Cannon` a `Mist`.

Sono state aggiunte **200 localizzazioni**, suddivise in 5 overlay complessivi: il file 251-260 già avviato e quattro cataloghi da 40-50 elementi per mantenere leggibili differenze e controlli automatici.

## Nomi italiani

I nomi visualizzati sono stati confrontati con:

- Pokémon Central, pagina *Elenco delle mosse in altre lingue*;
- dati italiani di PokéAPI, file `move_names.csv`.

Risultato del blocco:

- **199 nomi ufficiali italiani** applicati alla UI;
- **1 voce personalizzata**, `Halo Song`, mantenuta con il nome tecnico perché non è stata trovata una mossa ufficiale corrispondente;
- `Ivy Cudgel` e `Matcha Gotcha`, non risolte dal dump PokéAPI usato dall’audit iniziale, sono state verificate su Pokémon Central e localizzate rispettivamente come **Clava di Liane** e **Spruzzatè**.

Esempi verificati:

| Nome tecnico | Nome visualizzato |
| --- | --- |
| Fleur Cannon | Cannonfiore |
| Flower Trick | Prestigiafiore |
| Gigaton Hammer | Granmartello |
| Hydro Steam | Idrovapore |
| Ivy Cudgel | Clava di Liane |
| Make it Rain | Corsa all’Oro |
| Matcha Gotcha | Spruzzatè |
| Mighty Cleave | Taglio Poderoso |

## Descrizioni 5e

Per ogni mossa sono stati conservati:

- numero e ordine dei blocchi descrittivi;
- presenza o assenza di `higherLevels`;
- dadi, valori numerici e modificatori;
- distanze, livelli, durate e formule;
- riferimenti tecnici come `MOVE`, `STAB`, `PP`, `SR` e `FLINCHED`;
- caratteristiche, CA/CD e relativi alias italiani;
- struttura e valori meccanici delle tabelle di `Hidden Power`, `Ivy Cudgel` e `Magnitude`.

ID, slug, nome tecnico inglese, tipo, PP, potenza, TM, tiri salvezza, attacchi e dati di danno restano nei file sorgente originali e non vengono modificati dagli overlay.

## Compatibilità

Il nome inglese continua a essere usato come riferimento tecnico nei salvataggi, nei learnset, nei trasferimenti e nei Fakemon. Il repository permette di risolvere una mossa tramite ID, nome tecnico inglese o nome italiano visualizzato.

## Controlli

I test automatici verificano:

- copertura esatta delle prime 450 mosse in ordine di catalogo;
- assenza di ID duplicati o mancanti;
- corrispondenza del `sourceName` con il catalogo originale;
- conteggio invariato dei blocchi descrittivi;
- conservazione dei token meccanici;
- corrispondenza dei 450 nomi con le fixture italiane verificate.
