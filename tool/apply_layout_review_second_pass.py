from pathlib import Path


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
    i = opening

    while i < len(text):
        char = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
            i += 1
            continue

        if block_comment:
            if char == "*" and nxt == "/":
                block_comment = False
                i += 2
            else:
                i += 1
            continue

        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            i += 1
            continue

        if char == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if char == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if char in ("'", '"'):
            quote = char
            i += 1
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1

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


home = Path("lib/screens/home/home_screen.dart")
pokedex = Path("lib/screens/pokedex/pokedex_screen.dart")
pc = Path("lib/screens/pc/pokemon_pc_screen.dart")
bag = Path("lib/screens/bag/bag_screen.dart")

add_import(
    home,
    "import '../../services/profile_storage_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    pokedex,
    "import '../../services/profile_storage_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    pc,
    "import '../../repositories/team_repository.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    bag,
    "import '../../services/trainer_path_passive_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)

# Home: larghezza leggibile e riepilogo allenatore che va a capo senza overflow.
home_text = home.read_text(encoding="utf-8")
home_text = replace_once(
    home_text,
    "padding: const EdgeInsets.all(24),",
    "padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),",
    label="home padding",
)
home_text = replace_once(
    home_text,
    """              Text(
                'Lv. $trainerLevel | ₽ $money | Pokéslot $pokeslots | SR max $maxSr',
              ),
""",
    """              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _TrainerInfoChip(label: 'Lv. $trainerLevel'),
                  _TrainerInfoChip(label: '₽ $money'),
                  _TrainerInfoChip(label: 'Pokéslot $pokeslots'),
                  _TrainerInfoChip(label: 'SR max $maxSr'),
                ],
              ),
""",
    label="home trainer metadata",
)
home_text = replace_once(
    home_text,
    "class _ProgressOverview extends StatelessWidget {",
    """class _TrainerInfoChip extends StatelessWidget {
  const _TrainerInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {""",
    label="home trainer chip",
)
home.write_text(home_text, encoding="utf-8")
wrap_call(
    home,
    "      body: RefreshIndicator(",
    "      body: ResponsiveContent(\n        maxWidth: 1040,\n        child: RefreshIndicator(",
    "\n      ),",
    label="home responsive body",
)

# Pokédex: filtri impilati su smartphone e affiancati su desktop.
pokedex_text = pokedex.read_text(encoding="utf-8")
state_start = pokedex_text.index("class _PokedexScreenState")
build_anchor = "  @override\n  Widget build(BuildContext context) {\n"
build_pos = pokedex_text.index(build_anchor, state_start)
filter_method = """  Widget _buildFilterControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final sortSelector = _SortModeSelector(
          sortMode: _sortMode,
          onChanged: (sortMode) {
            setState(() {
              _sortMode = sortMode;
              _applyFilters();
            });
          },
        );
        final resultCounter = _ResultCounter(count: _filteredPokemon.length);
        final regionSelector = _RegionFilterSelector(
          regions: _visibleRegions,
          selectedRegion: _selectedRegion,
          progressBuilder: _regionProgress,
          onChanged: _setRegionFilter,
        );
        final typeSelector = _TypeFilterSelector(
          types: _availableTypes,
          selectedTypes: _selectedTypes,
          onChanged: _setTypeFilters,
          onClear: _clearTypeFilters,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sortSelector,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: resultCounter),
              const SizedBox(height: 10),
              regionSelector,
              const SizedBox(height: 10),
              typeSelector,
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: sortSelector),
                const SizedBox(width: 10),
                resultCounter,
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: regionSelector),
                const SizedBox(width: 10),
                Expanded(child: typeSelector),
              ],
            ),
          ],
        );
      },
    );
  }

"""
pokedex_text = pokedex_text[:build_pos] + filter_method + pokedex_text[build_pos:]
old_filter_rows = """                Row(
                  children: [
                    Expanded(
                      child: _SortModeSelector(
                        sortMode: _sortMode,
                        onChanged: (sortMode) {
                          setState(() {
                            _sortMode = sortMode;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ResultCounter(count: _filteredPokemon.length),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RegionFilterSelector(
                        regions: _visibleRegions,
                        selectedRegion: _selectedRegion,
                        progressBuilder: _regionProgress,
                        onChanged: _setRegionFilter,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeFilterSelector(
                        types: _availableTypes,
                        selectedTypes: _selectedTypes,
                        onChanged: _setTypeFilters,
                        onClear: _clearTypeFilters,
                      ),
                    ),
                  ],
                ),
"""
pokedex_text = replace_once(
    pokedex_text,
    old_filter_rows,
    "                _buildFilterControls(),\n",
    label="pokedex filter rows",
)
pokedex_text = replace_once(
    pokedex_text,
    "      body: content,",
    """      body: ResponsiveContent(
        maxWidth: 1440,
        child: content,
      ),""",
    label="pokedex responsive body",
)
pokedex.write_text(pokedex_text, encoding="utf-8")

# PC: contenuto centrato e celle più leggibili sulle finestre ampie.
pc_text = pc.read_text(encoding="utf-8")
pc_text = replace_once(
    pc_text,
    """const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 88,""",
    """SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        MediaQuery.sizeOf(context).width >= 900
                                        ? 112
                                        : 92,""",
    label="pc grid extent",
)
pc.write_text(pc_text, encoding="utf-8")
wrap_call(
    pc,
    "           : SafeArea(",
    "           : ResponsiveContent(\n               maxWidth: 1280,\n               child: SafeArea(",
    "\n             ),",
    label="pc responsive body",
)

# Zaino: contenuto centrato e oggetti su due colonne quando c'è spazio.
bag_text = bag.read_text(encoding="utf-8")
old_bag_items = """        if (filteredItems.isEmpty)
          const _BagEmpty()
        else
          for (final entry in filteredItems)
            _BagItemCard(
              entry: entry,
              onUse: () => onUseItem(entry),
              onEquip: () => onEquipItem(entry),
            ),
"""
bag_text = replace_once(
    bag_text,
    old_bag_items,
    """        if (filteredItems.isEmpty)
          const _BagEmpty()
        else
          _BagItemsLayout(
            items: filteredItems,
            onUseItem: onUseItem,
            onEquipItem: onEquipItem,
          ),
""",
    label="bag item list",
)
bag_text = replace_once(
    bag_text,
    "class _BagItemCard extends StatefulWidget {",
    """class _BagItemsLayout extends StatelessWidget {
  const _BagItemsLayout({
    required this.items,
    required this.onUseItem,
    required this.onEquipItem,
  });

  final List<_OwnedBagItem> items;
  final ValueChanged<_OwnedBagItem> onUseItem;
  final ValueChanged<_OwnedBagItem> onEquipItem;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final twoColumns = constraints.maxWidth >= 760;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: [
            for (final entry in items)
              SizedBox(
                width: itemWidth,
                child: _BagItemCard(
                  entry: entry,
                  onUse: () => onUseItem(entry),
                  onEquip: () => onEquipItem(entry),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BagItemCard extends StatefulWidget {""",
    label="bag responsive items widget",
)
bag.write_text(bag_text, encoding="utf-8")
wrap_call(
    bag,
    "      body: FutureBuilder<_BagData>(",
    "      body: ResponsiveContent(\n        maxWidth: 1180,\n        child: FutureBuilder<_BagData>(",
    "\n      ),",
    label="bag responsive body",
)

# Changelog.
changelog = Path("CHANGELOG.md")
changelog_text = changelog.read_text(encoding="utf-8")
entry = (
    "- secondo passaggio della review pre-release: Home, Pokédex, PC Pokémon e Zaino "
    "usano larghezze leggibili su desktop; i filtri del Pokédex si impilano su smartphone, "
    "il riepilogo Allenatore evita overflow e lo Zaino dispone gli oggetti su due colonne "
    "quando lo spazio lo consente;\n"
)
changelog_text = replace_once(
    changelog_text,
    "### Modificato\n\n",
    "### Modificato\n\n" + entry,
    label="changelog second layout pass",
)
changelog.write_text(changelog_text, encoding="utf-8")

# Test di integrazione mirato alle quattro schermate.
test = Path("test/layout_second_pass_integration_test.dart")
test.write_text(
    """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le schermate principali usano il secondo passaggio responsivo', () {
    final home = File('lib/screens/home/home_screen.dart').readAsStringSync();
    final pokedex = File('lib/screens/pokedex/pokedex_screen.dart').readAsStringSync();
    final pc = File('lib/screens/pc/pokemon_pc_screen.dart').readAsStringSync();
    final bag = File('lib/screens/bag/bag_screen.dart').readAsStringSync();

    expect(home, contains('maxWidth: 1040'));
    expect(home, contains('_TrainerInfoChip'));
    expect(pokedex, contains('_buildFilterControls'));
    expect(pokedex, contains('maxWidth: 1440'));
    expect(pc, contains('maxWidth: 1280'));
    expect(pc, contains('? 112'));
    expect(bag, contains('maxWidth: 1180'));
    expect(bag, contains('_BagItemsLayout'));
  });
}
""",
    encoding="utf-8",
)
