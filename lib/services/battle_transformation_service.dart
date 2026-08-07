import '../models/bag_inventory_entry.dart';
import '../models/battle_transformation.dart';
import '../models/move_data.dart';
import '../models/team_slot.dart';
import '../localization/ui_text.dart';

class TransformationEligibility {
  const TransformationEligibility({
    required this.kind,
    required this.isAvailable,
    required this.missingRequirements,
  });

  final BattleTransformationKind kind;
  final bool isAvailable;
  final List<String> missingRequirements;
}

class ZCrystalInfo {
  const ZCrystalInfo({required this.itemId, required this.type});

  final String itemId;
  final String type;
}

class BattleTransformationService {
  const BattleTransformationService._();

  static const List<String> teraTypes = [
    'Normal',
    'Fighting',
    'Flying',
    'Poison',
    'Ground',
    'Rock',
    'Bug',
    'Ghost',
    'Steel',
    'Fire',
    'Water',
    'Grass',
    'Electric',
    'Psychic',
    'Ice',
    'Dragon',
    'Dark',
    'Fairy',
    'Stellar',
  ];

  static const Map<String, String> _zCrystalTypes = {
    'normalium-z': 'Normal',
    'fightinium-z': 'Fighting',
    'flyinium-z': 'Flying',
    'poisonium-z': 'Poison',
    'groundium-z': 'Ground',
    'rockium-z': 'Rock',
    'buginium-z': 'Bug',
    'ghostium-z': 'Ghost',
    'steelium-z': 'Steel',
    'firium-z': 'Fire',
    'waterium-z': 'Water',
    'grassium-z': 'Grass',
    'electrium-z': 'Electric',
    'psychium-z': 'Psychic',
    'icium-z': 'Ice',
    'dragonium-z': 'Dragon',
    'darkinium-z': 'Dark',
    'fairium-z': 'Fairy',
  };

  static TransformationEligibility eligibility({
    required BattleTransformationKind kind,
    required int pokemonLevel,
    required bool isFinalEvolutionStage,
    required String? heldItemId,
    required Iterable<BagInventoryEntry> inventory,
    required Set<String> trainerUses,
    required bool pokemonAlreadyTransformed,
    required bool hasActiveTransformation,
    Iterable<MoveData> knownMoves = const [],
  }) {
    final missing = <String>[];
    final inventoryIds = inventory
        .where((entry) => entry.quantity > 0)
        .map((entry) => _key(entry.itemId))
        .toSet();
    final heldKey = _key(heldItemId ?? '');

    if (hasActiveTransformation) {
      missing.add(
        uiTextForLanguage(
          'Il Pokémon ha già una trasformazione attiva',
          'The Pokémon already has an active transformation',
        ),
      );
    }
    if (pokemonAlreadyTransformed) {
      missing.add(
        uiTextForLanguage(
          'Questo Pokémon ha già usato una trasformazione dopo l’ultimo riposo lungo',
          'This Pokémon has already used a transformation since the last long rest',
        ),
      );
    }
    if (trainerUses.contains(kind.trainerUseId)) {
      missing.add(
        uiTextForLanguage(
          'L’Allenatore ha già usato ${_trainerUseLabel(kind)} dopo l’ultimo riposo lungo',
          'The Trainer has already used ${_trainerUseLabel(kind)} since the last long rest',
        ),
      );
    }

    switch (kind) {
      case BattleTransformationKind.mega:
        if (!isFinalEvolutionStage) {
          missing.add(
            uiTextForLanguage(
              'Richiede lo stadio evolutivo finale',
              'Requires the final evolution stage',
            ),
          );
        }
        if (pokemonLevel < 10) {
          missing.add(
            uiTextForLanguage('Richiede livello 10', 'Requires level 10'),
          );
        }
        if (heldKey != 'megalite-stone') {
          missing.add(
            uiTextForLanguage(
              'Il Pokémon deve tenere Megalite Stone',
              'The Pokémon must hold a Megalite Stone',
            ),
          );
        }
        if (!inventoryIds.contains('key-stone')) {
          missing.add(
            uiTextForLanguage(
              'Richiede una Pietrachiave nello Zaino',
              'Requires a Key Stone in the Bag',
            ),
          );
        }
        break;
      case BattleTransformationKind.zMove:
        if (pokemonLevel < 6) {
          missing.add(
            uiTextForLanguage('Richiede livello 6', 'Requires level 6'),
          );
        }
        final crystal = zCrystalForHeldItem(heldItemId);
        if (crystal == null) {
          missing.add(
            uiTextForLanguage(
              'Il Pokémon deve tenere un Cristallo Z',
              'The Pokémon must hold a Z-Crystal',
            ),
          );
        } else if (!knownMoves.any(
          (move) => _key(move.type) == _key(crystal.type),
        )) {
          missing.add(
            uiTextForLanguage(
              'Nessuna mossa conosciuta corrisponde al Cristallo Z',
              'No known move matches the Z-Crystal',
            ),
          );
        }
        if (!inventoryIds.contains('z-ring')) {
          missing.add(
            uiTextForLanguage(
              'Richiede un Cerchio Z nello Zaino',
              'Requires a Z-Ring in the Bag',
            ),
          );
        }
        break;
      case BattleTransformationKind.dynamax:
      case BattleTransformationKind.gigamax:
        if (pokemonLevel < 10) {
          missing.add(
            uiTextForLanguage('Richiede livello 10', 'Requires level 10'),
          );
        }
        if (!inventoryIds.contains('dynamax-band')) {
          missing.add(
            uiTextForLanguage(
              'Richiede un Polsino Dynamax nello Zaino',
              'Requires a Dynamax Band in the Bag',
            ),
          );
        }
        break;
      case BattleTransformationKind.terastal:
        if (pokemonLevel < 6) {
          missing.add(
            uiTextForLanguage('Richiede livello 6', 'Requires level 6'),
          );
        }
        if (!inventoryIds.contains('tera-orb')) {
          missing.add(
            uiTextForLanguage(
              'Richiede una Terasfera nello Zaino',
              'Requires a Tera Orb in the Bag',
            ),
          );
        }
        break;
    }

    return TransformationEligibility(
      kind: kind,
      isAvailable: missing.isEmpty,
      missingRequirements: missing,
    );
  }

