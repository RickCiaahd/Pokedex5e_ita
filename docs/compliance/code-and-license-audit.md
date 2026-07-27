# Audit preliminare di codice e licenze

Stato: **blocco P0 avanzato, ma ancora bloccante per gli asset**  
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

Azioni completate:

- `LICENSE` contiene il testo integrale e non modificato della GNU GPLv3;
- `NOTICE.md` separa gli avvisi del progetto, la provenienza a monte e i limiti relativi ai contenuti di terzi;
- l'interfaccia espone licenza, codice sorgente e attribuzioni;
- la pagina interna delle licenze mostra gli avvisi registrati da Flutter tramite `showLicensePage`;
- il workflow `Compliance audit` verifica che il testo GPL sia completo.

Il requisito del testo integrale GPL non è più aperto. Resta necessario assicurarsi che ogni pacchetto binario distribuito contenga o accompagni effettivamente `LICENSE` e `NOTICE.md` e colleghi il tag o commit del codice sorgente corrispondente.

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

Il generatore `tooling/generate_compliance_reports.py` legge `pubspec.lock` e i file di licenza installati da `flutter pub get`, quindi produce:

- `docs/compliance/dependency-licenses.md`;
- `docs/compliance/dependency-licenses.csv`.

Il report corrente censisce **74 pacchetti**: 58 rilevati come BSD-3-Clause, 6 Apache-2.0, 6 MIT, 1 MPL-2.0 e 3 pacchetti SDK senza un file di licenza nella radice specifica del package. Questi ultimi sono `flutter_localizations`, `flutter_test` e `flutter_web_plugins`; devono essere ricondotti e verificati rispetto alla licenza del Flutter SDK durante la revisione finale.

La classificazione è euristica. I testi originali delle licenze, gli hash registrati e la pagina licenze runtime restano le evidenze da confrontare.

## 6. Censimento degli asset

Il generatore produce inoltre:

- `docs/compliance/asset-audit-summary.md`;
- `docs/compliance/asset-manifest.csv`.

Il manifest corrente censisce **8.539 file per 332,1 MiB**. Soltanto 2 file risultano coperti da un'evidenza di attribuzione o licenza trovata nella cartella o in una cartella antenata. La presenza di tale evidenza non dimostra comunque il diritto di redistribuzione.

La classificazione prudenziale corrente è:

- 6.441 file `not-cleared`;
- 1.643 file `mixed`;
- 432 file `unverified`;
- 23 file `project-created-pending-proof`.

Questi numeri rendono gli asset il principale blocco residuo per una build pubblica.

## 7. Contenuti non risolti dalla GPL

Restano separati e potenzialmente bloccanti:

- nomi, marchi e personaggi Pokémon;
- artwork, sprite, icone e immagini degli oggetti;
- nomi e materiali Dungeons & Dragons;
- testo delle regole e dei manuali;
- dati o asset provenienti dal sito `poke5e.app` per i quali non è stata ancora archiviata una licenza esplicita;
- immagini provenienti storicamente da Bulbapedia, PokémonDB o altre raccolte.

Un disclaimer di non affiliazione non equivale a un'autorizzazione alla redistribuzione.

## 8. Esito preliminare

| Area | Stato | Decisione |
|---|---|---|
| Codice derivato da Jerakin/Pokedex5E | Compatibile in via prudenziale con GPLv3 | Distribuire il codice corrente come GPL-3.0-only |
| Testo completo GPL nel repository | Completato | Verificare l'inclusione nei pacchetti finali |
| Codice sorgente corrispondente | Repository pubblico presente | Collegare ogni release a tag/commit esatto |
| Dipendenze Flutter | Inventario versionato generato | Rivedere i 3 package SDK e confrontare gli avvisi runtime |
| Dati di gioco | Provenienza mista | Verificare licenza per ogni catalogo |
| Artwork e sprite Pokémon | Diritti non verificati | Sostituire, ottenere autorizzazione o escludere dalla build pubblica |
| Marchi e nomi | Proprietà di terzi | Uso da sottoporre a valutazione legale |

## 9. Prossimi passi

1. verificare manualmente le tre dipendenze SDK senza evidenza locale specifica;
2. collegare ciascuna famiglia o singolo asset a fonte, autore e licenza verificabile;
3. misurare l'impatto delle famiglie di asset sull'AAB e progettare una variante pubblicabile;
4. includere automaticamente `LICENSE`, `NOTICE.md` e i report rilevanti nei pacchetti release;
5. definire una build priva di asset non autorizzati;
6. effettuare una revisione legale prima di caricare materiale sul Play Store.
