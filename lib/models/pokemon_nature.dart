class PokemonNature {
  static const Map<String, Map<String, int>> modifiers = {
    'Reckless': {'STR': 2, 'DEX': -2},
    'Rash': {'STR': 2, 'CON': -2},
    'Brave': {'STR': 2, 'WIS': -2},
    'Arrogant': {'STR': 2, 'CHA': -2},
    'Skittish': {'DEX': 2, 'STR': -2},
    'Hasty': {'DEX': 2, 'CON': -2},
    'Energetic': {'DEX': 2, 'CHA': -2},
    'Clumsy': {'DEX': 2, 'WIS': -2},
    'Apathetic': {'CON': 2, 'DEX': -2},
    'Stubborn': {'CON': 2, 'WIS': -2},
    'Grumpy': {'CON': 2, 'CHA': -2},
    'Relaxed': {'CON': 2, 'STR': -2},
    'Careful': {'WIS': 2, 'STR': -2},
    'Curious': {'WIS': 2, 'CON': -2},
    'Naughty': {'WIS': 2, 'CHA': -2},
    'Cheerful': {'CHA': 2, 'STR': -2},
    'Sassy': {'CHA': 2, 'DEX': -2},
    'Innocent': {'CHA': 2, 'WIS': -2},
    'Hardy': {'AC': 1, 'DEX': -2},
    'Nimble': {'AC': 1, 'STR': -2},
    'No Nature': {},
  };

  static const Map<String, String> labels = {
    'Reckless': 'Sconsiderata',
    'Rash': 'Impulsiva',
    'Brave': 'Coraggiosa',
    'Arrogant': 'Arrogante',
    'Skittish': 'Timorosa',
    'Hasty': 'Frettolosa',
    'Energetic': 'Energica',
    'Clumsy': 'Goffa',
    'Apathetic': 'Apatica',
    'Stubborn': 'Testarda',
    'Grumpy': 'Scontrosa',
    'Relaxed': 'Rilassata',
    'Careful': 'Prudente',
    'Curious': 'Curiosa',
    'Naughty': 'Birichina',
    'Cheerful': 'Allegra',
    'Sassy': 'Insolente',
    'Innocent': 'Innocente',
    'Hardy': 'Tenace',
    'Nimble': 'Agile',
    'No Nature': 'Nessuna natura',
  };

  static List<String> get names => modifiers.keys.toList();

  static String labelFor(String nature) => labels[nature] ?? nature;

  static Map<String, int> forName(String nature) {
    return modifiers[nature] ?? const {};
  }
}
