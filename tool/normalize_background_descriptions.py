from pathlib import Path

path = Path('lib/models/trainer_ui_localization.dart')
text = path.read_text(encoding='utf-8')

it_start = text.index('  static const Map<String, String> _backgroundDescriptionsIt = {')
en_start = text.index('  static const Map<String, String> _backgroundDescriptionsEn = {', it_start)
getters_start = text.index('  static Map<String, String> get ', en_start)

it_block = '''  static const Map<String, String> _backgroundDescriptionsIt = {
    'Ricercatore': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Esploratore': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Allevatore': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Combattente': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Artista': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Studioso': 'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
  };
'''

en_block = '''  static const Map<String, String> _backgroundDescriptionsEn = {
    'Ricercatore': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Esploratore': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Allevatore': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Combattente': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Artista': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Studioso': 'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
  };
'''

text = text[:it_start] + it_block + en_block + text[getters_start:]
path.write_text(text, encoding='utf-8')
