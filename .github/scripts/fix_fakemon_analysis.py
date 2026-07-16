from pathlib import Path

path = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
source = path.read_text(encoding='utf-8')

source = source.replace(
    "import '../../models/custom_pokemon_transfer_bundle.dart';\n",
    '',
    1,
)
source = source.replace(
    "    if (number == null)\n      throw const FormatException('Elenco numerico non valido.');\n",
    "    if (number == null) {\n"
    "      throw const FormatException('Elenco numerico non valido.');\n"
    "    }\n",
    1,
)
source = source.replace(
    "    if (level == null || level <= 0 || moves.isEmpty)\n      throw FormatException('Riga mosse non valida: $line');\n",
    "    if (level == null || level <= 0 || moves.isEmpty) {\n"
    "      throw FormatException('Riga mosse non valida: $line');\n"
    "    }\n",
    1,
)

path.write_text(source, encoding='utf-8')

error_log = Path('fakemon_analyze_error.txt')
if error_log.exists():
    error_log.unlink()
