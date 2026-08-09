import '../localization/ui_text.dart';

enum BattleTransformationKind {
  mega,
  zMove,
  dynamax,
  gigamax,
  terastal;

  String get id => switch (this) {
    BattleTransformationKind.mega => 'mega',
    BattleTransformationKind.zMove => 'z-move',
    BattleTransformationKind.dynamax => 'dynamax',
    BattleTransformationKind.gigamax => 'gigamax',
    BattleTransformationKind.terastal => 'terastal',
  };

  String get trainerUseId => switch (this) {
    BattleTransformationKind.gigamax => 'dynamax',
    _ => id,
  };

  String get label => switch (this) {
    BattleTransformationKind.mega => uiTextForLanguage(
      'Mega Evoluzione',
      'Mega Evolution',
    ),
    BattleTransformationKind.zMove => uiTextForLanguage('Mossa Z', 'Z-Move'),
    BattleTransformationKind.dynamax => 'Dynamax',
    BattleTransformationKind.gigamax => uiTextForLanguage(
      'Gigamax',
      'Gigantamax',
    ),
    BattleTransformationKind.terastal => uiTextForLanguage(
      'Teracristal',
      'Terastallization',
    ),
  };

  static BattleTransformationKind? fromId(String? value) {
    for (final kind in BattleTransformationKind.values) {
      if (kind.id == value) return kind;
    }
    return null;
  }
}

class BattleTransformationState {
  const BattleTransformationState({
    required this.kind,
    this.formIdentifier,
    this.teraType,
    this.dynamaxTemporaryHp = 0,
    this.zMoveReference,
  });

  final BattleTransformationKind kind;
  final String? formIdentifier;
  final String? teraType;
  final int dynamaxTemporaryHp;
  final String? zMoveReference;

  bool get isDynamaxLike =>
      kind == BattleTransformationKind.dynamax ||
      kind == BattleTransformationKind.gigamax;

  BattleTransformationState copyWith({
    String? formIdentifier,
    String? teraType,
    int? dynamaxTemporaryHp,
    String? zMoveReference,
  }) {
    return BattleTransformationState(
      kind: kind,
      formIdentifier: formIdentifier ?? this.formIdentifier,
      teraType: teraType ?? this.teraType,
      dynamaxTemporaryHp: dynamaxTemporaryHp ?? this.dynamaxTemporaryHp,
      zMoveReference: zMoveReference ?? this.zMoveReference,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.id,
    'formIdentifier': formIdentifier,
    'teraType': teraType,
    'dynamaxTemporaryHp': dynamaxTemporaryHp,
    'zMoveReference': zMoveReference,
  };

  factory BattleTransformationState.fromJson(Map<String, dynamic> json) {
    final kind = BattleTransformationKind.fromId(json['kind']?.toString());
    if (kind == null) {
      throw FormatException(
        uiTextForLanguage(
          'Trasformazione di battaglia non valida.',
          'Invalid battle transformation.',
        ),
      );
    }
    return BattleTransformationState(
      kind: kind,
      formIdentifier: _nullableText(json['formIdentifier']),
      teraType: _nullableText(json['teraType']),
      dynamaxTemporaryHp: _readInt(
        json['dynamaxTemporaryHp'],
      ).clamp(0, 9999).toInt(),
      zMoveReference: _nullableText(json['zMoveReference']),
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
