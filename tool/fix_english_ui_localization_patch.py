from pathlib import Path

path = Path('tool/apply_english_ui_localization_pass.py')
text = path.read_text(encoding='utf-8')
text = text.replace(
    '"title: Text(uiTextForLanguage(\'Impossibile eliminare ${definition.name}\', \'Cannot delete ${definition.name}\')),\n",',
    '"title: Text(uiTextForLanguage(\'Impossibile eliminare ${definition.name}\', \'Cannot delete ${definition.name}\')),",',
)
text = text.replace(
    '"title: Text(uiTextForLanguage(\'Eliminare ${definition.name}?\', \'Delete ${definition.name}?\')),\n",',
    '"title: Text(uiTextForLanguage(\'Eliminare ${definition.name}?\', \'Delete ${definition.name}?\')),",',
)
text = text.replace(
    "import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';\n",
    '',
)

# The original temporary patch used a regex beginning with
# `if (dynamaxAbsorbed > 0)`. That condition appears twice in _changeHp and
# the first occurrence is part of the HP calculation, so the regex could
# consume gameplay code. Remove that patch entirely: the dedicated output
# repair script below the main patch rewrites only the final message block.
start_marker = "regex_replace(\n    path,\n    r\"    if \\(dynamaxAbsorbed > 0\\) \\{.*?"
end_marker = "replace_all(path, \"'${rule.label}: $currentHp PF temporanei',\""
start = text.find(start_marker)
end = text.find(end_marker, start)
if start < 0 or end < 0:
    raise SystemExit('ambiguous battle damage patch block not found')
text = text[:start] + text[end:]

path.write_text(text, encoding='utf-8')
