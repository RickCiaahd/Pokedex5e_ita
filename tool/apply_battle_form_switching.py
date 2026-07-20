from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: str, old: str, new: str) -> None:
    file_path = ROOT / path
    text = file_path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one match in {path}, found {count}: {old[:100]!r}")
    file_path.write_text(text.replace(old, new, 1), encoding="utf-8")


def write(path: str, content: str) -> None:
    file_path = ROOT / path
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(content, encoding="utf-8")


# Register the newly uploaded Deoxys asset directories.
replace_once(
    "pubspec.yaml",
    "    - assets/textures/textures_webapp/pokemon/deoxys/\n",
    "    - assets/textures/textures_webapp/pokemon/deoxys/\n"
    "    - assets/textures/textures_webapp/pokemon/deoxys-attack/\n"
    "    - assets/textures/textures_webapp/pokemon/deoxys-defense/\n"
    "    - assets/textures/textures_webapp/pokemon/deoxys-speed/\n",
)

# Add mechanical form definitions. Technical names remain English for save compatibility.
replace_once(
    "assets/data/pokemon/Deoxys.json",
    '  "size": "Medium"\n}',
    '''  "size": "Medium",
  "variant_data": {
    "create_mode": "default",
    "default": "Normal Forme",
    "permanent": false,
    "variants": {
      "Normal Forme": {
        "display": "Deoxys Normal Forme",
        "original_species": "Deoxys Normal Forme"
      },
      "Attack Forme": {
        "display": "Deoxys Attack Forme",
        "original_species": "Deoxys Attack Forme"
      },
      "Defense Forme": {
        "display": "Deoxys Defense Forme",
        "original_species": "Deoxys Defense Forme"
      },
      "Speed Forme": {
        "display": "Deoxys Speed Forme",
        "original_species": "Deoxys Speed Forme"
      }
    }
  }
}''',
)

replace_once(
    "assets/data/pokemon/Aegislash.json",
    '  "size": "Medium"\n}',
    '''  "size": "Medium",
  "variant_data": {
    "create_mode": "default",
    "default": "Blade Forme",
    "permanent": false,
    "variants": {
      "Blade Forme": {
        "display": "Aegislash Blade Forme",
        "original_species": "Aegislash Blade Forme"
      },
      "Shield Forme": {
        "diff": {
          "AC": 20,
          "attributes": {
            "DEX": 15
          }
        },
        "display": "Aegislash Shield Forme",
        "original_species": "Aegislash Shield Forme"
      }
    }
  }
}''',
)

replace_once(
    "assets/data/pokemon/Darmanitan.json",
    '  "size": "Medium"\n}',
    '''  "size": "Medium",
  "variant_data": {
    "create_mode": "default",
    "default": "Standard Mode",
    "permanent": false,
    "variants": {
      "Standard Mode": {
        "display": "Darmanitan Standard Mode",
        "original_species": "Darmanitan Standard Mode"
      },
      "Zen Mode": {
        "diff": {
          "AC": 18,
          "Type": [
            "Fire",
            "Psychic"
          ],
          "attributes": {
            "STR": 12,
            "WIS": 17
          }
        },
        "display": "Darmanitan Zen Mode",
        "original_species": "Darmanitan Zen Mode"
      }
    }
  }
}''',
)

# Remove default-form duplicates such as Base + Normal for Deoxys.
replace_once(
    "lib/widgets/pokemon/pokemon_asset_image_legacy.dart",
    """      if (canonicalName.isEmpty ||
          _isBaseSpriteLabel(canonicalName) ||
          _isGenderOnlyLabel(canonicalName)) {
        return;
      }

      final key = _formIdentityKey(pokemon, canonicalName);
""",
    """      if (canonicalName.isEmpty ||
          _isBaseSpriteLabel(canonicalName) ||
          _isGenderOnlyLabel(canonicalName) ||
          _isDefaultFormChoice(pokemon, canonicalName)) {
        return;
      }

      final key = _formIdentityKey(pokemon, canonicalName);
""",
)

