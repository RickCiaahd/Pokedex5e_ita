import 'dart:math' as math;

import '../models/pokemon.dart';
import '../models/team_slot.dart';

class BattleFormChangeService {
  const BattleFormChangeService._();

  static const Set<String> _supportedSpecies = {
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
    return _supportedSpecies.contains(pokemon.name);
  }

  static String canonicalFormKey(Pokemon pokemon, String? formName) {
    final raw = Pokemon.formReferenceKey(
      formName?.trim().isNotEmpty == true ? formName! : 'Base',
      pokemon.name,
    );

    switch (pokemon.name) {
      case 'Deoxys':
        if (raw == 'base' || raw == 'normal') return 'normal';
        return raw;
      case 'Castform':
        if (raw == 'base' || raw == 'normal') return 'normal';
        return raw;
      case 'Cherrim':
        if (raw == 'base' || raw == 'overcast') return 'overcast';
        return raw;
      case 'Darmanitan':
        if (raw.contains('galar')) {
          return raw.contains('zen')
              ? 'galarian-zen'
              : 'galarian-standard';
        }
        if (raw == 'base' || raw.contains('standard')) return 'standard';
        if (raw.contains('zen')) return 'zen';
        return raw;
      case 'Meloetta':
        if (raw == 'base' || raw == 'aria') return 'aria';
        return raw;
      case 'Aegislash':
        if (raw == 'base' || raw == 'blade') return 'blade';
        return raw;
      case 'Zygarde':
        if (raw == 'base' || raw == '50') return '50';
        return raw;
      case 'Wishiwashi':
        if (raw == 'base' || raw == 'solo') return 'solo';
        return raw;
      case 'Minior':
        if (raw == 'base' || raw == 'meteor') return 'meteor';
        return raw;
      case 'Mimikyu':
        if (raw == 'base' || raw == 'disguised') return 'disguised';
        return raw;
      case 'Necrozma':
        if (raw == 'base' || raw == 'normal') return 'normal';
        return raw;
      case 'Cramorant':
        if (raw == 'base' || raw == 'normal') return 'normal';
        return raw;
      case 'Eiscue':
        if (raw == 'base' || raw == 'ice-face') return 'ice-face';
        return raw;
      case 'Morpeko':
        if (raw == 'base' || raw == 'full-belly') return 'full-belly';
        return raw;
      case 'Palafin':
        if (raw == 'base' || raw == 'zero') return 'zero';
        return raw;
      case 'Ogerpon':
        if (raw == 'base' || raw == 'teal-mask') return 'teal-mask';
        return raw;
      case 'Terapagos':
        if (raw == 'base' || raw == 'normal') return 'normal';
        return raw;
      default:
        return raw;
    }
  }

  static String normalizedChoiceName(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    return key == _defaultFormKey(pokemon) ? 'Base' : key;
  }

  static int formSortWeight(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    late final List<String> order;
    switch (pokemon.name) {
      case 'Deoxys':
        order = const ['normal', 'attack', 'defense', 'speed'];
        break;
      case 'Castform':
        order = const ['normal', 'sunny', 'rainy', 'snowy'];
        break;
      case 'Cherrim':
        order = const ['overcast', 'sunshine'];
        break;
      case 'Darmanitan':
        order = const [
          'standard',
          'zen',
          'galarian-standard',
          'galarian-zen',
        ];
        break;
      case 'Meloetta':
        order = const ['aria', 'pirouette'];
        break;
      case 'Aegislash':
        order = const ['blade', 'shield'];
        break;
      case 'Zygarde':
        order = const ['10', '50', 'complete'];
        break;
      case 'Wishiwashi':
        order = const ['solo', 'school'];
        break;
      case 'Minior':
        order = const ['meteor', 'core'];
        break;
      case 'Mimikyu':
        order = const ['disguised', 'busted'];
        break;
      case 'Necrozma':
        order = const ['normal', 'dusk-mane', 'dawn-wings', 'ultra'];
        break;
      case 'Cramorant':
        order = const ['normal', 'gulping', 'gorging'];
        break;
      case 'Eiscue':
        order = const ['ice-face', 'noice-face'];
        break;
      case 'Morpeko':
        order = const ['full-belly', 'hangry'];
        break;
      case 'Palafin':
        order = const ['zero', 'hero'];
        break;
      case 'Ogerpon':
        order = const [
          'teal-mask',
          'wellspring-mask',
          'hearthflame-mask',
          'cornerstone-mask',
        ];
        break;
      case 'Terapagos':
        order = const ['normal', 'terastal', 'stellar'];
        break;
      default:
        order = const [];
        break;
    }
    final index = order.indexOf(key);
    return index < 0 ? 100 : index;
  }

