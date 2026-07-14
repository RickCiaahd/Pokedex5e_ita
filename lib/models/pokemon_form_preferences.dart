class PokemonFormPreferences {
  const PokemonFormPreferences._();

  static String? normalizeGender(String? gender) {
    final normalizedGender = gender?.trim().toLowerCase();
    if (normalizedGender == null || normalizedGender.isEmpty) return null;

    switch (normalizedGender) {
      case 'male':
      case 'm':
      case 'maschio':
        return 'male';
      case 'female':
      case 'f':
      case 'femmina':
        return 'female';
      case 'genderless':
      case 'sesso sconosciuto':
      case 'senza sesso':
      case 'none':
      case 'unknown':
        return 'genderless';
      default:
        return normalizedGender;
    }
  }

  static String? normalizeFormName({
    required String? formName,
    String? gender,
  }) {
    final normalizedForm = formName?.trim();
    if (normalizedForm == null || normalizedForm.isEmpty) return null;

    final lowerForm = normalizedForm.toLowerCase();
    switch (lowerForm) {
      case 'base':
      case 'default':
      case 'forma base':
        return null;
      case 'male':
      case 'm':
      case 'maschio':
      case 'female':
      case 'f':
      case 'femmina':
        return null;
      default:
        break;
    }

    final normalizedGender = normalizeGender(gender);
    final formAsGender = normalizeGender(normalizedForm);
    if (normalizedGender != null && formAsGender == normalizedGender) {
      return null;
    }

    return normalizedForm;
  }

  // Kept as compatibility hooks for older call sites. Form, gender and shiny
  // now belong exclusively to TeamSlot/PcPokemon instances and must not be
  // shared globally by Pokédex number.
  static void setForm({
    required int pokemonId,
    required String? formName,
  }) {}

  static void setShiny({
    required int pokemonId,
    required bool isShiny,
  }) {}

  static void setGender({
    required int pokemonId,
    required String? gender,
  }) {}

  static String? formFor(int pokemonId) => null;

  static bool shinyFor(int pokemonId) => false;

  static String? genderFor(int pokemonId) => null;
}