replace_once(
    "lib/widgets/pokemon/pokemon_asset_image_legacy.dart",
    """  static bool _isBaseSpriteLabel(String label) {
""",
    """  static bool _isDefaultFormChoice(Pokemon pokemon, String label) {
    final normalized = _webSlug(
      _stripGenericFormWords(_removePokemonName(label, pokemon.name)),
    );
    const defaultForms = <String, Set<String>>{
      'Deoxys': {'normal'},
      'Castform': {'normal'},
      'Cherrim': {'overcast'},
      'Darmanitan': {'standard'},
      'Meloetta': {'aria'},
      'Aegislash': {'blade'},
      'Wishiwashi': {'solo'},
      'Minior': {'meteor'},
      'Mimikyu': {'disguised'},
      'Eiscue': {'ice-face'},
      'Morpeko': {'full-belly'},
      'Palafin': {'zero'},
      'Zygarde': {'50'},
      'Ogerpon': {'teal-mask'},
      'Terapagos': {'normal'},
    };
    return defaultForms[pokemon.name]?.contains(normalized) ?? false;
  }

  static bool _isBaseSpriteLabel(String label) {
""",
)

write(
    "lib/services/battle_form_change_service.dart",
    r'''import '../models/pokemon.dart';
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
      return isGalarian
          ? key.contains('galar')
          : key == 'base' || key == 'zen';
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
          'Darmanitan': 'Passa allo Stato Zen sotto metà dei PF se possiede Stato Zen.',
          'Meloetta': 'Cantoantico alterna Forma Canto e Forma Danza.',
          'Aegislash': 'Le mosse offensive e Scudo Reale alternano le due forme.',
          'Zygarde': 'Cambia forma quando si attivano le sue capacità di aggregazione.',
          'Wishiwashi': 'Alterna Forma Individuale e Forma Banco secondo Banco.',
          'Minior': 'Scudosoglia espone il nucleo quando i PF scendono.',
          'Mimikyu': 'Il travestimento si rompe quando viene consumato.',
          'Necrozma': 'Gestisci fusioni e Ultraesplosione durante la lotta.',
          'Cramorant': 'Cambia forma dopo Surf o Sub.',
          'Eiscue': 'Alterna Facciagelo e Facciavuota quando il ghiaccio si rompe o si riforma.',
          'Morpeko': 'Alterna modalità alla fine di ogni turno con Pancialterna.',
          'Palafin': 'Supercambio attiva la Forma Possente quando lascia il campo.',
          'Ogerpon': 'La maschera determina forma e tipo durante la lotta.',
          'Terapagos': 'Gestisci Forma Teracristal e Forma Astrale durante la lotta.',
        }[pokemon.name] ??
        'Cambia manualmente la forma quando si verifica la relativa condizione.';
  }

  static String? effectNote(Pokemon pokemon, String? formName) {
    final key = _key(pokemon, formName);
    return <String, String>{
      'Deoxys:attack': 'Mutante: +5 ai tiri per colpire; gli attacchi contro Deoxys hanno vantaggio.',
      'Deoxys:defense': 'Mutante: CA +3; i suoi attacchi hanno svantaggio e i bersagli hanno vantaggio ai tiri salvezza.',
      'Deoxys:speed': 'Mutante: ottiene un’azione di attacco aggiuntiva, effettuata con svantaggio; i bersagli hanno vantaggio ai tiri salvezza.',
      'Castform:base': 'Tipo Normale in assenza di sole intenso, pioggia o neve.',
      'Castform:sunny': 'Tipo Fuoco durante la luce solare intensa.',
      'Castform:rainy': 'Tipo Acqua durante la pioggia.',
      'Castform:snowy': 'Tipo Ghiaccio in condizioni fredde o nevose.',
      'Darmanitan:zen': 'Sotto metà PF: Fuoco/Psico, CA +4 e FOR/SAG scambiate.',
      'Aegislash:shield': 'Scudo Reale: CA e DES vengono scambiate rispetto alla Forma Spada.',
      'Aegislash:base': 'Una mossa che infligge danni riporta Aegislash alla Forma Spada.',
      'Aegislash:blade': 'Una mossa che infligge danni riporta Aegislash alla Forma Spada.',
      'Meloetta:pirouette': 'Cantoantico attiva la Forma Danza; tornando in panchina riassume la Forma Canto.',
      'Palafin:hero': 'Supercambio mantiene la Forma Possente fino al termine della lotta.',
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
''',
)

