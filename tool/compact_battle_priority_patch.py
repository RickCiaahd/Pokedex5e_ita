from pathlib import Path

path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')

# Reorder the guided tour to match the new visual hierarchy:
# header/round -> active Pokemon -> moves -> environment.
env_tour = "    GuidedTourStepData(\n      targetKey: _environmentKey,"
active_tour = "    GuidedTourStepData(\n      targetKey: _activePokemonKey,"
moves_tour = "    GuidedTourStepData(\n      targetKey: _movesKey,"
tour_end = "  ];\n\n  @override\n  void initState()"

env_start = text.index(env_tour)
active_start = text.index(active_tour, env_start)
moves_start = text.index(moves_tour, active_start)
tour_end_index = text.index(tour_end, moves_start)

environment_tour_block = text[env_start:active_start]
active_tour_block = text[active_start:moves_start]
moves_tour_block = text[moves_start:tour_end_index]

active_tour_block = active_tour_block.replace(
    'fallbackScrollFraction: .50,', 'fallbackScrollFraction: .30,'
)
moves_tour_block = moves_tour_block.replace(
    'fallbackScrollFraction: 1,', 'fallbackScrollFraction: .55,'
)
environment_tour_block = environment_tour_block.replace(
    'fallbackScrollFraction: .30,', 'fallbackScrollFraction: .80,'
)

text = (
    text[:env_start]
    + active_tour_block
    + moves_tour_block
    + environment_tour_block
    + text[tour_end_index:]
)

# Move battle moves directly below the active Pokemon card. Environment and
# secondary assistance remain available immediately afterwards.
environment_marker = (
    "                            const SizedBox(height: 12),\n"
    "                            KeyedSubtree(\n"
    "                              key: _environmentKey,"
)
active_marker = (
    "                            const SizedBox(height: 12),\n"
    "                            KeyedSubtree(\n"
    "                              key: _activePokemonKey,"
)
support_marker = "                            if (passiveNotes.isNotEmpty) ...["
moves_marker = (
    "                            const SizedBox(height: 12),\n"
    "                            KeyedSubtree(\n"
    "                              key: _movesKey,"
)
list_end_marker = "\n                          ],\n                        ),\n                      );"

environment_start = text.index(environment_marker)
active_start = text.index(active_marker, environment_start)
support_start = text.index(support_marker, active_start)
moves_start = text.index(moves_marker, support_start)
list_end = text.index(list_end_marker, moves_start)

environment_block = text[environment_start:active_start]
active_block = text[active_start:support_start]
support_block = text[support_start:moves_start]
moves_block = text[moves_start:list_end]

text = (
    text[:environment_start]
    + active_block
    + moves_block
    + environment_block
    + support_block
    + text[list_end:]
)

path.write_text(text, encoding='utf-8')
