from pathlib import Path

path = Path('lib/screens/home/home_screen.dart')
text = path.read_text(encoding='utf-8')

import_needle = "import '../trainer/trainer_sheet_screen.dart';\n"
import_replacement = import_needle + "import '../tools/tools_screen.dart';\n"
if "../tools/tools_screen.dart" not in text:
    if import_needle not in text:
        raise SystemExit('Could not locate the HomeScreen import insertion point.')
    text = text.replace(import_needle, import_replacement, 1)

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
if "title: 'Strumenti'" not in text:
    if button_needle not in text:
        raise SystemExit('Could not locate the HomeScreen action insertion point.')
    text = text.replace(button_needle, button_replacement, 1)

path.write_text(text, encoding='utf-8')
