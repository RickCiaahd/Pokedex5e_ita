class TeamSlot {
  final int slotIndex;
  final int? pokemonId;

  TeamSlot({
    required this.slotIndex,
    required this.pokemonId,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotIndex': slotIndex,
      'pokemonId': pokemonId,
    };
  }

  factory TeamSlot.fromJson(Map<String, dynamic> json) {
    return TeamSlot(
      slotIndex: json['slotIndex'],
      pokemonId: json['pokemonId'],
    );
  }
}