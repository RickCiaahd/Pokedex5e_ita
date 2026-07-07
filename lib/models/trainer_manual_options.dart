class TrainerSkillDefinition {
  const TrainerSkillDefinition({
    required this.name,
    required this.ability,
    required this.description,
  });

  final String name;
  final String ability;
  final String description;
}

class TrainerPathFeature {
  const TrainerPathFeature({
    required this.level,
    required this.title,
    required this.description,
  });

  final int level;
  final String title;
  final String description;
}

class TrainerManualOptions {
  const TrainerManualOptions._();

  static const List<String> fixedSkillProficiencies = ['Animal Handling'];
  static const List<String> fixedSavingThrowProficiencies = ['CHA'];

  static const List<String> savingThrows = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];

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
    'Origine 5e approvata dal DM',
  ];

  static const Map<String, String> trainerRaceNotes = {
    'Alolan':
        'Bonus caratteristiche: INT +2, CHA +1.\n'
        'Competenza: Nature.\n'
        'Tratto: puoi lanciare Speak with Pokemon una volta per riposo lungo. '
        'E una buona origine per trainer curiosi, sociali e molto legati alla vita naturale dei Pokemon.',
    'Hoennian':
        'Bonus caratteristiche: WIS +2, INT +1.\n'
        'Competenza: Survival.\n'
        'Tratto: sei abituato a viaggiare in ambienti difficili e a cavartela tra clima, terreno e rotte selvagge. '
        'Funziona bene per esploratori, ranger e allenatori da viaggio.',
    'Johtoan':
        'Bonus caratteristiche: INT +2, STR +1.\n'
        'Competenza: History.\n'
        'Tratto: la tua formazione richiama tradizioni antiche e disciplina fisica; il tratto marziale premia i colpi critici con armi. '
        'Adatta a trainer legati a storia, templi, rovine e leggende.',
    'Kalosian':
        'Bonus caratteristiche: CHA +2, INT +1.\n'
        'Competenza: Persuasion.\n'
        'Tratto: puoi ritirare un 1 secondo le regole dell origine. '
        'E pensata per trainer eleganti, diplomatici e capaci di restare lucidi quando contano presenza e stile.',
    'Kantoan':
        'Bonus caratteristiche: +1 a due caratteristiche a scelta. Questo bonus va assegnato manualmente nei box delle caratteristiche.\n'
        'Competenza: Investigation.\n'
        'Tratto: ottieni un talento approvato dal DM. '
        'E l origine piu flessibile, ottima se vuoi costruire un trainer molto personalizzato.',
    'Sinnoan':
        'Bonus caratteristiche: CON +2, STR +1.\n'
        'Competenza: Athletics.\n'
        'Tratto: ottieni competenza nei tiri salvezza di Costituzione. '
        'Ideale per allenatori resistenti, abituati a montagna, neve e lunghe spedizioni.',
    'Unovan':
        'Bonus caratteristiche: DEX +2, WIS +1.\n'
        'Competenza: Insight.\n'
        'Tratto: ottieni due competenze aggiuntive a scelta. '
        'Perfetta per trainer rapidi, adattabili e capaci di leggere persone e situazioni.',
    'Galarian':
        'Bonus caratteristiche: scegli DEX +2 e STR +1 oppure STR +2 e DEX +1. Questo bonus va assegnato manualmente nei box delle caratteristiche.\n'
        'Competenza: Intimidation.\n'
        'Tratto: ottieni una reazione difensiva. '
        'Adatta a trainer competitivi, fisici e abituati a reggere la pressione dello scontro.',
    'Origine 5e approvata dal DM':
        'Usa una origine 5e classica o homebrew approvata dal DM. '
        'Segna manualmente bonus caratteristiche, competenze e tratti concordati al tavolo.',
  };

  static const Map<String, Map<String, int>> originAbilityBonuses = {
    'Alolan': {'INT': 2, 'CHA': 1},
    'Hoennian': {'WIS': 2, 'INT': 1},
    'Johtoan': {'INT': 2, 'STR': 1},
    'Kalosian': {'CHA': 2, 'INT': 1},
    'Sinnoan': {'CON': 2, 'STR': 1},
    'Unovan': {'DEX': 2, 'WIS': 1},
  };

  static const List<TrainerSkillDefinition> skills = [
    TrainerSkillDefinition(
      name: 'Acrobatics',
      ability: 'DEX',
      description:
          'Equilibrio, capriole, salti difficili, atterraggi controllati e manovre agili quando il corpo deve evitare cadute o ostacoli.',
    ),
    TrainerSkillDefinition(
      name: 'Animal Handling',
      ability: 'WIS',
      description:
          'Calmare, guidare, intuire e gestire Pokémon o altre creature. Per i trainer è competenza fissa e copre molte interazioni con Pokémon selvatici o alleati.',
    ),
    TrainerSkillDefinition(
      name: 'Arcana',
      ability: 'INT',
      description:
          'Conoscenze su magia, fenomeni soprannaturali, energie insolite, piani e tradizioni occulte che possono emergere in un mondo Pokémon.',
    ),
    TrainerSkillDefinition(
      name: 'Athletics',
      ability: 'STR',
      description:
          'Scalare, saltare, nuotare, spingere, trattenere o superare ostacoli usando forza fisica e allenamento corporeo.',
    ),
    TrainerSkillDefinition(
      name: 'Deception',
      ability: 'CHA',
      description:
          'Mentire, camuffare intenzioni, raggirare, bluffare o sostenere una falsa identita in modo convincente.',
    ),
    TrainerSkillDefinition(
      name: 'History',
      ability: 'INT',
      description:
          'Ricordare eventi, luoghi, culture, leggende, lignaggi, guerre, rovine e tradizioni del mondo.',
    ),
    TrainerSkillDefinition(
      name: 'Insight',
      ability: 'WIS',
      description:
          'Leggere emozioni, intenzioni e bugie non evidenti; capire se una persona o creatura sta nascondendo qualcosa.',
    ),
    TrainerSkillDefinition(
      name: 'Intimidation',
      ability: 'CHA',
      description:
          'Imporre pressione con presenza, minacce, tono o reputazione per costringere qualcuno a cedere o esitare.',
    ),
    TrainerSkillDefinition(
      name: 'Investigation',
      ability: 'INT',
      description:
          'Cercare indizi, collegare dettagli, dedurre cause e ricostruire cosa è successo tramite ragionamento attivo.',
    ),
    TrainerSkillDefinition(
      name: 'Medicine',
      ability: 'WIS',
      description:
          'Stabilizzare creature, diagnosticare ferite o malattie, riconoscere condizioni fisiche e applicare cure pratiche.',
    ),
    TrainerSkillDefinition(
      name: 'Nature',
      ability: 'INT',
      description:
          'Conoscenze su ambienti, piante, clima, cicli naturali, terreni e creature del mondo naturale.',
    ),
    TrainerSkillDefinition(
      name: 'Perception',
      ability: 'WIS',
      description:
          'Notare dettagli, pericoli, tracce, rumori, odori, movimenti o presenze nascoste prima che diventino evidenti.',
    ),
    TrainerSkillDefinition(
      name: 'Performance',
      ability: 'CHA',
      description:
          'Intrattenere, recitare, cantare, suonare, attirare attenzione o sostenere una presenza scenica davanti a un pubblico.',
    ),
    TrainerSkillDefinition(
      name: 'Persuasion',
      ability: 'CHA',
      description:
          'Convincere, mediare, negoziare o ispirare fiducia tramite tatto, argomenti e buona presenza sociale.',
    ),
    TrainerSkillDefinition(
      name: 'Religion',
      ability: 'INT',
      description:
          'Conoscenze su divinità, miti, riti, chiese, simboli sacri, culti e tradizioni religiose.',
    ),
    TrainerSkillDefinition(
      name: 'Sleight of Hand',
      ability: 'DEX',
      description:
          'Rapidita manuale, borseggiare, nascondere piccoli oggetti, manipolare strumenti o compiere movimenti precisi senza farsi notare.',
    ),
    TrainerSkillDefinition(
      name: 'Stealth',
      ability: 'DEX',
      description:
          'Nascondersi, muoversi silenziosamente, restare fuori vista e agire senza attirare attenzione.',
    ),
    TrainerSkillDefinition(
      name: 'Survival',
      ability: 'WIS',
      description:
          'Seguire tracce, orientarsi, trovare cibo o riparo, prevedere pericoli naturali e resistere in ambienti selvaggi.',
    ),
  ];

  static List<String> get skillChoices => const [
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

  static Map<String, String> get skillNotes => {
    for (final skill in skills) skill.name: skill.description,
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
    'Bird Keeper':
        'Ottieni competenza in Perception. I tuoi Pokémon Volante aggiungono +1 alle prove di abilita.',
    'Bug Maniac':
        'Ottieni competenza in Nature. I tuoi Pokémon Coleottero aggiungono +1 alle prove di abilita.',
    'Camper':
        'Ottieni competenza in Survival. I tuoi Pokémon Terra aggiungono +1 alle prove di abilita.',
    'Dragon Tamer':
        'Aumenti WIS di +1. I tuoi Pokémon Drago aggiungono +1 alle prove di abilita.',
    'Engineer':
        'Aumenti INT di +1. I tuoi Pokémon Elettro aggiungono +1 alle prove di abilita.',
    'Martial Artist':
        'Aumenti STR, CON o DEX di +1. I tuoi Pokémon Lotta aggiungono +1 alle prove di abilita.',
    'Mountaineer':
        'Aumenti STR, CON o DEX di +1. I tuoi Pokémon Roccia aggiungono +1 alle prove di abilita.',
    'Mystic':
        'Ottieni competenza in Arcana. I tuoi Pokémon Spettro aggiungono +1 alle prove di abilita.',
    'Steel Worker':
        'Aumenti STR o CON di +1. I tuoi Pokémon Acciaio aggiungono +1 alle prove di abilita.',
    'Psychic':
        'Puoi usare Telepathy una volta al giorno su un tuo Pokémon. I tuoi Pokémon Psico aggiungono +1 alle prove di abilita.',
    'Swimmer':
        'Ottieni velocita di nuoto pari al tuo movimento. I tuoi Pokémon Acqua aggiungono +1 alle prove di abilita.',
    'Charmer':
        'Aumenti CHA di +1. I tuoi Pokémon Folletto aggiungono +1 alle prove di abilita.',
    'Shadow':
        'Ottieni competenza in Deception o Stealth. I tuoi Pokémon Buio aggiungono +1 alle prove di abilita.',
    'Alchemist':
        'Ottieni competenza in Medicine o Deception. I tuoi Pokémon Veleno aggiungono +1 alle prove di abilita.',
    'Team Player':
        'Aumenti una caratteristica di +1. I tuoi Pokémon Normale aggiungono +1 alle prove di abilita.',
    'Ice Skater':
        'Ottieni competenza in Performance o Persuasion. I tuoi Pokémon Ghiaccio aggiungono +1 alle prove di abilita.',
    'Pyromaniac':
        'Aumenti CON di +1. I tuoi Pokémon Fuoco aggiungono +1 alle prove di abilita.',
    'Gardener':
        'Ottieni competenza in Nature. I tuoi Pokémon Erba aggiungono +1 alle prove di abilita.',
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

  static const Map<String, List<TrainerPathFeature>> trainerPathFeatures = {
    'Ace Trainer': [
      TrainerPathFeature(
        level: 2,
        title: 'Ace Trainer',
        description:
            'I tuoi Pokémon ottengono +1 ai tiri per colpire e ai danni. È il path più diretto per chi vuole eccellere in battaglia.',
      ),
      TrainerPathFeature(
        level: 5,
        title: 'Battle Master',
        description:
            'Ottieni dadi battaglia d6 pari a 1 + modificatore WIS, minimo 1. Puoi assegnarne uno a un tuo Pokémon dopo un tiro per colpire o danni per aggiungerlo al risultato. Recuperi i dadi con un riposo lungo.',
      ),
      TrainerPathFeature(
        level: 9,
        title: 'Max Potential',
        description:
            'Scegli un potenziamento permanente per tutti i tuoi Pokémon: +10 ft velocita, +1 STR, +1 DEX oppure +1 CON.',
      ),
      TrainerPathFeature(
        level: 15,
        title: 'Rapid Switching',
        description:
            'Puoi richiamare e mandare in campo Pokémon come azione bonus. Usi pari a 1 + modificatore WIS, minimo 1, recuperati con riposo lungo. Un Pokémon non può essere sostituito prima della fine del suo primo turno completo, salvo effetti specifici.',
      ),
    ],
    'Hobbyist': [
      TrainerPathFeature(level: 2, title: 'Hobbyist', description: 'Scegli una specializzazione aggiuntiva e due competenze extra.'),
      TrainerPathFeature(level: 5, title: 'Versatile', description: 'Ottieni dadi abilita d6 pari a 1 + modificatore WIS, minimo 1. Puoi aggiungerne uno a una prova di abilita o tiro salvezza di un tuo Pokémon dopo il tiro. Recuperi i dadi con riposo lungo.'),
      TrainerPathFeature(level: 9, title: 'Many Faces', description: 'Scegli una feature di livello 2, 5 o 9 da un altro Trainer Path.'),
      TrainerPathFeature(level: 15, title: 'Skill Switch', description: 'A ogni riposo lungo scegli un talento dalla sezione Additional Feats: tutti i tuoi Pokémon lo conoscono per quel giorno.'),
    ],
    'Poké Mentor': [
      TrainerPathFeature(level: 2, title: 'Poké Mentor', description: 'Le tue TM possono essere usate due volte prima di rompersi.'),
      TrainerPathFeature(level: 5, title: 'Tutor', description: 'Il tuo addestramento riduce tempi e sprechi nell’insegnare mosse. Usa questa tappa come riferimento per gestione TM e apprendimento al tavolo.'),
      TrainerPathFeature(level: 9, title: 'Guided Practice', description: 'Il mentoring diventa più efficiente: i Pokémon apprendono e consolidano tecniche con maggiore facilita durante la crescita.'),
      TrainerPathFeature(level: 15, title: 'Master Teacher', description: 'Le mosse dei tuoi Pokémon possono essere apprese e dimenticate a ogni riposo lungo invece che solo al level up.'),
    ],
    'Pokéchef': [
      TrainerPathFeature(level: 2, title: 'Pokéchef', description: 'Sei specializzato nel preparare cibo e treat per sostenere i Pokémon durante l’avventura.'),
      TrainerPathFeature(level: 5, title: 'Edible Treat', description: 'Prepari treat curativi. Come azione un Pokémon recupera 2d4+2 PF. Usi pari a 1 + modificatore WIS, recuperati con riposo lungo.'),
      TrainerPathFeature(level: 9, title: 'Cheerleader', description: 'Una volta per riposo breve, come azione bonus, ispiri gli alleati: fino al tuo prossimo turno aggiungi il modificatore CHA, minimo 1, a tiri per colpire, danni oppure CA degli alleati. I treat curano 3d10+6.'),
      TrainerPathFeature(level: 15, title: 'Master Teacher', description: 'Le mosse possono essere apprese e dimenticate a ogni riposo lungo; i tuoi treat curano 4d12+10 PF.'),
    ],
    'Researcher': [
      TrainerPathFeature(level: 2, title: 'Researcher', description: 'Scegli WIS o INT quando prendi il path. Puoi aggiungere quel modificatore, minimo 1, alle prove di abilita dei tuoi Pokémon.'),
      TrainerPathFeature(level: 5, title: 'Analyst', description: 'Come azione bonus puoi fare una prova Investigation CD 12 per determinare il livello di un Pokémon e identificare una sua abilita scelta dal DM.'),
      TrainerPathFeature(level: 9, title: 'Evolutionary Expert', description: 'Quando un tuo Pokémon evolve, puoi usare due suoi punti evoluzione per acquistare un talento.'),
      TrainerPathFeature(level: 15, title: 'Professor', description: 'Come azione bonus puoi identificare tutte le mosse note di un bersaglio. Inoltre indichi punti deboli: gli alleati entro 60 ft ottengono +2 ai tiri per colpire contro quel bersaglio fino alla fine del tuo prossimo turno. Usi pari a 1 + modificatore INT, recuperati con riposo lungo.'),
    ],
    'Pokémon Collector': [
      TrainerPathFeature(level: 2, title: 'Pokémon Collector', description: 'Ottieni expertise in Animal Handling, raddoppiando il bonus competenza per questa abilita.'),
      TrainerPathFeature(level: 5, title: "Gotta Catch 'Em All", description: 'Una volta per riposo lungo puoi tirare Animal Handling con vantaggio per catturare, anche se il bersaglio non ha condizioni negative.'),
      TrainerPathFeature(level: 9, title: 'Catching Expert', description: 'I Pokémon che catturi vengono guariti da condizioni e tornano a PF pieni. Aggiungi anche il modificatore CHA ai tentativi di cattura.'),
      TrainerPathFeature(level: 15, title: 'Disciplined Strikes', description: 'Quando un tuo Pokémon infliggerebbe abbastanza danni da mandare KO un Pokémon, puoi lasciarlo invece a 1 PF.'),
    ],
    'Nurse': [
      TrainerPathFeature(level: 2, title: 'Nurse', description: 'Ottieni competenza in Medicine. Dopo un riposo lungo o visita a un Pokécenter, i Pokémon con te ottengono PF temporanei pari al tuo livello.'),
      TrainerPathFeature(level: 5, title: 'Pure Heart', description: 'Ottieni una riserva di guarigione pari a livello trainer x 5. Come azione puoi toccare una creatura consenziente e spendere punti per curarla. Si ricarica con riposo lungo.'),
      TrainerPathFeature(level: 9, title: 'Healing Spirit', description: 'Quando usi consumabili curativi sui Pokémon, o un Pokémon usa una mossa curativa, tira due volte i dadi di cura e tieni il risultato migliore.'),
      TrainerPathFeature(level: 15, title: 'Joy', description: 'Una volta dopo ogni riposo lungo puoi spendere 1 ora per curare completamente fino a sei Pokémon e rimuovere tutti gli status, come in un Pokécenter.'),
    ],
    'Commander': [
      TrainerPathFeature(level: 2, title: 'Commander', description: 'La lealta dello starter diventa Loyal. Tutti i tuoi Pokémon raddoppiano i bonus ai tiri salvezza e PF provenienti da livelli di lealta positivi.'),
      TrainerPathFeature(level: 5, title: 'Follow Me', description: 'I nuovi Pokémon che catturi ottengono +1 Loyalty. La Loyalty dei tuoi Pokémon non diminuisce per aver perso una battaglia.'),
      TrainerPathFeature(level: 9, title: "Show Me What You've Got", description: 'Una volta per riposo breve, un tuo Pokémon può raddoppiare i dadi danno di una mossa oppure usare una mossa di un tier superiore disponibile nel suo stat block. Puoi decidere il raddoppio dopo aver visto tiro per colpire o tiro salvezza.'),
      TrainerPathFeature(level: 15, title: "We're a Team", description: 'Come azione bonus pronunci un comando. Fino alla fine del tuo prossimo turno, i Pokémon alleati entro 60 ft hanno vantaggio agli attacchi. Usi pari a 1 + modificatore CHA, recuperati con riposo lungo.'),
    ],
    'Type Master': [
      TrainerPathFeature(level: 2, title: 'Type Master', description: 'I Pokémon dello stesso tipo della tua specializzazione aumentano lo STAB di +1. Se in futuro hai più specializzazioni, il bonus si applica anche ai nuovi tipi; con doppio tipo e doppia specializzazione il bonus diventa +2.'),
      TrainerPathFeature(level: 5, title: 'Drawing Power', description: 'I Pokémon dei tuoi tipi specializzati aggiungono +2 ai tiri per colpire.'),
      TrainerPathFeature(level: 9, title: 'Storing Power', description: 'I Pokémon che porti con te e appartengono ai tuoi tipi specializzati ottengono resistenza a uno dei tipi della tua specializzazione, scelto quando ottieni la feature.'),
      TrainerPathFeature(level: 15, title: 'Releasing Power', description: 'I Pokémon dei tuoi tipi specializzati possono applicare lo STAB a una qualsiasi mossa dannosa a scelta, anche se la mossa non è del loro tipo.'),
    ],
    'Grunt': [
      TrainerPathFeature(level: 2, title: 'Sabotage', description: 'Ottieni Shadow Points pari al tuo livello, recuperati con riposo lungo. Come reazione puoi spendere punti per ridurre un tiro per colpire che colpisce un tuo Pokémon, potenzialmente facendolo mancare; un 20 naturale non può essere ridotto.'),
      TrainerPathFeature(level: 5, title: 'And Make It Double', description: 'Spendendo 3 Shadow Points, tu o un tuo Pokémon potete tirare con vantaggio una prova di abilita, un tiro per colpire o un tiro salvezza.'),
      TrainerPathFeature(level: 9, title: 'Surrender Now', description: 'Come reazione puoi spendere 4 Shadow Points per aumentare di un grado la resistenza di un tuo Pokémon contro una mossa che lo danneggia.'),
      TrainerPathFeature(level: 15, title: 'Prepare to Fight', description: 'Puoi spendere 5 Shadow Points per permettere a un tuo Pokémon di invocare la reazione Me First tramite Copy Meowth.'),
    ],
    'Tactician': [
      TrainerPathFeature(level: 2, title: 'Tactician', description: 'Ottieni Tactical Points pari al tuo livello, recuperati con riposo lungo. Quando un Pokémon recupera PF da item o mossa, puoi spendere punti per aumentare la cura di 1d4 per punto.'),
      TrainerPathFeature(level: 5, title: 'Directed Strike', description: 'Spendendo 2 Tactical Points, un tuo Pokémon tira due volte i danni di un attacco e tiene il risultato migliore.'),
      TrainerPathFeature(level: 9, title: 'Raise Your Defenses', description: 'Come reazione puoi spendere fino a 3 Tactical Points per aumentare la CA di un Pokémon se questo trasforma un colpo in un mancato.'),
      TrainerPathFeature(level: 15, title: 'Not This Time', description: 'Dopo che un avversario tira un TS contro una mossa di un tuo Pokémon, puoi aumentare la CD fino a 5 spendendo 1 Tactical Point per ogni punto, se questo causa il fallimento.'),
    ],
    'Ranger': [
      TrainerPathFeature(level: 2, title: 'Ranger', description: 'Ottieni competenza in Nature e Survival, o expertise se eri già competente. La velocita aumenta di 5 ft e ottieni velocita di scalata e nuoto pari alla velocita di camminata.'),
      TrainerPathFeature(level: 5, title: 'Deep Connection', description: 'Puoi lanciare Speak with Animals per comunicare con un Pokémon consenziente e comprenderne la risposta. Usi giornalieri pari a modificatore WIS o CHA, minimo 1.'),
      TrainerPathFeature(level: 9, title: 'Strong Bond', description: 'A ogni riposo lungo puoi creare un legame con fino a due Pokémon.'),
      TrainerPathFeature(level: 15, title: 'Best Friends', description: 'Puoi avere due Pokémon attivi fuori dalla Ball. In battaglia condividono comunque economia d’azione come se ci fosse un solo Pokémon attivo; se uno sviene puoi mandarne fuori un altro.'),
    ],
    'Guru': [
      TrainerPathFeature(level: 2, title: 'Guru', description: 'Ottieni competenza in Persuasion. I Pokémon non ancora controllabili restano Indifferent invece di Disloyal finché non raggiungi il Control Upgrade richiesto.'),
      TrainerPathFeature(level: 5, title: 'Mind', description: 'Tutti i tuoi Pokémon sono competenti nei tiri salvezza di Saggezza e hanno vantaggio per evitare di fallire contro confusione.'),
      TrainerPathFeature(level: 9, title: 'Body', description: 'I tuoi Pokémon hanno accesso a entrambe le abilita non nascoste, se disponibili. Tireless costa 1 ASI invece di 2; chi lo possiede già può ottenere 1 ASI.'),
      TrainerPathFeature(level: 15, title: 'Spirit', description: 'All’inizio del tuo turno puoi aggiungere il modificatore WIS ai tiri per colpire oppure ai danni del tuo Pokémon fino all’inizio del tuo prossimo turno. Usi pari a 1 + modificatore WIS, recuperati con riposo lungo.'),
    ],
    'Pokémon Breeder': [
      TrainerPathFeature(level: 2, title: 'Pokémon Breeder', description: 'Quando provi a far accoppiare due Pokémon, aggiungi il modificatore WIS al d20 della prova di successo.'),
      TrainerPathFeature(level: 5, title: 'Tender Love and Care', description: 'Hai vantaggio su tutti i tiri che riducono il contatore di incubazione delle uova Pokémon.'),
      TrainerPathFeature(level: 9, title: 'Good Genes', description: 'Ogni Pokémon nato da un uovo che fai schiudere ottiene 2 punti da aggiungere alle caratteristiche o da spendere in un talento.'),
      TrainerPathFeature(level: 15, title: 'Master of Traits', description: 'Per le uova future puoi scegliere sesso, natura e abilita disponibili del Pokémon. Se eredita almeno una Egg Move, puoi sostituirla con altre mosse dalla lista Egg Moves.'),
    ],
  };

  static Map<String, String> get trainerPathNotes => {
    for (final entry in trainerPathFeatures.entries)
      entry.key: entry.value.first.description,
  };

  static TrainerPathFeature? trainerPathFeatureFor(String path, int level) {
    final features = trainerPathFeatures[path];
    if (features == null) return null;

    for (final feature in features) {
      if (feature.level == level) {
        return feature;
      }
    }

    return null;
  }
}
