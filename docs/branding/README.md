# Branding Trainer Atlas

Questa cartella conserva i file sorgente ad alta risoluzione usati per il branding dell'app.

## Asset

- `trainer_atlas_app_icon_source.png`: sorgente quadrata dell'icona dell'app.
- `assets/textures/trainers/trainer_atlas_logo.png`: logo trasparente mostrato nella schermata iniziale dell'onboarding.

Le risorse Android derivate si trovano sotto `android/app/src/main/res/`:

- icone launcher legacy nelle cartelle `mipmap-*`;
- foreground adattivo in `drawable-xxxhdpi/trainer_atlas_launcher_foreground.png`;
- configurazione adattiva in `drawable/ic_launcher_foreground.xml` e `mipmap-anydpi-v26/ic_launcher.xml`.

La tagline dell'onboarding rimane testo Flutter separato dal logo, così conserva localizzazione, ridimensionamento e accessibilità.
