from pathlib import Path
import re

path = Path('lib/services/profile_backup_service.dart')
source = path.read_text(encoding='utf-8')
pattern = re.compile(
    r"\s+_encounterCollectionRepository\s*=\s*\n\s*encounterCollectionRepository\s*\?\?\s*EncounterCollectionRepository\(\);"
)
replacement = (
    "\n       _encounterCollectionRepository =\n"
    "             encounterCollectionRepository ?? EncounterCollectionRepository();"
)
source, count = pattern.subn(replacement, source, count=1)
if count != 1:
    raise RuntimeError(f'Expected one encounter repository initializer, found {count}')
path.write_text(source, encoding='utf-8')
