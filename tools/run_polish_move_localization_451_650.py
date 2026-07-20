import importlib.util
import re
from pathlib import Path

MODULE_PATH = Path('tools/polish_move_localization_451_650.py')

spec = importlib.util.spec_from_file_location('move_polish', MODULE_PATH)
if spec is None or spec.loader is None:
    raise RuntimeError('Impossibile caricare lo script di revisione.')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

# Le sigle tecniche restano case-sensitive: in questo modo parole comuni come
# "move", "concentration" o "strong" non vengono scambiate per MOVE, CON o STR.
module.MECHANICAL_RE = re.compile(
    r'\b\d+d\d+\b|\bd\d+\b|[+\-]\s*\d+|\b\d+[sx]\b|'
    r'\b\d+(?:ft|\s*(?:feet|foot|piedi|piede))?\b|'
    r'\b(?:hit points?|Hit Points?|punti ferita|Punti ferita)\b|'
    r'\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\b|'
    r'\b(?:flinch|flinches|flinched)\b'
)


def canonical_token(value: str) -> str:
    token = value.upper().replace(' ', '')
    token = re.sub(r'(FT|FEET|FOOT|PIEDI|PIEDE)$', '', token)
    token = re.sub(r'(?<=\d)[SX]$', '', token)
    if token in {'HITPOINT', 'HITPOINTS', 'PUNTIFERITA'}:
        return 'HP'
    aliases = {
        'PF': 'HP', 'FOR': 'STR', 'DES': 'DEX', 'COS': 'CON',
        'SAG': 'WIS', 'CAR': 'CHA', 'CA': 'AC', 'CD': 'DC',
        'FLINCH': 'FLINCHED', 'FLINCHES': 'FLINCHED',
    }
    return aliases.get(token, token)


module.canonical_token = canonical_token
module.main()

path = Path('test/move_localization_integrity_test.dart')
text = path.read_text(encoding='utf-8')
old_expression = """  final expression = RegExp(
    r'\\b\\d+d\\d+\\b|\\bd\\d+\\b|[+\\-]\\s*\\d+|\\b\\d+(?:ft|\\s*(?:feet|foot|piedi|piede))?\\b|\\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED|flinch(?:es|ed)?)\\b',
  );"""
new_expression = """  final expression = RegExp(
    r'\\b\\d+d\\d+\\b|\\bd\\d+\\b|[+\\-]\\s*\\d+|\\b\\d+[sx]\\b|\\b\\d+(?:ft|\\s*(?:feet|foot|piedi|piede))?\\b|\\b(?:hit points?|Hit Points?|punti ferita|Punti ferita)\\b|\\b(?:HP|PF|STR|FOR|DEX|DES|CON|COS|WIS|SAG|CHA|CAR|INT|AC|CA|STAB|DC|CD|MOVE|PP|SR|FLINCHED)\\b|\\b(?:flinch|flinches|flinched)\\b',
  );"""
if old_expression not in text:
    raise RuntimeError('Espressione meccanica Dart non trovata.')
text = text.replace(old_expression, new_expression)

old_canonical = """  token = token.replaceAll(RegExp(r'(FT|FEET|FOOT|PIEDI|PIEDE)$'), '');
  const aliases = <String, String>{"""
new_canonical = """  token = token.replaceAll(RegExp(r'(FT|FEET|FOOT|PIEDI|PIEDE)$'), '');
  if (RegExp(r'^\\d+[SX]$').hasMatch(token)) {
    token = token.substring(0, token.length - 1);
  }
  if (token == 'HITPOINT' ||
      token == 'HITPOINTS' ||
      token == 'PUNTIFERITA') {
    return 'HP';
  }
  const aliases = <String, String>{"""
if old_canonical not in text:
    raise RuntimeError('Normalizzazione meccanica Dart non trovata.')
text = text.replace(old_canonical, new_canonical)
path.write_text(text, encoding='utf-8')
