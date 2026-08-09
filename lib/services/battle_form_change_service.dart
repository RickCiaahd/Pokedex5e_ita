import 'dart:math' as math;

import '../localization/pokemon_form_localization.dart';
import '../localization/ui_text.dart';
import '../models/battle_environment.dart';
import '../models/level_progression.dart';
import '../models/move_data.dart';
import '../models/pokemon.dart';
import '../models/team_slot.dart';
import 'battle_transformation_service.dart';
import 'custom_pokemon_runtime_registry.dart';

class BattleFormEligibility {
  const BattleFormEligibility({
    required this.isAvailable,
    this.missingRequirements = const [],
    this.confirmationText,
    this.consumeItemId,
  });

  final bool isAvailable;
  final List<String> missingRequirements;
  final String? confirmationText;
  final String? consumeItemId;
}

class BattleFormDamageResult {
  const BattleFormDamageResult({
    required this.damage,
    this.formName,
    this.message,
  });

  final int damage;
  final String? formName;
  final String? message;
}

class BattleFormHpResult {
  const BattleFormHpResult({
    this.formName,
    this.restoreToFull = false,
    this.lockWishiwashiSchooling = false,
    this.message,
  });

  final String? formName;
  final bool restoreToFull;
  final bool lockWishiwashiSchooling;
  final String? message;
}

class BattleFormChangeService {
  const BattleFormChangeService._();

  static const String wishiwashiSchoolingLockedKey =
      'wishiwashi-schooling-locked';
  static const String eiscueIceFaceBrokenKey = 'eiscue-ice-face-broken';

  static const Set<String> _supportedSpecies = {
    'Deoxys',
    'Castform',
    'Cherrim',
    'Darmanitan',
    'Giratina',
    'Hoopa',
    'Keldeo',
    'Kyurem',
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
    'Oricorio',
    'Rotom',
    'Shaymin',
    'Tornadus',
    'Thundurus',
    'Landorus',
    'Enamorus',
    'Terapagos',
  };

  static const Set<String> _manualControlSpecies = {
    'Deoxys',
    'Giratina',
    'Hoopa',
    'Kyurem',
    'Necrozma',
    'Oricorio',
    'Palafin',
    'Rotom',
    'Shaymin',
    'Tornadus',
    'Thundurus',
    'Landorus',
    'Enamorus',
    'Terapagos',
    'Wishiwashi',
  };

  static const Set<String> _persistentControlSpecies = {
    'Giratina',
    'Hoopa',
    'Kyurem',
    'Necrozma',
    'Oricorio',
    'Rotom',
    'Shaymin',
    'Tornadus',
    'Thundurus',
    'Landorus',
    'Enamorus',
  };

  static bool supports(Pokemon pokemon) {
    return _supportedSpecies.contains(pokemon.name) ||
        CustomPokemonRuntimeRegistry.hasTemporaryForms(pokemon.id);
  }

  static bool hasManualControls(Pokemon pokemon) {
    return _manualControlSpecies.contains(pokemon.name) ||
        CustomPokemonRuntimeRegistry.hasTemporaryForms(pokemon.id);
  }

  static bool usesPersistentControls(Pokemon pokemon) {
    return _persistentControlSpecies.contains(pokemon.name);
  }

