from pathlib import Path

path = Path('tool/fix_existing_license_pokedex_and_discard.py')
text = path.read_text(encoding='utf-8')

old = '''text += """

test('starting inventory reuses the existing license and pokedex items', () {
  expect(TrainerStartingEquipment.baseInventory['trainers-license'], 1);
  expect(TrainerStartingEquipment.baseInventory['pokedex'], 1);
  expect(TrainerStartingEquipment.baseInventory, isNot(contains('trainer-license')));
  expect(TrainerStartingEquipment.baseInventory, isNot(contains('trainer-pokedex')));

  final generatedIds = TrainerStartingEquipment.catalogItems
      .map((item) => item.id)
      .toSet();
  expect(generatedIds, isNot(contains('trainers-license')));
  expect(generatedIds, isNot(contains('pokedex')));
});
"""
write(path, text)'''

new = '''new_test = """
  test('starting inventory reuses the existing license and pokedex items', () {
    expect(TrainerStartingEquipment.baseInventory['trainers-license'], 1);
    expect(TrainerStartingEquipment.baseInventory['pokedex'], 1);
    expect(
      TrainerStartingEquipment.baseInventory,
      isNot(contains('trainer-license')),
    );
    expect(
      TrainerStartingEquipment.baseInventory,
      isNot(contains('trainer-pokedex')),
    );

    final generatedIds = TrainerStartingEquipment.catalogItems
        .map((item) => item.id)
        .toSet();
    expect(generatedIds, isNot(contains('trainers-license')));
    expect(generatedIds, isNot(contains('pokedex')));
  });
"""
if not text.rstrip().endswith('}'):
    raise RuntimeError('Expected test file to end with the main closing brace')
text = text.rstrip()[:-1] + new_test + '}\\n'
write(path, text)'''

if old not in text:
    raise RuntimeError('Faulty test append block not found')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
