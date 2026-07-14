class BreedingCandidate {
  const BreedingCandidate({
    required this.key,
    required this.pokemonId,
    required this.displayName,
    required this.location,
    required this.loyalty,
    required this.selectedMoves,
    required this.abilities,
    this.formName,
    this.gender,
  });

  final String key;
  final int pokemonId;
  final String displayName;
  final String location;
  final int loyalty;
  final List<String> selectedMoves;
  final List<String> abilities;
  final String? formName;
  final String? gender;

  bool get isMale => gender?.toLowerCase() == 'male';
  bool get isFemale => gender?.toLowerCase() == 'female';
  bool get isGenderless => gender?.toLowerCase() == 'genderless';

  String get genderLabel => switch (gender?.toLowerCase()) {
    'male' => 'Maschio',
    'female' => 'Femmina',
    'genderless' => 'Senza sesso',
    _ => 'Sesso non impostato',
  };
}
