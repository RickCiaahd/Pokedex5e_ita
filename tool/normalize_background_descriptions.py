from pathlib import Path
import re

path = Path('lib/models/trainer_ui_localization.dart')
text = path.read_text(encoding='utf-8')

it_block = '''  static const Map<String, String> _backgroundDescriptionsIt = {
    'Ricercatore': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Esploratore': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Allevatore': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Combattente': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Artista': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Studioso': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
  };'''

en_block = '''  static const Map<String, String> _backgroundDescriptionsEn = {
    'Ricercatore': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Esploratore': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Allevatore': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Combattente': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Artista': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Studioso': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
  };'''

text, count_it = re.subn(
    r"  static const Map<String, String> _backgroundDescriptionsIt = \{.*?\n  \};",
    it_block,
    text,
    count=1,
    flags=re.S,
)
text, count_en = re.subn(
    r"  static const Map<String, String> _backgroundDescriptionsEn = \{.*?\n  \};",
    en_block,
    text,
    count=1,
    flags=re.S,
)
if count_it != 1 or count_en != 1:
    raise RuntimeError(f'Expected one IT and one EN block, got {count_it} and {count_en}')

path.write_text(text, encoding='utf-8')