  static bool hasAbility(
    Pokemon pokemon,
    TeamSlot slot,
    Iterable<String> aliases,
  ) {
    final wanted = aliases.map(_referenceKey).toSet();
    final references = slot.abilities.isNotEmpty
        ? slot.abilities
        : <String>[
            ...pokemon.abilities,
            if (pokemon.hiddenAbility != null) pokemon.hiddenAbility!,
          ];
    return references.map(_referenceKey).any(wanted.contains);
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
      case 'Giratina':
        if (raw == 'base' || raw.contains('altered')) return 'altered';
        if (raw.contains('origin')) return 'origin';
        return raw;
      case 'Hoopa':
        if (raw == 'base' || raw.contains('confined')) return 'confined';
        if (raw.contains('unbound') || raw.contains('unconfined')) {
          return 'unbound';
        }
        return raw;
      case 'Keldeo':
        if (raw == 'base' || raw.contains('ordinary')) return 'ordinary';
        if (raw.contains('resolute')) return 'resolute';
        return raw;
      case 'Kyurem':
        if (raw == 'base' || raw == 'normal') return 'normal';
        if (raw.contains('black')) return 'black';
        if (raw.contains('white')) return 'white';
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
        if (raw == 'base' || raw == 'ice-face' || raw == 'ice') {
          return 'ice-face';
        }
        if (raw == 'noice' || raw == 'no-ice') return 'noice-face';
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
      case 'Giratina':
        order = const ['altered', 'origin'];
        break;
      case 'Hoopa':
        order = const ['confined', 'unbound'];
        break;
      case 'Keldeo':
        order = const ['ordinary', 'resolute'];
        break;
      case 'Kyurem':
        order = const ['normal', 'black', 'white'];
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
    if (pokemon.name == 'Darmanitan') {
      final persistentKey = canonicalFormKey(pokemon, slot.formName);
      final choiceKey = canonicalFormKey(pokemon, formName);
      final isGalarian = persistentKey.startsWith('galarian-');
      if (isGalarian) {
        return choiceKey == 'galarian-standard' || choiceKey == 'galarian-zen';
      }
      return choiceKey == 'standard' || choiceKey == 'zen';
    }
    if (pokemon.name == 'Cramorant') {
      // The Poke5e Gulp Missile rule describes Surf/Dive + Grapple but does
      // not define which of the two visual catch forms should be selected.
      return canonicalFormKey(pokemon, formName) == 'normal';
    }
    if (pokemon.name == 'Necrozma' &&
        canonicalFormKey(pokemon, formName) == 'ultra') {
      // Ultra Necrozma follows the handbook Mega rules and is not a free
      // generic form choice.
      return false;
    }
    if (const {
      'Castform',
      'Cherrim',
      'Meloetta',
      'Aegislash',
      'Zygarde',
      'Minior',
      'Mimikyu',
      'Eiscue',
      'Morpeko',
      'Ogerpon',
      'Keldeo',
    }.contains(pokemon.name)) {
      return false;
    }
    return true;
  }

  static bool sameForm(Pokemon pokemon, String? current, String candidate) {
    return canonicalFormKey(pokemon, current) ==
        canonicalFormKey(pokemon, candidate);
  }

  static String? environmentForm(
    Pokemon pokemon,
    TeamSlot slot,
    BattleEnvironment environment,
  ) {
    final suppressed = environment.suppressWeatherAbilities;
    if (pokemon.name == 'Castform' &&
        hasAbility(pokemon, slot, const {'Forecast'})) {
      if (suppressed) return 'Base';
      return switch (environment.weather) {
        BattleWeather.harshSunCalm || BattleWeather.harshSunWindy => 'sunny',
        BattleWeather.lightDrizzle ||
        BattleWeather.heavyRain ||
        BattleWeather.dangerousStorm => 'rainy',
        BattleWeather.lightSnow ||
        BattleWeather.heavySnow ||
        BattleWeather.blizzard ||
        BattleWeather.hail => 'snowy',
        _ => 'Base',
      };
    }
    if (pokemon.name == 'Cherrim') {
      if (suppressed) return 'Base';
      return switch (environment.weather) {
        BattleWeather.harshSunCalm || BattleWeather.harshSunWindy => 'sunshine',
        _ => 'Base',
      };
    }
    return null;
  }

  static String? ruleFormAtBattleStart(
    Pokemon pokemon,
    TeamSlot slot,
    BattleEnvironment environment,
  ) {
    final environmental = environmentForm(pokemon, slot, environment);
    if (environmental != null) return environmental;
    if (pokemon.name == 'Keldeo') {
      return slot.selectedMoves.any(
            (move) => _referenceKey(move) == 'secret-sword',
          )
          ? 'resolute'
          : 'Base';
    }
    if (pokemon.name == 'Meloetta') return 'Base';
    if (pokemon.name == 'Morpeko') return 'Base';
    if (pokemon.name == 'Mimikyu') return 'Base';
    return null;
  }

  static BattleFormDamageResult onIncomingDamage({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String? currentFormName,
    required int damage,
  }) {
    if (damage <= 0) return BattleFormDamageResult(damage: damage);
    final key = canonicalFormKey(pokemon, currentFormName);
    if (pokemon.name == 'Eiscue' &&
        key == 'ice-face' &&
        hasAbility(pokemon, slot, const {'Ice Face'})) {
      final reduced = damage ~/ 2;
      return BattleFormDamageResult(
        damage: reduced,
        formName: 'noice-face',
        message: uiTextForLanguage(
          'Gelofaccia dimezza il primo danno e si rompe: Eiscue assume la Forma Liquefaccia.',
          'Ice Face halves the first damage and breaks: Eiscue assumes Noice Face.',
        ),
      );
    }
    return BattleFormDamageResult(damage: damage);
  }

