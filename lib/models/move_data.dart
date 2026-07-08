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
    this.higherLevels,
    this.damageModifier,
    this.damageTypes = const [],
    this.attackScope,
    this.tmNumber,
    this.tmCost,
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
  final String? higherLevels;
  final String? damageModifier;
  final List<String> damageTypes;
  final String? attackScope;
  final int? tmNumber;
  final int? tmCost;

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
      movePowers: _normalizePowers(json['Move Power']),
      isAttack: json['atk'] == true,
      save: json['Save']?.toString(),
    );
  }

  factory MoveData.fromWebJson(Map<String, dynamic> json) {
    final damage = json['damage'];
    final damageMap = damage is Map ? Map<String, dynamic>.from(damage) : null;
    final diceMap = damageMap == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(damageMap['dice'] ?? const {});
    final attack = json['attack'];
    final attackMap = attack is Map ? Map<String, dynamic>.from(attack) : null;
    final save = json['save'];
    final saveMap = save is Map ? Map<String, dynamic>.from(save) : null;
    final tm = json['tm'];
    final tmMap = tm is Map ? Map<String, dynamic>.from(tm) : null;
    final higherLevels = json['higherLevels']?.toString();

    return MoveData(
      name: json['name']?.toString() ?? 'Mossa sconosciuta',
      type: _titleCase(json['type']?.toString() ?? 'Typeless'),
      pp: json['pp']?.toString() ?? '-',
      range: json['range']?.toString() ?? '-',
      duration: json['duration']?.toString() ?? '-',
      moveTime: json['time']?.toString() ?? '-',
      description: _readDescription(
        json['description'],
        higherLevels: higherLevels,
      ),
      scaling: higherLevels,
      higherLevels: higherLevels,
      damageByLevel: diceMap.map(
        (key, value) => MapEntry(
          int.tryParse(key) ?? 1,
          MoveDamage.fromDiceString(value?.toString() ?? ''),
        ),
      ),
      movePowers: _normalizePowers(json['power']),
      isAttack: attackMap != null,
      attackScope: attackMap?['scope']?.toString(),
      save: _readSave(saveMap),
      damageModifier: damageMap?['modifier']?.toString(),
      damageTypes: _readStringList(damageMap?['type'])
          .map(_titleCase)
          .toList(growable: false),
      tmNumber: _readInt(tmMap?['id']),
      tmCost: _readInt(tmMap?['cost']),
    );
  }

  MoveDamage? damageForLevel(int level) {
    MoveDamage? selected;

    final entries = damageByLevel.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      if (level >= entry.key) {
        selected = entry.value;
      }
    }

    return selected;
  }

  static List<String> _normalizePowers(dynamic value) {
    return _readStringList(value)
        .where((power) => power.toLowerCase() != 'none')
        .map((power) => power.toUpperCase())
        .toList(growable: false);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return const [];
  }

  static String _readDescription(dynamic value, {String? higherLevels}) {
    final parts = <String>[];

    if (value is String && value.trim().isNotEmpty) {
      parts.add(value.trim());
    } else if (value is List) {
      parts.addAll(
        value
            .map(_descriptionBlockToText)
            .where((entry) => entry.trim().isNotEmpty),
      );
    }

    if (higherLevels != null && higherLevels.trim().isNotEmpty) {
      parts.add('Livelli superiori: ${higherLevels.trim()}');
    }

    return parts.join('\n\n');
  }

  static String _descriptionBlockToText(dynamic block) {
    if (block is String) return block;

    if (block is Map) {
      final map = Map<String, dynamic>.from(block);
      if (map['type'] == 'table') {
        final headers = _readStringList(map['headers']);
        final rows = map['rows'];
        final lines = <String>[];

        if (headers.isNotEmpty) {
          lines.add(headers.join(' | '));
        }

        if (rows is List) {
          for (final row in rows) {
            lines.add(_readStringList(row).join(' | '));
          }
        }

        return lines.join('\n');
      }

      return map.values.map((value) => value.toString()).join(' ');
    }

    return block?.toString() ?? '';
  }

  static String? _readSave(Map<String, dynamic>? saveMap) {
    if (saveMap == null) return null;

    final attributes = _readStringList(saveMap['attribute'])
        .map((attribute) => attribute.toUpperCase())
        .toList(growable: false);
    if (attributes.isEmpty) return 'SAVE';

    return attributes.join('/');
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _titleCase(String value) {
    return value
        .trim()
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
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

  factory MoveDamage.fromDiceString(String value) {
    final normalized = value.trim().toLowerCase();
    final diceMatch = RegExp(r'^(\d+)d(\d+)$').firstMatch(normalized);

    if (diceMatch != null) {
      return MoveDamage(
        amount: int.tryParse(diceMatch.group(1) ?? '') ?? 0,
        diceMax: int.tryParse(diceMatch.group(2) ?? '') ?? 0,
        isMoveDamage: true,
      );
    }

    return MoveDamage(
      amount: int.tryParse(normalized) ?? 0,
      diceMax: 1,
      isMoveDamage: true,
    );
  }

  String get label {
    if (diceMax <= 1) return amount.toString();
    return '${amount}d$diceMax';
  }
}