# Persist a battle-only form override without changing the saved TeamSlot form.
replace_once(
    "lib/models/battle_session.dart",
    """    required this.remainingPp,
    required this.volatileStatuses,
  });
""",
    """    required this.remainingPp,
    required this.volatileStatuses,
    this.battleFormName,
  });
""",
)
replace_once(
    "lib/models/battle_session.dart",
    """  final Map<String, int> remainingPp;
  final Set<String> volatileStatuses;

  bool matches(TeamSlot slot) {
""",
    """  final Map<String, int> remainingPp;
  final Set<String> volatileStatuses;
  final String? battleFormName;

  bool matches(TeamSlot slot) {
""",
)
replace_once(
    "lib/models/battle_session.dart",
    """      'remainingPp': remainingPp,
      'volatileStatuses': volatileStatuses.toList(growable: false),
    };
""",
    """      'remainingPp': remainingPp,
      'volatileStatuses': volatileStatuses.toList(growable: false),
      'battleFormName': battleFormName,
    };
""",
)
replace_once(
    "lib/models/battle_session.dart",
    """      volatileStatuses: Set<String>.from(
        List<dynamic>.from(
          json['volatileStatuses'] ?? const [],
        ).map((value) => value.toString()),
      ),
    );
""",
    """      volatileStatuses: Set<String>.from(
        List<dynamic>.from(
          json['volatileStatuses'] ?? const [],
        ).map((value) => value.toString()),
      ),
      battleFormName: json['battleFormName']?.toString(),
    );
""",
)

# Battle Companion integration.
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """import '../../services/battle_environment_service.dart';
import '../../services/battle_quick_item_service.dart';
""",
    """import '../../services/battle_environment_service.dart';
import '../../services/battle_form_change_service.dart';
import '../../services/battle_quick_item_service.dart';
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """  final Map<int, Map<String, int>> _remainingPpBySlot = {};
  final Map<int, Set<String>> _volatileStatusesBySlot = {};
  final List<BattleInitiativeEntry> _initiativeEntries = [];
""",
    """  final Map<int, Map<String, int>> _remainingPpBySlot = {};
  final Map<int, Set<String>> _volatileStatusesBySlot = {};
  final Map<int, String> _battleFormBySlot = {};
  final List<BattleInitiativeEntry> _initiativeEntries = [];
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """      referencesByPokemon
          .putIfAbsent(pokemonId, () => <String>{'Struggle'})
          .addAll(_movesForSlot(slot, pokemon));
""",
    """      final references = referencesByPokemon.putIfAbsent(
        pokemonId,
        () => <String>{'Struggle'},
      );
      references.addAll(_movesForSlot(slot, pokemon));
      for (final definition in pokemon.formDefinitions) {
        references.addAll(_movesForSlot(slot, definition.pokemon));
      }
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    _remainingPpBySlot.clear();
    _volatileStatusesBySlot.clear();
    _initiativeEntries.clear();
""",
    """    _remainingPpBySlot.clear();
    _volatileStatusesBySlot.clear();
    _battleFormBySlot.clear();
    _initiativeEntries.clear();
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """        _volatileStatusesBySlot[matchingSlot.slotIndex] = {
          ...state.volatileStatuses,
        };
