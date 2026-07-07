class TrainerManualOptions {
  const TrainerManualOptions._();

  static const List<String> startingPacks = [
    "Dungeoneer's pack",
    "Explorer's pack",
    "Filcher's pack",
  ];

  static const List<String> skillChoices = [
    'Acrobatics',
    'Athletics',
    'Insight',
    'Intimidation',
    'Investigation',
    'Medicine',
    'Nature',
    'Perception',
    'Performance',
    'Persuasion',
    'Sleight of Hand',
    'Stealth',
    'Survival',
  ];

  static const List<String> specializations = [
    'Bird Keeper',
    'Bug Maniac',
    'Camper',
    'Dragon Tamer',
    'Engineer',
    'Martial Artist',
    'Mountaineer',
    'Mystic',
    'Steel Worker',
    'Psychic',
    'Swimmer',
    'Charmer',
    'Shadow',
    'Alchemist',
    'Team Player',
    'Ice Skater',
    'Pyromaniac',
    'Gardener',
  ];

  static const Map<String, String> specializationNotes = {
    'Bird Keeper': 'Perception; +1 alle prove dei Pokémon Volante.',
    'Bug Maniac': 'Nature; +1 alle prove dei Pokémon Coleottero.',
    'Camper': 'Survival; +1 alle prove dei Pokémon Terra.',
    'Dragon Tamer': '+1 WIS; +1 alle prove dei Pokémon Drago.',
    'Engineer': '+1 INT; +1 alle prove dei Pokémon Elettro.',
    'Martial Artist': '+1 STR, CON o DEX; +1 alle prove dei Pokémon Lotta.',
    'Mountaineer': '+1 STR, CON o DEX; +1 alle prove dei Pokémon Roccia.',
    'Mystic': 'Arcana; +1 alle prove dei Pokémon Spettro.',
    'Steel Worker': '+1 STR o CON; +1 alle prove dei Pokémon Acciaio.',
    'Psychic': 'Telepathy 1/giorno su un tuo Pokémon; +1 ai Pokémon Psico.',
    'Swimmer': 'Velocità di nuoto pari al movimento; +1 ai Pokémon Acqua.',
    'Charmer': '+1 CHA; +1 alle prove dei Pokémon Folletto.',
    'Shadow': 'Deception o Stealth; +1 alle prove dei Pokémon Buio.',
    'Alchemist': 'Medicine o Deception; +1 alle prove dei Pokémon Veleno.',
    'Team Player': '+1 a una caratteristica; +1 alle prove dei Pokémon Normale.',
    'Ice Skater': 'Performance o Persuasion; +1 alle prove dei Pokémon Ghiaccio.',
    'Pyromaniac': '+1 CON; +1 alle prove dei Pokémon Fuoco.',
    'Gardener': 'Nature; +1 alle prove dei Pokémon Erba.',
  };

  static const List<String> trainerPaths = [
    'Ace Trainer',
    'Hobbyist',
    'Poké Mentor',
    'Pokéchef',
    'Researcher',
    'Pokémon Collector',
    'Nurse',
    'Commander',
    'Type Master',
    'Grunt',
    'Tactician',
    'Ranger',
    'Guru',
    'Pokémon Breeder',
  ];

  static const Map<String, String> trainerPathNotes = {
    'Ace Trainer': '+1 ad attacco e danni per tutti i Pokémon.',
    'Hobbyist': 'Una specializzazione extra e due competenze extra.',
    'Poké Mentor': 'Le TM possono essere usate due volte prima di rompersi.',
    'Pokéchef': 'Crea cibo e treat curativi per i Pokémon.',
    'Researcher': 'Aggiunge WIS o INT alle prove dei Pokémon.',
    'Pokémon Collector': 'Expertise in Animal Handling e focus sulla cattura.',
    'Nurse': 'Medicine e temp HP ai Pokémon dopo riposo lungo/Pokécenter.',
    'Commander': 'Starter Loyal; raddoppia bonus positivi di Loyalty.',
    'Type Master': 'Aumenta STAB dei Pokémon della specializzazione.',
    'Grunt': 'Shadow Points e opzioni reattive da team malvagio.',
    'Tactician': 'Tactical Points per supporto in battaglia.',
    'Ranger': 'Nature/Survival, Natural Explorer e legame col territorio.',
    'Guru': 'Pokémon sopra SR max restano Indifferent invece di Disloyal.',
    'Pokémon Breeder': 'Bonus a breeding, uova e tratti ereditati.',
  };
}