  static BattleFormHpResult afterHpChange({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String? currentFormName,
    required int currentHp,
    required int maxHp,
  }) {
    if (maxHp <= 0) return const BattleFormHpResult();
    final key = canonicalFormKey(pokemon, currentFormName);

    if (pokemon.name == 'Darmanitan' &&
        hasAbility(pokemon, slot, const {'Zen Mode', 'Zen Mode (Galarian)'})) {
      final isGalarian = canonicalFormKey(
        pokemon,
        slot.formName,
      ).startsWith('galarian-');
      final zen = currentHp * 2 <= maxHp;
      return BattleFormHpResult(
        formName: isGalarian
            ? (zen ? 'galar-zen' : 'galar-standard')
            : (zen ? 'zen' : 'Base'),
      );
    }

    if (pokemon.name == 'Wishiwashi' &&
        key == 'school' &&
        currentHp * 4 < maxHp) {
      return BattleFormHpResult(
        formName: 'Base',
        lockWishiwashiSchooling: true,
        message: uiTextForLanguage(
          'Schooling termina sotto il 25% dei PF: Wishiwashi torna in Forma Individuale e richiede un riposo breve prima di riattivarsi.',
          'Schooling ends below 25% HP: Wishiwashi returns to Solo Form and needs a short rest before it can activate again.',
        ),
      );
    }

    if (pokemon.name == 'Minior' &&
        key == 'meteor' &&
        currentHp * 2 < maxHp &&
        hasAbility(pokemon, slot, const {'Shields Down'})) {
      return BattleFormHpResult(
        formName: 'core-red',
        message: uiTextForLanguage(
          'Scudi Giù si attiva sotto il 50% dei PF: Minior passa alla Forma Nucleo fino a un riposo breve.',
          'Shields Down activates below 50% HP: Minior changes to Core Form until a short rest.',
        ),
      );
    }

    if (pokemon.name == 'Zygarde' &&
        currentHp * 2 < maxHp &&
        hasAbility(pokemon, slot, const {'Power Construct'})) {
      if (key == '10') {
        return BattleFormHpResult(
          formName: '50',
          restoreToFull: true,
          message: uiTextForLanguage(
            'Sciamefusione: Zygarde 10% passa alla Forma 50% e recupera tutti i PF.',
            'Power Construct: Zygarde 10% changes to 50% Form and restores all HP.',
          ),
        );
      }
      if (key == '50') {
        return BattleFormHpResult(
          formName: 'complete',
          restoreToFull: true,
          message: uiTextForLanguage(
            'Sciamefusione: Zygarde 50% passa alla Forma Perfetta e recupera tutti i PF.',
            'Power Construct: Zygarde 50% changes to Complete Form and restores all HP.',
          ),
        );
      }
    }

    return const BattleFormHpResult();
  }

  static String? formAfterMove({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String? currentFormName,
    required MoveData move,
  }) {
    final moveKey = _referenceKey(move.technicalName);
    final key = canonicalFormKey(pokemon, currentFormName);

    if (pokemon.name == 'Meloetta' && moveKey == 'relic-song') {
      return key == 'pirouette' ? 'Base' : 'pirouette';
    }

    if (pokemon.name == 'Aegislash' &&
        hasAbility(pokemon, slot, const {'Stance Change'})) {
      if (moveKey == 'kings-shield') return 'shield';
      if (move.damageForLevel(
            LevelProgression.levelFromExperience(slot.experience),
          ) !=
          null) {
        return 'Base';
      }
    }

    return null;
  }

  static String? formAtTurnStart({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String? currentFormName,
    required BattleEnvironment environment,
  }) {
    final environmental = environmentForm(pokemon, slot, environment);
    if (environmental != null) return environmental;

    final key = canonicalFormKey(pokemon, currentFormName);
    if (pokemon.name == 'Morpeko' &&
        hasAbility(pokemon, slot, const {'Hunger Switch'})) {
      return key == 'hangry' ? 'Base' : 'hangry';
    }
    if (pokemon.name == 'Eiscue' &&
        key == 'noice-face' &&
        environment.weather == BattleWeather.hail &&
        hasAbility(pokemon, slot, const {'Ice Face'})) {
      return 'Base';
    }
    return null;
  }