  static ZCrystalInfo? zCrystalForHeldItem(String? heldItemId) {
    final key = _key(heldItemId ?? '');
    final type = _zCrystalTypes[key];
    return type == null ? null : ZCrystalInfo(itemId: key, type: type);
  }

  static List<MoveData> compatibleZMoves({
    required String? heldItemId,
    required Iterable<MoveData> knownMoves,
  }) {
    final crystal = zCrystalForHeldItem(heldItemId);
    if (crystal == null) return const [];
    return knownMoves
        .where((move) => _key(move.type) == _key(crystal.type))
        .toList(growable: false);
  }

  static String pokemonUsageKey(TeamSlot slot) {
    final nickname = _key(slot.nickname ?? '');
    return '${slot.slotIndex}:${slot.pokemonId ?? 0}:$nickname';
  }

  static bool isDynamaxLike(BattleTransformationState? state) =>
      state?.isDynamaxLike == true;

  static int megaModifier(int modifier, BattleTransformationState? state) {
    return state?.kind == BattleTransformationKind.mega
        ? modifier * 2
        : modifier;
  }

  static int armorClassBonus(BattleTransformationState? state) {
    return state?.kind == BattleTransformationKind.mega ? 2 : 0;
  }

  static String effectSummary(BattleTransformationState state) {
    switch (state.kind) {
      case BattleTransformationKind.mega:
        return uiTextForLanguage(
          'CA +2; raddoppia i modificatori di caratteristica per attacchi, danni, tiri salvezza e CD.',
          'AC +2; doubles ability modifiers for attacks, damage, saving throws and DCs.',
        );
      case BattleTransformationKind.zMove:
        return uiTextForLanguage(
          'La Mossa Z non manca; CD +5; raddoppia dadi di danno/guarigione e bonus MOVE.',
          'The Z-Move cannot miss; DC +5; doubles damage/healing dice and MOVE bonus.',
        );
      case BattleTransformationKind.dynamax:
      case BattleTransformationKind.gigamax:
        return uiTextForLanguage(
          'Taglia Gargantuan, immunità agli status volatili, niente cambio e tiri di danno due volte.',
          'Gargantuan size, immunity to volatile conditions, no switching, and damage rolls are made twice.',
        );
      case BattleTransformationKind.terastal:
        return uiTextForLanguage(
          'Il tipo diventa ${state.teraType ?? 'Tera'}; conserva lo STAB originale ed è vulnerabile a Stellar.',
          'Type becomes ${state.teraType ?? 'Tera'}; keeps its original STAB and is vulnerable to Stellar.',
        );
    }
  }

  static String zMoveSummary(MoveData move) {
    final parts = <String>[uiTextForLanguage('non può mancare', 'cannot miss')];
    if (move.save != null) parts.add(uiTextForLanguage('CD +5', 'DC +5'));
    if (move.damageByLevel.isNotEmpty) {
      parts.add(uiTextForLanguage('dadi di danno ×2', 'damage dice ×2'));
    }
    if (_key(move.damageModifier ?? '') == 'move') {
      parts.add(uiTextForLanguage('bonus MOVE ×2', 'MOVE bonus ×2'));
    }
    return parts.join(' · ');
  }

  static String _trainerUseLabel(BattleTransformationKind kind) {
    return switch (kind) {
      BattleTransformationKind.mega => uiTextForLanguage(
        'la Mega Evoluzione',
        'Mega Evolution',
      ),
      BattleTransformationKind.zMove => uiTextForLanguage(
        'una Mossa Z',
        'a Z-Move',
      ),
      BattleTransformationKind.dynamax => uiTextForLanguage(
        'Dynamax/Gigamax',
        'Dynamax/Gigantamax',
      ),
      BattleTransformationKind.gigamax => uiTextForLanguage(
        'Dynamax/Gigamax',
        'Dynamax/Gigantamax',
      ),
      BattleTransformationKind.terastal => uiTextForLanguage(
        'la Teracristallizzazione',
        'Terastallization',
      ),
    };
  }

  static String _key(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
