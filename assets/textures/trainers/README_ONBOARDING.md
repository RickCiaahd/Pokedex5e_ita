# Asset grafici dell'onboarding

Lo scheletro dell'onboarding carica automaticamente questi tre file.

## 1. Copertina

`onboarding_welcome_background.webp`

- sfondo verticale della schermata iniziale;
- formato consigliato: 1440 × 2560 px, rapporto 9:16;
- lascia libera la zona centrale per logo e titolo.

## 2. Laboratorio

`onboarding_lab_background.webp`

- sfondo usato in tutte le schermate del Professore;
- formato consigliato: 1440 × 2560 px, rapporto 9:16;
- evita personaggi e testi; finestra e scaffali possono stare ai lati.

## 3. Professore

`onboarding_professor.png`

- personaggio con sfondo trasparente;
- formato consigliato: almeno 1200 × 1800 px;
- figura intera o a tre quarti, allineata al bordo inferiore;
- lascia margine trasparente intorno a capelli, mani e tablet.

Inserire tutti e tre i file in:

`assets/textures/trainers/`

Non occorre modificare `pubspec.yaml`: la cartella è già inclusa negli asset Flutter.
Se un file manca, l'app mostra un segnaposto con il nome esatto da usare.