  static bool isAllowedChoice({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String formName,
  }) {
    if (pokemon.name != 'Darmanitan') return true;

    final persistentKey = canonicalFormKey(pokemon, slot.formName);
    final choiceKey = canonicalFormKey(pokemon, formName);
    final isGalarian = persistentKey.startsWith('galarian-');
    if (isGalarian) {
      return choiceKey == 'galarian-standard' ||
          choiceKey == 'galarian-zen';
    }
    return choiceKey == 'standard' || choiceKey == 'zen';
  }

  static bool sameForm(
    Pokemon pokemon,
    String? current,
    String candidate,
  ) {
    return canonicalFormKey(pokemon, current) ==
        canonicalFormKey(pokemon, candidate);
  }

  static String formLabel(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    switch (pokemon.name) {
      case 'Deoxys':
        return switch (key) {
          'attack' => 'Forma Attacco',
          'defense' => 'Forma Difesa',
          'speed' => 'Forma Velocità',
          _ => 'Forma Normale',
        };
      case 'Castform':
        return switch (key) {
          'sunny' => 'Forma Sole',
          'rainy' => 'Forma Pioggia',
          'snowy' => 'Forma Neve',
          _ => 'Forma Normale',
        };
      case 'Cherrim':
        return key == 'sunshine' ? 'Forma Splendore' : 'Forma Nuvola';
      case 'Darmanitan':
        return switch (key) {
          'zen' => 'Stato Zen',
          'galarian-standard' => 'Forma di Galar · Stato Normale',
          'galarian-zen' => 'Forma di Galar · Stato Zen',
          _ => 'Stato Normale',
        };
      case 'Meloetta':
        return key == 'pirouette' ? 'Forma Danza' : 'Forma Canto';
      case 'Aegislash':
        return key == 'shield' ? 'Forma Scudo' : 'Forma Spada';
      case 'Zygarde':
        return switch (key) {
          '10' => 'Forma 10%',
          'complete' => 'Forma Perfetta',
          _ => 'Forma 50%',
        };
      case 'Wishiwashi':
        return key == 'school' ? 'Forma Banco' : 'Forma Individuale';
      case 'Minior':
        return key == 'core' ? 'Forma Nucleo' : 'Forma Meteora';
      case 'Mimikyu':
        return key == 'busted'
            ? 'Forma Smascherata'
            : 'Forma Mascherata';
      case 'Necrozma':
        return switch (key) {
          'dusk-mane' => 'Criniera del Vespro',
          'dawn-wings' => 'Ali dell’Aurora',
          'ultra' => 'UltraNecrozma',
          _ => 'Forma Normale',
        };
      case 'Cramorant':
        return switch (key) {
          'gulping' => 'Forma Inghiottitutto',
          'gorging' => 'Forma Ingozzata',
          _ => 'Forma Normale',
        };
      case 'Eiscue':
        return key == 'noice-face' ? 'Faccia Liquida' : 'Faccia Gelata';
      case 'Morpeko':
        return key == 'hangry'
            ? 'Motivo Pancia Vuota'
            : 'Motivo Panciapiena';
      case 'Palafin':
        return key == 'hero' ? 'Forma Possente' : 'Forma Ingenua';
      case 'Ogerpon':
        return switch (key) {
          'wellspring-mask' => 'Maschera Pozzo',
          'hearthflame-mask' => 'Maschera Focolare',
          'cornerstone-mask' => 'Maschera Fondamenta',
          _ => 'Maschera Turchese',
        };
      case 'Terapagos':
        return switch (key) {
          'terastal' => 'Forma Teracristal',
          'stellar' => 'Forma Astrale',
          _ => 'Forma Normale',
        };
      default:
        return formName?.trim().isNotEmpty == true ? formName! : 'Forma';
    }
  }