""",
    """        _volatileStatusesBySlot[matchingSlot.slotIndex] = {
          ...state.volatileStatuses,
        };
        final battleFormName = state.battleFormName;
        if (battleFormName != null && battleFormName.trim().isNotEmpty) {
          _battleFormBySlot[matchingSlot.slotIndex] = battleFormName;
        }
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """        remainingPp: {...?_remainingPpBySlot[slot.slotIndex]},
        volatileStatuses: {...?_volatileStatusesBySlot[slot.slotIndex]},
      );
""",
    """        remainingPp: {...?_remainingPpBySlot[slot.slotIndex]},
        volatileStatuses: {...?_volatileStatusesBySlot[slot.slotIndex]},
        battleFormName: _battleFormBySlot[slot.slotIndex],
      );
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    return data.pokemonById[pokemonId]?.resolveVariant(
      formName: slot.formName,
      gender: slot.gender,
    );
  }

  List<String> _movesForSlot(TeamSlot slot, Pokemon pokemon) {
""",
    """  String? _effectiveFormName(TeamSlot slot) {
    if (_battleFormBySlot.containsKey(slot.slotIndex)) {
      return _battleFormBySlot[slot.slotIndex];
    }
    return slot.formName;
  }

  Pokemon? _pokemonForSlot(_BattleData data, TeamSlot slot) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return null;
    return data.pokemonById[pokemonId]?.resolveVariant(
      formName: _effectiveFormName(slot),
      gender: slot.gender,
    );
  }

  Future<void> _openBattleFormPicker(
    _BattleData data,
    TeamSlot slot,
  ) async {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) return;
    final basePokemon = data.pokemonById[pokemonId];
    if (basePokemon == null || !BattleFormChangeService.supports(basePokemon)) {
      return;
    }

    final allChoices = await PokemonAssetPaths.formChoices(basePokemon);
    final choices = allChoices
        .where(
          (choice) => BattleFormChangeService.isAllowedChoice(
            pokemon: basePokemon,
            slot: slot,
            formName: choice.name,
          ),
        )
        .toList(growable: false);
    if (!mounted || choices.length <= 1) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _BattleFormPickerSheet(
        pokemon: basePokemon,
        slot: slot,
        currentFormName: _effectiveFormName(slot),
        choices: choices,
      ),
    );
    if (!mounted || selected == null) return;

    setState(() {
      _battleFormBySlot[slot.slotIndex] = selected;
      _message =
          '${_displayName(slot, basePokemon)} assume la ${BattleFormChangeService.formLabel(basePokemon, selected)}.';
    });
    await _saveSession(data);
  }

  List<String> _movesForSlot(TeamSlot slot, Pokemon pokemon) {
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """  String _moveStats(MoveData move, Pokemon pokemon, TeamSlot slot) {
""",
    """  String _moveStats(
    MoveData move,
    Pokemon pokemon,
    TeamSlot slot,
    String? formName,
  ) {
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    final effectiveMoveType = BattleEnvironmentService.effectiveMoveType(
      move,
      _environment,
    );
""",
    """    final effectiveMoveType = BattleEnvironmentService.effectiveMoveType(
      move,
      _environment,
    );
    final formAttackBonus = BattleFormChangeService.attackRollBonus(
      pokemon,
      formName,
    );
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """      final attackBonus =
          moveModifier + proficiency + attackPathBonus + terrainAttackBonus;
""",
    """      final attackBonus =
          moveModifier +
          proficiency +
          attackPathBonus +
          terrainAttackBonus +
          formAttackBonus;
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    _remainingPpBySlot.clear();
    _volatileStatusesBySlot.clear();
    _initiativeEntries.clear();
    if (!mounted) return;
""",
    """    _remainingPpBySlot.clear();
    _volatileStatusesBySlot.clear();
    _battleFormBySlot.clear();
    _initiativeEntries.clear();
    if (!mounted) return;
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """            final activeSlot = _activeSlotFor(data)!;
            final pokemon = _pokemonForSlot(data, activeSlot)!;
            final moveReferences = _movesForSlot(activeSlot, pokemon);
""",
    """            final activeSlot = _activeSlotFor(data)!;
            final basePokemon = data.pokemonById[activeSlot.pokemonId!]!;
            final effectiveFormName = _effectiveFormName(activeSlot);
            final pokemon = _pokemonForSlot(data, activeSlot)!;
            final canChangeForm = BattleFormChangeService.supports(basePokemon);
            final moveReferences = _movesForSlot(activeSlot, pokemon);
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """            final baseArmorClass = BattleEnvironmentService.baseArmorClass(
              pokemon,
              activeSlot,
            );
            final effectiveArmorClass =
                baseArmorClass +
                BattleEnvironmentService.armorClassBonus(
""",
    """            final baseArmorClass = BattleEnvironmentService.baseArmorClass(
              pokemon,
              activeSlot,
            );
            final formArmorClass =
                baseArmorClass +
                BattleFormChangeService.armorClassBonus(
                  basePokemon,
                  effectiveFormName,
                );
            final effectiveArmorClass =
                formArmorClass +
                BattleEnvironmentService.armorClassBonus(
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                  _PartyBar(
                    slots: data.occupiedSlots,
                    activeSlot: activeSlot,
                    pokemonForSlot: (slot) => _pokemonForSlot(data, slot),
                    onSelected: (slotIndex) {
""",
    """                  _PartyBar(
                    slots: data.occupiedSlots,
                    activeSlot: activeSlot,
                    pokemonForSlot: (slot) => _pokemonForSlot(data, slot),
                    formNameForSlot: _effectiveFormName,
                    onSelected: (slotIndex) {
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                  _ActivePokemonCard(
                    pokemon: pokemon,
                    slot: activeSlot,
                    heldItem: heldItem,
""",
    """                  _ActivePokemonCard(
                    pokemon: pokemon,
                    slot: activeSlot,
                    formName: effectiveFormName,
                    formLabel: canChangeForm
                        ? BattleFormChangeService.formLabel(
                            basePokemon,
                            effectiveFormName,
                          )
                        : null,
                    formNote: canChangeForm
                        ? BattleFormChangeService.effectNote(
                            basePokemon,
                            effectiveFormName,
                          )
                        : null,
                    heldItem: heldItem,
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                    baseArmorClass: baseArmorClass,
                    effectiveArmorClass: effectiveArmorClass,
""",
    """                    baseArmorClass: formArmorClass,
                    effectiveArmorClass: effectiveArmorClass,
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                    onOpenBag: () => _openQuickBag(data, activeSlot),
                  ),
""",
    """                    onOpenBag: () => _openQuickBag(data, activeSlot),
                    onChangeForm: canChangeForm
                        ? () => _openBattleFormPicker(data, activeSlot)
                        : null,
                  ),
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                              pokemon,
                              activeSlot,
                            ),
""",
    """                              pokemon,
                              activeSlot,
                              effectiveFormName,
                            ),
""",
)

# Party bar also reflects temporary battle forms.
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    required this.pokemonForSlot,
    required this.onSelected,
  });
