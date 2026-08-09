import '../models/pokemon.dart';
import 'game_catalog_locale.dart';

/// Localizes only the visible name of a Pokémon form.
///
/// Technical identifiers and persisted form names remain unchanged. The
/// mapping intentionally covers the complete alternate-form catalog used by
/// the app so Italian UI never falls back to English labels.
class PokemonFormDisplayName {
  const PokemonFormDisplayName._();

  static String label(Pokemon pokemon, String? formName) {
    final raw = formName?.trim() ?? '';
    final key = Pokemon.formReferenceKey(raw, pokemon.name);
    if (!GameCatalogLocale.isItalian) {
      return key == 'base' || raw.isEmpty ? 'Base form' : raw;
    }

    final species = pokemon.name.trim().toLowerCase();
    final specific = _bySpecies[species];
    final normalizedKey = key.isEmpty ? 'base' : key;
    final direct = specific?[normalizedKey];
    if (direct != null) return direct;

    final regional = _regionalLabel(normalizedKey);
    if (regional != null) return regional;

    final generic = _generic[normalizedKey];
    if (generic != null) return generic;

    if (normalizedKey == 'base' || raw.isEmpty) return 'Forma base';
    return _italianizeFallback(raw);
  }

  static String? _regionalLabel(String key) {
    if (key == 'alola' || key == 'alolan') return 'Forma di Alola';
    if (key == 'galar' || key == 'galarian') return 'Forma di Galar';
    if (key == 'hisui' || key == 'hisuian') return 'Forma di Hisui';
    if (key == 'paldea' || key == 'paldean') return 'Forma di Paldea';
    if (key.contains('paldea') && key.contains('blaze')) {
      return 'Paldea · Razza Fuoco';
    }
    if (key.contains('paldea') && key.contains('aqua')) {
      return 'Paldea · Razza Acqua';
    }
    if (key.contains('paldea') && key.contains('combat')) {
      return 'Paldea · Razza Lotta';
    }
    return null;
  }

  static String _italianizeFallback(String raw) {
    var value = raw.trim();
    const replacements = <String, String>{
      ' Forme': '',
      ' Form': '',
      ' form': '',
      ' Style': '',
      ' Mode': '',
      ' Cloak': '',
      ' Mask': '',
      ' Pattern': '',
      ' Trim': '',
      ' Flower': '',
      ' Plumage': '',
      ' Breed': '',
      ' Face': '',
      ' Core': '',
      ' Sea': '',
      ' Rider': '',
      ' Segment': '',
    };
    for (final entry in replacements.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }
    return value.isEmpty ? 'Forma base' : value;
  }

  static const Map<String, String> _generic = {
    'male': 'Maschio',
    'female': 'Femmina',
    'attack': 'Forma Attacco',
    'defense': 'Forma Difesa',
    'speed': 'Forma Velocità',
    'sunny': 'Forma Sole',
    'rainy': 'Forma Pioggia',
    'snowy': 'Forma Neve',
    'altered': 'Forma Alterata',
    'origin': 'Forma Origine',
    'confined': 'Forma Vincolata',
    'unbound': 'Forma Libera',
    'black': 'Forma Nera',
    'white': 'Forma Bianca',
    'land': 'Forma Terra',
    'sky': 'Forma Cielo',
    'aria': 'Forma Canto',
    'pirouette': 'Forma Danza',
    'solo': 'Forma Individuale',
    'school': 'Forma Banco',
    'midday': 'Forma Giorno',
    'midnight': 'Forma Notte',
    'dusk': 'Forma Crepuscolo',
    'meteor': 'Forma Meteora',
    'complete': 'Forma Perfetta',
    'shield': 'Forma Scudo',
    'blade': 'Forma Spada',
    'incarnate': 'Forma Incarnazione',
    'therian': 'Forma Totem',
    'ordinary': 'Forma Ordinaria',
    'resolute': 'Forma Risoluta',
    'disguised': 'Forma Mascherata',
    'busted': 'Forma Smascherata',
    'ice-face': 'Forma Gelofaccia',
    'noice-face': 'Forma Liquefaccia',
    'full-belly': 'Motivo Panciapiena',
    'hangry': 'Motivo Panciavuota',
    'zero': 'Forma Ingenua',
    'hero': 'Forma Possente',
    'normal': 'Forma Normale',
    'terastal': 'Forma Teracristal',
    'stellar': 'Forma Astrale',
  };

