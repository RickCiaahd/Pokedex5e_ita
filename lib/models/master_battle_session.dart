import 'battle_session.dart';
import 'saved_npc_trainer.dart';

class MasterBattlePokemonState {
  const MasterBattlePokemonState({
    required this.slotIndex,
    required this.pokemon,
    required this.currentHp,
    this.nonVolatileStatus,
    this.volatileStatuses = const {},
    this.remainingPp = const {},
  });

  final int slotIndex;
  final SavedNpcPokemon pokemon;
  final int currentHp;
  final String? nonVolatileStatus;
  final Set<String> volatileStatuses;
  final Map<String, int> remainingPp;

  bool get isFainted => currentHp <= 0;

  MasterBattlePokemonState copyWith({
    int? currentHp,
    Object? nonVolatileStatus = _unset,
    Set<String>? volatileStatuses,
    Map<String, int>? remainingPp,
  }) {
    return MasterBattlePokemonState(
      slotIndex: slotIndex,
      pokemon: pokemon,
      currentHp: currentHp ?? this.currentHp,
      nonVolatileStatus: identical(nonVolatileStatus, _unset)
          ? this.nonVolatileStatus
          : nonVolatileStatus as String?,
      volatileStatuses: volatileStatuses ?? this.volatileStatuses,
      remainingPp: remainingPp ?? this.remainingPp,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotIndex': slotIndex,
    'pokemon': pokemon.toJson(),
    'currentHp': currentHp,
    'nonVolatileStatus': nonVolatileStatus,
    'volatileStatuses': volatileStatuses.toList(growable: false),
    'remainingPp': remainingPp,
  };

  factory MasterBattlePokemonState.fromJson(Map<String, dynamic> json) {
    final pokemonJson = json['pokemon'] is Map
        ? Map<String, dynamic>.from(json['pokemon'] as Map)
        : const <String, dynamic>{};
    final pokemon = SavedNpcPokemon.fromJson(pokemonJson);
    return MasterBattlePokemonState(
      slotIndex: _readInt(json['slotIndex']),
      pokemon: pokemon,
      currentHp: _readInt(json['currentHp'], fallback: pokemon.maxHp)
          .clamp(0, pokemon.maxHp)
          .toInt(),
      nonVolatileStatus: _readNullableString(json['nonVolatileStatus']),
      volatileStatuses: {
        for (final value in _readList(json['volatileStatuses'])) value.toString(),
      },
      remainingPp: {
        for (final entry in Map<dynamic, dynamic>.from(
          json['remainingPp'] is Map ? json['remainingPp'] as Map : const {},
        ).entries)
          entry.key.toString(): _readInt(entry.value),
      },
    );
  }

  static const Object _unset = Object();
}

class MasterBattleParticipant {
  const MasterBattleParticipant({
    required this.trainerId,
    required this.name,
    required this.epithet,
    required this.rank,
    required this.tactics,
    required this.personality,
    required this.rewardMoney,
    required this.rewards,
    required this.activeLimit,
    required this.activeSlotIndices,
    required this.team,
  });

  final String trainerId;
  final String name;
  final String epithet;
  final String rank;
  final String tactics;
  final String personality;
  final int rewardMoney;
  final List<String> rewards;
  final int activeLimit;
  final Set<int> activeSlotIndices;
  final List<MasterBattlePokemonState> team;

  String get displayName => '$name, $epithet';

  MasterBattleParticipant copyWith({
    int? activeLimit,
    Set<int>? activeSlotIndices,
    List<MasterBattlePokemonState>? team,
  }) {
    return MasterBattleParticipant(
      trainerId: trainerId,
      name: name,
      epithet: epithet,
      rank: rank,
      tactics: tactics,
      personality: personality,
      rewardMoney: rewardMoney,
      rewards: rewards,
      activeLimit: activeLimit ?? this.activeLimit,
      activeSlotIndices: activeSlotIndices ?? this.activeSlotIndices,
      team: team ?? this.team,
    );
  }

  Map<String, dynamic> toJson() => {
    'trainerId': trainerId,
    'name': name,
    'epithet': epithet,
    'rank': rank,
    'tactics': tactics,
    'personality': personality,
    'rewardMoney': rewardMoney,
    'rewards': rewards,
    'activeLimit': activeLimit,
    'activeSlotIndices': activeSlotIndices.toList(growable: false),
    'team': team.map((pokemon) => pokemon.toJson()).toList(growable: false),
  };

