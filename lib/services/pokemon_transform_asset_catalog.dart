class PokemonTransformArt {
  const PokemonTransformArt({
    required this.identifier,
    required this.speciesId,
    required this.kind,
    required this.label,
    required this.types,
    this.formKey,
  });

  final String identifier;
  final int speciesId;
  final String kind;
  final String label;
  final List<String> types;
  final String? formKey;

  String assetPath({required bool shiny}) {
    final suffix = shiny ? '-shiny' : '';
    return 'assets/textures/textures_webapp/pokemon_transforms/$kind/$identifier$suffix.png';
  }
}

class PokemonTransformAssetCatalog {
  const PokemonTransformAssetCatalog._();

  static const List<PokemonTransformArt> all = [
    PokemonTransformArt(identifier: 'venusaur-mega', speciesId: 3, kind: 'mega', label: 'Mega', types: ['Grass', 'Poison']),
    PokemonTransformArt(identifier: 'charizard-mega-x', speciesId: 6, kind: 'mega', label: 'Mega X', types: ['Fire', 'Dragon']),
    PokemonTransformArt(identifier: 'charizard-mega-y', speciesId: 6, kind: 'mega', label: 'Mega Y', types: ['Fire', 'Flying']),
    PokemonTransformArt(identifier: 'blastoise-mega', speciesId: 9, kind: 'mega', label: 'Mega', types: ['Water']),
    PokemonTransformArt(identifier: 'alakazam-mega', speciesId: 65, kind: 'mega', label: 'Mega', types: ['Psychic']),
    PokemonTransformArt(identifier: 'gengar-mega', speciesId: 94, kind: 'mega', label: 'Mega', types: ['Ghost', 'Poison']),
    PokemonTransformArt(identifier: 'kangaskhan-mega', speciesId: 115, kind: 'mega', label: 'Mega', types: ['Normal']),
    PokemonTransformArt(identifier: 'pinsir-mega', speciesId: 127, kind: 'mega', label: 'Mega', types: ['Bug', 'Flying']),
    PokemonTransformArt(identifier: 'gyarados-mega', speciesId: 130, kind: 'mega', label: 'Mega', types: ['Water', 'Dark']),
    PokemonTransformArt(identifier: 'aerodactyl-mega', speciesId: 142, kind: 'mega', label: 'Mega', types: ['Rock', 'Flying']),
    PokemonTransformArt(identifier: 'mewtwo-mega-x', speciesId: 150, kind: 'mega', label: 'Mega X', types: ['Psychic', 'Fighting']),
    PokemonTransformArt(identifier: 'mewtwo-mega-y', speciesId: 150, kind: 'mega', label: 'Mega Y', types: ['Psychic']),
    PokemonTransformArt(identifier: 'ampharos-mega', speciesId: 181, kind: 'mega', label: 'Mega', types: ['Electric', 'Dragon']),
    PokemonTransformArt(identifier: 'scizor-mega', speciesId: 212, kind: 'mega', label: 'Mega', types: ['Bug', 'Steel']),
    PokemonTransformArt(identifier: 'heracross-mega', speciesId: 214, kind: 'mega', label: 'Mega', types: ['Bug', 'Fighting']),
    PokemonTransformArt(identifier: 'houndoom-mega', speciesId: 229, kind: 'mega', label: 'Mega', types: ['Dark', 'Fire']),
    PokemonTransformArt(identifier: 'tyranitar-mega', speciesId: 248, kind: 'mega', label: 'Mega', types: ['Rock', 'Dark']),
    PokemonTransformArt(identifier: 'blaziken-mega', speciesId: 257, kind: 'mega', label: 'Mega', types: ['Fire', 'Fighting']),
    PokemonTransformArt(identifier: 'gardevoir-mega', speciesId: 282, kind: 'mega', label: 'Mega', types: ['Psychic', 'Fairy']),
    PokemonTransformArt(identifier: 'mawile-mega', speciesId: 303, kind: 'mega', label: 'Mega', types: ['Steel', 'Fairy']),
    PokemonTransformArt(identifier: 'aggron-mega', speciesId: 306, kind: 'mega', label: 'Mega', types: ['Steel']),
    PokemonTransformArt(identifier: 'medicham-mega', speciesId: 308, kind: 'mega', label: 'Mega', types: ['Fighting', 'Psychic']),
    PokemonTransformArt(identifier: 'manectric-mega', speciesId: 310, kind: 'mega', label: 'Mega', types: ['Electric']),
    PokemonTransformArt(identifier: 'banette-mega', speciesId: 354, kind: 'mega', label: 'Mega', types: ['Ghost']),
    PokemonTransformArt(identifier: 'absol-mega', speciesId: 359, kind: 'mega', label: 'Mega', types: ['Dark']),
    PokemonTransformArt(identifier: 'garchomp-mega', speciesId: 445, kind: 'mega', label: 'Mega', types: ['Dragon', 'Ground']),
    PokemonTransformArt(identifier: 'lucario-mega', speciesId: 448, kind: 'mega', label: 'Mega', types: ['Fighting', 'Steel']),
    PokemonTransformArt(identifier: 'abomasnow-mega', speciesId: 460, kind: 'mega', label: 'Mega', types: ['Grass', 'Ice']),
    PokemonTransformArt(identifier: 'latias-mega', speciesId: 380, kind: 'mega', label: 'Mega', types: ['Dragon', 'Psychic']),
    PokemonTransformArt(identifier: 'latios-mega', speciesId: 381, kind: 'mega', label: 'Mega', types: ['Dragon', 'Psychic']),
    PokemonTransformArt(identifier: 'swampert-mega', speciesId: 260, kind: 'mega', label: 'Mega', types: ['Water', 'Ground']),
    PokemonTransformArt(identifier: 'sceptile-mega', speciesId: 254, kind: 'mega', label: 'Mega', types: ['Grass', 'Dragon']),
    PokemonTransformArt(identifier: 'sableye-mega', speciesId: 302, kind: 'mega', label: 'Mega', types: ['Dark', 'Ghost']),
    PokemonTransformArt(identifier: 'altaria-mega', speciesId: 334, kind: 'mega', label: 'Mega', types: ['Dragon', 'Fairy']),
    PokemonTransformArt(identifier: 'gallade-mega', speciesId: 475, kind: 'mega', label: 'Mega', types: ['Psychic', 'Fighting']),
    PokemonTransformArt(identifier: 'audino-mega', speciesId: 531, kind: 'mega', label: 'Mega', types: ['Normal', 'Fairy']),
    PokemonTransformArt(identifier: 'sharpedo-mega', speciesId: 319, kind: 'mega', label: 'Mega', types: ['Water', 'Dark']),
    PokemonTransformArt(identifier: 'slowbro-mega', speciesId: 80, kind: 'mega', label: 'Mega', types: ['Water', 'Psychic']),
    PokemonTransformArt(identifier: 'steelix-mega', speciesId: 208, kind: 'mega', label: 'Mega', types: ['Steel', 'Ground']),
    PokemonTransformArt(identifier: 'pidgeot-mega', speciesId: 18, kind: 'mega', label: 'Mega', types: ['Normal', 'Flying']),
    PokemonTransformArt(identifier: 'glalie-mega', speciesId: 362, kind: 'mega', label: 'Mega', types: ['Ice']),
    PokemonTransformArt(identifier: 'diancie-mega', speciesId: 719, kind: 'mega', label: 'Mega', types: ['Rock', 'Fairy']),
    PokemonTransformArt(identifier: 'metagross-mega', speciesId: 376, kind: 'mega', label: 'Mega', types: ['Steel', 'Psychic']),
    PokemonTransformArt(identifier: 'rayquaza-mega', speciesId: 384, kind: 'mega', label: 'Mega', types: ['Dragon', 'Flying']),
    PokemonTransformArt(identifier: 'camerupt-mega', speciesId: 323, kind: 'mega', label: 'Mega', types: ['Fire', 'Ground']),
    PokemonTransformArt(identifier: 'lopunny-mega', speciesId: 428, kind: 'mega', label: 'Mega', types: ['Normal', 'Fighting']),
    PokemonTransformArt(identifier: 'salamence-mega', speciesId: 373, kind: 'mega', label: 'Mega', types: ['Dragon', 'Flying']),
    PokemonTransformArt(identifier: 'beedrill-mega', speciesId: 15, kind: 'mega', label: 'Mega', types: ['Bug', 'Poison']),
    PokemonTransformArt(identifier: 'venusaur-gmax', speciesId: 3, kind: 'gigamax', label: 'Gigamax', types: ['Grass', 'Poison']),
    PokemonTransformArt(identifier: 'charizard-gmax', speciesId: 6, kind: 'gigamax', label: 'Gigamax', types: ['Fire', 'Flying']),
    PokemonTransformArt(identifier: 'blastoise-gmax', speciesId: 9, kind: 'gigamax', label: 'Gigamax', types: ['Water']),
    PokemonTransformArt(identifier: 'butterfree-gmax', speciesId: 12, kind: 'gigamax', label: 'Gigamax', types: ['Bug', 'Flying']),
    PokemonTransformArt(identifier: 'pikachu-gmax', speciesId: 25, kind: 'gigamax', label: 'Gigamax', types: ['Electric']),
    PokemonTransformArt(identifier: 'meowth-gmax', speciesId: 52, kind: 'gigamax', label: 'Gigamax', types: ['Normal']),
    PokemonTransformArt(identifier: 'machamp-gmax', speciesId: 68, kind: 'gigamax', label: 'Gigamax', types: ['Fighting']),
    PokemonTransformArt(identifier: 'gengar-gmax', speciesId: 94, kind: 'gigamax', label: 'Gigamax', types: ['Ghost', 'Poison']),
    PokemonTransformArt(identifier: 'kingler-gmax', speciesId: 99, kind: 'gigamax', label: 'Gigamax', types: ['Water']),
    PokemonTransformArt(identifier: 'lapras-gmax', speciesId: 131, kind: 'gigamax', label: 'Gigamax', types: ['Water', 'Ice']),
    PokemonTransformArt(identifier: 'eevee-gmax', speciesId: 133, kind: 'gigamax', label: 'Gigamax', types: ['Normal']),
    PokemonTransformArt(identifier: 'snorlax-gmax', speciesId: 143, kind: 'gigamax', label: 'Gigamax', types: ['Normal']),
    PokemonTransformArt(identifier: 'garbodor-gmax', speciesId: 569, kind: 'gigamax', label: 'Gigamax', types: ['Poison']),
    PokemonTransformArt(identifier: 'melmetal-gmax', speciesId: 809, kind: 'gigamax', label: 'Gigamax', types: ['Steel']),
    PokemonTransformArt(identifier: 'rillaboom-gmax', speciesId: 812, kind: 'gigamax', label: 'Gigamax', types: ['Grass']),
    PokemonTransformArt(identifier: 'cinderace-gmax', speciesId: 815, kind: 'gigamax', label: 'Gigamax', types: ['Fire']),
    PokemonTransformArt(identifier: 'inteleon-gmax', speciesId: 818, kind: 'gigamax', label: 'Gigamax', types: ['Water']),
    PokemonTransformArt(identifier: 'corviknight-gmax', speciesId: 823, kind: 'gigamax', label: 'Gigamax', types: ['Flying', 'Steel']),
    PokemonTransformArt(identifier: 'orbeetle-gmax', speciesId: 826, kind: 'gigamax', label: 'Gigamax', types: ['Bug', 'Psychic']),
    PokemonTransformArt(identifier: 'drednaw-gmax', speciesId: 834, kind: 'gigamax', label: 'Gigamax', types: ['Water', 'Rock']),
    PokemonTransformArt(identifier: 'coalossal-gmax', speciesId: 839, kind: 'gigamax', label: 'Gigamax', types: ['Rock', 'Fire']),
    PokemonTransformArt(identifier: 'flapple-gmax', speciesId: 841, kind: 'gigamax', label: 'Gigamax', types: ['Grass', 'Dragon']),
    PokemonTransformArt(identifier: 'appletun-gmax', speciesId: 842, kind: 'gigamax', label: 'Gigamax', types: ['Grass', 'Dragon']),
    PokemonTransformArt(identifier: 'sandaconda-gmax', speciesId: 844, kind: 'gigamax', label: 'Gigamax', types: ['Ground']),
    PokemonTransformArt(identifier: 'toxtricity-amped-gmax', speciesId: 849, kind: 'gigamax', label: 'Gigamax (Amped)', types: ['Electric', 'Poison'], formKey: 'amped'),
    PokemonTransformArt(identifier: 'centiskorch-gmax', speciesId: 851, kind: 'gigamax', label: 'Gigamax', types: ['Fire', 'Bug']),
    PokemonTransformArt(identifier: 'hatterene-gmax', speciesId: 858, kind: 'gigamax', label: 'Gigamax', types: ['Psychic', 'Fairy']),
    PokemonTransformArt(identifier: 'grimmsnarl-gmax', speciesId: 861, kind: 'gigamax', label: 'Gigamax', types: ['Dark', 'Fairy']),
    PokemonTransformArt(identifier: 'alcremie-gmax', speciesId: 869, kind: 'gigamax', label: 'Gigamax', types: ['Fairy']),
    PokemonTransformArt(identifier: 'copperajah-gmax', speciesId: 879, kind: 'gigamax', label: 'Gigamax', types: ['Steel']),
    PokemonTransformArt(identifier: 'duraludon-gmax', speciesId: 884, kind: 'gigamax', label: 'Gigamax', types: ['Steel', 'Dragon']),
    PokemonTransformArt(identifier: 'urshifu-single-strike-gmax', speciesId: 892, kind: 'gigamax', label: 'Gigamax (Single Strike)', types: ['Fighting', 'Dark'], formKey: 'single-strike'),
    PokemonTransformArt(identifier: 'urshifu-rapid-strike-gmax', speciesId: 892, kind: 'gigamax', label: 'Gigamax (Rapid Strike)', types: ['Fighting', 'Water'], formKey: 'rapid-strike'),
    PokemonTransformArt(identifier: 'toxtricity-low-key-gmax', speciesId: 849, kind: 'gigamax', label: 'Gigamax (Low Key)', types: ['Electric', 'Poison'], formKey: 'low-key'),
    PokemonTransformArt(identifier: 'clefable-mega', speciesId: 36, kind: 'mega', label: 'Mega', types: ['Fairy', 'Flying']),
    PokemonTransformArt(identifier: 'victreebel-mega', speciesId: 71, kind: 'mega', label: 'Mega', types: ['Grass', 'Poison']),
    PokemonTransformArt(identifier: 'starmie-mega', speciesId: 121, kind: 'mega', label: 'Mega', types: ['Water', 'Psychic']),
    PokemonTransformArt(identifier: 'dragonite-mega', speciesId: 149, kind: 'mega', label: 'Mega', types: ['Dragon', 'Flying']),
    PokemonTransformArt(identifier: 'meganium-mega', speciesId: 154, kind: 'mega', label: 'Mega', types: ['Grass', 'Fairy']),
    PokemonTransformArt(identifier: 'feraligatr-mega', speciesId: 160, kind: 'mega', label: 'Mega', types: ['Water', 'Dragon']),
    PokemonTransformArt(identifier: 'skarmory-mega', speciesId: 227, kind: 'mega', label: 'Mega', types: ['Steel', 'Flying']),
    PokemonTransformArt(identifier: 'froslass-mega', speciesId: 478, kind: 'mega', label: 'Mega', types: ['Ice', 'Ghost']),
    PokemonTransformArt(identifier: 'emboar-mega', speciesId: 500, kind: 'mega', label: 'Mega', types: ['Fire', 'Fighting']),
    PokemonTransformArt(identifier: 'excadrill-mega', speciesId: 530, kind: 'mega', label: 'Mega', types: ['Ground', 'Steel']),
    PokemonTransformArt(identifier: 'scolipede-mega', speciesId: 545, kind: 'mega', label: 'Mega', types: ['Bug', 'Poison']),
    PokemonTransformArt(identifier: 'scrafty-mega', speciesId: 560, kind: 'mega', label: 'Mega', types: ['Dark', 'Fighting']),
    PokemonTransformArt(identifier: 'eelektross-mega', speciesId: 604, kind: 'mega', label: 'Mega', types: ['Electric']),
    PokemonTransformArt(identifier: 'chandelure-mega', speciesId: 609, kind: 'mega', label: 'Mega', types: ['Ghost', 'Fire']),
    PokemonTransformArt(identifier: 'chesnaught-mega', speciesId: 652, kind: 'mega', label: 'Mega', types: ['Grass', 'Fighting']),
    PokemonTransformArt(identifier: 'delphox-mega', speciesId: 655, kind: 'mega', label: 'Mega', types: ['Fire', 'Psychic']),
    PokemonTransformArt(identifier: 'greninja-mega', speciesId: 658, kind: 'mega', label: 'Mega', types: ['Water', 'Dark']),
    PokemonTransformArt(identifier: 'pyroar-mega', speciesId: 668, kind: 'mega', label: 'Mega', types: ['Fire', 'Normal']),
    PokemonTransformArt(identifier: 'floette-mega', speciesId: 670, kind: 'mega', label: 'Mega', types: ['Fairy']),
    PokemonTransformArt(identifier: 'malamar-mega', speciesId: 687, kind: 'mega', label: 'Mega', types: ['Dark', 'Psychic']),
    PokemonTransformArt(identifier: 'barbaracle-mega', speciesId: 689, kind: 'mega', label: 'Mega', types: ['Rock', 'Fighting']),
    PokemonTransformArt(identifier: 'dragalge-mega', speciesId: 691, kind: 'mega', label: 'Mega', types: ['Poison', 'Dragon']),
    PokemonTransformArt(identifier: 'hawlucha-mega', speciesId: 701, kind: 'mega', label: 'Mega', types: ['Fighting', 'Flying']),
    PokemonTransformArt(identifier: 'zygarde-mega', speciesId: 718, kind: 'mega', label: 'Mega', types: ['Dragon', 'Ground']),
    PokemonTransformArt(identifier: 'drampa-mega', speciesId: 780, kind: 'mega', label: 'Mega', types: ['Normal', 'Dragon']),
    PokemonTransformArt(identifier: 'falinks-mega', speciesId: 870, kind: 'mega', label: 'Mega', types: ['Fighting']),
    PokemonTransformArt(identifier: 'raichu-mega-x', speciesId: 26, kind: 'mega', label: 'Mega X', types: ['Electric']),
    PokemonTransformArt(identifier: 'raichu-mega-y', speciesId: 26, kind: 'mega', label: 'Mega Y', types: ['Electric']),
    PokemonTransformArt(identifier: 'chimecho-mega', speciesId: 358, kind: 'mega', label: 'Mega', types: ['Psychic', 'Steel']),
    PokemonTransformArt(identifier: 'absol-mega-z', speciesId: 359, kind: 'mega', label: 'Mega Z', types: ['Dark', 'Ghost']),
    PokemonTransformArt(identifier: 'staraptor-mega', speciesId: 398, kind: 'mega', label: 'Mega', types: ['Fighting', 'Flying']),
    PokemonTransformArt(identifier: 'garchomp-mega-z', speciesId: 445, kind: 'mega', label: 'Mega Z', types: ['Dragon']),
    PokemonTransformArt(identifier: 'lucario-mega-z', speciesId: 448, kind: 'mega', label: 'Mega Z', types: ['Fighting', 'Steel']),
    PokemonTransformArt(identifier: 'heatran-mega', speciesId: 485, kind: 'mega', label: 'Mega', types: ['Fire', 'Steel']),
    PokemonTransformArt(identifier: 'darkrai-mega', speciesId: 491, kind: 'mega', label: 'Mega', types: ['Dark']),
    PokemonTransformArt(identifier: 'golurk-mega', speciesId: 623, kind: 'mega', label: 'Mega', types: ['Ground', 'Ghost']),
    PokemonTransformArt(identifier: 'meowstic-male-mega', speciesId: 678, kind: 'mega', label: 'Mega (Male)', types: ['Psychic'], formKey: 'male'),
    PokemonTransformArt(identifier: 'crabominable-mega', speciesId: 740, kind: 'mega', label: 'Mega', types: ['Fighting', 'Ice']),
    PokemonTransformArt(identifier: 'golisopod-mega', speciesId: 768, kind: 'mega', label: 'Mega', types: ['Bug', 'Steel']),
    PokemonTransformArt(identifier: 'magearna-mega', speciesId: 801, kind: 'mega', label: 'Mega', types: ['Steel', 'Fairy']),
    PokemonTransformArt(identifier: 'magearna-original-mega', speciesId: 801, kind: 'mega', label: 'Mega (Original)', types: ['Steel', 'Fairy'], formKey: 'original'),
    PokemonTransformArt(identifier: 'zeraora-mega', speciesId: 807, kind: 'mega', label: 'Mega', types: ['Electric']),
    PokemonTransformArt(identifier: 'scovillain-mega', speciesId: 952, kind: 'mega', label: 'Mega', types: ['Grass', 'Fire']),
    PokemonTransformArt(identifier: 'glimmora-mega', speciesId: 970, kind: 'mega', label: 'Mega', types: ['Rock', 'Poison']),
    PokemonTransformArt(identifier: 'tatsugiri-curly-mega', speciesId: 978, kind: 'mega', label: 'Mega (Curly)', types: ['Dragon', 'Water'], formKey: 'curly'),
    PokemonTransformArt(identifier: 'tatsugiri-droopy-mega', speciesId: 978, kind: 'mega', label: 'Mega (Droopy)', types: ['Dragon', 'Water'], formKey: 'droopy'),
    PokemonTransformArt(identifier: 'tatsugiri-stretchy-mega', speciesId: 978, kind: 'mega', label: 'Mega (Stretchy)', types: ['Dragon', 'Water'], formKey: 'stretchy'),
    PokemonTransformArt(identifier: 'baxcalibur-mega', speciesId: 998, kind: 'mega', label: 'Mega', types: ['Dragon', 'Ice']),
    PokemonTransformArt(identifier: 'meowstic-female-mega', speciesId: 678, kind: 'mega', label: 'Mega (Female)', types: ['Psychic'], formKey: 'female'),
  ];

  static PokemonTransformArt? byIdentifier(String identifier) {
    for (final art in all) {
      if (art.identifier == identifier) return art;
    }
    return null;
  }

  static List<PokemonTransformArt> megaOptions(
    int speciesId, {
    String? formName,
    String? gender,
  }) => _options('mega', speciesId, formName: formName, gender: gender);

  static List<PokemonTransformArt> gigamaxOptions(
    int speciesId, {
    String? formName,
    String? gender,
  }) => _options('gigamax', speciesId, formName: formName, gender: gender);

  static List<PokemonTransformArt> _options(
    String kind,
    int speciesId, {
    String? formName,
    String? gender,
  }) {
    final requested = <String>{
      _key(formName ?? ''),
      _key(gender ?? ''),
    }..remove('');
    return all.where((art) {
      if (art.speciesId != speciesId || art.kind != kind) return false;
      final formKey = art.formKey;
      if (formKey == null || requested.isEmpty) return true;
      return requested.any((value) => value == formKey || value.contains(formKey) || formKey.contains(value));
    }).toList(growable: false);
  }

  static String _key(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