""",
    """    required this.pokemonForSlot,
    required this.formNameForSlot,
    required this.onSelected,
  });
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final ValueChanged<int> onSelected;
""",
    """  final Pokemon? Function(TeamSlot slot) pokemonForSlot;
  final String? Function(TeamSlot slot) formNameForSlot;
  final ValueChanged<int> onSelected;
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                        pokemon: pokemonForSlot(slot),
                        selected: slot.slotIndex == activeSlot.slotIndex,
""",
    """                        pokemon: pokemonForSlot(slot),
                        formName: formNameForSlot(slot),
                        selected: slot.slotIndex == activeSlot.slotIndex,
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    required this.pokemon,
    required this.selected,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final bool selected;
""",
    """    required this.pokemon,
    required this.formName,
    required this.selected,
    required this.onTap,
  });

  final TeamSlot slot;
  final Pokemon? pokemon;
  final String? formName;
  final bool selected;
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                  formName: slot.formName,
                  gender: slot.gender,
""",
    """                  formName: formName,
                  gender: slot.gender,
""",
)

# Insert the battle form picker before the active Pokémon card.
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """class _ActivePokemonCard extends StatelessWidget {
""",
    r'''class _BattleFormPickerSheet extends StatelessWidget {
  const _BattleFormPickerSheet({
    required this.pokemon,
    required this.slot,
    required this.currentFormName,
    required this.choices,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final String? currentFormName;
  final List<PokemonFormChoice> choices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            'Cambia forma in battaglia',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(BattleFormChangeService.changeHint(pokemon)),
          const SizedBox(height: 12),
          for (final choice in choices)
            Card(
              child: ListTile(
                leading: PokemonAssetImage(
                  pokemon: pokemon,
                  formName: choice.name,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                  size: 54,
                ),
                title: Text(
                  BattleFormChangeService.formLabel(pokemon, choice.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: BattleFormChangeService.effectNote(
                          pokemon,
                          choice.name,
                        ) ==
                        null
                    ? null
                    : Text(
                        BattleFormChangeService.effectNote(
                          pokemon,
                          choice.name,
                        )!,
                      ),
                trailing: BattleFormChangeService.sameForm(
                  pokemon,
                  currentFormName,
                  choice.name,
                )
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () => Navigator.of(context).pop(choice.name),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivePokemonCard extends StatelessWidget {
''',
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    required this.pokemon,
    required this.slot,
    required this.heldItem,
""",
    """    required this.pokemon,
    required this.slot,
    required this.formName,
    required this.formLabel,
    required this.formNote,
    required this.heldItem,
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """    required this.onUseHeldBerry,
    required this.onOpenBag,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final BagItem? heldItem;
""",
    """    required this.onUseHeldBerry,
    required this.onOpenBag,
    required this.onChangeForm,
  });

  final Pokemon pokemon;
  final TeamSlot slot;
  final String? formName;
  final String? formLabel;
  final String? formNote;
  final BagItem? heldItem;
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """  final VoidCallback? onUseHeldBerry;
  final VoidCallback onOpenBag;

  @override
""",
    """  final VoidCallback? onUseHeldBerry;
  final VoidCallback onOpenBag;
  final VoidCallback? onChangeForm;

  @override
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """                  formName: slot.formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
""",
    """                  formName: formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
