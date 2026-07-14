class EvolutionData {
  const EvolutionData({
    required this.evolutions,
    required this.currentStage,
    required this.totalStages,
    this.level,
    this.points,
    this.options = const [],
  });

  final List<String> evolutions;
  final int currentStage;
  final int totalStages;
  final int? level;
  final int? points;
  final List<EvolutionOption> options;

  bool get canEvolve => evolutions.isNotEmpty && level != null;

  factory EvolutionData.fromJson(Map<String, dynamic> json) {
    return EvolutionData(
      evolutions: List<String>.from(json['into'] ?? []),
      currentStage: json['current_stage'] ?? 1,
      totalStages: json['total_stages'] ?? 1,
      level: json['level'],
      points: json['points'],
    );
  }

  factory EvolutionData.fromOptions(
    List<EvolutionOption> options, {
    int currentStage = 1,
    int totalStages = 1,
  }) {
    final sortedOptions = [...options]
      ..sort((a, b) {
        final levelCompare = (a.levelCondition ?? 0).compareTo(
          b.levelCondition ?? 0,
        );
        if (levelCompare != 0) return levelCompare;
        return a.toName.compareTo(b.toName);
      });

    return EvolutionData(
      evolutions: sortedOptions.map((option) => option.toName).toList(),
      currentStage: currentStage,
      totalStages: totalStages,
      level: _lowestLevel(sortedOptions),
      points: _firstAsiEffect(sortedOptions),
      options: sortedOptions,
    );
  }

  static int? _lowestLevel(List<EvolutionOption> options) {
    final levels = options
        .map((option) => option.levelCondition)
        .whereType<int>()
        .toList();
    if (levels.isEmpty) return null;
    levels.sort();
    return levels.first;
  }

  static int? _firstAsiEffect(List<EvolutionOption> options) {
    for (final option in options) {
      final asi = option.asiEffect;
      if (asi != null) return asi;
    }
    return null;
  }
}

class EvolutionOption {
  const EvolutionOption({
    required this.id,
    required this.fromKey,
    required this.toKey,
    required this.toName,
    required this.conditions,
    required this.effects,
  });

  final String id;
  final String fromKey;
  final String toKey;
  final String toName;
  final List<EvolutionRule> conditions;
  final List<EvolutionRule> effects;

  int? get levelCondition => _intValueFor('level', conditions);
  int? get loyaltyCondition => _intValueFor('loyalty', conditions);
  int? get asiEffect => _intValueFor('asi', effects);

  String? get itemCondition {
    for (final condition in conditions) {
      if (condition.type == 'item') return condition.valueLabel;
    }
    return null;
  }

  List<String> get conditionLabels {
    if (conditions.isEmpty) return const ['Nessuna condizione'];
    return conditions.map((condition) => condition.displayLabel).toList();
  }

  factory EvolutionOption.fromWebJson(
    Map<String, dynamic> json, {
    required String Function(String key) displayNameBuilder,
  }) {
    final toKey = json['to']?.toString() ?? '';

    return EvolutionOption(
      id: json['id']?.toString() ?? '',
      fromKey: json['from']?.toString() ?? '',
      toKey: toKey,
      toName: displayNameBuilder(toKey),
      conditions: _readRules(json['conditions']),
      effects: _readRules(json['effects']),
    );
  }

  static List<EvolutionRule> _readRules(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map(
          (entry) => EvolutionRule.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);
  }

  static int? _intValueFor(String type, List<EvolutionRule> rules) {
    for (final rule in rules) {
      if (rule.type == type) return rule.intValue;
    }
    return null;
  }
}

class EvolutionRule {
  const EvolutionRule({required this.type, required this.value});

  final String type;
  final Object? value;

  int? get intValue {
    final value = this.value;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String get valueLabel => value?.toString() ?? '';

  String get displayLabel {
    switch (type) {
      case 'level':
        return 'Livello $valueLabel';
      case 'item':
        return valueLabel;
      case 'loyalty':
        return 'Lealtà $valueLabel';
      case 'gender':
        return 'Sesso: $valueLabel';
      case 'move':
        return 'Mossa: $valueLabel';
      case 'biome':
        return 'Bioma: $valueLabel';
      default:
        return valueLabel.isEmpty ? type : '$type: $valueLabel';
    }
  }

  factory EvolutionRule.fromJson(Map<String, dynamic> json) {
    return EvolutionRule(
      type: json['type']?.toString() ?? '',
      value: json['value'],
    );
  }
}
