from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def insert_once(path: str, anchor: str, addition: str) -> None:
    file_path = ROOT / path
    source = file_path.read_text(encoding='utf-8')
    if addition in source:
        return
    if source.count(anchor) != 1:
        raise RuntimeError(f'{path}: expected one anchor, found {source.count(anchor)}')
    file_path.write_text(source.replace(anchor, anchor + addition, 1), encoding='utf-8')


insert_once(
    'lib/screens/tools/encounter_generator_screen.dart',
    "import '../../models/generated_encounter.dart';\n",
    "import '../../models/generated_pokemon.dart';\n",
)
insert_once(
    'lib/screens/tools/encounter_collection_editor_screen.dart',
    "import '../../models/encounter_collection.dart';\n",
    "import '../../models/generated_pokemon.dart';\n",
)

for relative in [
    'tool/encounter-form-analyze.txt',
    'tool/encounter-form-tests.txt',
    'tool/encounter-form-full-tests.txt',
]:
    path = ROOT / relative
    if path.exists():
        path.unlink()