  static String? cramorantMoveCue(
    Pokemon pokemon,
    TeamSlot slot,
    MoveData move,
  ) {
    if (pokemon.name != 'Cramorant' ||
        !hasAbility(pokemon, slot, const {'Gulp Missile'})) {
      return null;
    }
    final key = _referenceKey(move.technicalName);
    if (key != 'surf' && key != 'dive') return null;
    return uiTextForLanguage(
      'Missilcarica: dopo Surf o Sub puoi effettuare una lotta come azione bonus. Le regole 5e sorgente non distinguono quale aspetto Gulping/Gorging mostrare, quindi l’app non cambia forma automaticamente.',
      'Gulp Missile: after Surf or Dive you may Grapple as a bonus action. The source 5e rule does not distinguish which Gulping/Gorging appearance to show, so the app does not change form automatically.',
    );
  }

  static BattleFormEligibility wishiwashiSchoolEligibility({
    required Pokemon pokemon,
    required TeamSlot slot,
    required int currentHp,
    required int maxHp,
    required Map<String, int> ruleState,
    required bool isTurnStart,
  }) {
    final missing = <String>[];
    if (!hasAbility(pokemon, slot, const {'Schooling'})) {
      missing.add(
        uiTextForLanguage('Richiede Schooling', 'Requires Schooling'),
      );
    }
    if (LevelProgression.levelFromExperience(slot.experience) < 5) {
      missing.add(uiTextForLanguage('Richiede livello 5', 'Requires level 5'));
    }
    if (maxHp <= 0 || currentHp * 4 <= maxHp) {
      missing.add(
        uiTextForLanguage(
          'Richiede più del 25% dei PF massimi',
          'Requires more than 25% maximum HP',
        ),
      );
    }
    if (!isTurnStart) {
      missing.add(
        uiTextForLanguage(
          'Si attiva all’inizio del turno',
          'Activates at the start of the turn',
        ),
      );
    }
    if ((ruleState[wishiwashiSchoolingLockedKey] ?? 0) > 0) {
      missing.add(
        uiTextForLanguage(
          'Serve un riposo breve prima di riusare Schooling',
          'A short rest is required before Schooling can be used again',
        ),
      );
    }
    return BattleFormEligibility(
      isAvailable: missing.isEmpty,
      missingRequirements: missing,
    );
  }

  static String palafinLongRestUseToken(TeamSlot slot) {
    return 'battle-form:palafin:${BattleTransformationService.pokemonUsageKey(slot)}';
  }

  static BattleFormEligibility palafinHeroEligibility({
    required Pokemon pokemon,
    required TeamSlot slot,
    required Set<String> longRestUses,
  }) {
    final missing = <String>[];
    if (!hasAbility(pokemon, slot, const {'Zero to Hero'})) {
      missing.add(
        uiTextForLanguage('Richiede Supercambio', 'Requires Zero to Hero'),
      );
    }
    if (longRestUses.contains(palafinLongRestUseToken(slot))) {
      missing.add(
        uiTextForLanguage(
          'Supercambio è già stato usato dopo l’ultimo riposo lungo',
          'Zero to Hero has already been used since the last long rest',
        ),
      );
    }
    return BattleFormEligibility(
      isAvailable: missing.isEmpty,
      missingRequirements: missing,
      confirmationText: uiTextForLanguage(
        'Conferma che un alleato non-Pokémon di Palafin abbia appena subito danni da una fonte fuori dal controllo dell’alleato. La regola 5e permette allora di attivare la Forma Possente una volta per riposo lungo.',
        'Confirm that a non-Pokémon ally of Palafin has just taken damage from a source outside that ally’s control. The 5e rule then allows Hero Form once per long rest.',
      ),
    );
  }

  static int terapagosDailyShiftUses(Pokemon pokemon, TeamSlot slot) {
    final con =
        slot.customAbilityScores['CON'] ?? pokemon.attributes.constitution;
    return math.max(0, ((con - 10) / 2).floor());
  }

