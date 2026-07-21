import '../models/pokemon.dart';
import '../models/team_slot.dart';

class BattleFormChangeService {
  const BattleFormChangeService._();

  static const Set<String> supportedSpecies = {
    'Deoxys',
    'Castform',
    'Cherrim',
    'Darmanitan',
    'Meloetta',
    'Aegislash',
    'Zygarde',
    'Wishiwashi',
    'Minior',
    'Mimikyu',
    'Necrozma',
    'Cramorant',
    'Eiscue',
    'Morpeko',
    'Palafin',
    'Ogerpon',
    'Terapagos',
  };

  static bool supports(Pokemon pokemon) {
    return supportedSpecies.contains(pokemon.name);
  }

  static bool isAllowedChoice({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String formName,
  }) {
    if (!supports(pokemon)) return false;
    final key = _key(pokemon, formName);

    if (pokemon.name == 'Darmanitan') {
      final persistentKey = _key(pokemon, slot.formName);
      final isGalarian = persistentKey.contains('galar');
      return isGalarian ? key.contains('galar') : key == 'base' || key == 'zen';
    }

    return true;
  }

  static bool sameForm(Pokemon pokemon, String? first, String? second) {
    return _key(pokemon, first) == _key(pokemon, second);
  }

  static String formLabel(Pokemon pokemon, String? formName) {
    final key = _key(pokemon, formName);
    final translated = <String, String>{
      'Deoxys:base': 'Forma Normale',
      'Deoxys:attack': 'Forma Attacco',
      'Deoxys:defense': 'Forma Difesa',
      'Deoxys:speed': 'Forma Velocità',
      'Castform:base': 'Forma Normale',
      'Castform:sunny': 'Forma Sole',
      'Castform:rainy': 'Forma Pioggia',
      'Castform:snowy': 'Forma Nuvola di Neve',
      'Cherrim:base': 'Forma Nuvola',
      'Cherrim:sunshine': 'Forma Splendore',
      'Darmanitan:base': 'Stato Normale',
      'Darmanitan:zen': 'Stato Zen',
      'Darmanitan:galarian-standard': 'Forma di Galar · Stato Normale',
      'Darmanitan:galarian-zen': 'Forma di Galar · Stato Zen',
      'Meloetta:base': 'Forma Canto',
      'Meloetta:aria': 'Forma Canto',
      'Meloetta:pirouette': 'Forma Danza',
      'Aegislash:base': 'Forma Spada',
      'Aegislash:blade': 'Forma Spada',
      'Aegislash:shield': 'Forma Scudo',
      'Zygarde:10': 'Forma 10%',
      'Zygarde:base': 'Forma 50%',
      'Zygarde:50': 'Forma 50%',
      'Zygarde:complete': 'Forma Perfetta',
      'Wishiwashi:base': 'Forma Individuale',
      'Wishiwashi:solo': 'Forma Individuale',
      'Wishiwashi:school': 'Forma Banco',
      'Minior:base': 'Forma Meteora',
      'Minior:meteor': 'Forma Meteora',
      'Minior:core': 'Forma Nucleo',
      'Mimikyu:base': 'Forma Mascherata',
      'Mimikyu:disguised': 'Forma Mascherata',
      'Mimikyu:busted': 'Forma Smascherata',
      'Necrozma:base': 'Forma Normale',
      'Necrozma:dusk-mane': 'Criniera del Vespro',
      'Necrozma:dawn-wings': 'Ali dell’Aurora',
      'Necrozma:ultra': 'UltraNecrozma',
      'Cramorant:base': 'Forma Normale',
      'Cramorant:gulping': 'Forma Inghiottitutto',
      'Cramorant:gorging': 'Forma Inghiottipikachu',
      'Eiscue:base': 'Facciagelo',
      'Eiscue:ice-face': 'Facciagelo',
      'Eiscue:noice-face': 'Facciavuota',
      'Morpeko:base': 'Modalità Panciapiena',
      'Morpeko:full-belly': 'Modalità Panciapiena',
      'Morpeko:hangry': 'Modalità Panciavuota',
      'Palafin:base': 'Forma Ingenua',
      'Palafin:zero': 'Forma Ingenua',
      'Palafin:hero': 'Forma Possente',
      'Ogerpon:base': 'Maschera Turchese',
      'Ogerpon:teal-mask': 'Maschera Turchese',
      'Ogerpon:wellspring-mask': 'Maschera Pozzo',
      'Ogerpon:hearthflame-mask': 'Maschera Focolare',
      'Ogerpon:cornerstone-mask': 'Maschera Fondamenta',
      'Terapagos:base': 'Forma Normale',
      'Terapagos:normal': 'Forma Normale',
      'Terapagos:terastal': 'Forma Teracristal',
      'Terapagos:stellar': 'Forma Astrale',
    }['${pokemon.name}:$key'];
    if (translated != null) return translated;
    if (key == 'base') return 'Forma base';
    return _titleCase(key.replaceAll('-', ' '));
  }

