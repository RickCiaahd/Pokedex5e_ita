from pathlib import Path

path = Path('lib/screens/battle/battle_screen.dart')
text = path.read_text(encoding='utf-8')
method_start = text.find('  Future<void> _changeHp(')
method_end = text.find('  Future<void> _editHp(', method_start)
if method_start < 0 or method_end < 0:
    raise SystemExit('change HP method boundaries not found')

save_marker = '    await _saveSession(data);\n'
end_marker = '    if (!mounted) return;\n'
start = text.find(save_marker, method_start, method_end)
if start < 0:
    raise SystemExit('change HP save marker not found')
start += len(save_marker)
end = text.find(end_marker, start, method_end)
if end < 0:
    raise SystemExit('change HP mounted marker not found')

replacement = """
    final messages = <String>[];
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

trainer_path = Path('lib/services/trainer_path_automation_service.dart')
trainer_text = trainer_path.read_text(encoding='utf-8')
old = '      if (!definition.isRequired || definition.options.isEmpty) return false;\n'
new = """      if (!definition.isRequired || definition.options.isEmpty) {
        return false;
      }
"""
if old not in trainer_text:
    raise SystemExit('Trainer Path lint marker not found')
trainer_path.write_text(trainer_text.replace(old, new, 1), encoding='utf-8')
print('Trainer Path lint repaired.')
