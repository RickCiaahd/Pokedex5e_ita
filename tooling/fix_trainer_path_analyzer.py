from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return text.replace(old, new, 1)


path = Path('lib/screens/trainer/trainer_sheet_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "    if (definition == null) return;\n    setState(() {\n      _trainerPathResources = {\n        ..._trainerPathResources,\n        resourceId: value.clamp(0, definition.maxUses).toInt(),",
    "    if (definition == null) return;\n    final maxUses = definition.maxUses;\n    setState(() {\n      _trainerPathResources = {\n        ..._trainerPathResources,\n        resourceId: value.clamp(0, maxUses).toInt(),",
    'promozione definizione risorsa',
)
text = replace_once(
    text,
    "    if (selected == null || selected == _trainerPath) return;\n\n    final savedPath",
    "    if (!mounted || selected == null || selected == _trainerPath) return;\n\n    final savedPath",
    'mounted dopo picker path',
)
path.write_text(text, encoding='utf-8')
