class MoveData {
  const MoveData({
    required this.id,
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
    this.sourceName,
  });

  final String id;
  final String name;
  final String? sourceName;
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

  String get technicalName {
    final value = sourceName?.trim();
    return value == null || value.isEmpty ? name : value;
  }

  MoveData copyWith({String? type}) {
    return MoveData(
      id: id,
      name: name,
      sourceName: sourceName,
      type: type ?? this.type,
      pp: pp,
      range: range,
      duration: duration,
      moveTime: moveTime,
      description: description,
      scaling: scaling,
      higherLevels: higherLevels,
      damageByLevel: damageByLevel,
      movePowers: movePowers,
      isAttack: isAttack,
      save: save,
      damageModifier: damageModifier,
      damageTypes: damageTypes,
      attackScope: attackScope,
      tmNumber: tmNumber,
      tmCost: tmCost,
    );
  }

  factory MoveData.fromJson(
    String name,
    Map<String, dynamic> json, {
    bool localizeToItalian = true,
  }) {
    final damageJson = Map<String, dynamic>.from(json['Damage'] ?? {});

    return MoveData(
      id: referenceKey(name),
      name: name,
      type: json['Type']?.toString() ?? 'Typeless',
      pp: json['PP']?.toString() ?? '-',
      range: _metadataText(
        json['Range']?.toString() ?? '-',
        localizeToItalian: localizeToItalian,
      ),
      duration: _metadataText(
        json['Duration']?.toString() ?? '-',
        localizeToItalian: localizeToItalian,
      ),
      moveTime: _metadataText(
        json['Move Time']?.toString() ?? '-',
        localizeToItalian: localizeToItalian,
      ),
      description: _visibleText(
        json['Description']?.toString() ?? '',
        localizeToItalian: localizeToItalian,
      ),
      scaling: _nullableText(
        json['Scaling']?.toString(),
        localizeToItalian: localizeToItalian,
      ),
      damageByLevel: damageJson.map(
        (key, value) => MapEntry(
          int.parse(key),
          MoveDamage.fromJson(Map<String, dynamic>.from(value)),
        ),
      ),
      movePowers: _normalizePowers(json['Move Power']),
      isAttack: json['atk'] == true,
      save: localizeToItalian
          ? _localizeSave(json['Save']?.toString())
          : _normalizedNullableText(json['Save']?.toString()),
    );
  }

