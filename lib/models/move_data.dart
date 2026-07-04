class MoveData {
  const MoveData({
    required this.name,
    required this.type,
    required this.pp,
    required this.range,
    required this.duration,
    required this.moveTime,
    required this.description,
    required this.scaling,
    required this.damageByLevel,
    required this.movePowers,
    required this.isAttack,
    required this.save,
  });

  final String name;
  final String type;
  final String pp;
  final String range;
  final String duration;
  final String moveTime;
  final String description;
  final String? scaling;
  final Map<int, MoveDamage> damageByLevel;
  final List<String> movePowers;
  final bool isAttack;
  final String? save;

  factory MoveData.fromJson(String name, Map<String, dynamic> json) {
    final damageJson = Map<String, dynamic>.from(json['Damage'] ?? {});

    return MoveData(
      name: name,
      type: json['Type']?.toString() ?? 'Typeless',
      pp: json['PP']?.toString() ?? '-',
      range: json['Range']?.toString() ?? '-',
      duration: json['Duration']?.toString() ?? '-',
      moveTime: json['Move Time']?.toString() ?? '-',
      description: json['Description']?.toString() ?? '',
      scaling: json['Scaling']?.toString(),
      damageByLevel: damageJson.map(
        (key, value) => MapEntry(
          int.parse(key),
          MoveDamage.fromJson(Map<String, dynamic>.from(value)),
        ),
      ),
      movePowers: List<String>.from(json['Move Power'] ?? []),
      isAttack: json['atk'] == true,
      save: json['Save']?.toString(),
    );
  }

  MoveDamage? damageForLevel(int level) {
    MoveDamage? selected;

    for (final entry in damageByLevel.entries) {
      if (level >= entry.key) {
        selected = entry.value;
      }
    }

    return selected;
  }
}

class MoveDamage {
  const MoveDamage({
    required this.amount,
    required this.diceMax,
    required this.isMoveDamage,
  });

  final int amount;
  final int diceMax;
  final bool isMoveDamage;

  factory MoveDamage.fromJson(Map<String, dynamic> json) {
    return MoveDamage(
      amount: json['amount'] ?? 0,
      diceMax: json['dice_max'] ?? 0,
      isMoveDamage: json['move'] == true,
    );
  }

  String get label {
    if (diceMax <= 1) return amount.toString();
    return '${amount}d$diceMax';
  }
}
