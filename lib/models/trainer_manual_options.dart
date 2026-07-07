class TrainerManualOptions {
  const TrainerManualOptions._();

  static const List<String> fixedSkillProficiencies = ['Animal Handling'];

  static const List<String> startingPacks = [
    "Dungeoneer's pack",
    "Explorer's pack",
    "Filcher's pack",
  ];

  static const List<String> trainerRaces = [
    'Alolan',
    'Hoennian',
    'Johtoan',
    'Kalosian',
    'Kantoan',
    'Sinnoan',
    'Unovan',
    'Galarian',
    'Razza 5e approvata dal DM',
  ];

  static const Map<String, String> trainerRaceNotes = {
    'Alolan': '+2 INT, +1 CHA, Nature e Speak with Pokémon 1/riposo lungo.',
    'Hoennian': '+2 WIS, +1 INT, Survival e boon ambientale.',
    'Johtoan': '+2 INT, +1 STR, History e bonus ai critici con armi.',
    'Kalosian': '+2 CHA, +1 INT, Persuasion e reroll di un 1.',
    'Kantoan': '+1 a due caratteristiche, Investigation e un talento approvato.',
    'Sinnoan': '+2 CON, +1 STR, Athletics e TS Costituzione.',
    'Unovan': '+2 DEX, +1 WIS, Insight e due competenze a scelta.',
    'Galarian': '+2 DEX/+1 STR o +2 STR/+1 DEX, Intimidation e reazione difensiva.',
    'Razza 5e approvata dal DM': 'Usa una razza 5e classica o homebrew approvata.',
  };

  static const List<String> backgroundOptions = [
    'Acolyte',
    'Charlatan',
    'Criminal',
    'Entertainer',
    'Folk Hero',
    'Guild Artisan',
    'Hermit',
    'Noble',
    'Outlander',
    'Sage',
    'Sailor',
    'Soldier',
    'Urchin',
    'Background personalizzato',
  ];

  static const Map<String, String> backgroundNotes = {
    'Acolyte': 'Vita religiosa, templi, riti e contatti con fedeli.',
    'Charlatan': 'Falsa identita, raggiri, travestimenti e inganni sociali.',
    'Criminal': 'Contatti nel sottobosco criminale e conoscenza di attivita illecite.',
    'Entertainer': 'Esibizioni, pubblico, strumenti e ospitalita tramite performance.',
    'Folk Hero': 'Origine popolare, gente comune pronta ad aiutarti.',
    'Guild Artisan': 'Mestiere, corporazione, contatti professionali e botteghe.',
    'Hermit': 'Isolamento, scoperta personale e conoscenze rare.',
    'Noble': 'Titolo, privilegio, etichetta e accesso a circoli elevati.',
    'Outlander': 'Viaggi, terre selvagge, memoria del territorio e sopravvivenza.',
    'Sage': 'Studio, ricerca, biblioteche e accesso a conoscenze specialistiche.',
    'Sailor': 'Navi, equipaggi, porti e vita sul mare.',
    'Soldier': 'Grado militare, disciplina, eserciti e gerarchie.',
    'Urchin': 'Strade cittadine, furtivita urbana e sopravvivenza nei vicoli.',
    'Background personalizzato': 'Definisci con il DM competenze, strumenti e tratto.',
  };

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

  static const Map<String, String> skillNotes = {
    'Animal Handling': 'Gestire, calmare e guidare Pokémon o altre creature.',
    'Acrobatics': 'Equilibrio, salti, cadute controllate e manovre agili.',
    'Athletics': 'Scalare, nuotare, saltare, spingere o trattenere con forza.',
    'Insight': 'Leggere intenzioni, emozioni e menzogne non evidenti.',
    'Intimidation': 'Imporre pressione, minaccia o autorità in una scena.',
    'Investigation': 'Cercare indizi e collegare dettagli con ragionamento.',
    'Medicine': 'Stabilizzare, curare e riconoscere condizioni fisiche.',
    'Nature': 'Conoscenze su ambienti, piante, meteo e creature naturali.',
    'Perception': 'Notare dettagli, pericoli, tracce e presenze nascoste.',
    'Performance': 'Intrattenere, recitare, suonare o attirare attenzione.',
    'Persuasion': 'Convincere, mediare o negoziare senza coercizione.',
    'Sleight of Hand': 'Destrezza manuale, borseggiare o manipolare oggetti.',
    'Stealth': 'Muoversi, nascondersi e agire senza farsi notare.',
    'Survival': 'Orientarsi, seguire tracce e resistere in ambienti selvaggi.',
  };

  static const Map<int, List<String>> trainerLevelFeatures = {
    1: ['Starter Pokémon', 'Specializzazione'],
    2: ['Trainer Path'],
    3: ['Control Upgrade'],
    4: ['Ability Score Improvement'],
    5: ['Trainer Path Feature', 'Pokéslot'],
    6: ['Control Upgrade'],
    7: ['Specializzazione'],
    8: ['Ability Score Improvement', 'Control Upgrade'],
    9: ['Trainer Path Feature'],
    10: ["Trainer's Resolve", 'Pokéslot'],
    11: ['Control Upgrade'],
    12: ['Ability Score Improvement'],
    13: ['Pokémon Tracker'],
    14: ['Control Upgrade'],
    15: ['Trainer Path Feature', 'Pokéslot'],
    16: ['Ability Score Improvement'],
    17: ['Control Upgrade'],
    18: ['Specializzazione'],
    19: ['Ability Score Improvement'],
    20: ['Master Trainer'],
  };

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
