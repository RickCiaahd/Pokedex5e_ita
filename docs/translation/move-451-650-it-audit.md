# Audit della localizzazione italiana delle mosse 451-650

## Ambito

Questo blocco localizza le mosse dalla posizione **451** alla **650** del catalogo unificato restituito da `MoveRepository.getAllMoves()`, da `Mist Ball` a `Sludge Bomb`.

Sono state aggiunte **200 localizzazioni**, suddivise in quattro overlay da 50 elementi.

## Nomi italiani

I 200 nomi visualizzati sono stati verificati tramite il riferimento italiano delle mosse di Pokémon Central e confrontati con i dati italiani di PokéAPI. Tutte le voci del blocco hanno un equivalente ufficiale italiano.

| Nome tecnico | Nome visualizzato |
| --- | --- |
| Mist Ball | Foschisfera |
| Misty Terrain | Campo Nebbioso |
| Nature’s Madness | Ira della Natura |
| Photon Geyser | Geyser Fotonico |
| Psychic Noise | Psicorumore |
| Raging Bull | Scatenatoro |
| Revival Blessing | Preghiera Vitale |
| Sludge Bomb | Fangobomba |

## Descrizioni 5e

Per ogni mossa sono stati conservati numero e ordine dei blocchi, presenza di `higherLevels`, dadi, numeri, formule, distanze, livelli, durate e riferimenti tecnici. Le tabelle di Dononaturale, Naturforza, Alta Cucina, Scatenatoro e Forzasegreta sono state ricostruite con intestazioni e valori italiani controllati.

ID, slug, nome tecnico inglese, tipo, PP, potenza, TM, tiri salvezza, attacchi e dati di danno restano nei file sorgente originali.

## Compatibilità

Il nome inglese continua a essere usato nei salvataggi, nei learnset, nei trasferimenti e nei Fakemon. Il repository risolve ogni mossa tramite ID, nome tecnico inglese o nome italiano visualizzato.

## Controlli

I test automatici verificano la copertura esatta delle prime 650 mosse, l’assenza di duplicati, la corrispondenza dei nomi tecnici, il numero dei blocchi descrittivi e la conservazione dei token meccanici.
