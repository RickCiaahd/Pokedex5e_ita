class TeamSlot {
  final int slotIndex;
  final int? pokemonId;
  final int experience;
  final int currentHp;

  TeamSlot({
    required this.slotIndex,
    required this.pokemonId,
    this.experience = 0,
    this.currentHp = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'pokemonId': pokemonId,
      'experience': experience,
      'currentHp': currentHp,
    };
  }

  factory TeamSlot.fromJson(Map<String, dynamic> json) {
    return TeamSlot(
      slotIndex: json['slotIndex'],
      pokemonId: json['pokemonId'],
      experience: json['experience'] ?? 0,
      currentHp: json['currentHp'] ?? 0,
    );
  }

  TeamSlot copyWith({
    int? slotIndex,
    int? pokemonId,
    int? experience,
    int? currentHp,
    bool clearPokemon = false,
  }) {
    return TeamSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      pokemonId: clearPokemon ? null : pokemonId ?? this.pokemonId,
      experience: experience ?? this.experience,
      currentHp: currentHp ?? this.currentHp,
    );
  }
}