""",
)
replace_once(
    "lib/screens/battle/battle_screen.dart",
    """            const SizedBox(height: 12),
            InkWell(
              onTap: onEditHp,
""",
    """            if (onChangeForm != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.change_circle_outlined, size: 18),
                    label: Text(formLabel ?? 'Forma'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onChangeForm,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('CAMBIA FORMA'),
                  ),
                ],
              ),
              if (formNote != null) ...[
                const SizedBox(height: 6),
                Text(
                  formNote!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: onEditHp,
""",
)

# Tests: data mechanics, duplicate removal, service behavior and session round-trip.
replace_once(
    "test/pokemon_form_mechanics_test.dart",
    """import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
""",
    """import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';
""",
)
replace_once(
    "test/pokemon_form_mechanics_test.dart",
    """  test('web gender variants are selected from the saved gender', () async {
""",
    r'''  test('Deoxys exposes one base form plus Attack, Defense and Speed', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final deoxys = pokemon.firstWhere((entry) => entry.id == 386);
    final choices = await PokemonAssetPaths.formChoices(deoxys);
    final keys = choices
        .map((choice) => Pokemon.formReferenceKey(choice.name, deoxys.name))
        .toList(growable: false);

    expect(keys.where((key) => key == 'base'), hasLength(1));
    expect(keys, containsAll(<String>['attack', 'defense', 'speed']));
    expect(deoxys.resolveVariant(formName: 'Attack').name, 'Deoxys');
  });

  test('Aegislash Shield Forme swaps AC and DEX', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final aegislash = pokemon.firstWhere((entry) => entry.id == 681);
    final shield = aegislash.resolveVariant(formName: 'Shield');

    expect(shield.armorClass, 20);
    expect(shield.attributes.dexterity, 15);
  });

  test('Darmanitan Zen Mode applies the 5e form mechanics', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final darmanitan = pokemon.firstWhere((entry) => entry.id == 555);
    final zen = darmanitan.resolveVariant(formName: 'Zen');

    expect(zen.armorClass, 18);
    expect(zen.types, <String>['Fire', 'Psychic']);
    expect(zen.attributes.strength, 12);
    expect(zen.attributes.wisdom, 17);
  });

  test('web gender variants are selected from the saved gender', () async {
''',
)

replace_once(
    "test/battle_session_test.dart",
    """      remainingPp: const {'bite': 3},
      volatileStatuses: const {'Confused'},
    );
""",
    """      remainingPp: const {'bite': 3},
      volatileStatuses: const {'Confused'},
      battleFormName: 'Attack',
    );
""",
)
replace_once(
    "test/battle_session_test.dart",
    """    expect(restored.pokemonStates[2]?.volatileStatuses, {'Confused'});
    expect(restored.initiativeEntries.last.name, 'Boss');
""",
    """    expect(restored.pokemonStates[2]?.volatileStatuses, {'Confused'});
    expect(restored.pokemonStates[2]?.battleFormName, 'Attack');
    expect(restored.initiativeEntries.last.name, 'Boss');
""",
)

write(
    "test/battle_form_change_service_test.dart",
    r'''import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/team_slot.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';
import 'package:pokedex_5e_ita/services/battle_form_change_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('battle form support covers in-combat transformations', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final byName = {for (final entry in pokemon) entry.name: entry};

    for (final name in const [
      'Deoxys',
      'Castform',
      'Cherrim',
      'Darmanitan',
      'Meloetta',
      'Aegislash',
      'Wishiwashi',
      'Minior',
      'Mimikyu',
      'Cramorant',
      'Eiscue',
      'Morpeko',
      'Palafin',
      'Terapagos',
    ]) {
      expect(
        BattleFormChangeService.supports(byName[name]!),
        isTrue,
        reason: name,
      );
    }
    expect(BattleFormChangeService.supports(byName['Pikachu']!), isFalse);
  });

  test('Deoxys uses official Italian form labels and 5e bonuses', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final deoxys = pokemon.firstWhere((entry) => entry.id == 386);

    expect(BattleFormChangeService.formLabel(deoxys, 'Base'), 'Forma Normale');
    expect(BattleFormChangeService.formLabel(deoxys, 'Attack'), 'Forma Attacco');
    expect(BattleFormChangeService.formLabel(deoxys, 'Defense'), 'Forma Difesa');
    expect(BattleFormChangeService.formLabel(deoxys, 'Speed'), 'Forma Velocità');
    expect(BattleFormChangeService.attackRollBonus(deoxys, 'Attack'), 5);
    expect(BattleFormChangeService.armorClassBonus(deoxys, 'Defense'), 3);
  });

  test('Darmanitan does not mix Unovan and Galarian battle forms', () async {
    final pokemon = await PokemonRepository().getAllPokemon();
    final darmanitan = pokemon.firstWhere((entry) => entry.id == 555);
    final unovan = TeamSlot(slotIndex: 0, pokemonId: 555);
    final galarian = TeamSlot(
      slotIndex: 1,
      pokemonId: 555,
      formName: 'Galarian Darmanitan Standard Mode',
    );

    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: unovan,
        formName: 'Zen',
      ),
      isTrue,
    );
    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: unovan,
        formName: 'Galarian Zen',
      ),
      isFalse,
    );
    expect(
      BattleFormChangeService.isAllowedChoice(
        pokemon: darmanitan,
        slot: galarian,
        formName: 'Galarian Zen',
      ),
      isTrue,
    );
  });
}
''',
)

# Changelog entry remains under Non rilasciato until the release PR.
replace_once(
    "CHANGELOG.md",
    """### Aggiunto

""",
    """### Aggiunto

- cambio forma temporaneo nel Battle Companion per i Pokémon che si trasformano durante la lotta, con stato separato dalla forma salvata nella squadra;\n- forme Attacco, Difesa e Velocità di Deoxys con asset dedicati e regole 5e di Mutante;\n
""",
)
replace_once(
    "CHANGELOG.md",
    """### Modificato

""",
    """### Modificato

- eliminato il duplicato tra forma Base e forma predefinita nei selettori, incluso Deoxys Forma Normale;\n
""",
)

# Basic JSON validation before handing control back to Flutter CI.
for json_path in [
    "assets/data/pokemon/Deoxys.json",
    "assets/data/pokemon/Aegislash.json",
    "assets/data/pokemon/Darmanitan.json",
]:
    json.loads((ROOT / json_path).read_text(encoding="utf-8"))

print("Battle form switching changes applied successfully.")
