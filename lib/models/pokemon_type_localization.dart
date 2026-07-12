class PokemonTypeLocalization {
  const PokemonTypeLocalization._();

  static const Map<String, String> _englishByKey = {
    'bug': 'Bug',
    'dark': 'Dark',
    'dragon': 'Dragon',
    'electric': 'Electric',
    'fairy': 'Fairy',
    'fighting': 'Fighting',
    'fire': 'Fire',
    'flying': 'Flying',
    'ghost': 'Ghost',
    'grass': 'Grass',
    'ground': 'Ground',
    'ice': 'Ice',
    'normal': 'Normal',
    'poison': 'Poison',
    'psychic': 'Psychic',
    'rock': 'Rock',
    'steel': 'Steel',
    'water': 'Water',
    'typeless': 'Typeless',
  };

  static const Map<String, String> _italianByKey = {
    'bug': 'Coleottero',
    'dark': 'Buio',
    'dragon': 'Drago',
    'electric': 'Elettro',
    'fairy': 'Folletto',
    'fighting': 'Lotta',
    'fire': 'Fuoco',
    'flying': 'Volante',
    'ghost': 'Spettro',
    'grass': 'Erba',
    'ground': 'Terra',
    'ice': 'Ghiaccio',
    'normal': 'Normale',
    'poison': 'Veleno',
    'psychic': 'Psico',
    'rock': 'Roccia',
    'steel': 'Acciaio',
    'water': 'Acqua',
    'typeless': 'Senza tipo',
  };

  static const Map<String, String> _aliases = {
    'bug': 'bug',
    'coleottero': 'bug',
    'dark': 'dark',
    'buio': 'dark',
    'dragon': 'dragon',
    'drago': 'dragon',
    'electric': 'electric',
    'elettro': 'electric',
    'fairy': 'fairy',
    'folletto': 'fairy',
    'fighting': 'fighting',
    'lotta': 'fighting',
    'fire': 'fire',
    'fuoco': 'fire',
    'flying': 'flying',
    'volante': 'flying',
    'ghost': 'ghost',
    'spettro': 'ghost',
    'grass': 'grass',
    'erba': 'grass',
    'ground': 'ground',
    'terra': 'ground',
    'ice': 'ice',
    'ghiaccio': 'ice',
    'normal': 'normal',
    'normale': 'normal',
    'poison': 'poison',
    'veleno': 'poison',
    'psychic': 'psychic',
    'psico': 'psychic',
    'rock': 'rock',
    'roccia': 'rock',
    'steel': 'steel',
    'acciaio': 'steel',
    'water': 'water',
    'acqua': 'water',
    'typeless': 'typeless',
    'senza tipo': 'typeless',
  };

  static String canonicalKey(String value) {
    final normalized = value.trim().toLowerCase();
    return _aliases[normalized] ?? normalized;
  }

  static String englishValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return _englishByKey[canonicalKey(trimmed)] ?? trimmed;
  }

  static String italianLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return _italianByKey[canonicalKey(trimmed)] ?? trimmed;
  }

  static bool sameType(String first, String second) {
    return canonicalKey(first) == canonicalKey(second);
  }

  static int compareByItalianLabel(String first, String second) {
    return italianLabel(
      first,
    ).toLowerCase().compareTo(italianLabel(second).toLowerCase());
  }
}