  factory MasterBattleParticipant.fromJson(Map<String, dynamic> json) {
    final team = [
      for (final value in _readList(json['team']))
        if (value is Map)
          MasterBattlePokemonState.fromJson(Map<String, dynamic>.from(value)),
    ];
    final safeLimit = _readInt(json['activeLimit'], fallback: 1)
        .clamp(1, team.isEmpty ? 1 : team.length)
        .toInt();
    final active = {
      for (final value in _readList(json['activeSlotIndices']))
        _readInt(value),
    }.where((slot) => team.any((pokemon) => pokemon.slotIndex == slot)).toSet();
    if (active.isEmpty && team.isNotEmpty) active.add(team.first.slotIndex);
    while (active.length > safeLimit) active.remove(active.last);

    return MasterBattleParticipant(
      trainerId: json['trainerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Allenatore PNG',
      epithet: json['epithet']?.toString() ?? 'Allenatore',
      rank: json['rank']?.toString() ?? 'Comune',
      tactics: json['tactics']?.toString() ?? '',
      personality: json['personality']?.toString() ?? '',
      rewardMoney: _readInt(json['rewardMoney']),
      rewards: [for (final value in _readList(json['rewards'])) value.toString()],
      activeLimit: safeLimit,
      activeSlotIndices: active,
      team: team,
    );
  }
}

class MasterBattleSession {
  const MasterBattleSession({
    required this.profileId,
    required this.id,
    required this.round,
    required this.turnIndex,
    required this.selectedTrainerId,
    required this.focusedSlotIndex,
    required this.participants,
    required this.initiativeEntries,
    required this.updatedAt,
  });

  final String profileId;
  final String id;
  final int round;
  final int turnIndex;
  final String selectedTrainerId;
  final int? focusedSlotIndex;
  final List<MasterBattleParticipant> participants;
  final List<BattleInitiativeEntry> initiativeEntries;
  final DateTime updatedAt;

  bool get isValid =>
      profileId.trim().isNotEmpty &&
      id.trim().isNotEmpty &&
      participants.isNotEmpty &&
      participants.every(
        (participant) =>
            participant.trainerId.trim().isNotEmpty && participant.team.isNotEmpty,
      );

  MasterBattleSession copyWith({
    int? round,
    int? turnIndex,
    String? selectedTrainerId,
    Object? focusedSlotIndex = _unset,
    List<MasterBattleParticipant>? participants,
    List<BattleInitiativeEntry>? initiativeEntries,
    DateTime? updatedAt,
  }) {
    return MasterBattleSession(
      profileId: profileId,
      id: id,
      round: round ?? this.round,
      turnIndex: turnIndex ?? this.turnIndex,
      selectedTrainerId: selectedTrainerId ?? this.selectedTrainerId,
      focusedSlotIndex: identical(focusedSlotIndex, _unset)
          ? this.focusedSlotIndex
          : focusedSlotIndex as int?,
      participants: participants ?? this.participants,
      initiativeEntries: initiativeEntries ?? this.initiativeEntries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'id': id,
    'round': round,
    'turnIndex': turnIndex,
    'selectedTrainerId': selectedTrainerId,
    'focusedSlotIndex': focusedSlotIndex,
    'participants': participants
        .map((participant) => participant.toJson())
        .toList(growable: false),
    'initiativeEntries': initiativeEntries
        .map((entry) => entry.toJson())
        .toList(growable: false),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MasterBattleSession.fromJson(Map<String, dynamic> json) {
    final participants = [
      for (final value in _readList(json['participants']))
        if (value is Map)
          MasterBattleParticipant.fromJson(Map<String, dynamic>.from(value)),
    ];
    final selected = json['selectedTrainerId']?.toString() ?? '';
    final selectedTrainerId = participants.any(
      (participant) => participant.trainerId == selected,
    )
        ? selected
        : participants.isEmpty
            ? ''
            : participants.first.trainerId;
    final initiative = [
      for (final value in _readList(json['initiativeEntries']))
        if (value is Map)
          BattleInitiativeEntry.fromJson(Map<String, dynamic>.from(value)),
    ];
    return MasterBattleSession(
      profileId: json['profileId']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      round: _readInt(json['round'], fallback: 1).clamp(1, 9999).toInt(),
      turnIndex: initiative.isEmpty
          ? 0
          : _readInt(json['turnIndex'])
              .clamp(0, initiative.length - 1)
              .toInt(),
      selectedTrainerId: selectedTrainerId,
      focusedSlotIndex: _readNullableInt(json['focusedSlotIndex']),
      participants: participants,
      initiativeEntries: initiative,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static const Object _unset = Object();
}

List<dynamic> _readList(dynamic value) =>
    value is List ? List<dynamic>.from(value) : const <dynamic>[];

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
