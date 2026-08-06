import '../localization/game_catalog_locale.dart';

class TrainerUiLocalization {
  const TrainerUiLocalization._();

  static const Map<String, String> _abilityLabelsIt = {
    'STR': 'FOR',
    'DEX': 'DES',
    'CON': 'COS',
    'INT': 'INT',
    'WIS': 'SAG',
    'CHA': 'CAR',
    'AC': 'CA',
    'HP': 'PF',
    'DC': 'CD',
    'STRENGTH': 'Forza',
    'DEXTERITY': 'Destrezza',
    'CONSTITUTION': 'Costituzione',
    'INTELLIGENCE': 'Intelligenza',
    'WISDOM': 'Saggezza',
    'CHARISMA': 'Carisma',
  };

  static const Map<String, String> _skillLabelsIt = {
    'Acrobatics': 'Acrobazia',
    'Animal Handling': 'Addestrare Animali',
    'Arcana': 'Arcano',
    'Athletics': 'Atletica',
    'Deception': 'Inganno',
    'History': 'Storia',
    'Insight': 'Intuizione',
    'Intimidation': 'Intimidire',
    'Investigation': 'Indagare',
    'Medicine': 'Medicina',
    'Nature': 'Natura',
    'Perception': 'Percezione',
    'Performance': 'Intrattenere',
    'Persuasion': 'Persuasione',
    'Religion': 'Religione',
    'Sleight of Hand': 'Rapidità di Mano',
    'Stealth': 'Furtività',
    'Survival': 'Sopravvivenza',
  };

  static const Map<String, String> _startingPackLabelsIt = {
    "Dungeoneer's pack": 'Dotazione da Avventuriero',
    "Explorer's pack": 'Dotazione da Esploratore',
    "Filcher's pack": 'Dotazione da Borseggiatore',
  };

  static const Map<String, String> _startingPackDescriptionsIt = {
    "Dungeoneer's pack":
        'Contiene: zaino, kit da scalatore, torcia, 5 celle energetiche, acciarino e pietra focaia, 10 razioni da campeggio, borraccia e 30 piedi di corda.',
    "Explorer's pack":
        'Contiene: zaino, sacco a pelo, gavetta, acciarino e pietra focaia, torcia, 5 celle energetiche, 10 razioni da campeggio, borraccia e 30 piedi di corda.',
    "Filcher's pack":
        'Contiene: zaino, arnesi da scasso, 20 piedi di filo, campanella, lanterna, 3 celle energetiche, 5 razioni da campeggio, acciarino e pietra focaia e borraccia.',
  };
  static const Map<String, String> _startingPackDescriptionsEn = {
    "Dungeoneer's pack":
        "Contains a backpack, climber's kit, flashlight, 5 energy cells, flint and steel, 10 camping rations, a canteen, and 30 feet of rope.",
    "Explorer's pack":
        'Contains a backpack, sleeping bag, mess kit, flint and steel, flashlight, 5 energy cells, 10 camping rations, a canteen, and 30 feet of rope.',
    "Filcher's pack":
        "Contains a backpack, thieves' tools, 20 feet of wire, a bell, a lantern, 3 energy cells, 5 camping rations, flint and steel, and a canteen.",
  };
  static const List<String> backgroundOptions = [
    'Ricercatore',
    'Esploratore',
    'Allevatore',
    'Combattente',
    'Artista',
    'Studioso',
  ];
  static const Map<String, String> _backgroundLabelsIt = {
    'Ricercatore': 'Ricercatore',
    'Esploratore': 'Esploratore',
    'Allevatore': 'Allevatore',
    'Combattente': 'Combattente',
    'Artista': 'Artista',
    'Studioso': 'Studioso',
  };
  static const Map<String, String> _backgroundLabelsEn = {
    'Ricercatore': 'Researcher',
    'Esploratore': 'Explorer',
    'Allevatore': 'Breeder',
    'Combattente': 'Fighter',
    'Artista': 'Artist',
    'Studioso': 'Scholar',
  };
  static const Map<String, String> _backgroundDescriptionsIt = {
    'Ricercatore':
        'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Esploratore':
        'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Allevatore':
        'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Combattente':
        'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Artista':
        'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
    'Studioso':
        'Background scelto durante l’onboarding. Nel manuale disponibile non gli sono associati aumenti automatici delle caratteristiche.',
  };
  static const Map<String, String> _backgroundDescriptionsEn = {
    'Ricercatore':
        'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Esploratore':
        'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Allevatore':
        'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Combattente':
        'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Artista':
        'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
    'Studioso':
        'Background selected during onboarding. The available manual does not associate it with automatic ability-score increases.',
  };

