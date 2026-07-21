import 'pokemon.dart';

/// Catalogo delle specie con differenze visive tra maschio e femmina.
///
/// Il sesso resta una proprietà del singolo Pokémon catturato e non viene
/// trattato come una forma distinta del Pokédex.
class PokemonGenderAppearance {
  const PokemonGenderAppearance._();

  static const Set<int> visuallyDimorphicIds = {
    // Generazione I
    3, 12, 19, 20, 25, 26, 41, 42, 44, 45, 64, 65, 84, 85, 97, 111,
    112, 118, 119, 123, 129, 130, 133,
    // Generazione II
    154, 165, 166, 178, 185, 186, 190, 194, 195, 198, 202, 203, 207,
    208, 212, 214, 215, 217, 221, 224, 229, 232,
    // Generazione III
    255, 256, 257, 267, 269, 272, 274, 275, 307, 308, 315, 316, 317,
    322, 323, 332, 350, 369,
    // Generazione IV
    396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 407, 415, 417,
    418, 419, 424, 443, 444, 445, 449, 450, 453, 454, 456, 457, 459,
    460, 461, 464, 465, 473,
    // Generazione V
    521, 592, 593,
    // Generazione VI
    668, 678,
    // Generazione VIII
    876, 902,
    // Generazione IX
    916,
  };

  static bool hasVisibleDifference(Pokemon pokemon) {
    return visuallyDimorphicIds.contains(pokemon.id);
  }
}
