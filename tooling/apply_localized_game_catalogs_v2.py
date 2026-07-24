from pathlib import Path
import runpy

root = Path(__file__).resolve().parents[1]

move_data = root / 'lib/models/move_data.dart'
text = move_data.read_text(encoding='utf-8')
old = "    if (saveMap == null) return null;\n\n    final attributes ="
new = "    if (saveMap == null) return null;\n    final attributes ="
if old not in text:
    raise RuntimeError('Blocco _readSave originale non trovato')
move_data.write_text(text.replace(old, new, 1), encoding='utf-8')

move_repository = root / 'lib/repositories/move_repository.dart'
text = move_repository.read_text(encoding='utf-8')
normalizations = {
    "      final move = MoveData.fromJson(reference, json);\n":
        "       final move = MoveData.fromJson(reference, json);\n",
    "      final move = MoveData.fromWebJson(\n"
    "        _localizedMoveJson(sourceJson, localizations[moveId]),\n"
    "      );\n":
        "       final move = MoveData.fromWebJson(\n"
        "         _localizedMoveJson(sourceJson, localizations[moveId]),\n"
        "       );\n",
}
for source, target in normalizations.items():
    if source not in text:
        raise RuntimeError(f'Pattern repository mosse non trovato: {source!r}')
    text = text.replace(source, target, 1)
move_repository.write_text(text, encoding='utf-8')

runpy.run_path(
    str(root / 'tooling/apply_localized_game_catalogs.py'),
    run_name='__main__',
)
