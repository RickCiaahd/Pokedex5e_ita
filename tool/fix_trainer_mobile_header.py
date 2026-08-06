from pathlib import Path

path = Path('lib/screens/trainer/trainer_sheet_mobile.dart')
text = path.read_text(encoding='utf-8')

old = """        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: TrainerProfileImagePicker(
                imageBase64: profileImageBase64,
                trainerName: nameController.text,
                compact: true,
                editButtonOnly: true,
                enabled: !isSaving,
                onChanged: onProfileImageChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: context.uiText('Nome', 'Name'),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CompactChoiceLine(
                    label: context.uiText('LIVELLO', 'LEVEL'),
                    value: '$trainerLevel',
                    onTap: () => _showCounterSheet(
                      context: context,
                      title: context.uiText(
                        'Livello allenatore',
                        'Trainer level',
                      ),
                      initialValue: trainerLevel,
                      minValue: TrainerProgression.minLevel,
                      maxValue: TrainerProgression.maxLevel,
                      onDecrease: onDecreaseLevel,
                      onIncrease: onIncreaseLevel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
"""
new = """        TrainerProfileImagePicker(
          imageBase64: profileImageBase64,
          trainerName: nameController.text,
          compact: true,
          editButtonOnly: true,
          enabled: !isSaving,
          onChanged: onProfileImageChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: nameController,
          enabled: !isSaving,
          decoration: InputDecoration(
            labelText: context.uiText('Nome', 'Name'),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        _CompactChoiceLine(
          label: context.uiText('LIVELLO', 'LEVEL'),
          value: '$trainerLevel',
          onTap: () => _showCounterSheet(
            context: context,
            title: context.uiText(
              'Livello allenatore',
              'Trainer level',
            ),
            initialValue: trainerLevel,
            minValue: TrainerProgression.minLevel,
            maxValue: TrainerProgression.maxLevel,
            onDecrease: onDecreaseLevel,
            onIncrease: onIncreaseLevel,
          ),
        ),
"""
if text.count(old) != 1:
    raise RuntimeError(f'header block: expected 1 match, found {text.count(old)}')
text = text.replace(old, new, 1)

old_speed = "value: context.uiText('$speed ft', '$speed ft'),"
new_speed = "value: context.uiText('$speed piedi', '$speed ft'),"
if text.count(old_speed) != 1:
    raise RuntimeError(f'speed label: expected 1 match, found {text.count(old_speed)}')
text = text.replace(old_speed, new_speed, 1)

path.write_text(text, encoding='utf-8')
print('Trainer mobile header fixed.')
