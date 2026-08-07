from pathlib import Path

path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')
start_marker = '    final messages = <String>[];\n'
end_marker = '    if (!mounted) return;\n'
start = text.find(start_marker)
if start < 0:
    raise SystemExit('messages block start not found')
end = text.find(end_marker, start)
if end < 0:
    raise SystemExit('messages block end not found')
replacement = """    final messages = <String>[];
    if (dynamaxAbsorbed > 0) {
      final stillActive =
          _transformationBySlot[slot.slotIndex]?.isDynamaxLike == true;
      messages.add(
        stillActive
            ? context.uiText(
                '$dynamaxAbsorbed danni assorbiti dai PF Dynamax.',
                '$dynamaxAbsorbed damage absorbed by Dynamax HP.',
              )
            : context.uiText(
                '$dynamaxAbsorbed danni assorbiti: Dynamax/Gigamax termina.',
                '$dynamaxAbsorbed damage absorbed: Dynamax/Gigantamax ends.',
              ),
      );
    }
    if (absorbed > 0) {
      messages.add(
        (_temporaryHpBySlot[slot.slotIndex] ?? 0) > 0
            ? context.uiText(
                '$absorbed danni assorbiti dai PF temporanei.',
                '$absorbed damage absorbed by temporary HP.',
              )
            : context.uiText(
                '$absorbed danni assorbiti: ${rule?.localizedLabel ?? 'la protezione'} si spezza.',
                '$absorbed damage absorbed: ${rule?.localizedLabel ?? 'the protection'} breaks.',
              ),
      );
    }
"""
path.write_text(text[:start] + replacement + text[end:], encoding='utf-8')
print('Battle damage message block repaired.')
