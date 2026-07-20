from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 occurrence, found {count}")
    return text.replace(old, new, 1)


# Complete the display-only Pokémon terminology catalogue.
path = Path("lib/models/trainer_ui_localization.dart")
text = path.read_text(encoding="utf-8")
text = replace_once(
    text,
    '''  static const Map<String, String> startingPackLabels = {
    "Dungeoneer's pack": 'Dotazione da Avventuriero',
    "Explorer's pack": 'Dotazione da Esploratore',
    "Filcher's pack": 'Dotazione da Borseggiatore',
  };
''',
    '''  static const Map<String, String> startingPackLabels = {
    "Dungeoneer's pack": 'Dotazione da Avventuriero',
    "Explorer's pack": 'Dotazione da Esploratore',
    "Filcher's pack": 'Dotazione da Borseggiatore',
  };

  static const Map<String, String> natureLabels = {
    'Hardy': 'Ardita',
    'Lonely': 'Schiva',
    'Brave': 'Audace',
    'Adamant': 'Decisa',
    'Naughty': 'Birbona',
    'Bold': 'Sicura',
    'Docile': 'Docile',
    'Relaxed': 'Placida',
    'Impish': 'Scaltra',
    'Lax': 'Fiacca',
    'Timid': 'Timida',
    'Hasty': 'Lesta',
    'Serious': 'Seria',
    'Jolly': 'Allegra',
    'Naive': 'Ingenua',
    'Modest': 'Modesta',
    'Mild': 'Mite',
    'Quiet': 'Quieta',
    'Bashful': 'Ritrosa',
    'Rash': 'Ardente',
    'Calm': 'Calma',
    'Gentle': 'Gentile',
    'Sassy': 'Vivace',
    'Careful': 'Cauta',
    'Quirky': 'Furba',
    'No Nature': 'Nessuna natura',
  };

  static const Map<String, String> sizeLabels = {
    'Tiny': 'Minuscola',
    'Small': 'Piccola',
    'Medium': 'Media',
    'Large': 'Grande',
    'Huge': 'Enorme',
    'Gargantuan': 'Mastodontica',
  };

  static const Map<String, String> genderLabels = {
    'Male': 'Maschio',
    'Female': 'Femmina',
    'Genderless': 'Senza sesso',
    'Random': 'Casuale',
  };
''',
    "nature, size and gender maps",
)
text = replace_once(
    text,
    '''  static String startingPackName(String value) {
    return startingPackLabels[value] ?? value;
  }
''',
    '''  static String startingPackName(String value) {
    return startingPackLabels[value] ?? value;
  }

  static String natureName(String value) => natureLabels[value] ?? value;

  static String sizeName(String value) => sizeLabels[value] ?? value;

  static String genderName(String value) => genderLabels[value] ?? value;
''',
    "nature, size and gender methods",
)
path.write_text(text, encoding="utf-8")

# Translate the remaining visible details in the Pokémon screen.
path = Path("lib/screens/pokemon/pokemon_detail_screen_legacy.dart")
text = path.read_text(encoding="utf-8")
text = replace_once(
    text,
    '''              _InfoRow(label: 'Taglia', value: pokemon.size),
              _InfoRow(label: 'Velocità', value: '${pokemon.speed} ft'),
              _InfoRow(label: 'Dado vita', value: 'd${pokemon.hitDice}'),
              _InfoRow(label: 'Competenza', value: '+$proficiency'),
              _InfoRow(
                label: 'Livello minimo',
                value: '${pokemon.minLevelFound}',
              ),
              _InfoRow(
                label: 'Tiri salvezza',
                value: pokemon.savingThrows.join(', '),
              ),
              _InfoRow(
                label: 'Competenze',
                value: [...pokemon.skills, ...?slot?.extraSkills].join(', '),
              ),
              _InfoRow(
                label: 'Natura',
                value: slot?.nature ?? 'Nessuna natura',
              ),
              _InfoRow(label: 'Forma', value: slot?.formName ?? '-'),
              _InfoRow(
                label: 'Cromatico',
                value: slot?.isShiny == true ? 'Si' : 'No',
              ),
              _InfoRow(label: 'Sesso', value: slot?.gender ?? '-'),
''',
    '''              _InfoRow(
                label: 'Taglia',
                value: TrainerUiLocalization.sizeName(pokemon.size),
              ),
              _InfoRow(
                label: 'Velocità',
                value: '${pokemon.speed} piedi',
              ),
              _InfoRow(label: 'Dado vita', value: 'd${pokemon.hitDice}'),
              _InfoRow(label: 'Competenza', value: '+$proficiency'),
              _InfoRow(
                label: 'Livello minimo',
                value: '${pokemon.minLevelFound}',
              ),
              _InfoRow(
                label: 'Tiri salvezza',
                value: pokemon.savingThrows
                    .map(TrainerUiLocalization.abilityAbbreviation)
                    .join(', '),
              ),
              _InfoRow(
                label: 'Competenze',
                value: [...pokemon.skills, ...?slot?.extraSkills]
                    .map(TrainerUiLocalization.skillName)
                    .join(', '),
              ),
              _InfoRow(
                label: 'Natura',
                value: TrainerUiLocalization.natureName(
                  slot?.nature ?? 'No Nature',
                ),
              ),
              _InfoRow(label: 'Forma', value: slot?.formName ?? '-'),
              _InfoRow(
                label: 'Cromatico',
                value: slot?.isShiny == true ? 'Sì' : 'No',
              ),
              _InfoRow(
                label: 'Sesso',
                value: TrainerUiLocalization.genderName(slot?.gender ?? '-'),
              ),
''',
    "Pokémon detail metadata",
)
path.write_text(text, encoding="utf-8")

