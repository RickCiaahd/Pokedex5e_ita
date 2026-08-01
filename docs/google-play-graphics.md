# Grafiche e screenshot Google Play

Ultimo aggiornamento: 1 agosto 2026

## Stato attuale del branding

Il logo dell'onboarding e la nuova icona Android sono stati integrati, collaudati su dispositivo reale e uniti in `main` tramite la PR #168.

Asset canonici:

- icona sorgente: `docs/branding/trainer_atlas_app_icon_source.png`;
- logo completo: `assets/textures/trainers/trainer_atlas_logo.png`;
- registro di provenienza: `docs/branding/provenance.md`.

Le risorse launcher contenute nelle cartelle Android sono derivate tecniche e non devono essere usate come file promozionali dello Store.

## Risorse da preparare

### Icona Play Store

- esportare dalla sorgente `trainer_atlas_app_icon_source.png`;
- formato: PNG 32 bit con trasparenza;
- dimensioni: 512 × 512 px;
- peso massimo: 1024 KB;
- niente badge, prezzi, ranking o simboli ingannevoli;
- mantenere il soggetto principale centrato e leggibile anche in piccolo.

L'icona dello Store è distinta tecnicamente dall'icona launcher inclusa nell'AAB, ma deve usare lo stesso emblema e la stessa identità visiva.

Prima del caricamento verificare che l'export finale:

- non presenti bordi tagliati;
- non incorpori uno sfondo rettangolare indesiderato;
- resti leggibile nelle anteprime molto piccole;
- non contenga testi troppo minuti;
- sia coerente con l'icona mostrata nel launcher Android.

### Grafica in primo piano

- formato: JPEG oppure PNG 24 bit senza trasparenza;
- dimensioni: 1024 × 500 px;
- elementi importanti nella zona centrale;
- testo ridotto al minimo;
- nessun riferimento che faccia apparire l'app ufficiale o affiliata a terzi.

Proposta di composizione aggiornata:

- sfondo coerente con la palette ambra/oro del nuovo launcher, compreso il riferimento `#F2B34A` usato dall'icona adattiva;
- logo o emblema di Trainer Atlas 5e al centro-sinistra;
- breve richiamo visivo alla gestione di squadra e campagna;
- nessun logo Google Play;
- nessun artwork o marchio di terzi usato come elemento promozionale dominante.

La feature graphic non è ancora pronta e deve essere prodotta come asset separato.

### Screenshot telefono

Usare catture reali della build distribuita tramite Play Store. Non inserire funzioni non presenti e non modificare le schermate per simulare risultati diversi.

Sequenza proposta in italiano:

1. schermata iniziale con il nuovo logo Trainer Atlas 5e;
2. Home con accesso alle aree principali;
3. profilo Allenatore e riepilogo della campagna;
4. squadra con quattro o più Pokémon visibili;
5. dettaglio Pokémon con statistiche e informazioni;
6. Pokédex o catalogo con ricerca;
7. zaino e inventario;
8. strumenti del Master o gestione incontri.

Preparare la stessa sequenza in inglese oppure usare gli stessi screenshot soltanto dove il testo è neutro. Le localizzazioni della scheda Store dovrebbero mostrare preferibilmente l'interfaccia nella lingua corrispondente.

## Preparazione del dispositivo

Prima delle catture:

- installare la build dal canale interno o chiuso di Google Play;
- selezionare tema e dimensione caratteri standard;
- impostare lingua italiana per il primo set e inglese per il secondo;
- usare un profilo dimostrativo senza nomi, email o dati reali;
- riempire squadra, PC e zaino con dati sufficienti a evitare schermate vuote;
- disattivare notifiche o usare la modalità non disturbare;
- nascondere eventuali informazioni personali nella barra di stato;
- verificare che non siano visibili overlay di debug, indicatori FPS o banner di test.

## Criteri di qualità

- nessun overflow, testo tagliato o immagine mancante;
- immagini nitide e orientamento coerente;
- stessa risoluzione e rapporto tra gli screenshot dello stesso gruppo;
- contenuto leggibile su un normale schermo da telefono;
- niente cornici di dispositivi, claim, premi o classifiche non verificabili;
- niente schermate contenenti backup, nomi reali o identificativi personali;
- disclaimer e attribuzioni coerenti con la scheda Store;
- nessun riferimento a funzioni Premium o acquisti in-app finché non sono realmente implementati nella build.

## Controllo legale e di policy

Prima del caricamento, verificare separatamente:

- provenienza e licenza di ogni elemento grafico usato per icona e feature graphic;
- uso corretto di marchi e personaggi di terzi;
- assenza di elementi che suggeriscano affiliazione ufficiale;
- coerenza con il nome sviluppatore, la descrizione e il disclaimer;
- adeguatezza delle immagini al pubblico di destinazione dichiarato;
- completamento delle evidenze ancora richieste in `docs/branding/provenance.md`.

## Cartella di lavoro locale consigliata

Non inserire bozze contenenti dati personali nella repository. Organizzare localmente:

```text
play-store-assets/
  icon/
    trainer-atlas-512.png
  feature-graphic/
    trainer-atlas-feature-1024x500.png
  screenshots/
    it/
    en/
  source/
  export/
```

Conservare i file sorgente modificabili separatamente dagli export finali e annotare per ogni risorsa autore, provenienza e licenza.