# Audit preliminare di codice e licenze

Stato: **blocco P0 in corso**  
Ultimo aggiornamento: 27 luglio 2026

> Questo documento è un inventario tecnico e non costituisce consulenza legale. Prima della pubblicazione sul Play Store è necessaria una verifica professionale dei diritti sui contenuti e delle condizioni di distribuzione.

## 1. Progetto corrente

- Nome pubblico: **Trainer Atlas 5e**.
- Repository: `RickCiaahd/Pokedex5e_ita`.
- Application ID Android: `io.github.rickciaahd.traineratlas`.
- Distribuzione prevista: beta gratuita, senza pubblicità.
- Tecnologia: Flutter, con salvataggi locali Hive.

## 2. Provenienza principale

Il progetto è una reimplementazione Flutter che deriva e rielabora funzionalità, struttura e dati provenienti almeno dalle seguenti fonti:

1. `Jerakin/Pokedex5E` — applicazione originale Defold/Lua;
2. `poke5e.app` — riferimento web e sorgente di parte dei cataloghi più recenti;
3. manuali Pokémon 5e utilizzati come riferimento per regole e contenuti;
4. traduzioni italiane e modifiche applicative create nel repository corrente.

Il repository `Jerakin/Pokedex5E` dichiara la **GNU General Public License v3.0**. La sua README attribuisce inoltre le immagini Pokémon ad altre fonti e ai rispettivi titolari. La GPL del codice non trasferisce automaticamente diritti su marchi, artwork o contenuti di terzi.

## 3. Scelta di licenza del codice

Per mantenere compatibilità con la provenienza GPLv3, il codice licenziabile di Trainer Atlas 5e viene dichiarato **GPL-3.0-only**.

Azioni introdotte da questo blocco:

- file `LICENSE` nel repository;
- avviso GPL e collegamento al codice sorgente nell'interfaccia;
- pagina interna Licenze e attribuzioni;
- accesso alle licenze dei pacchetti Flutter tramite `showLicensePage`.

### Requisito ancora bloccante

Il file `LICENSE` contiene per ora la dichiarazione e il collegamento al testo canonico. Prima di qualsiasi distribuzione pubblica deve essere sostituito o affiancato da una copia **integrale e verbatim** della GPLv3 inclusa anche nel pacchetto distribuito.

## 4. Obblighi operativi da rispettare

Per ogni APK, AAB, archivio Windows o altra copia distribuita, il processo di release deve almeno:

- mantenere gli avvisi di copyright e licenza applicabili;
- indicare chiaramente che la versione è stata modificata rispetto ai progetti a monte;
- rendere disponibile il codice sorgente corrispondente della stessa versione distribuita;
- includere una copia completa della GPLv3;
- mantenere script, configurazioni e istruzioni necessari a ricostruire la release;
- documentare eventuali componenti con licenze differenti;
- evitare di presentare marchi o contenuti di terzi come coperti dalla GPL.

La possibile applicazione degli obblighi GPLv3 relativi alle informazioni di installazione e la compatibilità concreta con le condizioni dello store devono essere verificate prima della pubblicazione.

## 5. Dipendenze Flutter

Le dipendenze dirette dichiarate comprendono Flutter, `flutter_localizations`, `intl`, Hive, `file_picker`, `share_plus`, `scrollable_positioned_list` e `cupertino_icons`.

Le licenze dei pacchetti vengono raccolte dal registro licenze di Flutter e mostrate nell'app. Prima della release va generato anche un report riproducibile delle dipendenze dirette e transitive con nome, versione e licenza.

## 6. Contenuti non risolti dalla GPL

Restano separati e potenzialmente bloccanti:

- nomi, marchi e personaggi Pokémon;
- artwork, sprite, icone e immagini degli oggetti;
- nomi e materiali Dungeons & Dragons;
- testo delle regole e dei manuali;
- dati o asset provenienti dal sito `poke5e.app` per i quali non è stata ancora archiviata una licenza esplicita;
- immagini provenienti storicamente da Bulbapedia, PokémonDB o altre raccolte.

Un disclaimer di non affiliazione non equivale a un'autorizzazione alla redistribuzione.

## 7. Esito preliminare

| Area | Stato | Decisione |
|---|---|---|
| Codice derivato da Jerakin/Pokedex5E | Compatibile in via prudenziale con GPLv3 | Distribuire il codice corrente come GPL-3.0-only |
| Testo completo GPL nel pacchetto | Non completato | Bloccante prima della beta pubblica |
| Codice sorgente corrispondente | Repository pubblico presente | Collegare ogni release a tag/commit esatto |
| Dipendenze Flutter | Licenze runtime consultabili | Generare inventario versionato prima della release |
| Dati di gioco | Provenienza mista | Verificare licenza per ogni catalogo |
| Artwork e sprite Pokémon | Diritti non verificati | Sostituire, ottenere autorizzazione o escludere dalla build pubblica |
| Marchi e nomi | Proprietà di terzi | Uso da sottoporre a valutazione legale |

## 8. Prossimi passi

1. includere il testo integrale GPLv3;
2. generare SBOM/licence report delle dipendenze;
3. completare l'inventario per file o famiglia di asset;
4. eliminare i fallback remoti e verificare il funzionamento offline;
5. definire una build pubblicabile priva di asset non autorizzati;
6. effettuare una revisione legale prima di caricare materiale sul Play Store.