  factory MoveData.fromWebJson(
    Map<String, dynamic> json, {
    bool localizeToItalian = true,
  }) {
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
    final higherLevels = _nullableText(
      json['higherLevels']?.toString(),
      localizeToItalian: localizeToItalian,
    );
    final name = json['name']?.toString() ?? 'Mossa sconosciuta';

    return MoveData(
      id: json['id']?.toString() ?? referenceKey(name),
      name: name,
      sourceName: json['sourceName']?.toString(),
      type: _titleCase(json['type']?.toString() ?? 'Typeless'),
      pp: json['pp']?.toString() ?? '-',
      range: _metadataText(
        json['range']?.toString() ?? '-',
        localizeToItalian: localizeToItalian,
      ),
      duration: _metadataText(
        json['duration']?.toString() ?? '-',
        localizeToItalian: localizeToItalian,
      ),
      moveTime: _metadataText(
        json['time']?.toString() ?? '-',
        localizeToItalian: localizeToItalian,
      ),
      description: _readDescription(
        json['description'],
        higherLevels: higherLevels,
        localizeToItalian: localizeToItalian,
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
      save: _readSave(saveMap, localizeToItalian: localizeToItalian),
      damageModifier: damageMap?['modifier']?.toString(),
      damageTypes: _readStringList(
        damageMap?['type'],
      ).map(_titleCase).toList(growable: false),
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

  static String referenceKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
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

  static String _readDescription(
    dynamic value, {
    String? higherLevels,
    required bool localizeToItalian,
  }) {
    final parts = <String>[];

    if (value is String && value.trim().isNotEmpty) {
      parts.add(
        _visibleText(value.trim(), localizeToItalian: localizeToItalian),
      );
    } else if (value is List) {
      parts.addAll(
        value
            .map(
              (block) => _descriptionBlockToText(
                block,
                localizeToItalian: localizeToItalian,
              ),
            )
            .where((entry) => entry.trim().isNotEmpty),
      );
    }

    if (higherLevels != null && higherLevels.trim().isNotEmpty) {
      final label = localizeToItalian
          ? 'Livelli superiori'
          : 'At Higher Levels';
      parts.add('$label: ${higherLevels.trim()}');
    }

    return parts.join('\n\n');
  }

  static String _descriptionBlockToText(
    dynamic block, {
    required bool localizeToItalian,
  }) {
    if (block is String) {
      return _visibleText(block, localizeToItalian: localizeToItalian);
    }

    if (block is Map) {
      final map = Map<String, dynamic>.from(block);
      if (map['type'] == 'table') {
        final headers = _readStringList(map['headers']);
        final rows = map['rows'];
        final lines = <String>[];

        if (headers.isNotEmpty) {
          lines.add(
            headers
                .map(
                  (header) => _visibleText(
                    header,
                    localizeToItalian: localizeToItalian,
                  ),
                )
                .join(' | '),
          );
        }

        if (rows is List) {
          for (final row in rows) {
            lines.add(
              _readStringList(row)
                  .map(
                    (cell) => _visibleText(
                      cell,
                      localizeToItalian: localizeToItalian,
                    ),
                  )
                  .join(' | '),
            );
          }
        }

        return lines.join('\n');
      }

      return map.values
          .map(
            (value) => _visibleText(
              value.toString(),
              localizeToItalian: localizeToItalian,
            ),
          )
          .join(' ');
    }

    return _visibleText(
      block?.toString() ?? '',
      localizeToItalian: localizeToItalian,
    );
  }

  static String? _readSave(
    Map<String, dynamic>? saveMap, {
    required bool localizeToItalian,
  }) {
    if (saveMap == null) return null;
    final attributes = _readStringList(saveMap['attribute'])
        .map(
          (attribute) => localizeToItalian
              ? _localizeAbilityAbbreviation(attribute.toUpperCase())
              : attribute.toUpperCase(),
        )
        .toList(growable: false);
    if (attributes.isEmpty) {
      return localizeToItalian ? 'TIRO SALVEZZA' : 'SAVING THROW';
    }

    return attributes.join('/');
  }

  static String? _localizeSave(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;

    return normalized
        .split('/')
        .map((part) => _localizeAbilityAbbreviation(part.trim().toUpperCase()))
        .join('/');
  }

  static String _localizeAbilityAbbreviation(String value) {
    return const <String, String>{
          'STR': 'FOR',
          'DEX': 'DES',
          'CON': 'COS',
          'INT': 'INT',
          'WIS': 'SAG',
          'CHA': 'CAR',
          'AC': 'CA',
          'HP': 'PF',
          'DC': 'CD',
          'SAVE': 'TIRO SALVEZZA',
        }[value] ??
        value;
  }

  static String _localizeMetadata(String value) {
    var result = value.trim();
    if (result.isEmpty || result == '-') return '-';

    result = result.replaceAllMapped(
      RegExp(r'^self\s*\((\d+)\s*ft\s+radius\)$', caseSensitive: false),
      (match) => 'personale (raggio di ${match.group(1)} piedi)',
    );
    result = result.replaceAllMapped(
      RegExp(r'^self\s*\((\d+)\s*ft\s+cone\)$', caseSensitive: false),
      (match) => 'personale (cono di ${match.group(1)} piedi)',
    );

    return _localizeVisibleText(result)
        .replaceAll(RegExp(r'\bself\b', caseSensitive: false), 'personale')
        .replaceAll(RegExp(r'\bmelee\b', caseSensitive: false), 'mischia')
        .replaceAll(RegExp(r'\btouch\b', caseSensitive: false), 'contatto')
        .replaceAll(RegExp(r'\bvaries\b', caseSensitive: false), 'variabile')
        .replaceAll(RegExp(r'\bspecial\b', caseSensitive: false), 'speciale')
        .replaceAll(RegExp(r'\bminutes\b', caseSensitive: false), 'minuti')
        .replaceAll(RegExp(r'\bminute\b', caseSensitive: false), 'minuto')
        .replaceAll(RegExp(r'\bhours\b', caseSensitive: false), 'ore')
        .replaceAll(RegExp(r'\bhour\b', caseSensitive: false), 'ora');
  }

  static String _metadataText(String value, {required bool localizeToItalian}) {
    return localizeToItalian ? _localizeMetadata(value) : value.trim();
  }

  static String _visibleText(String value, {required bool localizeToItalian}) {
    return localizeToItalian ? _localizeVisibleText(value) : value;
  }

  static String? _nullableText(
    String? value, {
    required bool localizeToItalian,
  }) {
    final normalized = _normalizedNullableText(value);
    if (normalized == null) return null;
    return localizeToItalian ? _localizeVisibleText(normalized) : normalized;
  }

  static String? _normalizedNullableText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String _localizeVisibleText(String value) {
    var result = value;

    for (final replacement in <MapEntry<RegExp, String>>[
      MapEntry(
        RegExp(r'\bMove\s+DC\b', caseSensitive: false),
        'CD della mossa',
      ),
      MapEntry(
        RegExp(r'\bfree action\b', caseSensitive: false),
        'azione gratuita',
      ),
      MapEntry(
        RegExp(r'\bbonus action\b', caseSensitive: false),
        'azione bonus',
      ),
      MapEntry(RegExp(r'\breaction\b', caseSensitive: false), 'reazione'),
      MapEntry(RegExp(r'\baction\b', caseSensitive: false), 'azione'),
      MapEntry(
        RegExp(r'\bsaving throws\b', caseSensitive: false),
        'tiri salvezza',
      ),
      MapEntry(
        RegExp(r'\bsaving throw\b', caseSensitive: false),
        'tiro salvezza',
      ),
      MapEntry(RegExp(r'\bhit points\b', caseSensitive: false), 'punti ferita'),
      MapEntry(
        RegExp(r'\bArmor Class\b', caseSensitive: false),
        'Classe Armatura',
      ),
      MapEntry(
        RegExp(r'\bproficiency bonus\b', caseSensitive: false),
        'bonus di competenza',
      ),
      MapEntry(
        RegExp(r'\binstantaneous\b', caseSensitive: false),
        'istantanea',
      ),
      MapEntry(
        RegExp(r'\bconcentration\b', caseSensitive: false),
        'concentrazione',
      ),
      MapEntry(
        RegExp(r'\bBurn Drive\b', caseSensitive: false),
        'Piromodulo',
      ),
      MapEntry(
        RegExp(r'\bChill Drive\b', caseSensitive: false),
        'Gelomodulo',
      ),
      MapEntry(
        RegExp(r'\bDouse Drive\b', caseSensitive: false),
        'Idromodulo',
      ),
      MapEntry(
        RegExp(r'\bShock Drive\b', caseSensitive: false),
        'Voltmodulo',
      ),
      MapEntry(
        RegExp(r'\bMemory Disc\b', caseSensitive: false),
        'ROM',
      ),
      MapEntry(RegExp(r'\bDrive\b', caseSensitive: false), 'Modulo'),
      MapEntry(
        RegExp(r'\bTechno Blast\b', caseSensitive: false),
        'Tecnobotto',
      ),
      MapEntry(
        RegExp(r'\bmodificatore\s+MOVE\b', caseSensitive: false),
        'modificatore di caratteristica della mossa',
      ),
      MapEntry(
        RegExp(r'\bMOVE\s+modifier\b', caseSensitive: false),
        'modificatore di caratteristica della mossa',
      ),
    ]) {
      result = result.replaceAll(replacement.key, replacement.value);
    }

    result = result.replaceAllMapped(
      RegExp(r'\b(\d+d\d+)\s*\+\s*MOVE\s+danni\b'),
      (match) =>
          'danni pari a ${match.group(1)} + il modificatore di caratteristica della mossa',
    );
    result = result.replaceAll(
      RegExp(r'\bMOVE\b'),
      'modificatore di caratteristica della mossa',
    );

    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)\s*(?:ft|feet|foot)\b', caseSensitive: false),
      (match) => '${match.group(1)} piedi',
    );

    for (final entry in const <String, String>{
      'STR': 'FOR',
      'DEX': 'DES',
      'CON': 'COS',
      'WIS': 'SAG',
      'CHA': 'CAR',
      'AC': 'CA',
      'HP': 'PF',
      'DC': 'CD',
    }.entries) {
      result = result.replaceAll(RegExp('\\b${entry.key}\\b'), entry.value);
    }

    return result;
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
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
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
