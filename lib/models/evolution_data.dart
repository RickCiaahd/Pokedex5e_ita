class EvolutionData {
  const EvolutionData({
    required this.evolutions,
    required this.currentStage,
    required this.totalStages,
    this.level,
    this.points,
  });

  final List<String> evolutions;
  final int currentStage;
  final int totalStages;
  final int? level;
  final int? points;

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
}
