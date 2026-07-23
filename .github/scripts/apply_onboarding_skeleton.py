from __future__ import annotations

from pathlib import Path

SOURCE = Path("lib/screens/onboarding/first_launch_onboarding_screen_impl.dart")
TARGET = Path("lib/screens/onboarding/first_launch_onboarding_screen.dart")
ASSET_DIRECTORY = Path("assets/textures/trainers")

WELCOME_SECTION = r'''class _OnboardingAssets {
  const _OnboardingAssets._();

  static const welcomeBackground =
      'assets/textures/trainers/onboarding_welcome_background.webp';
  static const laboratoryBackground =
      'assets/textures/trainers/onboarding_lab_background.webp';
  static const professor =
      'assets/textures/trainers/onboarding_professor.png';
}

class _WelcomeStage extends StatelessWidget {
  const _WelcomeStage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _OnboardingAssetImage(
            path: _OnboardingAssets.welcomeBackground,
            fit: BoxFit.cover,
            fallback: _WelcomeBackgroundPlaceholder(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x08FFFFFF),
                  Color(0x24FFFFFF),
                  Color(0x66FFF8ED),
                ],
                stops: [0, .48, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .82),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.catching_pokemon,
                    size: 72,
                    color: _OnboardingPalette.rust,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TRAINER ATLAS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _OnboardingPalette.text,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Color(0x44FFFFFF), blurRadius: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Il tuo compagno per le avventure da tavolo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _OnboardingPalette.rust,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAssetImage extends StatelessWidget {
  const _OnboardingAssetImage({
    required this.path,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String path;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _WelcomeBackgroundPlaceholder extends StatelessWidget {
  const _WelcomeBackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF7FB), Color(0xFFFFF4DE)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: 'SFONDO COPERTINA',
            fileName: 'onboarding_welcome_background.webp',
          ),
        ),
      ),
    );
  }
}
'''

SCENE_SECTION = r'''class _ProfessorScene extends StatelessWidget {
  const _ProfessorScene({
    super.key,
    required this.child,
    required this.compactCardTopFactor,
  });

  final Widget child;
  final double compactCardTopFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final proposedCardTop = constraints.maxHeight * compactCardTopFactor;
        final maximumCardTop = math.max(160.0, constraints.maxHeight - 140);
        final cardTop = math.min(
          maximumCardTop,
          math.max(190.0, proposedCardTop),
        );
        final horizontalInset = constraints.maxWidth < 760 ? 14.0 : 34.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _OnboardingAssetImage(
                    path: _OnboardingAssets.laboratoryBackground,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    fallback: _LaboratoryBackgroundPlaceholder(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x08FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x33FFF2EA),
                        ],
                        stops: [0, .55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth < 760 ? 28 : 88,
                    right: constraints.maxWidth < 760 ? 28 : 88,
                    top: 8,
                    height: cardTop + 78,
                    child: const _ProfessorPortrait(),
                  ),
                  Positioned(
                    left: horizontalInset,
                    right: horizontalInset,
                    top: cardTop,
                    bottom: 14,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfessorPortrait extends StatelessWidget {
  const _ProfessorPortrait();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingAssetImage(
      path: _OnboardingAssets.professor,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      fallback: _ProfessorAssetPlaceholder(),
    );
  }
}

class _LaboratoryBackgroundPlaceholder extends StatelessWidget {
  const _LaboratoryBackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4EFEA), Color(0xFFFFF7F1)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: 'SFONDO LABORATORIO',
            fileName: 'onboarding_lab_background.webp',
          ),
        ),
      ),
    );
  }
}

class _ProfessorAssetPlaceholder extends StatelessWidget {
  const _ProfessorAssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 260,
        height: 330,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .64),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(120),
            bottom: Radius.circular(28),
          ),
          border: Border.all(color: const Color(0xFFBCA99F), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              size: 72,
              color: _OnboardingPalette.rust,
            ),
            SizedBox(height: 12),
            Text(
              'PROFESSORE PNG\nTRASPARENTE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _OnboardingPalette.rust,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'onboarding_professor.png',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingAssetLabel extends StatelessWidget {
  const _MissingAssetLabel({
    required this.title,
    required this.fileName,
  });

  final String title;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _OnboardingPalette.border),
      ),
      child: Text(
        '$title  ·  $fileName',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _OnboardingPalette.rust,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
'''

README = """# Asset grafici dell'onboarding

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
"""


def replace_section(text: str, start: str, end: str, replacement: str) -> str:
    start_index = text.index(start)
    end_index = text.index(end, start_index)
    return text[:start_index] + replacement.rstrip() + "\n\n" + text[end_index:]


def main() -> None:
    text = SOURCE.read_text(encoding="utf-8")

    old_factors = """    final compactCardFactor = switch (_step) {
      6 => .19,
      7 || 8 || 9 => .24,
      _ => .41,
    };"""
    new_factors = """    final compactCardFactor = switch (_step) {
      6 => .46,
      7 => .42,
      8 || 9 => .54,
      _ => .55,
    };"""
    if text.count(old_factors) != 1:
        raise RuntimeError("Fattori della card onboarding inattesi")
    text = text.replace(old_factors, new_factors, 1)

    text = replace_section(
        text,
        "class _WelcomeStage extends StatelessWidget {",
        "class _ProfessorScene extends StatelessWidget {",
        WELCOME_SECTION,
    )
    text = replace_section(
        text,
        "class _ProfessorScene extends StatelessWidget {",
        "class _DialogueCard extends StatelessWidget {",
        SCENE_SECTION,
    )

    TARGET.write_text(text, encoding="utf-8")
    SOURCE.unlink()

    ASSET_DIRECTORY.mkdir(parents=True, exist_ok=True)
    (ASSET_DIRECTORY / "README_ONBOARDING.md").write_text(
        README,
        encoding="utf-8",
    )

    for obsolete in [
        ASSET_DIRECTORY / "professor_riccardo.webp",
        Path(".github/workflows/apply-onboarding-asset-skeleton.yml"),
        Path(".github/onboarding-skeleton-retry.md"),
        Path(".github/onboarding-skeleton-error.log"),
        Path(__file__),
    ]:
        obsolete.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
