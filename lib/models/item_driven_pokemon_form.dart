class ItemDrivenPokemonForm {
  const ItemDrivenPokemonForm._();

  static const int arceusId = 493;
  static const int genesectId = 649;
  static const int silvallyId = 773;

  static const Map<String, String> _arceusPlateTypes = {
    'draco-plate': 'Dragon',
    'dread-plate': 'Dark',
    'earth-plate': 'Ground',
    'fist-plate': 'Fighting',
    'flame-plate': 'Fire',
    'icicle-plate': 'Ice',
    'insect-plate': 'Bug',
    'iron-plate': 'Steel',
    'meadow-plate': 'Grass',
    'mind-plate': 'Psychic',
    'pixie-plate': 'Fairy',
    'sky-plate': 'Flying',
    'splash-plate': 'Water',
    'spooky-plate': 'Ghost',
    'stone-plate': 'Rock',
    'toxic-plate': 'Poison',
    'zap-plate': 'Electric',
    // Localized display names are accepted for imported legacy data.
    'lastradrakon': 'Dragon',
    'lastratimore': 'Dark',
    'lastrageo': 'Ground',
    'lastrapugno': 'Fighting',
    'lastrarogo': 'Fire',
    'lastragelo': 'Ice',
    'lastrabaco': 'Bug',
    'lastraferro': 'Steel',
    'lastraprato': 'Grass',
    'lastramente': 'Psychic',
    'lastraspiritello': 'Fairy',
    'lastracielo': 'Flying',
    'lastraidro': 'Water',
    'lastratetra': 'Ghost',
    'lastrapietra': 'Rock',
    'lastrafiele': 'Poison',
    'lastrasaetta': 'Electric',
  };

  static const Map<String, String> _silvallyMemoryTypes = {
    'bug-memory-disc': 'Bug',
    'dark-memory-disc': 'Dark',
    'dragon-memory-disc': 'Dragon',
    'electric-memory-disc': 'Electric',
    'fairy-memory-disc': 'Fairy',
    'fighting-memory-disc': 'Fighting',
    'fire-memory-disc': 'Fire',
    'flying-memory-disc': 'Flying',
    'ghost-memory-disc': 'Ghost',
    'grass-memory-disc': 'Grass',
    'ground-memory-disc': 'Ground',
    'ice-memory-disc': 'Ice',
    'poison-memory-disc': 'Poison',
    'psychic-memory-disc': 'Psychic',
    'rock-memory-disc': 'Rock',
    'steel-memory-disc': 'Steel',
    'water-memory-disc': 'Water',
    // Localized display names are accepted for imported legacy data.
    'rom-coleottero': 'Bug',
    'rom-buio': 'Dark',
    'rom-drago': 'Dragon',
    'rom-elettro': 'Electric',
    'rom-folletto': 'Fairy',
    'rom-lotta': 'Fighting',
    'rom-fuoco': 'Fire',
    'rom-volante': 'Flying',
    'rom-spettro': 'Ghost',
    'rom-erba': 'Grass',
    'rom-terra': 'Ground',
    'rom-ghiaccio': 'Ice',
    'rom-veleno': 'Poison',
    'rom-psico': 'Psychic',
    'rom-roccia': 'Rock',
    'rom-acciaio': 'Steel',
    'rom-acqua': 'Water',
  };

  static const Map<String, String> _genesectDriveForms = {
    'burn-drive': 'Burn',
    'chill-drive': 'Chill',
    'douse-drive': 'Douse',
    'shock-drive': 'Shock',
    // Localized display names are accepted for imported legacy data.
    'piromodulo': 'Burn',
    'gelomodulo': 'Chill',
    'idromodulo': 'Douse',
    'voltmodulo': 'Shock',
  };

  static const Map<String, String> _genesectDriveTypes = {
    'burn-drive': 'Fire',
    'chill-drive': 'Ice',
    'douse-drive': 'Water',
    'shock-drive': 'Electric',
    // Localized display names are accepted for imported legacy data.
    'piromodulo': 'Fire',
    'gelomodulo': 'Ice',
    'idromodulo': 'Water',
    'voltmodulo': 'Electric',
  };

  static bool usesHeldItemForm(int? pokemonId) {
    return pokemonId == arceusId ||
        pokemonId == genesectId ||
        pokemonId == silvallyId;
  }

  static bool usesHeldItemFormForSpecies(String speciesName) {
    final key = speciesName.trim().toLowerCase();
    return key == 'arceus' || key == 'genesect' || key == 'silvally';
  }

  /// Item-driven species never persist an independently selected form.
  static String? normalizePersistedFormName({
    required int? pokemonId,
    required String? formName,
  }) {
    return usesHeldItemForm(pokemonId) ? null : formName;
  }

  /// Returns the mechanical/visual form implied by the held item.
  ///
  /// A null result means the species must use its base Normal form.
  static String? formNameForHeldItem({
    required int? pokemonId,
    required String? heldItem,
  }) {
    final itemKey = _referenceKey(heldItem);
    if (itemKey.isEmpty) return null;

    return switch (pokemonId) {
      arceusId => _arceusPlateTypes[itemKey],
      genesectId => _genesectDriveForms[itemKey],
      silvallyId => _silvallyMemoryTypes[itemKey],
      _ => null,
    };
  }

  /// Returns the contextual type of moves whose type depends on a held item.
  ///
  /// The returned value is always a real Pokémon type, so the UI never tries
  /// to resolve technical placeholders such as `Varies` as image assets.
  static String effectiveMoveType({
    required int? pokemonId,
    required String moveReference,
    required String? heldItem,
    required String fallbackType,
  }) {
    final moveKey = _referenceKey(moveReference);
    final itemKey = _referenceKey(heldItem);

    if (pokemonId == arceusId &&
        const {'judgment', 'giudizio'}.contains(moveKey)) {
      return _arceusPlateTypes[itemKey] ?? 'Normal';
    }
    if (pokemonId == silvallyId &&
        const {'multi-attack', 'multiattacco'}.contains(moveKey)) {
      return _silvallyMemoryTypes[itemKey] ?? 'Normal';
    }
    if (pokemonId == genesectId &&
        const {'techno-blast', 'tecnobotto'}.contains(moveKey)) {
      return _genesectDriveTypes[itemKey] ?? 'Normal';
    }

    return fallbackType;
  }

  static String? effectiveFormName({
    required int? pokemonId,
    required String? persistedFormName,
    required String? heldItem,
  }) {
    if (!usesHeldItemForm(pokemonId)) return persistedFormName;
    return formNameForHeldItem(pokemonId: pokemonId, heldItem: heldItem);
  }

  static String _referenceKey(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