# Remove the final mixed-language labels from the Trainer sheet.
path = Path("lib/screens/trainer/trainer_sheet_screen.dart")
text = path.read_text(encoding="utf-8")
for old, new, label in [
    ("title: 'Pack iniziale',", "title: 'Dotazione iniziale',", "starting pack picker title"),
    ("label: 'Pack iniziale',", "label: 'Dotazione iniziale',", "starting pack label"),
    ("detail: 'Equipaggiamento rapido. Lo zaino lo separiamo dopo.',", "detail: 'Equipaggiamento iniziale dell’Allenatore.',", "starting pack detail"),
    ("title: 'Prossimi upgrade',", "title: 'Prossimi avanzamenti',", "upgrades title"),
    ("'Pokéslot: massimo gia raggiunto.'", "'Pokéslot: massimo già raggiunto.'", "pokeslot wording"),
    ("'Controllo SR: massimo gia raggiunto.'", "'Controllo SR: massimo già raggiunto.'", "control wording"),
    ("title: 'Privilegio del Path',", "title: 'Privilegio del Percorso',", "path privilege title"),
    ("return 'Tocca il box e scegli dal pool disponibile.';", "return 'Tocca il riquadro e scegli dall’elenco disponibile.';", "specialization empty detail"),
]:
    text = replace_once(text, old, new, label)
text = replace_once(
    text,
    '''            _SheetInfoBox(
              label: 'Bonus competenza',
              value: _signed(_trainerProficiencyBonus(trainerLevel)),
              width: 92,
            ),''',
    '''            _SheetInfoBox(
              label: 'Competenza',
              value: _signed(_trainerProficiencyBonus(trainerLevel)),
              width: 108,
            ),''',
    "proficiency box",
)
path.write_text(text, encoding="utf-8")

# Extend the regression tests to cover the official nature names and final labels.
path = Path("test/trainer_ui_localization_test.dart")
text = path.read_text(encoding="utf-8")
text = replace_once(
    text,
    '''    expect(TrainerUiLocalization.featureName('Follow Me'), 'Sonoqui');
  });
''',
    '''    expect(TrainerUiLocalization.featureName('Follow Me'), 'Sonoqui');
    expect(TrainerUiLocalization.natureName('Adamant'), 'Decisa');
    expect(TrainerUiLocalization.natureName('Jolly'), 'Allegra');
    expect(TrainerUiLocalization.sizeName('Medium'), 'Media');
    expect(TrainerUiLocalization.genderName('Female'), 'Femmina');
  });
''',
    "localization mapping tests",
)
text = replace_once(
    text,
    '''    expect(trainerSheet, contains("title: 'AVANZAMENTO'"));
''',
    '''    expect(trainerSheet, contains("title: 'AVANZAMENTO'"));
    expect(trainerSheet, contains("title: 'Privilegio del Percorso'"));
    expect(trainerSheet, contains("label: 'Dotazione iniziale'"));
''',
    "source regression tests",
)
path.write_text(text, encoding="utf-8")
