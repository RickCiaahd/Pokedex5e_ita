from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, *, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected one occurrence, found {count}")
    return text.replace(old, new, 1)


def add_import(path: Path, anchor: str, new_import: str) -> None:
    text = path.read_text(encoding="utf-8")
    if new_import in text:
        return
    text = replace_once(
        text,
        anchor,
        f"{anchor}{new_import}",
        label=f"{path}: import anchor",
    )
    path.write_text(text, encoding="utf-8")


def find_matching_parenthesis(text: str, opening: int) -> int:
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    index = opening

    while index < len(text):
        char = text[index]
        nxt = text[index + 1] if index + 1 < len(text) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue

        if block_comment:
            if char == "*" and nxt == "/":
                block_comment = False
                index += 2
            else:
                index += 1
            continue

        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue

        if char == "/" and nxt == "/":
            line_comment = True
            index += 2
            continue
        if char == "/" and nxt == "*":
            block_comment = True
            index += 2
            continue
        if char in ("'", '"'):
            quote = char
            index += 1
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return index
        index += 1

    raise RuntimeError("Unmatched parenthesis")


def wrap_call(
    path: Path,
    marker: str,
    replacement: str,
    closing: str,
    *,
    label: str,
) -> None:
    text = path.read_text(encoding="utf-8")
    start = text.find(marker)
    if start < 0:
        raise RuntimeError(f"{label}: marker not found")
    opening = start + marker.rfind("(")
    end = find_matching_parenthesis(text, opening)
    comma = end + 1
    while comma < len(text) and text[comma].isspace():
        comma += 1
    if comma >= len(text) or text[comma] != ",":
        raise RuntimeError(f"{label}: closing comma not found")

    text = text[:start] + replacement + text[start + len(marker) :]
    delta = len(replacement) - len(marker)
    comma += delta
    text = text[: comma + 1] + closing + text[comma + 1 :]
    path.write_text(text, encoding="utf-8")


def make_alert_dialogs_scrollable(text: str) -> str:
    pattern = re.compile(r"AlertDialog\(\n(?P<indent>[ \t]+)(?!scrollable:)")

    def replacement(match: re.Match[str]) -> str:
        indent = match.group("indent")
        return f"AlertDialog(\n{indent}scrollable: true,\n{indent}"

    return pattern.sub(replacement, text)


def add_bottom_sheet_safe_area(text: str) -> str:
    pattern = re.compile(
        r"(showModalBottomSheet(?:<[^>\n]+>)?\(\n(?P<indent>[ \t]+)context: context,\n)(?![ \t]+useSafeArea:)"
    )

    def replacement(match: re.Match[str]) -> str:
        indent = match.group("indent")
        return f"{match.group(1)}{indent}useSafeArea: true,\n"

    return pattern.sub(replacement, text)


battle = Path("lib/screens/battle/battle_screen.dart")
master = Path("lib/screens/battle/npc_battle_screen.dart")
tools = Path("lib/screens/tools/tools_screen.dart")
changelog = Path("CHANGELOG.md")

