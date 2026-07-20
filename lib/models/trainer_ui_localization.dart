class TrainerUiLocalization {
  const TrainerUiLocalization._();

  static const Map<String, String> abilityLabels = {
    'STR': 'FOR',
    'DEX': 'DES',
    'CON': 'COS',
    'INT': 'INT',
    'WIS': 'SAG',
    'CHA': 'CAR',
    'AC': 'CA',
    'HP': 'PF',
    'DC': 'CD',
  };

  static const Map<String, String> skillLabels = {
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

  static const Map<String, String> startingPackLabels = {
    "Dungeoneer's pack": 'Dotazione da Avventuriero',
    "Explorer's pack": 'Dotazione da Esploratore',
    "Filcher's pack": 'Dotazione da Borseggiatore',
  };

  static const Map<String, String> specializationLabels = {
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

  static const Map<String, String> trainerPathLabels = {
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

  static const Map<String, String> featureLabels = {
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

  static String abilityAbbreviation(String value) {
    return abilityLabels[value.trim().toUpperCase()] ?? value;
  }

  static String skillName(String value) => skillLabels[value] ?? value;

  static String startingPackName(String value) {
    return startingPackLabels[value] ?? value;
  }

  static String specializationName(String value) {
    return specializationLabels[value] ?? value;
  }

  static String trainerPathName(String value) {
    return trainerPathLabels[value] ?? value;
  }

  static String featureName(String value) {
    return featureLabels[value] ?? trainerPathName(value);
  }

  static String optionLabel(String value) {
    final parts = value.split(' · ');
    if (parts.length == 3 && parts[1].startsWith('Lv ')) {
      return '${trainerPathName(parts[0])} · Liv. ${parts[1].substring(3)} · ${featureName(parts[2])}';
    }
    final ability = abilityLabels[value.toUpperCase()];
    if (ability != null) return ability;
    final specialization = specializationLabels[value];
    if (specialization != null) return specialization;
    return visibleText(value);
  }

  static String visibleText(String value) {
    final exactFeature = featureLabels[value];
    if (exactFeature != null) return exactFeature;
    final exactPath = trainerPathLabels[value];
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
    for (final entry in skillLabels.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    for (final entry in abilityLabels.entries) {
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
