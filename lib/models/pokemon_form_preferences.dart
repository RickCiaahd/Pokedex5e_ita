class PokemonFormPreferences {
  const PokemonFormPreferences._();

  static final Map<int, String> _formByPokemonId = {};
  static final Map<int, bool> _shinyByPokemonId = {};

  static void setForm({required int pokemonId, required String? formName}) {
    final normalizedForm = formName?.trim();
    if (normalizedForm == null || normalizedForm.isEmpty) {
      _formByPokemonId.remove(pokemonId);
      return;
    }

    _formByPokemonId[pokemonId] = normalizedForm;
  }

  static void setShiny({required int pokemonId, required bool isShiny}) {
    if (!isShiny) {
      _shinyByPokemonId.remove(pokemonId);
      return;
    }

    _shinyByPokemonId[pokemonId] = true;
  }

  static String? formFor(int pokemonId) => _formByPokemonId[pokemonId];

  static bool shinyFor(int pokemonId) => _shinyByPokemonId[pokemonId] ?? false;
}