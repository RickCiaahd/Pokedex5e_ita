import '../localization/ui_text.dart';

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
    'male' => uiTextForLanguage('Maschio', """Male"""),
    'female' => uiTextForLanguage('Femmina', """Female"""),
    'genderless' => uiTextForLanguage('Senza sesso', """Genderless"""),
    _ => uiTextForLanguage('Sesso non impostato', """Gender not set"""),
  };
}