  static const Map<String, String> _natureLabelsIt = {
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

  static const Map<String, String> _sizeLabelsIt = {
    'Tiny': 'Minuscola',
    'Small': 'Piccola',
    'Medium': 'Media',
    'Large': 'Grande',
    'Huge': 'Enorme',
    'Gargantuan': 'Mastodontica',
  };

  static const Map<String, String> _genderLabelsIt = {
    'Male': 'Maschio',
    'Female': 'Femmina',
    'Genderless': 'Senza sesso',
    'Random': 'Casuale',
  };

  static const Map<String, String> _specializationLabelsIt = {
    'Bird Keeper': 'Avicoltore',
    'Bug Maniac': 'Insettologo',
    'Camper': 'Campeggiatore',
    'Dragon Tamer': 'Domadraghi',
    'Engineer': 'Meccanico',
    'Martial Artist': 'Esperto Lotta',
    'Mountaineer': 'Montanaro',
    'Mystic': 'Mistico',
    'Steel Worker': "Lavoratore dell'Acciaio",
    'Psychic': 'Sensitivo',
    'Swimmer': 'Nuotatore',
    'Charmer': 'Ammaliatore',
    'Shadow': 'Ombra',
    'Alchemist': 'Alchimista',
    'Team Player': 'Giocatore di Squadra',
    'Ice Skater': 'Pattinatore su Ghiaccio',
    'Pyromaniac': 'Brandifuoco',
    'Gardener': 'Giardiniere',
  };

  static const Map<String, String> _trainerPathLabelsIt = {
    'Ace Trainer': 'Fantallenatore',
    'Hobbyist': 'Appassionato',
    'Poké Mentor': 'Mentore Pokémon',
    'Pokéchef': 'Pokéchef',
    'Researcher': 'Ricercatore',
    'Pokémon Collector': 'Collezionista Pokémon',
    'Nurse': 'Infermiera',
    'Commander': 'Comandante',
    'Type Master': 'Maestro dei Tipi',
    'Grunt': 'Recluta',
    'Tactician': 'Stratega',
    'Ranger': 'Pokémon Ranger',
    'Guru': 'Guru',
    'Pokémon Breeder': 'Allevapokémon',
  };

  static const Map<String, String> _featureLabelsIt = {
    'Ace Trainer': 'Fantallenatore',
    'Battle Master': 'Maestro della Lotta',
    'Max Potential': 'Massimo Potenziale',
    'Rapid Switching': 'Cambio Rapido',
    'Hobbyist': 'Appassionato',
    'Versatile': 'Versatile',
    'Many Faces': 'Mille Volti',
    'Skill Switch': 'Cambio di Talento',
    'Poké Mentor': 'Mentore Pokémon',
    'Tutor': 'Tutor',
    'Guided Practice': 'Pratica Guidata',
    'Master Teacher': 'Maestro Insegnante',
    'Pokéchef': 'Pokéchef',
    'Edible Treat': 'Leccornia Curativa',
    'Cheerleader': 'Incitatore',
    'Researcher': 'Ricercatore',
    'Analyst': 'Analista',
    'Evolutionary Expert': 'Esperto di Evoluzione',
    'Professor': 'Professore',
    'Pokémon Collector': 'Collezionista Pokémon',
    "Gotta Catch 'Em All": 'Acchiappali Tutti',
    'Catching Expert': 'Esperto di Cattura',
    'Disciplined Strikes': 'Colpi Controllati',
    'Nurse': 'Infermiera',
    'Pure Heart': 'Cuore Puro',
    'Healing Spirit': 'Spirito Curativo',
    'Joy': 'Gioia',
    'Commander': 'Comandante',
    'Follow Me': 'Sonoqui',
    "Show Me What You've Got": 'Fammi Vedere Cosa Sai Fare',
    "We're a Team": 'Siamo una Squadra',
    'Type Master': 'Maestro dei Tipi',
    'Drawing Power': 'Attingere Potere',
    'Storing Power': 'Accumulo di Potere',
    'Releasing Power': 'Scatenare il Potere',
    'Sabotage': 'Sabotaggio',
    'And Make It Double': 'E Raddoppiate i Guai',
    'Surrender Now': 'Arrendetevi Subito',
    'Prepare to Fight': 'Preparatevi a Combattere',
    'Tactician': 'Stratega',
    'Directed Strike': 'Colpo Guidato',
    'Raise Your Defenses': 'Alza le Difese',
    'Not This Time': 'Non Stavolta',
    'Ranger': 'Pokémon Ranger',
    'Deep Connection': 'Legame Profondo',
    'Strong Bond': 'Legame Forte',
    'Best Friends': 'Migliori Amici',
    'Guru': 'Guru',
    'Mind': 'Mente',
    'Body': 'Corpo',
    'Spirit': 'Spirito',
    'Pokémon Breeder': 'Allevapokémon',
    'Tender Love and Care': 'Cure Premurose',
    'Good Genes': 'Buoni Geni',
    'Master of Traits': 'Maestro dei Tratti',
  };

  static bool get _isItalian => GameCatalogLocale.isItalian;

  static Map<String, String> _localizedMap(Map<String, String> italian) {
    if (_isItalian) return italian;
    return {for (final key in italian.keys) key: key};
  }

  static Map<String, String> get abilityLabels =>
      _localizedMap(_abilityLabelsIt);
  static Map<String, String> get skillLabels => _localizedMap(_skillLabelsIt);
  static Map<String, String> get startingPackLabels =>
      _localizedMap(_startingPackLabelsIt);
  static Map<String, String> get startingPackDescriptions =>
      _isItalian ? _startingPackDescriptionsIt : _startingPackDescriptionsEn;
  static Map<String, String> get backgroundLabels =>
      _isItalian ? _backgroundLabelsIt : _backgroundLabelsEn;
  static Map<String, String> get backgroundDescriptions =>
      _isItalian ? _backgroundDescriptionsIt : _backgroundDescriptionsEn;
  static Map<String, String> get natureLabels => _localizedMap(_natureLabelsIt);
  static Map<String, String> get sizeLabels => _localizedMap(_sizeLabelsIt);
  static Map<String, String> get genderLabels => _localizedMap(_genderLabelsIt);
  static Map<String, String> get specializationLabels =>
      _localizedMap(_specializationLabelsIt);
  static Map<String, String> get trainerPathLabels =>
      _localizedMap(_trainerPathLabelsIt);
  static Map<String, String> get featureLabels =>
      _localizedMap(_featureLabelsIt);

  static String abilityAbbreviation(String value) {
    final normalized = value.trim().toUpperCase();
    if (_isItalian) return _abilityLabelsIt[normalized] ?? value.trim();

    return const <String, String>{
          'STRENGTH': 'Strength',
          'DEXTERITY': 'Dexterity',
          'CONSTITUTION': 'Constitution',
          'INTELLIGENCE': 'Intelligence',
          'WISDOM': 'Wisdom',
          'CHARISMA': 'Charisma',
        }[normalized] ??
        normalized;
  }

  static String skillName(String value) =>
      _isItalian ? (_skillLabelsIt[value] ?? value) : value;

  static String startingPackName(String value) =>
      _isItalian ? (_startingPackLabelsIt[value] ?? value) : value;
  static String startingPackDescription(String value) =>
      startingPackDescriptions[value] ?? '';
  static String backgroundName(String value) =>
      backgroundLabels[value] ?? value;
  static String backgroundDescription(String value) =>
      backgroundDescriptions[value] ?? '';

  static String natureName(String value) =>
      _isItalian ? (_natureLabelsIt[value] ?? value) : value;

  static String sizeName(String value) =>
      _isItalian ? (_sizeLabelsIt[value] ?? value) : value;

  static String genderName(String value) =>
      _isItalian ? (_genderLabelsIt[value] ?? value) : value;

  static String specializationName(String value) =>
      _isItalian ? (_specializationLabelsIt[value] ?? value) : value;

  static String trainerPathName(String value) =>
      _isItalian ? (_trainerPathLabelsIt[value] ?? value) : value;

  static String featureName(String value) {
    if (!_isItalian) return value;
    return _featureLabelsIt[value] ?? trainerPathName(value);
  }

  static String optionLabel(String value) {
    if (!_isItalian) return value;
    final parts = value.split(' · ');
    if (parts.length == 3 && parts[1].startsWith('Lv ')) {
      return '${trainerPathName(parts[0])} · Liv. ${parts[1].substring(3)} · ${featureName(parts[2])}';
    }
    final ability = _abilityLabelsIt[value.toUpperCase()];
    if (ability != null) return ability;
    final specialization = _specializationLabelsIt[value];
    if (specialization != null) return specialization;
    return visibleText(value);
  }

  static String visibleText(String value) {
    if (!_isItalian) return value;
    final exactFeature = _featureLabelsIt[value];
    if (exactFeature != null) return exactFeature;
    final exactPath = _trainerPathLabelsIt[value];
    if (exactPath != null) return exactPath;

    var result = value;
    const phraseReplacements = <String, String>{
      'Trainer Path': 'Percorso Allenatore',
      'Shadow Points': 'Punti Ombra',
      'Tactical Points': 'Punti Tattici',
      'Ability Score Improvement': 'Aumento di Caratteristica',
      'Control Upgrade': 'Aumento del Controllo',
      'Master Trainer': 'Maestro Allenatore',
      "Trainer's Resolve": "Determinazione dell'Allenatore",
      'Pokémon Tracker': 'Ricercatore Pokémon',
      'Additional Feats': 'Talenti Aggiuntivi',
      'Egg Moves': 'Mosse Uovo',
      'Egg Move': 'Mossa Uovo',
      'Speak with Animals': 'Parlare con gli Animali',
      'Copy Meowth': 'Copia Meowth',
      'livello trainer': "livello dell'Allenatore",
      'level up': 'aumento di livello',
      'stat block': 'blocco statistiche',
      'Pokecenter': 'Centro Pokémon',
      'Pokemon': 'Pokémon',
      'Loyalty': 'Lealtà',
      'Loyal': 'Leale',
      'Disloyal': 'Sleale',
      'Indifferent': 'Indifferente',
      'Feature': 'Privilegio',
      'feature': 'privilegio',
      'Path': 'Percorso',
      'path': 'percorso',
      'DM': 'Master',
      'pool': 'elenco',
      'item': 'oggetto',
      'tier': 'grado',
      'treat': 'leccornia',
    };
    for (final entry in phraseReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    for (final entry in _skillLabelsIt.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    for (final entry in _abilityLabelsIt.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b'),
        entry.value,
      );
    }
    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)\s*ft\b', caseSensitive: false),
      (match) => '${match.group(1)} piedi',
    );
    return result;
  }
}
