class TrainerOrigin {
  const TrainerOrigin({
    required this.name,
    required this.description,
    required this.abilityBonuses,
    required this.skillProficiencies,
    required this.savingThrowProficiencies,
  });

  final String name;
  final String description;
  final Map<String, int> abilityBonuses;
  final List<String> skillProficiencies;
  final List<String> savingThrowProficiencies;

  factory TrainerOrigin.fromJson(Map<String, dynamic> json) {
    final rawBonuses = Map<String, dynamic>.from(
      json['abilityBonuses'] as Map? ?? const {},
    );

    return TrainerOrigin(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      abilityBonuses: {
        for (final entry in rawBonuses.entries)
          entry.key: entry.value is int ? entry.value as int : 0,
      },
      skillProficiencies: List<String>.from(
        json['skillProficiencies'] as List? ?? const [],
      ),
      savingThrowProficiencies: List<String>.from(
        json['savingThrowProficiencies'] as List? ?? const [],
      ),
    );
  }
}

class TrainerPath {
  const TrainerPath({required this.name, required this.features});

  final String name;
  final List<TrainerPathFeature> features;

  factory TrainerPath.fromJson(Map<String, dynamic> json) {
    return TrainerPath(
      name: json['name'] as String,
      features: [
        for (final item in json['features'] as List? ?? const [])
          TrainerPathFeature.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  TrainerPathFeature? featureForLevel(int level) {
    for (final feature in features) {
      if (feature.level == level) {
        return feature;
      }
    }

    return null;
  }
}

class TrainerPathFeature {
  const TrainerPathFeature({
    required this.level,
    required this.title,
    required this.description,
  });

  final int level;
  final String title;
  final String description;

  factory TrainerPathFeature.fromJson(Map<String, dynamic> json) {
    return TrainerPathFeature(
      level: json['level'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}
