import '../localization/game_catalog_locale.dart';

class TrainerSkillDefinition {
  const TrainerSkillDefinition({required this.name, required this.ability});

  final String name;
  final String ability;
}

class TrainerManualOptions {
  const TrainerManualOptions._();

  static const List<String> fixedSkillProficiencies = ['Animal Handling'];
  static const List<String> fixedSavingThrowProficiencies = ['CHA'];
  static const List<String> savingThrows = [
    'STR',
    'DEX',
    'CON',
    'INT',
    'WIS',
    'CHA',
  ];

  static const List<String> startingPacks = [
    "Dungeoneer's pack",
    "Explorer's pack",
    "Filcher's pack",
  ];

  static const List<TrainerSkillDefinition> skills = [
    TrainerSkillDefinition(name: 'Acrobatics', ability: 'DEX'),
    TrainerSkillDefinition(name: 'Animal Handling', ability: 'WIS'),
    TrainerSkillDefinition(name: 'Arcana', ability: 'INT'),
    TrainerSkillDefinition(name: 'Athletics', ability: 'STR'),
    TrainerSkillDefinition(name: 'Deception', ability: 'CHA'),
    TrainerSkillDefinition(name: 'History', ability: 'INT'),
    TrainerSkillDefinition(name: 'Insight', ability: 'WIS'),
    TrainerSkillDefinition(name: 'Intimidation', ability: 'CHA'),
    TrainerSkillDefinition(name: 'Investigation', ability: 'INT'),
    TrainerSkillDefinition(name: 'Medicine', ability: 'WIS'),
    TrainerSkillDefinition(name: 'Nature', ability: 'INT'),
    TrainerSkillDefinition(name: 'Perception', ability: 'WIS'),
    TrainerSkillDefinition(name: 'Performance', ability: 'CHA'),
    TrainerSkillDefinition(name: 'Persuasion', ability: 'CHA'),
    TrainerSkillDefinition(name: 'Religion', ability: 'INT'),
    TrainerSkillDefinition(name: 'Sleight of Hand', ability: 'DEX'),
    TrainerSkillDefinition(name: 'Stealth', ability: 'DEX'),
    TrainerSkillDefinition(name: 'Survival', ability: 'WIS'),
  ];

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

  static const Map<String, String> specializationTypeByName = {
    'Bird Keeper': 'Volante',
    'Bug Maniac': 'Coleottero',
    'Camper': 'Terra',
    'Dragon Tamer': 'Drago',
    'Engineer': 'Elettro',
    'Martial Artist': 'Lotta',
    'Mountaineer': 'Roccia',
    'Mystic': 'Spettro',
    'Steel Worker': 'Acciaio',
    'Psychic': 'Psico',
    'Swimmer': 'Acqua',
    'Charmer': 'Folletto',
    'Shadow': 'Buio',
    'Alchemist': 'Veleno',
    'Team Player': 'Normale',
    'Ice Skater': 'Ghiaccio',
    'Pyromaniac': 'Fuoco',
    'Gardener': 'Erba',
  };

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

  static const Map<String, String> specializationNotesEn = {
    'Bird Keeper':
        'Gain proficiency in Perception. Your Flying-type Pokémon add +1 to all skill checks.',
    'Bug Maniac':
        'Gain proficiency in Nature. Your Bug-type Pokémon add +1 to all skill checks.',
    'Camper':
        'Gain proficiency in Survival. Your Ground-type Pokémon add +1 to all skill checks.',
    'Dragon Tamer':
        'Increase WIS by +1. Your Dragon-type Pokémon add +1 to all skill checks.',
    'Engineer':
        'Increase INT by +1. Your Electric-type Pokémon add +1 to all skill checks.',
    'Martial Artist':
        'Increase STR, CON, or DEX by +1. Your Fighting-type Pokémon add +1 to all skill checks.',
    'Mountaineer':
        'Increase STR, CON, or DEX by +1. Your Rock-type Pokémon add +1 to all skill checks.',
    'Mystic':
        'Gain proficiency in Arcana. Your Ghost-type Pokémon add +1 to all skill checks.',
    'Steel Worker':
        'Increase STR or CON by +1. Your Steel-type Pokémon add +1 to all skill checks.',
    'Psychic':
        'You can use Telepathy on one of your Pokémon once per day. Your Psychic-type Pokémon add +1 to all skill checks.',
    'Swimmer':
        'Gain a swim speed equal to your movement speed. Your Water-type Pokémon add +1 to all skill checks.',
    'Charmer':
        'Increase CHA by +1. Your Fairy-type Pokémon add +1 to all skill checks.',
    'Shadow':
        'Gain proficiency in Deception or Stealth. Your Dark-type Pokémon add +1 to all skill checks.',
    'Alchemist':
        'Gain proficiency in Medicine or Deception. Your Poison-type Pokémon add +1 to all skill checks.',
    'Team Player':
        'Increase one ability score by +1. Your Normal-type Pokémon add +1 to all skill checks.',
    'Ice Skater':
        'Gain proficiency in Performance or Persuasion. Your Ice-type Pokémon add +1 to all skill checks.',
    'Pyromaniac':
        'Increase CON by +1. Your Fire-type Pokémon add +1 to all skill checks.',
    'Gardener':
        'Gain proficiency in Nature. Your Grass-type Pokémon add +1 to all skill checks.',
  };

  static String specializationNote(String name) {
    if (GameCatalogLocale.isItalian) {
      return specializationNotes[name] ?? '';
    }
    return specializationNotesEn[name] ?? specializationNotes[name] ?? '';
  }
}