  static String changeHint(Pokemon pokemon) {
    return const <String, String>{
          'Deoxys': 'Può cambiare forma come azione bonus grazie a Mutante.',
          'Castform': 'Adegua la forma al meteo presente sul campo.',
          'Cherrim': 'Usa la Forma Splendore sotto la luce solare intensa.',
          'Darmanitan':
              'Passa allo Stato Zen sotto metà dei PF se possiede Stato Zen.',
          'Meloetta': 'Cantoantico alterna Forma Canto e Forma Danza.',
          'Aegislash':
              'Le mosse offensive e Scudo Reale alternano le due forme.',
          'Zygarde':
              'Cambia forma quando si attivano le sue capacità di aggregazione.',
          'Wishiwashi':
              'Alterna Forma Individuale e Forma Banco secondo Banco.',
          'Minior': 'Scudosoglia espone il nucleo quando i PF scendono.',
          'Mimikyu': 'Il travestimento si rompe quando viene consumato.',
          'Necrozma': 'Gestisci fusioni e Ultraesplosione durante la lotta.',
          'Cramorant': 'Cambia forma dopo Surf o Sub.',
          'Eiscue':
              'Alterna Facciagelo e Facciavuota quando il ghiaccio si rompe o si riforma.',
          'Morpeko':
              'Alterna modalità alla fine di ogni turno con Pancialterna.',
          'Palafin':
              'Supercambio attiva la Forma Possente quando lascia il campo.',
          'Ogerpon': 'La maschera determina forma e tipo durante la lotta.',
          'Terapagos':
              'Gestisci Forma Teracristal e Forma Astrale durante la lotta.',
        }[pokemon.name] ??
        'Cambia manualmente la forma quando si verifica la relativa condizione.';
  }

  static String? effectNote(Pokemon pokemon, String? formName) {
    final key = _key(pokemon, formName);
    return <String, String>{
      'Deoxys:attack':
          'Mutante: +5 ai tiri per colpire; gli attacchi contro Deoxys hanno vantaggio.',
      'Deoxys:defense':
          'Mutante: CA +3; i suoi attacchi hanno svantaggio e i bersagli hanno vantaggio ai tiri salvezza.',
      'Deoxys:speed':
          'Mutante: ottiene un’azione di attacco aggiuntiva, effettuata con svantaggio; i bersagli hanno vantaggio ai tiri salvezza.',
      'Castform:base':
          'Tipo Normale in assenza di sole intenso, pioggia o neve.',
      'Castform:sunny': 'Tipo Fuoco durante la luce solare intensa.',
      'Castform:rainy': 'Tipo Acqua durante la pioggia.',
      'Castform:snowy': 'Tipo Ghiaccio in condizioni fredde o nevose.',
      'Darmanitan:zen':
          'Sotto metà PF: Fuoco/Psico, CA +4 e FOR/SAG scambiate.',
      'Aegislash:shield':
          'Scudo Reale: CA e DES vengono scambiate rispetto alla Forma Spada.',
      'Aegislash:base':
          'Una mossa che infligge danni riporta Aegislash alla Forma Spada.',
      'Aegislash:blade':
          'Una mossa che infligge danni riporta Aegislash alla Forma Spada.',
      'Meloetta:pirouette':
          'Cantoantico attiva la Forma Danza; tornando in panchina riassume la Forma Canto.',
      'Palafin:hero':
          'Supercambio mantiene la Forma Possente fino al termine della lotta.',
    }['${pokemon.name}:$key'];
  }

  static int armorClassBonus(Pokemon pokemon, String? formName) {
    return pokemon.name == 'Deoxys' && _key(pokemon, formName) == 'defense'
        ? 3
        : 0;
  }

  static int attackRollBonus(Pokemon pokemon, String? formName) {
    return pokemon.name == 'Deoxys' && _key(pokemon, formName) == 'attack'
        ? 5
        : 0;
  }

  static String _key(Pokemon pokemon, String? formName) {
    return Pokemon.formReferenceKey(formName ?? '', pokemon.name);
  }

  static String _titleCase(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
