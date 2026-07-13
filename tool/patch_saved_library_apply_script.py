from pathlib import Path

path = Path('tool/apply_saved_encounter_library.py')
source = path.read_text(encoding='utf-8')
source = source.replace(
    "from pathlib import Path\n",
    "from pathlib import Path\nimport re\n",
    1,
)
old = r'''source = replace_once(
    source,
    r'''       _encounterCollectionRepository =
             encounterCollectionRepository ?? EncounterCollectionRepository();
''',
    r'''       _encounterCollectionRepository =
             encounterCollectionRepository ?? EncounterCollectionRepository(),
        _savedEncounterRepository =
             savedEncounterRepository ?? SavedEncounterRepository();
''',
    'backup service initializer',
)
'''
new = r'''source, initializer_count = re.subn(
    r"[ \\t]+_encounterCollectionRepository[ \\t]*=[ \\t]*\\n[ \\t]+encounterCollectionRepository[ \\t]*\\?\\?[ \\t]*EncounterCollectionRepository\\(\\);",
    "       _encounterCollectionRepository =\\n"
    "            encounterCollectionRepository ?? EncounterCollectionRepository(),\\n"
    "       _savedEncounterRepository =\\n"
    "            savedEncounterRepository ?? SavedEncounterRepository();",
    source,
    count=1,
)
if initializer_count != 1:
    raise RuntimeError(
        f'backup service initializer: expected one match, found {initializer_count}'
    )
'''
if old not in source:
    raise RuntimeError('Could not find backup service initializer patch block')
path.write_text(source.replace(old, new, 1), encoding='utf-8')
