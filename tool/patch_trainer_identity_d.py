from pathlib import Path


def replace_once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected 1, found {count}')
    return text.replace(old, new, 1)


path = Path('lib/screens/trainer/trainer_sheet_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '                    moneyController: moneyController,\n'
    '                    race: race,\n'
    '                    raceDescription: raceDescription,\n'
    '                    selectedStarter: selectedStarter,\n',
    '                    moneyController: moneyController,\n'
    '                    ageController: ageController,\n'
    '                    race: race,\n'
    '                    raceDescription: raceDescription,\n'
    '                    background: background,\n'
    '                    backgroundDescription: backgroundDescription,\n'
    '                    selectedStarter: selectedStarter,\n',
    'stacked desktop arguments',
)
text = replace_once(
    text,
    '                    onRaceTap: onRaceTap,\n'
    '                    onStarterTap: onStarterTap,\n',
    '                    onRaceTap: onRaceTap,\n'
    '                    onBackgroundTap: onBackgroundTap,\n'
    '                    onStarterTap: onStarterTap,\n',
    'stacked desktop callbacks',
)
path.write_text(text, encoding='utf-8')
