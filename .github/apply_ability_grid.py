from pathlib import Path

path = Path('lib/screens/trainer/trainer_sheet_screen.dart')
text = path.read_text(encoding='utf-8')

import_line = "import '../../widgets/layout/responsive_content.dart';\n"
if text.count(import_line) != 1:
    raise SystemExit('Expected responsive_content import exactly once.')
text = text.replace(import_line, '', 1)

selected_skills = """    final selectedSkills = [
      ...TrainerManualOptions.fixedSkillProficiencies,
      ...skillProficiencies,
    ];
"""
selected_skills_replacement = selected_skills + (
    '    final abilityEntries = '
    'UserProfile.defaultAbilityScores.entries.toList();\n'
)
if text.count(selected_skills) != 1:
    raise SystemExit('Could not identify the selectedSkills block exactly once.')
text = text.replace(selected_skills, selected_skills_replacement, 1)

old_grid = """        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in UserProfile.defaultAbilityScores.entries)
              _AbilityScoreTile(
                label: TrainerUiLocalization.abilityAbbreviation(entry.key),
                score: abilityScores[entry.key] ?? entry.value,
                onDecrease: () => onAbilityScoreChanged(entry.key, -1),
                onIncrease: () => onAbilityScoreChanged(entry.key, 1),
              ),
          ],
        ),
"""
new_grid = """        Column(
          children: [
            for (var row = 0; row < 2; row++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var column = 0; column < 3; column++) ...[
                    if (column > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _AbilityScoreTile(
                        label: TrainerUiLocalization.abilityAbbreviation(
                          abilityEntries[(row * 3) + column].key,
                        ),
                        score:
                            abilityScores[
                              abilityEntries[(row * 3) + column].key
                            ] ??
                            abilityEntries[(row * 3) + column].value,
                        onDecrease: () => onAbilityScoreChanged(
                          abilityEntries[(row * 3) + column].key,
                          -1,
                        ),
                        onIncrease: () => onAbilityScoreChanged(
                          abilityEntries[(row * 3) + column].key,
                          1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (row == 0) const SizedBox(height: 8),
            ],
          ],
        ),
"""
if text.count(old_grid) != 1:
    raise SystemExit('Could not identify the ability score Wrap exactly once.')
text = text.replace(old_grid, new_grid, 1)

tile_start = text.index('class _AbilityScoreTile extends StatelessWidget')
tile_end = text.index('class _ManualBulletCard extends StatelessWidget', tile_start)
tile = text[tile_start:tile_end]

old_width = """      child: SizedBox(
        width: textScaleAwareValue(
          context,
          normal: 104,
          enlarged: 116,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
"""
new_width = """      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
"""
if tile.count(old_width) != 1:
    raise SystemExit('Could not identify the ability tile width block exactly once.')
tile = tile.replace(old_width, new_width, 1)

old_button = """                  IconButton(
                    visualDensity: Theme.of(context).visualDensity,
                    tooltip: context.uiText(
"""
new_button = """                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 40,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: context.uiText(
"""
if tile.count(old_button) != 2:
    raise SystemExit('Expected exactly two ability score IconButtons.')
tile = tile.replace(old_button, new_button)
text = text[:tile_start] + tile + text[tile_end:]

path.write_text(text, encoding='utf-8')
