from pathlib import Path

home_path = Path('lib/screens/home/home_screen.dart')
home_text = home_path.read_text(encoding='utf-8')

import_needle = "import '../trainer/trainer_sheet_screen.dart';\n"
import_replacement = import_needle + "import '../tools/tools_screen.dart';\n"
if "../tools/tools_screen.dart" not in home_text:
    if import_needle not in home_text:
        raise SystemExit('Could not locate the HomeScreen import insertion point.')
    home_text = home_text.replace(import_needle, import_replacement, 1)

button_needle = """              _HomeActionButton(
                icon: Icons.person,
                title: 'Profili',
"""
button_replacement = """              _HomeActionButton(
                icon: Icons.construction,
                title: 'Strumenti',
                subtitle:
                    'Genera Pokémon e prepara i futuri strumenti per giocatori e Master.',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ToolsScreen()),
                  );
                  await _loadDashboard();
                },
              ),
              _HomeActionButton(
                icon: Icons.person,
                title: 'Profili',
"""
if "title: 'Strumenti'" not in home_text:
    if button_needle not in home_text:
        raise SystemExit('Could not locate the HomeScreen action insertion point.')
    home_text = home_text.replace(button_needle, button_replacement, 1)

home_path.write_text(home_text, encoding='utf-8')

generator_path = Path('lib/screens/tools/pokemon_generator_screen.dart')
generator_text = generator_path.read_text(encoding='utf-8')
generator_text = generator_text.replace(
    "                query: _query,\n",
    "",
    1,
)
generator_text = generator_text.replace(
    "    required this.query,\n",
    "",
    1,
)
generator_text = generator_text.replace(
    "  final String query;\n",
    "",
    1,
)
generator_text = generator_text.replace(
    "              divisions: (maximumSr * 2).round().clamp(1, 200),",
    "              divisions: (maximumSr * 2).round().clamp(1, 200).toInt(),",
    1,
)
generator_path.write_text(generator_text, encoding='utf-8')

service_path = Path('lib/services/pokemon_generator_service.dart')
service_text = service_path.read_text(encoding='utf-8')
service_text = service_text.replace(
    "      r'(\\d+(?:\\.\\d+)?)\\s*%?\\s*' + gender + r'\\b',",
    "      '(\\\\d+(?:\\\\.\\\\d+)?)\\\\s*%?\\\\s*$gender\\\\b',",
    1,
)
service_path.write_text(service_text, encoding='utf-8')