  static BattleFormEligibility manualEligibility({
    required Pokemon pokemon,
    required TeamSlot slot,
    required String targetFormName,
    required Set<String> inventoryItemIds,
    required Set<int> teamPokemonIds,
  }) {
    final target = canonicalFormKey(pokemon, targetFormName);
    final heldItem = _referenceKey(slot.heldItem ?? '');
    final missing = <String>[];
    String? confirmation;
    String? consumeItemId;

    switch (pokemon.name) {
      case 'Giratina':
        if (target == 'origin' && heldItem != 'griseous-orb') {
          confirmation = uiTextForLanguage(
            'Giratina assume la Forma Origine senza Grigiosfera soltanto nel Distortion World. Conferma che il Master abbia stabilito che vi troviate nel suo piano natale.',
            'Without a Griseous Orb, Giratina assumes Origin Form only in the Distortion World. Confirm that the GM has established that you are in its home plane.',
          );
        }
        break;
      case 'Hoopa':
        if (target == 'unbound' &&
            !inventoryItemIds.contains('prison-bottle')) {
          missing.add(
            uiTextForLanguage(
              'Richiede il Vaso del vincolo',
              'Requires the Prison Bottle',
            ),
          );
        }
        if (target == 'unbound') {
          confirmation = uiTextForLanguage(
            'Il Vaso del vincolo libera Hoopa per tre giorni secondo la regola sorgente. L’app salva la forma, ma non può misurare automaticamente tre giorni di gioco: riportalo manualmente alla Forma Vincolata quando il periodo termina.',
            'The Prison Bottle frees Hoopa for three days under the source rule. The app saves the form but cannot automatically measure three in-game days; return it to Confined Form manually when that period ends.',
          );
        }
        break;
      case 'Kyurem':
        if (target == 'black') {
          if (!inventoryItemIds.contains('dna-splicer')) {
            missing.add(
              uiTextForLanguage(
                'Richiede il Cuneo DNA',
                'Requires the DNA Splicer',
              ),
            );
          }
          if (!teamPokemonIds.contains(644)) {
            missing.add(
              uiTextForLanguage(
                'Richiede Zekrom in squadra',
                'Requires Zekrom in the team',
              ),
            );
          }
        } else if (target == 'white') {
          if (!inventoryItemIds.contains('dna-splicer')) {
            missing.add(
              uiTextForLanguage(
                'Richiede il Cuneo DNA',
                'Requires the DNA Splicer',
              ),
            );
          }
          if (!teamPokemonIds.contains(643)) {
            missing.add(
              uiTextForLanguage(
                'Richiede Reshiram in squadra',
                'Requires Reshiram in the team',
              ),
            );
          }
        }
        break;
      case 'Necrozma':
        if (target == 'dusk-mane') {
          if (!inventoryItemIds.contains('n-solarizer')) {
            missing.add(
              uiTextForLanguage(
                'Richiede il Necrosolix',
                'Requires the N-Solarizer',
              ),
            );
          }
          if (!teamPokemonIds.contains(791)) {
            missing.add(
              uiTextForLanguage(
                'Richiede Solgaleo in squadra',
                'Requires Solgaleo in the team',
              ),
            );
          }
        } else if (target == 'dawn-wings') {
          if (!inventoryItemIds.contains('n-lunarizer')) {
            missing.add(
              uiTextForLanguage(
                'Richiede il Necrolunix',
                'Requires the N-Lunarizer',
              ),
            );
          }
          if (!teamPokemonIds.contains(792)) {
            missing.add(
              uiTextForLanguage(
                'Richiede Lunala in squadra',
                'Requires Lunala in the team',
              ),
            );
          }
        } else if (target == 'ultra') {
          missing.add(
            uiTextForLanguage(
              'Ultra Necrozma non è una forma selezionabile liberamente: segue le regole della Mega Evoluzione del manuale',
              'Ultra Necrozma is not a freely selectable form: it follows the handbook Mega Evolution rules',
            ),
          );
        }
        break;
      case 'Oricorio':
        final nectar = switch (target) {
          'baile' || 'baile-style' => 'red-nectar',
          'pom-pom' || 'pom-pom-style' => 'yellow-nectar',
          'pau' || 'pau-style' => 'pink-nectar',
          'sensu' || 'sensu-style' => 'purple-nectar',
          _ => null,
        };
        if (nectar != null) {
          if (!inventoryItemIds.contains(nectar)) {
            missing.add(
              uiTextForLanguage(
                'Richiede il Nettare appropriato nello Zaino',
                'Requires the appropriate Nectar in the Bag',
              ),
            );
          } else {
            consumeItemId = nectar;
          }
        }
        break;
      case 'Rotom':
        if (target != 'base' && target != 'normal') {
          confirmation = uiTextForLanguage(
            'Conferma con il Master che Rotom disponga dell’elettrodomestico appropriato. La regola 5e lascia questa disponibilità alla discrezione del Master.',
            'Confirm with the GM that Rotom has access to the appropriate appliance. The 5e rule leaves that availability to GM discretion.',
          );
        }
        break;
      case 'Shaymin':
        if (target.contains('sky') && heldItem != 'gracidea-flower') {
          missing.add(
            uiTextForLanguage(
              'Shaymin deve tenere il Fiore Gracidea',
              'Shaymin must hold a Gracidea Flower',
            ),
          );
        }
        break;
      case 'Tornadus':
      case 'Thundurus':
      case 'Landorus':
      case 'Enamorus':
        if (heldItem != 'reveal-glass') {
          missing.add(
            uiTextForLanguage(
              'Richiede il Verispecchio tenuto dal Pokémon',
              'Requires the Reveal Glass to be held',
            ),
          );
        }
        break;
    }

    return BattleFormEligibility(
      isAvailable: missing.isEmpty,
      missingRequirements: missing,
      confirmationText: confirmation,
      consumeItemId: consumeItemId,
    );
  }

