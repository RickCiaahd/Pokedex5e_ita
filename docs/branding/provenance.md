# Provenienza del branding Trainer Atlas

Ultimo aggiornamento: 1 agosto 2026

Questo documento registra soltanto informazioni non sensibili utili all'audit degli asset. Non sostituisce una liberatoria, una licenza o una consulenza legale.

## Asset registrati

| Asset | Uso | Prima introduzione nel repository |
|---|---|---|
| `docs/branding/trainer_atlas_app_icon_source.png` | sorgente dell'icona dell'app e degli export per lo Store | commit `cf7ffc2f9699512ebff6db6686222ba0b9468299` del 31 luglio 2026 |
| `assets/textures/trainers/trainer_atlas_logo.png` | logo trasparente della schermata iniziale dell'onboarding | commit `cf7ffc2f9699512ebff6db6686222ba0b9468299` del 31 luglio 2026 |

Gli asset sono stati forniti dal proprietario del progetto e integrati nella PR #168, unita in `main` con merge commit `4a52896686566f368f7b1e77464fa251d2bcdfc6`.

## Derivati tecnici

Dalla sorgente dell'icona sono state generate:

- icone launcher Android legacy nelle cartelle `mipmap-*`;
- foreground dell'icona adattiva Android;
- splash Android basata sul foreground adattivo.

Il logo completo viene invece usato nell'onboarding. La tagline rimane testo separato.

## Verifica tecnica e manuale

Il 1 agosto 2026 il proprietario ha confermato il corretto funzionamento su dispositivo Android di:

- logo dell'onboarding;
- ridimensionamento con caratteri normali e ingranditi;
- icona nel launcher;
- splash iniziale;
- lettura TalkBack senza duplicazioni del nome dell'app.

## Evidenze ancora da archiviare

Prima di considerare gli asset completamente verificati, il proprietario deve conservare una dichiarazione non ambigua che riporti:

- autore o creatore effettivo;
- strumento, servizio o software usato;
- eventuale prompt o procedimento di generazione, se applicabile;
- eventuali immagini o materiali di partenza;
- termini d'uso applicabili al servizio impiegato;
- conferma che non sono stati incorporati asset di terzi privi di autorizzazione;
- file sorgente modificabile, quando disponibile.

Le informazioni sensibili o contenenti metadati personali possono essere conservate fuori dalla repository; nel repository è sufficiente una sintesi verificabile e non sensibile.

## Stato audit

Stato corrente: `project-created-pending-proof`.

Il presente registro dimostra la data di introduzione, l'uso e il collaudo, ma non dimostra ancora da solo la titolarità o la licenza commerciale degli elementi grafici.