# Grafiche e screenshot Google Play

Ultimo aggiornamento: 1 agosto 2026

## Stato attuale del branding

Il logo dell'onboarding e la nuova icona Android sono stati integrati, collaudati su dispositivo reale e uniti in `main` tramite la PR #168.

Asset canonici:

- icona sorgente: `docs/branding/trainer_atlas_app_icon_source.png`;
- logo completo: `assets/textures/trainers/trainer_atlas_logo.png`;
- registro di provenienza: `docs/branding/provenance.md`.

Le risorse launcher contenute nelle cartelle Android sono derivate tecniche e non devono essere usate come file promozionali dello Store.

## Stato degli asset Play Store

### Icona Play Store

La sorgente è disponibile e l'icona è stata usata nella compilazione della scheda Store. Prima del salvataggio definitivo controllare ancora l'anteprima mostrata dalla Play Console.

Requisiti di riferimento:

- formato: PNG 32 bit con trasparenza;
- dimensioni: 512 × 512 px;
- peso massimo: 1024 KB;
- niente badge, prezzi, ranking o simboli ingannevoli;
- soggetto principale centrato e leggibile anche in piccolo.

L'icona dello Store è distinta tecnicamente dall'icona launcher inclusa nell'AAB, ma deve usare lo stesso emblema e la stessa identità visiva.

Controlli finali:

- nessun bordo tagliato;
- nessuno sfondo rettangolare indesiderato;
- leggibilità nelle anteprime molto piccole;
- nessun testo troppo minuto;
- coerenza con l'icona mostrata nel launcher Android.

### Grafica in primo piano

Un candidato conforme è stato preparato il 1 agosto 2026 con queste caratteristiche:

- formato PNG RGB senza trasparenza;
- dimensioni 1024 × 500 px;
- palette ambra/oro coerente con il launcher;
- logo Trainer Atlas 5e e simbolo grafico del progetto;
- nessun personaggio o marchio di terzi usato come elemento promozionale dominante;
- nessun logo Google Play, prezzo, ranking o claim ingannevole.

La grafica deve essere approvata soltanto dopo il controllo dell'anteprima nella Play Console.

### Screenshot smartphone

Sono stati preparati e caricati screenshot reali dell'interfaccia smartphone per la scheda italiana.

Ordine consigliato:

1. Home con accesso alle aree principali;
2. squadra con più Pokémon visibili;
3. dettaglio Pokémon con statistiche e informazioni;
4. profilo Allenatore e riepilogo della progressione;
5. Pokédex o catalogo con ricerca;
6. zaino oppure strumenti del Master.

Home, squadra e dettaglio Pokémon devono restare nelle prime posizioni perché comunicano immediatamente la funzione principale dell'app. L'onboarding non è necessario come primo screenshot, dato che logo e identità visiva sono già rappresentati da icona e feature graphic.

### Screenshot tablet da 7 pollici

La Play Console non li ha richiesti come obbligatori per completare la scheda corrente. Vengono quindi rimandati e non devono bloccare il test interno.

Non riutilizzare screenshot smartphone ingranditi o deformati. Quando verranno aggiunti, dovranno essere catturati realmente da una build release eseguita su un emulatore o dispositivo grande.

Profilo di collaudo suggerito:

```text
Dimensione schermo: 7,0 pollici
Risoluzione: 1200 × 1920
Densità: 320 dpi
Orientamento: verticale
Android: 15 o 16
```

Sequenza minima tablet:

1. Home;
2. squadra;
3. dettaglio Pokémon;
4. Pokédex oppure strumenti del Master.

Prima delle catture tablet verificare layout, spazi vuoti, leggibilità, overflow e funzionamento della navigazione. Eventuali problemi devono essere corretti nell'app prima di produrre gli asset definitivi.

## Localizzazioni

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

Prima del caricamento definitivo, verificare separatamente:

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
