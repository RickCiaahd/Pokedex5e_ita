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
    triple = False
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
                i += 1
                continue
            if char == "\\":
                escaped = True
                i += 1
                continue
            if triple:
                if text.startswith(quote * 3, i):
                    quote = None
                    triple = False
                    i += 3
                else:
                    i += 1
                continue
            if char == quote:
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
            triple = text.startswith(char * 3, i)
            i += 3 if triple else 1
            continue
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1

    raise RuntimeError("Unmatched parenthesis")


def wrap_refresh_body(path: Path, max_width: int) -> None:
    text = path.read_text(encoding="utf-8")
    marker = "      body: RefreshIndicator("
    start = text.find(marker)
    if start < 0:
        raise RuntimeError(f"{path}: RefreshIndicator body not found")
    opening = start + marker.rfind("(")
    closing = find_matching_parenthesis(text, opening)
    comma = closing + 1
    while comma < len(text) and text[comma].isspace():
        comma += 1
    if comma >= len(text) or text[comma] != ",":
        raise RuntimeError(f"{path}: closing comma not found")

    replacement = (
        "      body: ResponsiveContent(\n"
        f"        maxWidth: {max_width},\n"
        "        child: RefreshIndicator("
    )
    text = text[:start] + replacement + text[start + len(marker) :]
    delta = len(replacement) - len(marker)
    comma += delta
    text = text[: comma + 1] + "\n      )," + text[comma + 1 :]
    path.write_text(text, encoding="utf-8")


team = Path("lib/screens/team/team_selection_screen.dart")
profiles = Path("lib/screens/profile/profiles_screen.dart")
encounters = Path("lib/screens/tools/encounter_library_screen.dart")
trainers = Path("lib/screens/tools/npc_trainer_library_screen.dart")

add_import(
    team,
    "import '../../services/pokemon_transfer_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    profiles,
    "import '../../services/profile_backup_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    encounters,
    "import '../../services/saved_encounter_mapper_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)
add_import(
    trainers,
    "import '../../services/saved_npc_trainer_mapper_service.dart';\n",
    "import '../../widgets/layout/responsive_content.dart';\n",
)

team_text = team.read_text(encoding="utf-8")
build_anchor = "  @override\n  Widget build(BuildContext context) {\n"
adaptive_method = """  Widget _buildTeamSlots(List<TeamSlot> visibleTeam) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final usesTwoColumns = constraints.maxWidth >= 840;
        final cardWidth = usesTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: 0,
          children: [
            for (final slot in visibleTeam)
              SizedBox(
                width: cardWidth,
                child: _TeamSlotCard(
                  slot: slot,
                  pokemon: _pokemonById(slot.pokemonId),
                  onOpen: () => _openPokemonDetail(slot),
                  onChange: () => _openPokemonPicker(slot),
                  onExport: slot.isPokemon ? () => _exportPokemon(slot) : null,
                  onShare: slot.isPokemon ? () => _sharePokemon(slot) : null,
                  onImport: slot.isEgg ? null : () => _importPokemonInto(slot),
                  onRemove: slot.isPokemon
                      ? () => _setPokemonInSlot(slot.slotIndex, null)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

"""
team_text = replace_once(
    team_text,
    build_anchor,
    adaptive_method + build_anchor,
    label="team adaptive method",
)
old_team_loop = """              for (final slot in visibleTeam)
                _TeamSlotCard(
                  slot: slot,
                  pokemon: _pokemonById(slot.pokemonId),
                  onOpen: () => _openPokemonDetail(slot),
                  onChange: () => _openPokemonPicker(slot),
                  onExport: slot.isPokemon ? () => _exportPokemon(slot) : null,
                  onShare: slot.isPokemon ? () => _sharePokemon(slot) : null,
                  onImport: slot.isEgg ? null : () => _importPokemonInto(slot),
                  onRemove: slot.isPokemon
                      ? () => _setPokemonInSlot(slot.slotIndex, null)
                      : null,
                ),
"""
team_text = replace_once(
    team_text,
    old_team_loop,
    "              _buildTeamSlots(visibleTeam),\n",
    label="team slot loop",
)
team.write_text(team_text, encoding="utf-8")

wrap_refresh_body(team, 1180)
wrap_refresh_body(profiles, 1040)
wrap_refresh_body(encounters, 1100)
wrap_refresh_body(trainers, 1180)

changelog = Path("CHANGELOG.md")
changelog_text = changelog.read_text(encoding="utf-8")
changelog_text = replace_once(
    changelog_text,
    "### Modificato\n\n",
    "### Modificato\n\n"
    "- primo passaggio della review pre-release: Squadra, Profili e librerie del Master ora mantengono una larghezza leggibile su Web e Windows; la Squadra usa due colonne sulle finestre ampie e una colonna su smartphone;\n",
    label="changelog layout entry",
)
changelog.write_text(changelog_text, encoding="utf-8")
