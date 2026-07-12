import '../models/pokemon.dart';
import '../models/pokemon_type_localization.dart';

class PokemonHabitatService {
  const PokemonHabitatService();

  static const List<String> habitats = [
    'Qualsiasi',
    'Prateria',
    'Foresta',
    'Grotta',
    'Montagna',
    'Deserto',
    'Palude',
    'Costa e fiumi',
    'Mare',
    'Città',
    'Neve e ghiaccio',
  ];

  bool matches(Pokemon pokemon, String habitat) {
    final normalizedHabitat = habitat.trim().toLowerCase();
    if (normalizedHabitat.isEmpty || normalizedHabitat == 'qualsiasi') {
      return true;
    }

    final types = pokemon.types
        .map(PokemonTypeLocalization.canonicalKey)
        .toSet();
    final searchable = [
      pokemon.name,
      pokemon.genus ?? '',
      pokemon.description ?? '',
    ].join(' ').toLowerCase();

    bool hasType(Iterable<String> values) => values.any(types.contains);
    bool hasWord(Iterable<String> values) =>
        values.any((value) => searchable.contains(value));

    return switch (normalizedHabitat) {
      'prateria' =>
        hasType(const ['normal', 'grass', 'electric', 'flying', 'bug']) ||
            hasWord(const ['field', 'grassland', 'plain', 'prairie', 'meadow']),
      'foresta' =>
        hasType(const ['grass', 'bug', 'fairy']) ||
            hasWord(const ['forest', 'tree', 'wood', 'leaf', 'mushroom']),
      'grotta' =>
        hasType(const ['rock', 'ground', 'dark', 'ghost', 'poison']) ||
            hasWord(const ['cave', 'cavern', 'underground', 'bat']),
      'montagna' =>
        hasType(const ['rock', 'ground', 'flying', 'dragon']) ||
            hasWord(const ['mountain', 'cliff', 'peak', 'high altitude']),
      'deserto' =>
        hasType(const ['ground', 'rock', 'fire']) ||
            hasWord(const ['desert', 'sand', 'dune', 'arid']),
      'palude' =>
        hasType(const ['poison', 'water', 'grass', 'ghost']) ||
            hasWord(const ['swamp', 'marsh', 'bog', 'mud']),
      'costa e fiumi' =>
        hasType(const ['water']) ||
            hasWord(const ['river', 'lake', 'pond', 'shore', 'coast', 'beach']),
      'mare' =>
        hasType(const ['water']) &&
            (hasWord(const ['sea', 'ocean', 'marine', 'deep water', 'coral']) ||
                pokemon.speed >= 9),
      'città' =>
        hasType(const ['normal', 'electric', 'steel', 'dark', 'poison']) ||
            hasWord(const ['city', 'urban', 'building', 'garbage', 'factory']),
      'neve e ghiaccio' =>
        hasType(const ['ice']) ||
            hasWord(const ['snow', 'ice', 'frozen', 'tundra', 'glacier']),
      _ => true,
    };
  }

  bool isLegendaryOrMythical(Pokemon pokemon) {
    return _legendaryAndMythicalIds.contains(pokemon.id);
  }

  static const Set<int> _legendaryAndMythicalIds = {
    144, 145, 146, 150, 151,
    243, 244, 245, 249, 250, 251,
    377, 378, 379, 380, 381, 382, 383, 384, 385, 386,
    480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493,
    494, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649,
    716, 717, 718, 719, 720, 721,
    772, 773, 785, 786, 787, 788, 789, 790, 791, 792, 800, 801, 802, 807,
    808, 809,
    888, 889, 890, 891, 892, 893, 894, 895, 896, 897, 898,
    905,
    1001, 1002, 1003, 1004, 1007, 1008, 1014, 1015, 1016, 1017, 1024,
  };
}
