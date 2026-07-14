from pathlib import Path

battle = Path('lib/screens/battle/battle_screen.dart')
text = battle.read_text(encoding='utf-8')
text = text.replace("import '../../models/pokemon_nature.dart';\n", '', 1)
battle.write_text(text, encoding='utf-8')

smoke = Path('test/trainer_path_passive_smoke_test.dart')
text = smoke.read_text(encoding='utf-8')
text = text.replace(
    'slot: const TeamSlot(slotIndex: 0, pokemonId: 1),',
    'slot: TeamSlot(slotIndex: 0, pokemonId: 1),',
    1,
)
smoke.write_text(text, encoding='utf-8')

Path('.github/workflows/agent-fix-trainer-path-passives.yml').unlink(
    missing_ok=True,
)

Path('.github/workflows/flutter-ci.yml').write_text('''name: Flutter CI

on:
  push:
    branches:
      - main
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: flutter-ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  quality:
    name: Analyze and test
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Show Flutter version
        run: flutter --version

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze source
        run: flutter analyze

      - name: Validate application data
        run: |
          set -o pipefail
          flutter test test/data_integrity_test.dart --reporter expanded 2>&1 | tee data-validation.log

      - name: Upload validation log
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: data-validation-log
          path: data-validation.log
          if-no-files-found: ignore
          retention-days: 7

      - name: Run complete test suite
        run: flutter test --reporter expanded
''', encoding='utf-8')

# Changelog.
