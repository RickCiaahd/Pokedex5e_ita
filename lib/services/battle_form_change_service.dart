import 'dart:math' as math;

import '../localization/ui_text.dart';
import '../models/pokemon.dart';
import '../models/team_slot.dart';
import 'custom_pokemon_runtime_registry.dart';

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
    return _supportedSpecies.contains(pokemon.name) ||
        CustomPokemonRuntimeRegistry.hasTemporaryForms(pokemon.id);
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
          return raw.contains('zen') ? 'galarian-zen' : 'galarian-standard';
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
        if (raw == 'base' || raw == 'meteor' || raw == 'meteor-form') {
          return 'meteor';
        }
        if (raw == 'core' || raw == 'core-form') return 'core-red';
        if (raw.startsWith('core-')) return raw;
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
    if (key == _defaultFormKey(pokemon)) return 'Base';
    if (pokemon.name == 'Darmanitan') {
      if (key == 'galarian-standard') return 'galar-standard';
      if (key == 'galarian-zen') return 'galar-zen';
    }
    return key;
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
        order = const ['standard', 'zen', 'galarian-standard', 'galarian-zen'];
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
        order = const [
          'meteor',
          'core-red',
          'core-orange',
          'core-yellow',
          'core-green',
          'core-blue',
          'core-indigo',
          'core-violet',
        ];
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
      return choiceKey == 'galarian-standard' || choiceKey == 'galarian-zen';
    }
    return choiceKey == 'standard' || choiceKey == 'zen';
  }

  static bool sameForm(Pokemon pokemon, String? current, String candidate) {
    return canonicalFormKey(pokemon, current) ==
        canonicalFormKey(pokemon, candidate);
  }

  static String formLabel(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    switch (pokemon.name) {
      case 'Deoxys':
        return switch (key) {
          'attack' => uiTextForLanguage('Forma Attacco', 'Attack Form'),
          'defense' => uiTextForLanguage('Forma Difesa', 'Defense Form'),
          'speed' => uiTextForLanguage('Forma Velocità', 'Speed Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Castform':
        return switch (key) {
          'sunny' => uiTextForLanguage('Forma Sole', 'Sunny Form'),
          'rainy' => uiTextForLanguage('Forma Pioggia', 'Rainy Form'),
          'snowy' => uiTextForLanguage('Forma Neve', 'Snowy Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Cherrim':
        return key == 'sunshine'
            ? uiTextForLanguage('Forma Splendore', 'Sunshine Form')
            : uiTextForLanguage('Forma Nuvola', 'Overcast Form');
      case 'Darmanitan':
        return switch (key) {
          'zen' => uiTextForLanguage('Stato Zen', 'Zen Mode'),
          'galarian-standard' => uiTextForLanguage(
            'Forma di Galar · Stato Normale',
            'Galarian Form · Standard Mode',
          ),
          'galarian-zen' => uiTextForLanguage(
            'Forma di Galar · Stato Zen',
            'Galarian Form · Zen Mode',
          ),
          _ => uiTextForLanguage('Stato Normale', 'Standard Mode'),
        };
      case 'Meloetta':
        return key == 'pirouette'
            ? uiTextForLanguage('Forma Danza', 'Pirouette Form')
            : uiTextForLanguage('Forma Canto', 'Aria Form');
      case 'Aegislash':
        return key == 'shield'
            ? uiTextForLanguage('Forma Scudo', 'Shield Form')
            : uiTextForLanguage('Forma Spada', 'Blade Form');
      case 'Zygarde':
        return switch (key) {
          '10' => uiTextForLanguage('Forma 10%', '10% Form'),
          'complete' => uiTextForLanguage('Forma Perfetta', 'Complete Form'),
          _ => uiTextForLanguage('Forma 50%', '50% Form'),
        };
      case 'Wishiwashi':
        return key == 'school'
            ? uiTextForLanguage('Forma Banco', 'School Form')
            : uiTextForLanguage('Forma Individuale', 'Solo Form');
      case 'Minior':
        return switch (key) {
          'core-red' => uiTextForLanguage('Nucleo Rosso', 'Red Core'),
          'core-orange' => uiTextForLanguage('Nucleo Arancione', 'Orange Core'),
          'core-yellow' => uiTextForLanguage('Nucleo Giallo', 'Yellow Core'),
          'core-green' => uiTextForLanguage('Nucleo Verde', 'Green Core'),
          'core-blue' => uiTextForLanguage('Nucleo Azzurro', 'Blue Core'),
          'core-indigo' => uiTextForLanguage('Nucleo Indaco', 'Indigo Core'),
          'core-violet' => uiTextForLanguage('Nucleo Violetto', 'Violet Core'),
          _ => uiTextForLanguage('Forma Meteora', 'Meteor Form'),
        };
      case 'Mimikyu':
        return key == 'busted'
            ? uiTextForLanguage('Forma Smascherata', 'Busted Form')
            : uiTextForLanguage('Forma Mascherata', 'Disguised Form');
      case 'Necrozma':
        return switch (key) {
          'dusk-mane' => uiTextForLanguage('Criniera del Vespro', 'Dusk Mane'),
          'dawn-wings' => uiTextForLanguage('Ali dell’Aurora', 'Dawn Wings'),
          'ultra' => 'Ultra Necrozma',
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Cramorant':
        return switch (key) {
          'gulping' => uiTextForLanguage(
            'Forma Inghiottitutto',
            'Gulping Form',
          ),
          'gorging' => uiTextForLanguage('Forma Ingozzata', 'Gorging Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      case 'Eiscue':
        return key == 'noice-face'
            ? uiTextForLanguage('Forma Liquefaccia', 'Noice Face')
            : uiTextForLanguage('Forma Gelofaccia', 'Ice Face');
      case 'Morpeko':
        return key == 'hangry'
            ? uiTextForLanguage('Motivo Panciavuota', 'Hangry Mode')
            : uiTextForLanguage('Motivo Panciapiena', 'Full Belly Mode');
      case 'Palafin':
        return key == 'hero'
            ? uiTextForLanguage('Forma Possente', 'Hero Form')
            : uiTextForLanguage('Forma Ingenua', 'Zero Form');
      case 'Ogerpon':
        return switch (key) {
          'wellspring-mask' => uiTextForLanguage(
            'Maschera Pozzo',
            'Wellspring Mask',
          ),
          'hearthflame-mask' => uiTextForLanguage(
            'Maschera Focolare',
            'Hearthflame Mask',
          ),
          'cornerstone-mask' => uiTextForLanguage(
            'Maschera Fondamenta',
            'Cornerstone Mask',
          ),
          _ => uiTextForLanguage('Maschera Turchese', 'Teal Mask'),
        };
      case 'Terapagos':
        return switch (key) {
          'terastal' => uiTextForLanguage('Forma Teracristal', 'Terastal Form'),
          'stellar' => uiTextForLanguage('Forma Astrale', 'Stellar Form'),
          _ => uiTextForLanguage('Forma Normale', 'Normal Form'),
        };
      default:
        return formName?.trim().isNotEmpty == true
            ? formName!
            : uiTextForLanguage('Forma', 'Form');
    }
  }

  static String changeHint(Pokemon pokemon) {
    switch (pokemon.name) {
      case 'Darmanitan':
        return uiTextForLanguage(
          'Lo Stato Zen si attiva sotto la metà dei PF se il Pokémon possiede l’abilità Stato Zen.',
          'Zen Mode activates below half HP if the Pokémon has the Zen Mode ability.',
        );
      case 'Aegislash':
        return uiTextForLanguage(
          'Accendilotta alterna Forma Spada e Forma Scudo in base alla mossa usata.',
          'Stance Change alternates Blade Form and Shield Form based on the move used.',
        );
      case 'Zygarde':
        return uiTextForLanguage(
          'La Forma 50% è quella predefinita; usa le altre forme quando la situazione di gioco lo richiede.',
          '50% Form is the default; use the other forms when the game situation requires them.',
        );
      case 'Minior':
        return uiTextForLanguage(
          'Scudi Giù alterna la Forma Meteora e il Nucleo; il colore del Nucleo è soltanto estetico.',
          'Shields Down alternates Meteor Form and Core; the Core color is cosmetic only.',
        );
      case 'Mimikyu':
        return uiTextForLanguage(
          'Fantasmanto mantiene la Forma Mascherata finché i suoi PF temporanei non vengono esauriti.',
          'Disguise keeps Disguised Form until its temporary HP are depleted.',
        );
      case 'Palafin':
        return uiTextForLanguage(
          'Supercambio consente di assumere la Forma Possente; al termine della lotta torna alla Forma Ingenua.',
          'Zero to Hero allows Hero Form; at the end of the battle it returns to Zero Form.',
        );
      default:
        return uiTextForLanguage(
          'Il cambio forma vale soltanto per la battaglia corrente.',
          'The form change applies only to the current battle.',
        );
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
        'attack' => uiTextForLanguage(
          'Mutante: +5 ai tiri per colpire.',
          'Mutant: +5 to attack rolls.',
        ),
        'defense' => uiTextForLanguage(
          'Mutante: +3 alla CA.',
          'Mutant: +3 AC.',
        ),
        'speed' => uiTextForLanguage(
          'Mutante: velocità raddoppiata.',
          'Mutant: Speed is doubled.',
        ),
        _ => uiTextForLanguage(
          'Forma equilibrata, senza bonus di Mutante.',
          'Balanced form, with no Mutant bonus.',
        ),
      };
    }
    if (pokemon.name == 'Aegislash' && key == 'shield') {
      return uiTextForLanguage(
        'Accendilotta: CA 20 e DES 15 al posto dei valori della Forma Spada.',
        'Stance Change: AC 20 and DEX 15 instead of the Blade Form values.',
      );
    }
    if (pokemon.name == 'Zygarde') {
      return switch (key) {
        '10' => uiTextForLanguage(
          'CA 16; FOR 16, DES 19, COS 15, INT 14, SAG 14, CAR 14.',
          'AC 16; STR 16, DEX 19, CON 15, INT 14, WIS 14, CHA 14.',
        ),
        'complete' => uiTextForLanguage(
          'CA 20; FOR 19, DES 17, COS 30, INT 18, SAG 18, CAR 18.',
          'AC 20; STR 19, DEX 17, CON 30, INT 18, WIS 18, CHA 18.',
        ),
        _ => uiTextForLanguage(
          'CA 18; FOR 19, DES 18, COS 20, INT 16, SAG 16, CAR 16.',
          'AC 18; STR 19, DEX 18, CON 20, INT 16, WIS 16, CHA 16.',
        ),
      };
    }
    if (pokemon.name == 'Darmanitan') {
      return switch (key) {
        'zen' => uiTextForLanguage(
          'Tipo Fuoco/Psico, CA 18; FOR e SAG vengono scambiate.',
          'Fire/Psychic type, AC 18; STR and WIS are swapped.',
        ),
        'galarian-zen' => uiTextForLanguage(
          'Tipo Ghiaccio/Fuoco; FOR e DES aumentano di 2.',
          'Ice/Fire type; STR and DEX increase by 2.',
        ),
        _ => null,
      };
    }
    if (pokemon.name == 'Mimikyu' && key == 'busted') {
      return uiTextForLanguage(
        'Fantasmanto è spezzato e non concede più PF temporanei.',
        'Disguise is broken and no longer grants temporary HP.',
      );
    }
    if (pokemon.name == 'Palafin' && key == 'hero') {
      return uiTextForLanguage(
        'Supercambio: +4 CA, +4 FOR e +4 DES (massimo 22) fino alla fine della lotta.',
        'Zero to Hero: +4 AC, +4 STR and +4 DEX (maximum 22) until the end of the battle.',
      );
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
