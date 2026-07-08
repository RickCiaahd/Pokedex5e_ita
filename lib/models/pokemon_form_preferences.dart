class PokemonFormPreferences {
  const PokemonFormPreferences._();

  static final Map<int, String> _formByPokemonId = {};

  static void setForm({required int pokemonId, required String? formName}) {
    final normalizedForm = formName?.trim();
    if (normalizedForm == null || normalizedForm.isEmpty) {
      _formByPokemonId.remove(pokemonId);
      return;
    }

    _formByPokemonId[pokemonId] = normalizedForm;
  }

  static String? formFor(int pokemonId) => _formByPokemonId[pokemonId];
}
