class PokemonFormPreferences {
  const PokemonFormPreferences._();

  static final Map<int, String> _formByPokemonId = {};
  static final Map<int, bool> _shinyByPokemonId = {};
  static final Map<int, String> _genderByPokemonId = {};

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

  static void setForm({
    required int pokemonId,
    required String? formName,
  }) {
    final normalizedForm = normalizeFormName(
      formName: formName,
      gender: null,
    );
    if (normalizedForm == null || normalizedForm.isEmpty) {
      _formByPokemonId.remove(pokemonId);
      return;
    }

    _formByPokemonId[pokemonId] = normalizedForm;
  }

  static void setShiny({
    required int pokemonId,
    required bool isShiny,
  }) {
    if (!isShiny) {
      _shinyByPokemonId.remove(pokemonId);
      return;
    }

    _shinyByPokemonId[pokemonId] = true;
  }

  static void setGender({
    required int pokemonId,
    required String? gender,
  }) {
    final normalizedGender = normalizeGender(gender);
    if (normalizedGender == null || normalizedGender.isEmpty) {
      _genderByPokemonId.remove(pokemonId);
      return;
    }

    _genderByPokemonId[pokemonId] = normalizedGender;
  }

  static String? formFor(int pokemonId) => _formByPokemonId[pokemonId];

  static bool shinyFor(int pokemonId) =>
      _shinyByPokemonId[pokemonId] ?? false;

  static String? genderFor(int pokemonId) =>
      _genderByPokemonId[pokemonId];
}