  static String changeHint(Pokemon pokemon) {
    switch (pokemon.name) {
      case 'Darmanitan':
        return 'Lo Stato Zen si attiva sotto la metà dei PF se il Pokémon possiede l’abilità Modalità Zen.';
      case 'Aegislash':
        return 'Accendilotta alterna Forma Spada e Forma Scudo in base alla mossa usata.';
      case 'Zygarde':
        return 'La Forma 50% è quella predefinita; usa le altre forme quando la situazione di gioco lo richiede.';
      case 'Mimikyu':
        return 'Fantasmanto mantiene la Forma Mascherata finché i suoi PF temporanei non vengono esauriti.';
      case 'Palafin':
        return 'Supercambio consente di assumere la Forma Possente; al termine della lotta torna alla Forma Ingenua.';
      default:
        return 'Il cambio forma vale soltanto per la battaglia corrente.';
    }
  }

  static int armorClassBonus(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Deoxys' && key == 'defense') return 3;
    if (pokemon.name == 'Palafin' && key == 'hero') return 4;
    return 0;
  }

  static int attackRollBonus(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Deoxys' && key == 'attack') return 5;
    return 0;
  }

  static Map<String, int> applyAttributeScoreModifiers(
    Pokemon pokemon,
    String? formName,
    Map<String, int> scores,
  ) {
    final result = Map<String, int>.from(scores);
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Palafin' && key == 'hero') {
      result['STR'] = math.min(22, (result['STR'] ?? 10) + 4);
      result['DEX'] = math.min(22, (result['DEX'] ?? 10) + 4);
    }
    return result;
  }

  static String? effectNote(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Deoxys') {
      return switch (key) {
        'attack' => 'Mutante: +5 ai tiri per colpire.',
        'defense' => 'Mutante: +3 alla CA.',
        'speed' => 'Mutante: velocità raddoppiata.',
        _ => 'Forma equilibrata, senza bonus di Mutante.',
      };
    }
    if (pokemon.name == 'Aegislash' && key == 'shield') {
      return 'Accendilotta: CA 20 e DES 15 al posto dei valori della Forma Spada.';
    }
    if (pokemon.name == 'Zygarde') {
      return switch (key) {
        '10' => 'CA 16; FOR 16, DES 19, COS 15, INT 14, SAG 14, CAR 14.',
        'complete' =>
          'CA 20; FOR 19, DES 17, COS 30, INT 18, SAG 18, CAR 18.',
        _ => 'CA 18; FOR 19, DES 18, COS 20, INT 16, SAG 16, CAR 16.',
      };
    }
    if (pokemon.name == 'Darmanitan') {
      return switch (key) {
        'zen' => 'Tipo Fuoco/Psico, CA 18; FOR e SAG vengono scambiate.',
        'galarian-zen' => 'Tipo Ghiaccio/Fuoco; FOR e DES aumentano di 2.',
        _ => null,
      };
    }
    if (pokemon.name == 'Mimikyu' && key == 'busted') {
      return 'Fantasmanto è spezzato e non concede più PF temporanei.';
    }
    if (pokemon.name == 'Palafin' && key == 'hero') {
      return 'Supercambio: +4 CA, +4 FOR e +4 DES (massimo 22) fino alla fine della lotta.';
    }
    return null;
  }

  static String _defaultFormKey(Pokemon pokemon) {
    return switch (pokemon.name) {
      'Deoxys' => 'normal',
      'Castform' => 'normal',
      'Cherrim' => 'overcast',
      'Darmanitan' => 'standard',
      'Meloetta' => 'aria',
      'Aegislash' => 'blade',
      'Zygarde' => '50',
      'Wishiwashi' => 'solo',
      'Minior' => 'meteor',
      'Mimikyu' => 'disguised',
      'Necrozma' => 'normal',
      'Cramorant' => 'normal',
      'Eiscue' => 'ice-face',
      'Morpeko' => 'full-belly',
      'Palafin' => 'zero',
      'Ogerpon' => 'teal-mask',
      'Terapagos' => 'normal',
      _ => 'base',
    };
  }
}
