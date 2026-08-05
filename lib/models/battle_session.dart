import 'battle_environment.dart';
import 'battle_transformation.dart';
import 'team_slot.dart';

class BattleSession {
  const BattleSession({
    required this.profileId,
    required this.round,
    required this.turnIndex,
    required this.activeSlotIndex,
    required this.pokemonStates,
    required this.initiativeEntries,
    this.environment = const BattleEnvironment(),
    required this.updatedAt,
  });

  final String profileId;
  final int round;
  final int turnIndex;
  final int? activeSlotIndex;
  final Map<int, BattlePokemonState> pokemonStates;
  final List<BattleInitiativeEntry> initiativeEntries;
  final BattleEnvironment environment;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'round': round,
      'turnIndex': turnIndex,
      'activeSlotIndex': activeSlotIndex,
      'pokemonStates': pokemonStates.values
          .map((state) => state.toJson())
          .toList(growable: false),
      'initiativeEntries': initiativeEntries
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'environment': environment.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BattleSession.fromJson(Map<String, dynamic> json) {
    final states = <int, BattlePokemonState>{};
    for (final value in List<dynamic>.from(json['pokemonStates'] ?? const [])) {
      if (value is! Map) continue;
      final state = BattlePokemonState.fromJson(
        Map<String, dynamic>.from(value),
      );
      states[state.slotIndex] = state;
    }

    return BattleSession(
      profileId: json['profileId']?.toString() ?? '',
      round: _readInt(json['round'], fallback: 1).clamp(1, 9999).toInt(),
      turnIndex: _readInt(json['turnIndex']).clamp(0, 9999).toInt(),
      activeSlotIndex: _readNullableInt(json['activeSlotIndex']),
      pokemonStates: states,
      initiativeEntries: [
        for (final value in List<dynamic>.from(
          json['initiativeEntries'] ?? const [],
        ))
          if (value is Map)
            BattleInitiativeEntry.fromJson(Map<String, dynamic>.from(value)),
      ],
      environment: json['environment'] is Map
          ? BattleEnvironment.fromJson(
              Map<String, dynamic>.from(json['environment'] as Map),
            )
          : const BattleEnvironment(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class BattlePokemonState {
  const BattlePokemonState({
    required this.slotIndex,
    required this.pokemonId,
    required this.identityKey,
    required this.remainingPp,
    required this.volatileStatuses,
    this.battleFormName,
    this.temporaryHp = 0,
    this.temporaryHpEnabled = false,
    this.temporaryHpInitialized = false,
    this.transformation,
  });

  final int slotIndex;
  final int pokemonId;
  final String identityKey;
  final Map<String, int> remainingPp;
  final Set<String> volatileStatuses;
  final String? battleFormName;
  final int temporaryHp;
  final bool temporaryHpEnabled;
  final bool temporaryHpInitialized;
  final BattleTransformationState? transformation;

  bool matches(TeamSlot slot) {
    return slot.slotIndex == slotIndex &&
        slot.pokemonId == pokemonId &&
        identityKey == identityKeyFor(slot);
  }

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'pokemonId': pokemonId,
      'identityKey': identityKey,
      'remainingPp': remainingPp,
      'volatileStatuses': volatileStatuses.toList(growable: false),
      'battleFormName': battleFormName,
      'temporaryHp': temporaryHp,
      'temporaryHpEnabled': temporaryHpEnabled,
      'temporaryHpInitialized': temporaryHpInitialized,
      'transformation': transformation?.toJson(),
    };
  }

  factory BattlePokemonState.fromJson(Map<String, dynamic> json) {
    return BattlePokemonState(
      slotIndex: _readInt(json['slotIndex']),
      pokemonId: _readInt(json['pokemonId']),
      identityKey: json['identityKey']?.toString() ?? '',
      remainingPp: {
        for (final entry in Map<dynamic, dynamic>.from(
          json['remainingPp'] ?? const {},
        ).entries)
          entry.key.toString(): _readInt(entry.value),
      },
      volatileStatuses: Set<String>.from(
        List<dynamic>.from(
          json['volatileStatuses'] ?? const [],
        ).map((value) => value.toString()),
      ),
      battleFormName: json['battleFormName']?.toString(),
      temporaryHp: _readInt(json['temporaryHp']).clamp(0, 9999).toInt(),
      temporaryHpEnabled: json['temporaryHpEnabled'] == true,
      temporaryHpInitialized: json['temporaryHpInitialized'] == true,
      transformation: json['transformation'] is Map
          ? BattleTransformationState.fromJson(
              Map<String, dynamic>.from(json['transformation'] as Map),
            )
          : null,
    );
  }

  static String identityKeyFor(TeamSlot slot) {
    final moves = [...slot.selectedMoves]..sort();
    return [
      slot.pokemonId?.toString() ?? '',
      slot.nickname?.trim().toLowerCase() ?? '',
      slot.formName?.trim().toLowerCase() ?? '',
      slot.gender?.trim().toLowerCase() ?? '',
      slot.isShiny ? 'shiny' : 'normal',
      slot.nature.trim().toLowerCase(),
      moves.join('|').toLowerCase(),
    ].join('::');
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BattleInitiativeEntry {
  const BattleInitiativeEntry({
    required this.id,
    required this.name,
    required this.initiative,
    required this.isTrainerGroup,
  });

  final String id;
  final String name;
  final int initiative;
  final bool isTrainerGroup;

  BattleInitiativeEntry copyWith({String? name, int? initiative}) {
    return BattleInitiativeEntry(
      id: id,
      name: name ?? this.name,
      initiative: initiative ?? this.initiative,
      isTrainerGroup: isTrainerGroup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initiative': initiative,
      'isTrainerGroup': isTrainerGroup,
    };
  }

  factory BattleInitiativeEntry.fromJson(Map<String, dynamic> json) {
    return BattleInitiativeEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Partecipante',
      initiative: _readInt(json['initiative']),
      isTrainerGroup: json['isTrainerGroup'] == true,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
