# Branding Trainer Atlas

Questa cartella conserva i file sorgente ad alta risoluzione usati per il branding dell'app.

## Asset canonici

- `trainer_atlas_app_icon_source.png`: sorgente quadrata dell'icona dell'app.
- `assets/textures/trainers/trainer_atlas_logo.png`: logo trasparente mostrato nella schermata iniziale dell'onboarding.

Le risorse Android derivate si trovano sotto `android/app/src/main/res/`:

- icone launcher legacy nelle cartelle `mipmap-*`;
- foreground adattivo in `drawable-xxxhdpi/trainer_atlas_launcher_foreground.png`;
- configurazione adattiva in `drawable/ic_launcher_foreground.xml` e `mipmap-anydpi-v26/ic_launcher.xml`.

La tagline dell'onboarding rimane testo Flutter separato dal logo, così conserva localizzazione, ridimensionamento e accessibilità.

## Stato dell'integrazione

Il nuovo branding è stato integrato e collaudato nella PR #168, unita in `main` il 1 agosto 2026 con merge commit `4a52896686566f368f7b1e77464fa251d2bcdfc6`.

Il collaudo manuale ha coperto:

- onboarding con dimensione caratteri normale e ingrandita;
- icona nel launcher Android;
- splash iniziale;
- leggibilità della tagline;
- TalkBack senza annunci duplicati del nome dell'app.

## Esportazione per Google Play

L'icona da caricare nella scheda Google Play deve essere esportata dalla sorgente `trainer_atlas_app_icon_source.png` come PNG 512 × 512. Non usare direttamente uno dei file `mipmap-*`, perché sono risorse launcher ridimensionate per Android e non l'asset promozionale dello Store.

La grafica in primo piano e gli screenshot devono mantenere la stessa identità visiva, senza suggerire affiliazioni ufficiali con titolari di marchi terzi.

## Provenienza

Il registro non sensibile della provenienza e delle verifiche richieste è in [`provenance.md`](provenance.md).

Finché non viene completata la dichiarazione del proprietario sugli strumenti e sulle sorgenti usate per creare i due asset, l'audit li mantiene nello stato `project-created-pending-proof`.