add_import(
    battle,
    "import '../../widgets/battle/pokemon_battle_attributes_card.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    master,
    "import '../../widgets/battle/battle_status_assistance_card.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    tools,
    "import '../../repositories/profile_repository.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)

# Battle Companion: larghezza leggibile, Home esplicita, dialog e bottom sheet sicuri.
battle_text = battle.read_text(encoding="utf-8")
battle_text = replace_once(
    battle_text,
    """        title: const Text('Battle Companion'),
      ),""",
    """        title: const Text('Battle Companion'),
        actions: const [HomeAppBarAction()],
      ),""",
    label="battle app bar actions",
)
battle_text = make_alert_dialogs_scrollable(battle_text)
battle_text = add_bottom_sheet_safe_area(battle_text)
battle.write_text(battle_text, encoding="utf-8")
wrap_call(
    battle,
    "      body: FutureBuilder<_BattleData>(",
    "      body: ResponsiveContent(\n        maxWidth: 1280,\n        child: FutureBuilder<_BattleData>(",
    "\n      ),",
    label="battle responsive body",
)

# Fight del Master: contenuto centrato e AppBar meno affollata.
master_text = master.read_text(encoding="utf-8")
old_master_actions = """        actions: [
          PopupMenuButton<_FightSummaryAction>(
            enabled: !_isWorking,
            tooltip: 'Esporta o condividi riepilogo',
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: (action) {
              switch (action) {
                case _FightSummaryAction.export:
                  _exportSummary();
                  break;
                case _FightSummaryAction.share:
                  _shareSummary();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _FightSummaryAction.export,
                child: Text('Salva riepilogo'),
              ),
              PopupMenuItem(
                value: _FightSummaryAction.share,
                child: Text('Condividi riepilogo'),
              ),
            ],
          ),
          IconButton(
            onPressed: _isWorking ? null : _resetFight,
            tooltip: 'Azzera fight',
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            onPressed: _isWorking ? null : _endFight,
            tooltip: 'Termina fight',
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],"""
new_master_actions = """        actions: [
          const HomeAppBarAction(),
          PopupMenuButton<_FightSummaryAction>(
            enabled: !_isWorking,
            tooltip: 'Esporta o condividi riepilogo',
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: (action) {
              switch (action) {
                case _FightSummaryAction.export:
                  _exportSummary();
                  break;
                case _FightSummaryAction.share:
                  _shareSummary();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _FightSummaryAction.export,
                child: Text('Salva riepilogo'),
              ),
              PopupMenuItem(
                value: _FightSummaryAction.share,
                child: Text('Condividi riepilogo'),
              ),
            ],
          ),
          PopupMenuButton<_FightSessionAction>(
            enabled: !_isWorking,
            tooltip: 'Azioni del fight',
            onSelected: (action) {
              switch (action) {
                case _FightSessionAction.reset:
                  _resetFight();
                  break;
                case _FightSessionAction.end:
                  _endFight();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _FightSessionAction.reset,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restart_alt),
                  title: Text('Azzera fight'),
                ),
              ),
              PopupMenuItem(
                value: _FightSessionAction.end,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.stop_circle_outlined),
                  title: Text('Termina fight'),
                ),
              ),
            ],
          ),
        ],"""
master_text = replace_once(
    master_text,
    old_master_actions,
    new_master_actions,
    label="master app bar actions",
)
master_text = replace_once(
    master_text,
    "enum _FightSummaryAction { export, share }",
    """enum _FightSummaryAction { export, share }

enum _FightSessionAction { reset, end }""",
    label="master action enum",
)
master_text = make_alert_dialogs_scrollable(master_text)
master.write_text(master_text, encoding="utf-8")
wrap_call(
    master,
    "      body: ListView(",
    "      body: ResponsiveContent(\n        maxWidth: 1320,\n        child: ListView(",
    "\n      ),",
    label="master responsive body",
)

# Strumenti del Master: due colonne sulle finestre ampie e card compatte sui telefoni.
tools_text = tools.read_text(encoding="utf-8")
old_generators = """            _ToolCard(
              icon: Icons.catching_pokemon,
              title: 'Generatore Pokémon',
              subtitle:
                  'Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.',
              actionLabel: 'GENERA',
              onTap: () => _open(const PokemonGeneratorScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.travel_explore,
              title: 'Generatore incontri',
              subtitle:
                  'Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.',
              actionLabel: 'GENERA',
              onTap: () => _open(const EncounterGeneratorScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.groups_2_outlined,
              title: 'Generatore Allenatori PNG',
              subtitle:
                  'Crea identità, specializzazione, squadra, personalità, tattiche e ricompense.',
              actionLabel: 'GENERA',
              onTap: () => _open(const NpcTrainerGeneratorScreen()),
            ),"""
new_generators = """            _ToolCardGrid(
              children: [
                _ToolCard(
                  icon: Icons.catching_pokemon,
                  title: 'Generatore Pokémon',
                  subtitle:
                      'Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.',
                  actionLabel: 'GENERA',
                  onTap: () => _open(const PokemonGeneratorScreen()),
                ),
                _ToolCard(
                  icon: Icons.travel_explore,
                  title: 'Generatore incontri',
                  subtitle:
                      'Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.',
                  actionLabel: 'GENERA',
                  onTap: () => _open(const EncounterGeneratorScreen()),
                ),
                _ToolCard(
                  icon: Icons.groups_2_outlined,
                  title: 'Generatore Allenatori PNG',
                  subtitle:
                      'Crea identità, specializzazione, squadra, personalità, tattiche e ricompense.',
                  actionLabel: 'GENERA',
                  onTap: () => _open(const NpcTrainerGeneratorScreen()),
                ),
              ],
            ),"""
tools_text = replace_once(
    tools_text,
    old_generators,
    new_generators,
    label="tools generator grid",
)
old_libraries = """            _ToolCard(
              icon: Icons.bookmarks_outlined,
              title: 'Libreria incontri',
              subtitle:
                  'Incontri salvati, raccolte ponderate e avvio diretto nel Fight del Master.',
              actionLabel: 'APRI',
              onTap: () => _open(const EncounterLibraryScreen()),
            ),
            const SizedBox(height: 10),
            _ToolCard(
              icon: Icons.people_alt_outlined,
              title: 'Libreria Allenatori PNG',
              subtitle:
                  'Allenatori salvati, selezione multipla e gestione delle loro squadre nel fight.',
              actionLabel: 'APRI',
              onTap: () => _open(const NpcTrainerLibraryScreen()),
            ),"""
new_libraries = """            _ToolCardGrid(
              children: [
                _ToolCard(
                  icon: Icons.bookmarks_outlined,
                  title: 'Libreria incontri',
                  subtitle:
                      'Incontri salvati, raccolte ponderate e avvio diretto nel Fight del Master.',
                  actionLabel: 'APRI',
                  onTap: () => _open(const EncounterLibraryScreen()),
                ),
                _ToolCard(
                  icon: Icons.people_alt_outlined,
                  title: 'Libreria Allenatori PNG',
                  subtitle:
                      'Allenatori salvati, selezione multipla e gestione delle loro squadre nel fight.',
                  actionLabel: 'APRI',
                  onTap: () => _open(const NpcTrainerLibraryScreen()),
                ),
              ],
            ),"""
tools_text = replace_once(
    tools_text,
    old_libraries,
    new_libraries,
    label="tools library grid",
)
tools_text = replace_once(
    tools_text,
    "class _ToolCard extends StatelessWidget {",
    """class _ToolCardGrid extends StatelessWidget {
  const _ToolCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final twoColumns = constraints.maxWidth >= 760;
        final cardWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 4,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {""",
    label="tools grid widget",
)
old_tool_card_return = """    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: enabled
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Icon(
                  icon,
                  color: enabled
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                actionLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (enabled) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );"""
new_tool_card_return = """    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(compact ? 13 : 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 23 : 27,
                    backgroundColor: enabled
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                    child: Icon(
                      icon,
                      color: enabled
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                  if (enabled) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );"""
tools_text = replace_once(
    tools_text,
    old_tool_card_return,
    new_tool_card_return,
    label="tools compact card",
)
tools.write_text(tools_text, encoding="utf-8")
wrap_call(
    tools,
    "      body: RefreshIndicator(",
    "      body: ResponsiveContent(\n        maxWidth: 1180,\n        child: RefreshIndicator(",
    "\n      ),",
    label="tools responsive body",
)

# Documentazione e test dell’ultimo passaggio.
changelog_text = changelog.read_text(encoding="utf-8")
changelog_text = replace_once(
    changelog_text,
    "### Modificato\n",
    """### Modificato

- ultimo passaggio della review pre-release: Battle Companion, Fight del Master e Strumenti del Master usano larghezze leggibili su desktop; le AppBar espongono Home in modo uniforme, le azioni del fight sono raccolte in menu meno affollati e dialog/bottom sheet critici gestiscono meglio smartphone e testo ingrandito;
""",
    label="changelog final layout block",
)
changelog.write_text(changelog_text, encoding="utf-8")

Path("test/layout_final_block_integration_test.dart").write_text(
    """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('l’ultimo blocco layout copre combattimenti e strumenti del Master', () {
    final battle = File(
      'lib/screens/battle/battle_screen.dart',
    ).readAsStringSync();
    final master = File(
      'lib/screens/battle/npc_battle_screen.dart',
    ).readAsStringSync();
    final tools = File(
      'lib/screens/tools/tools_screen.dart',
    ).readAsStringSync();

    expect(battle, contains('maxWidth: 1280'));
    expect(battle, contains('actions: const [HomeAppBarAction()]'));
    expect(battle, contains('useSafeArea: true'));
    expect(battle, contains('scrollable: true'));

    expect(master, contains('maxWidth: 1320'));
    expect(master, contains('const HomeAppBarAction()'));
    expect(master, contains('PopupMenuButton<_FightSessionAction>'));
    expect(master, contains('scrollable: true'));

    expect(tools, contains('maxWidth: 1180'));
    expect(tools, contains('class _ToolCardGrid'));
    expect(tools, contains('constraints.maxWidth >= 760'));
    expect(tools, contains('constraints.maxWidth < 430'));
  });
}
""",
    encoding="utf-8",
)

Path("docs/layout-pre-release-checklist.md").write_text(
    """# Checklist layout pre-release

Verificare le schermate principali a 360 px, 412 px, tablet e desktop/Web largo.
Ripetere almeno il controllo smartphone con dimensione testo di sistema aumentata.

## Navigazione

- La freccia torna alla schermata precedente.
- Il pulsante Home torna alla schermata iniziale.
- Le azioni delle AppBar restano raggiungibili senza sovrapporsi al titolo.

## Battle Companion

- Header, squadra, iniziativa, ambiente, Pokémon attivo e mosse restano leggibili.
- I selettori orizzontali scorrono senza overflow.
- Dialog di PF, status, iniziativa e ambiente restano utilizzabili con tastiera aperta.
- I bottom sheet rispettano le aree sicure del dispositivo.

## Fight del Master

- Home, condivisione e menu delle azioni sono visibili a 360 px.
- La selezione degli Allenatori scorre orizzontalmente.
- Scheda Allenatore, iniziativa, squadra, Pokémon attivo, status e mosse non hanno overflow.
- Azzera e Termina fight richiedono conferma e restano accessibili dal menu.

## Strumenti del Master

- Una colonna su smartphone e due colonne sulle finestre ampie.
- Titoli e descrizioni delle card vanno a capo senza tagli.
- Generatori, librerie e ripresa del fight aprono la schermata corretta.

## Controllo finale

- Nessun testo troncato o RenderFlex overflow.
- Stati di caricamento, vuoto ed errore sono leggibili.
- Refresh, scroll verticale e scroll orizzontale funzionano.
- Tema, spaziature, card e gerarchia tipografica restano coerenti.
""",
    encoding="utf-8",
)