  static String formLabel(Pokemon pokemon, String? formName) {
    if (const {
      'Oricorio',
      'Rotom',
      'Shaymin',
      'Tornadus',
      'Thundurus',
      'Landorus',
      'Enamorus',
    }.contains(pokemon.name)) {
      return PokemonFormLocalization.formLabel(pokemon, formName);
    }

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
      case 'Giratina':
        return key == 'origin'
            ? uiTextForLanguage('Forma Origine', 'Origin Forme')
            : uiTextForLanguage('Forma Alterata', 'Altered Forme');
      case 'Hoopa':
        return key == 'unbound'
            ? uiTextForLanguage('Forma Libera', 'Unbound Form')
            : uiTextForLanguage('Forma Vincolata', 'Confined Form');
      case 'Keldeo':
        return key == 'resolute'
            ? uiTextForLanguage('Forma Risoluta', 'Resolute Form')
            : uiTextForLanguage('Forma Normale', 'Ordinary Form');
      case 'Kyurem':
        return switch (key) {
          'black' => 'Kyurem Nero',
          'white' => 'Kyurem Bianco',
          _ => 'Kyurem',
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
        return uiTextForLanguage('Forma Normale', 'Normal Form');
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
      case 'Deoxys':
        return uiTextForLanguage(
          'Mutante permette a Deoxys di cambiare Forma Normale, Attacco, Difesa o Velocità come azione bonus.',
          'Mutant lets Deoxys change between Normal, Attack, Defense or Speed Form as a bonus action.',
        );
      case 'Castform':
        return uiTextForLanguage(
          'Previsioni cambia automaticamente forma con il meteo registrato nel Battle Companion.',
          'Forecast automatically changes form with the weather recorded in the Battle Companion.',
        );
      case 'Darmanitan':
        return uiTextForLanguage(
          'Lo Stato Zen viene applicato automaticamente al 50% o meno dei PF se il Pokémon possiede l’abilità corretta.',
          'Zen Mode is applied automatically at 50% HP or less if the Pokémon has the appropriate ability.',
        );
      case 'Aegislash':
        return uiTextForLanguage(
          'Accendilotta viene applicato automaticamente: Scudo Reale porta alla Forma Scudo, una mossa che infligge danni riporta alla Forma Spada.',
          'Stance Change is applied automatically: King’s Shield enters Shield Form, and a damaging move returns to Blade Form.',
        );
      case 'Zygarde':
        return uiTextForLanguage(
          'Sciamefusione viene applicato automaticamente sotto metà PF e ripristina tutti i PF quando cambia forma.',
          'Power Construct is applied automatically below half HP and restores all HP when the form changes.',
        );
      case 'Wishiwashi':
        return uiTextForLanguage(
          'Dal livello 5, all’inizio del turno e sopra il 25% dei PF puoi attivare Forma Banco. Sotto il 25% torna Individuale e richiede un riposo breve.',
          'From level 5, at the start of the turn and above 25% HP you may activate School Form. Below 25% it returns to Solo and requires a short rest.',
        );
      case 'Minior':
        return uiTextForLanguage(
          'Scudi Giù passa automaticamente alla Forma Nucleo sotto il 50% dei PF; un riposo breve ripristina la Forma Meteora.',
          'Shields Down automatically changes to Core Form below 50% HP; a short rest restores Meteor Form.',
        );
      case 'Mimikyu':
        return uiTextForLanguage(
          'Fantasmanto mantiene la Forma Mascherata finché i suoi PF temporanei non vengono esauriti.',
          'Disguise keeps Disguised Form until its temporary HP are depleted.',
        );
      case 'Eiscue':
        return uiTextForLanguage(
          'Gelofaccia dimezza il primo danno e passa a Liquefaccia; grandine a inizio turno o riposo breve ripristinano Gelofaccia.',
          'Ice Face halves the first damage and changes to Noice Face; hail at turn start or a short rest restores Ice Face.',
        );
      case 'Morpeko':
        return uiTextForLanguage(
          'Pancialterna cambia automaticamente motivo all’inizio di ogni turno.',
          'Hunger Switch automatically changes mode at the start of each turn.',
        );
      case 'Palafin':
        return uiTextForLanguage(
          'Supercambio si può confermare quando un alleato non-Pokémon subisce danni fuori dal proprio controllo; una volta per riposo lungo.',
          'Zero to Hero can be confirmed when a non-Pokémon ally takes damage outside its control; once per long rest.',
        );
      case 'Ogerpon':
        return uiTextForLanguage(
          'La forma deriva automaticamente dalla maschera tenuta. In Teracristal il tipo viene forzato al tipo della maschera.',
          'The form is derived automatically from the held mask. When Terastallized, its type is forced to the mask’s type.',
        );
      case 'Terapagos':
        return uiTextForLanguage(
          'Tera Shift consente la Forma Teracristal per un numero di usi giornalieri pari al modificatore di COS; la Teracristallizzazione porta alla Forma Astrale.',
          'Tera Shift allows Terastal Form a number of times per day equal to the CON modifier; Terastallization changes it to Stellar Form.',
        );
      case 'Cramorant':
        return uiTextForLanguage(
          'Missilcarica viene segnalata dopo Surf o Sub. Il testo 5e sorgente non assegna Gulping/Gorging a condizioni diverse, quindi l’app non inventa un cambio grafico.',
          'Gulp Missile is signaled after Surf or Dive. The source 5e text does not assign Gulping/Gorging to different conditions, so the app does not invent a visual switch.',
        );
      default:
        return uiTextForLanguage(
          'Il cambio forma segue i requisiti mostrati per questa specie.',
          'Form changes follow the requirements shown for this species.',
        );
    }
  }

