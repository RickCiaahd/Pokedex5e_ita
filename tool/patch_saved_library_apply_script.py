from pathlib import Path

path = Path('tool/apply_saved_encounter_library.py')
source = path.read_text(encoding='utf-8')
source = source.replace(
    "from pathlib import Path\n",
    "from pathlib import Path\nimport re\n",
    1,
)
start_marker = "source = replace_once(\n    source,\n    r'''       _encounterCollectionRepository ="
end_marker = "    'backup service initializer',\n)\n"
start = source.find(start_marker)
if start < 0:
    raise RuntimeError('Could not find backup service initializer patch start')
end = source.find(end_marker, start)
if end < 0:
    raise RuntimeError('Could not find backup service initializer patch end')
end += len(end_marker)
new = """source, initializer_count = re.subn(
    r\"[ \\t]+_encounterCollectionRepository[ \\t]*=[ \\t]*\\n[ \\t]+encounterCollectionRepository[ \\t]*\\?\\?[ \\t]*EncounterCollectionRepository\\(\\);\",
    \"       _encounterCollectionRepository =\\n\"
    \"            encounterCollectionRepository ?? EncounterCollectionRepository(),\\n\"
    \"       _savedEncounterRepository =\\n\"
    \"            savedEncounterRepository ?? SavedEncounterRepository();\",
    source,
    count=1,
)
if initializer_count != 1:
    raise RuntimeError(
        f'backup service initializer: expected one match, found {initializer_count}'
    )
"""
path.write_text(source[:start] + new + source[end:], encoding='utf-8')
