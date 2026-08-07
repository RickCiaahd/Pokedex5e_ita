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
path.write_text(text, encoding='utf-8')