  static int armorClassBonus(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Deoxys' && key == 'defense') return 3;
    if (pokemon.name == 'Palafin' && key == 'hero') return 4;
    if (pokemon.name == 'Eiscue' && key == 'noice-face') return -3;
    return 0;
  }

  static int speedBonus(Pokemon pokemon, String? formName) {
    final key = canonicalFormKey(pokemon, formName);
    if (pokemon.name == 'Eiscue' && key == 'noice-face') return 5;
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
          'Mutante: +5 ai tiri per colpire; gli attacchi contro Deoxys hanno vantaggio.',
          'Mutant: +5 to attack rolls; attacks against Deoxys have advantage.',
        ),
        'defense' => uiTextForLanguage(
          'Mutante: +3 alla CA; i suoi attacchi hanno svantaggio e i bersagli hanno vantaggio ai TS contro le sue mosse.',
          'Mutant: +3 AC; its attacks have disadvantage and targets have advantage on saves against its moves.',
        ),
        'speed' => uiTextForLanguage(
          'Mutante: ottiene un’azione di attacco aggiuntiva ogni turno; quell’attacco viene effettuato con svantaggio. Se la mossa richiede un TS, i bersagli hanno vantaggio.',
          'Mutant: gains one additional attack action each turn; that attack is made with disadvantage. If the move requires a save, the targets have advantage.',
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
    if (pokemon.name == 'Eiscue' && key == 'noice-face') {
      return uiTextForLanguage(
        'Gelofaccia è rotta: CA −3 e tutte le velocità +5 ft.',
        'Ice Face is broken: AC −3 and all movement speeds +5 ft.',
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
      'Giratina' => 'altered',
      'Hoopa' => 'confined',
      'Keldeo' => 'ordinary',
      'Kyurem' => 'normal',
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

  static String _referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
