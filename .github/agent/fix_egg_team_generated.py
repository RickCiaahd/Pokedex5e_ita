from pathlib import Path

breeding = Path('lib/screens/breeding/breeding_screen.dart')
text = breeding.read_text(encoding='utf-8')
old_subtitle = """                                    : 'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.'
                          ),
                          value: _useDayCare,"""
new_subtitle = """                                    : 'L’uovo occuperà lo slot squadra ${freeSlot.slotIndex + 1}.'
                          ),
                          value: _useDayCare,"""
# Ensure the Text widget is closed with a comma. The old source can contain either form.
if old_subtitle not in text:
    old_subtitle = old_subtitle.replace("                          ),", "                          )")
    new_subtitle = new_subtitle.replace("                          ),", "                          ),")
if old_subtitle not in text:
    raise RuntimeError('Chiusura del sottotitolo Pensione non trovata')
text = text.replace(old_subtitle, new_subtitle, 1)
needle = 'onPressed: compatibility?.isCompatible == true\n'
if text.count(needle) != 2:
    raise RuntimeError(f'Attesi 2 pulsanti allevamento, trovati {text.count(needle)}')
text = text.replace(
    needle,
    'onPressed: compatibility?.isCompatible == true && canStoreEgg\n',
    2,
)
breeding.write_text(text, encoding='utf-8')

pc = Path('lib/screens/pc/pokemon_pc_screen.dart')
text = pc.read_text(encoding='utf-8')
old = '        team: _visibleTeam,\n'
new = '        team: _visibleTeam.where((slot) => slot.isPokemon).toList(),\n'
if text.count(old) != 1:
    raise RuntimeError(f'Lista sostituzione PC non trovata: {text.count(old)}')
text = text.replace(old, new, 1)
text = text.replace(
    "'$storedCount nel PC • $filledTeamSlots/$totalTeamSlots in squadra'",
    "'$storedCount nel PC • $filledTeamSlots/$totalTeamSlots Pokéslot occupati'",
    1,
)
pc.write_text(text, encoding='utf-8')