  static const Map<String, Map<String, String>> _bySpecies = {
    'pumpkaboo': {
      'base': 'Taglia Media',
      'small': 'Taglia Piccola',
      'average': 'Taglia Media',
      'large': 'Taglia Grande',
      'supersize': 'Taglia Maxi',
    },
    'gourgeist': {
      'base': 'Taglia Media',
      'small': 'Taglia Piccola',
      'average': 'Taglia Media',
      'large': 'Taglia Grande',
      'supersize': 'Taglia Maxi',
    },
    'rotom': {
      'base': 'Forma Normale',
      'heat': 'Forma Calore',
      'wash': 'Forma Lavaggio',
      'frost': 'Forma Gelo',
      'fan': 'Forma Vortice',
      'mow': 'Forma Taglio',
    },
    'castform': {
      'base': 'Forma Normale',
      'sunny': 'Forma Sole',
      'rainy': 'Forma Pioggia',
      'snowy': 'Forma Neve',
    },
    'giratina': {'base': 'Forma Alterata', 'altered': 'Forma Alterata', 'origin': 'Forma Origine'},
    'hoopa': {'base': 'Forma Vincolata', 'confined': 'Forma Vincolata', 'unbound': 'Forma Libera'},
    'burmy': {
      'base': 'Manto Pianta',
      'plant-cloak': 'Manto Pianta',
      'sandy-cloak': 'Manto Sabbia',
      'trash-cloak': 'Manto Scarti',
    },
    'wormadam': {
      'base': 'Manto Pianta',
      'plant-cloak': 'Manto Pianta',
      'sandy-cloak': 'Manto Sabbia',
      'trash-cloak': 'Manto Scarti',
    },
    'zygarde': {'base': 'Forma 50%', '10': 'Forma 10%', '50': 'Forma 50%', 'complete': 'Forma Perfetta'},
    'kyurem': {'base': 'Kyurem', 'black': 'Kyurem Nero', 'white': 'Kyurem Bianco'},
    'shaymin': {'base': 'Forma Terra', 'land': 'Forma Terra', 'sky': 'Forma Cielo'},
    'meloetta': {'base': 'Forma Canto', 'aria': 'Forma Canto', 'pirouette': 'Forma Danza'},
    'wishiwashi': {'base': 'Forma Individuale', 'solo': 'Forma Individuale', 'school': 'Forma Banco'},
    'oricorio': {
      'base': 'Stile Flamenco',
      'baile': 'Stile Flamenco',
      'baile-style': 'Stile Flamenco',
      'pom-pom': 'Stile Cheerdance',
      'pom-pom-style': 'Stile Cheerdance',
      'pau': 'Stile Hula',
      'pau-style': 'Stile Hula',
      'sensu': 'Stile Buyō',
      'sensu-style': 'Stile Buyō',
    },
    'lycanroc': {'base': 'Forma Giorno', 'midday': 'Forma Giorno', 'midnight': 'Forma Notte', 'dusk': 'Forma Crepuscolo'},
    'minior': {
      'base': 'Forma Meteora',
      'meteor': 'Forma Meteora',
      'core': 'Forma Nucleo',
      'core-red': 'Nucleo Rosso',
      'core-orange': 'Nucleo Arancione',
      'core-yellow': 'Nucleo Giallo',
      'core-green': 'Nucleo Verde',
      'core-blue': 'Nucleo Azzurro',
      'core-indigo': 'Nucleo Indaco',
      'core-violet': 'Nucleo Violetto',
    },
    'necrozma': {
      'base': 'Forma Normale',
      'dusk-mane': 'Criniera del Vespro',
      'dawn-wings': 'Ali dell’Aurora',
      'ultra': 'Ultra Necrozma',
    },
    'deoxys': {'base': 'Forma Normale', 'normal': 'Forma Normale', 'attack': 'Forma Attacco', 'defense': 'Forma Difesa', 'speed': 'Forma Velocità'},
    'cherrim': {'base': 'Forma Nuvola', 'overcast': 'Forma Nuvola', 'sunshine': 'Forma Splendore'},
    'shellos': {'base': 'Mare Ovest', 'west-sea': 'Mare Ovest', 'east-sea': 'Mare Est'},
    'gastrodon': {'base': 'Mare Ovest', 'west-sea': 'Mare Ovest', 'east-sea': 'Mare Est'},
    'dialga': {'base': 'Forma Alterata', 'altered': 'Forma Alterata', 'origin': 'Forma Origine'},
    'palkia': {'base': 'Forma Alterata', 'altered': 'Forma Alterata', 'origin': 'Forma Origine'},
    'basculin': {
      'base': 'Forma Linearossa',
      'red-striped': 'Forma Linearossa',
      'blue-striped': 'Forma Lineablu',
      'white-striped': 'Forma Lineabianca',
    },
    'darmanitan': {
      'base': 'Stato Normale',
      'standard': 'Stato Normale',
      'zen': 'Stato Zen',
      'galarian-standard': 'Forma di Galar · Stato Normale',
      'galarian-zen': 'Forma di Galar · Stato Zen',
    },
    'deerling': {'base': 'Forma Primavera', 'spring': 'Forma Primavera', 'summer': 'Forma Estate', 'autumn': 'Forma Autunno', 'winter': 'Forma Inverno'},
    'sawsbuck': {'base': 'Forma Primavera', 'spring': 'Forma Primavera', 'summer': 'Forma Estate', 'autumn': 'Forma Autunno', 'winter': 'Forma Inverno'},
    'tornadus': {'base': 'Forma Incarnazione', 'incarnate': 'Forma Incarnazione', 'therian': 'Forma Totem'},
    'thundurus': {'base': 'Forma Incarnazione', 'incarnate': 'Forma Incarnazione', 'therian': 'Forma Totem'},
    'landorus': {'base': 'Forma Incarnazione', 'incarnate': 'Forma Incarnazione', 'therian': 'Forma Totem'},
    'enamorus': {'base': 'Forma Incarnazione', 'incarnate': 'Forma Incarnazione', 'therian': 'Forma Totem'},
    'keldeo': {'base': 'Forma Ordinaria', 'ordinary': 'Forma Ordinaria', 'resolute': 'Forma Risoluta'},
    'vivillon': {
      'base': 'Motivo Prato',
      'meadow-pattern': 'Motivo Prato',
      'archipelago-pattern': 'Motivo Arcipelago',
      'continental-pattern': 'Motivo Continentale',
      'elegant-pattern': 'Motivo Elegante',
      'garden-pattern': 'Motivo Giardino',
      'high-plains-pattern': 'Motivo Altopiano',
      'icy-snow-pattern': 'Motivo Neve Gelida',
      'jungle-pattern': 'Motivo Giungla',
      'marine-pattern': 'Motivo Marino',
      'modern-pattern': 'Motivo Moderno',
      'monsoon-pattern': 'Motivo Monsone',
      'ocean-pattern': 'Motivo Oceano',
      'polar-pattern': 'Motivo Polare',
      'river-pattern': 'Motivo Fiume',
      'sandstorm-pattern': 'Motivo Tempesta di Sabbia',
      'savanna-pattern': 'Motivo Savana',
      'sun-pattern': 'Motivo Sole',
      'tundra-pattern': 'Motivo Tundra',
      'fancy-pattern': 'Motivo Sbarazzino',
      'poke-ball-pattern': 'Motivo Poké Ball',
    },
    'flabebe': {'base': 'Fiore Rosso', 'red-flower': 'Fiore Rosso', 'yellow-flower': 'Fiore Giallo', 'orange-flower': 'Fiore Arancione', 'blue-flower': 'Fiore Blu', 'white-flower': 'Fiore Bianco'},
    'floette': {'base': 'Fiore Rosso', 'red-flower': 'Fiore Rosso', 'yellow-flower': 'Fiore Giallo', 'orange-flower': 'Fiore Arancione', 'blue-flower': 'Fiore Blu', 'white-flower': 'Fiore Bianco'},
    'florges': {'base': 'Fiore Rosso', 'red-flower': 'Fiore Rosso', 'yellow-flower': 'Fiore Giallo', 'orange-flower': 'Fiore Arancione', 'blue-flower': 'Fiore Blu', 'white-flower': 'Fiore Bianco'},
    'furfrou': {
      'base': 'Forma Naturale',
      'natural': 'Forma Naturale',
      'heart-trim': 'Taglio Cuore',
      'star-trim': 'Taglio Stella',
      'diamond-trim': 'Taglio Rombo',
      'debutante-trim': 'Taglio Signorina',
      'matron-trim': 'Taglio Matrona',
      'dandy-trim': 'Taglio Gentiluomo',
      'la-reine-trim': 'Taglio Regina',
      'kabuki-trim': 'Taglio Kabuki',
      'pharaoh-trim': 'Taglio Faraone',
    },
    'aegislash': {'base': 'Forma Scudo', 'shield': 'Forma Scudo', 'blade': 'Forma Spada'},
    'xerneas': {'base': 'Modalità Quiete', 'neutral': 'Modalità Quiete', 'active': 'Modalità Attiva'},
    'mimikyu': {'base': 'Forma Mascherata', 'disguised': 'Forma Mascherata', 'busted': 'Forma Smascherata'},
    'magearna': {'base': 'Forma Normale', 'original-color': 'Colore Originale'},
    'cramorant': {'base': 'Forma Normale', 'gulping': 'Forma Ingurgito', 'gorging': 'Forma Inghiottito'},
    'toxtricity': {'base': 'Forma Melodia', 'amped': 'Forma Melodia', 'low-key': 'Forma Basso'},
    'sinistea': {'base': 'Forma Contraffatta', 'phony': 'Forma Contraffatta', 'antique': 'Forma Autentica'},
    'polteageist': {'base': 'Forma Contraffatta', 'phony': 'Forma Contraffatta', 'antique': 'Forma Autentica'},
    'eiscue': {'base': 'Forma Gelofaccia', 'ice-face': 'Forma Gelofaccia', 'noice-face': 'Forma Liquefaccia'},
    'morpeko': {'base': 'Motivo Panciapiena', 'full-belly': 'Motivo Panciapiena', 'hangry': 'Motivo Panciavuota'},
    'zacian': {'base': 'Eroe di Mille Lotte', 'hero-of-many-battles': 'Eroe di Mille Lotte', 'crowned-sword': 'Re delle Spade'},
    'zamazenta': {'base': 'Eroe di Mille Lotte', 'hero-of-many-battles': 'Eroe di Mille Lotte', 'crowned-shield': 'Re degli Scudi'},
    'eternatus': {'base': 'Forma Normale', 'eternamax': 'Eternatus Dynamax Infinito'},
    'urshifu': {'base': 'Stile Singolcolpo', 'single': 'Stile Singolcolpo', 'single-strike': 'Stile Singolcolpo', 'rapid': 'Stile Pluricolpo', 'rapid-strike': 'Stile Pluricolpo'},
    'zarude': {'base': 'Forma Normale', 'dada': 'Forma Dada'},
    'calyrex': {'base': 'Calyrex', 'ice-rider': 'Calyrex Cavaliere Glaciale', 'shadow-rider': 'Calyrex Cavaliere Spettrale'},
    'maushold': {'base': 'Famiglia di Quattro', 'family-of-four': 'Famiglia di Quattro', 'family-of-three': 'Famiglia di Tre'},
    'squawkabilly': {'base': 'Piumaggio Verde', 'green-plumage': 'Piumaggio Verde', 'blue-plumage': 'Piumaggio Blu', 'yellow-plumage': 'Piumaggio Giallo', 'white-plumage': 'Piumaggio Bianco'},
    'palafin': {'base': 'Forma Ingenua', 'zero': 'Forma Ingenua', 'hero': 'Forma Possente'},
    'tatsugiri': {'base': 'Forma Arcuata', 'curly': 'Forma Arcuata', 'droopy': 'Forma Adagiata', 'stretchy': 'Forma Tesa'},
    'dudunsparce': {'base': 'Forma Bimetamero', 'two-segment': 'Forma Bimetamero', 'three-segment': 'Forma Trimetamero'},
    'gimmighoul': {'base': 'Scrigno', 'chest': 'Scrigno', 'roaming': 'Ambulante'},
    'tauros': {
      'paldea-combat-breed': 'Paldea · Razza Lotta',
      'paldea-blaze-breed': 'Paldea · Razza Fuoco',
      'paldea-aqua-breed': 'Paldea · Razza Acqua',
    },
    'ogerpon': {'base': 'Maschera Turchese', 'teal-mask': 'Maschera Turchese', 'wellspring-mask': 'Maschera Pozzo', 'hearthflame-mask': 'Maschera Focolare', 'cornerstone-mask': 'Maschera Fondamenta'},
    'terapagos': {'base': 'Forma Normale', 'normal': 'Forma Normale', 'terastal': 'Forma Teracristal', 'stellar': 'Forma Astrale'},
  };
}
