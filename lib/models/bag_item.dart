class BagItem {
  const BagItem({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.cost,
    required this.spriteAssetPath,
  });

  final String id;
  final String name;
  final String type;
  final List<String> description;
  final int? cost;
  final String? spriteAssetPath;

  String get displayDescription {
    if (description.isEmpty) return 'Nessuna descrizione disponibile.';
    return description.join('\n\n');
  }

  List<String> get spriteUrls {
    final seen = <String>{};
    final urls = <String?>[
      sourceSpriteUrl,
      githubSpriteUrl,
      _fallbackSpriteUrl,
      _typeFallbackSpriteUrl,
    ];

    return urls
        .whereType<String>()
        .where((url) => seen.add(url))
        .toList(growable: false);
  }

  String? get sourceSpriteUrl {
    final originalPath = _originalWebappSpritePath;
    if (originalPath == null) return null;

    return _poke5eAssetUrl(originalPath);
  }

  String? get githubSpriteUrl {
    final path = spriteAssetPath;
    if (path == null) return null;

    return Uri.https(
      'raw.githubusercontent.com',
      '/RickCiaahd/Pokedex5e_ita/main/$path',
    ).toString();
  }

  String? get remoteSpriteUrl {
    final urls = spriteUrls;
    if (urls.isEmpty) return null;
    return urls.first;
  }

  String? get _fallbackSpriteUrl {
    final path = _fallbackSpritePathById[id];
    if (path == null) return null;

    return _poke5eAssetUrl(path);
  }

  String? get _typeFallbackSpriteUrl {
    final path = _fallbackSpritePathByType[type];
    if (path == null) return null;

    return _poke5eAssetUrl(path);
  }

  String? get _originalWebappSpritePath {
    final path = spriteAssetPath;
    if (path == null || path.isEmpty) return null;

    const localPrefix = 'assets/textures/textures_webapp/items/';
    if (path.startsWith(localPrefix)) {
      final relativePath = path.substring(localPrefix.length);
      if (relativePath.startsWith('mt/')) return null;

      return '/assets/items/$relativePath';
    }

    if (path.startsWith('/assets/')) {
      return path;
    }

    if (path.startsWith('assets/')) {
      return '/$path';
    }

    return path.startsWith('/') ? path : '/$path';
  }

  factory BagItem.fromWebJson(Map<String, dynamic> json) {
    return BagItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Oggetto sconosciuto',
      type: _normalizeType(json['type']?.toString() ?? 'other'),
      description: _readDescription(json['description']),
      cost: _readCost(json['cost']),
      spriteAssetPath: _readSpritePath(json['media']),
    );
  }

  static String _poke5eAssetUrl(String path) {
    return Uri.https('poke5e.app', path).toString();
  }

  static String _normalizeType(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '-');
  }

  static List<String> _readDescription(dynamic value) {
    if (value is List) {
      return value.map((entry) => entry.toString()).toList(growable: false);
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }

    return const [];
  }

  static int? _readCost(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _readSpritePath(dynamic media) {
    if (media is! Map) return null;

    final rawPath = media['sprite']?.toString();
    if (rawPath == null || rawPath.isEmpty) return null;

    const webPrefix = '/assets/items/';
    if (rawPath.startsWith(webPrefix)) {
      return 'assets/textures/textures_webapp/items/${rawPath.substring(webPrefix.length)}';
    }

    return rawPath;
  }

  static const Map<String, String> _fallbackSpritePathById = {
    'alola-stone': '/assets/items/ice-stone/sprite.png',
    'sweet': '/assets/items/whipped-dream/sprite.png',
    'cracked-pot': '/assets/items/sachet/sprite.png',
    'chipped-pot': '/assets/items/prism-scale/sprite.png',
    'unremarkable-teacup': '/assets/items/sachet/sprite.png',
    'masterpiece-teacup': '/assets/items/prism-scale/sprite.png',
    'galarica-wreath': '/assets/items/gracidea-flower/sprite.png',
    'black-augurite': '/assets/items/dusk-stone/sprite.png',
    'peat-block': '/assets/items/oval-stone/sprite.png',
    'auspicious-armor': '/assets/items/protector/sprite.png',
    'malicious-armor': '/assets/items/protector/sprite.png',
    'n-solarizer': '/assets/items/key-stone/sprite.png',
    'n-lunarizer': '/assets/items/key-stone/sprite.png',
    'pokedex': '/assets/items/trainers-license/sprite.png',
    'dynamax-band': '/assets/items/z-ring/sprite.png',
    'tera-orb': '/assets/items/key-stone/sprite.png',
    'capture-styler': '/assets/items/trainers-license/sprite.png',
    'backpack': '/assets/items/trainers-license/sprite.png',
    'binoculars': '/assets/items/reveal-glass/sprite.png',
    'camping-kettle': '/assets/items/moomoo-milk/sprite.png',
  };

  static const Map<String, String> _fallbackSpritePathByType = {
    'pokeball': '/assets/items/poke-ball/sprite.png',
    'medicine': '/assets/items/potion/sprite.png',
    'vitamin': '/assets/items/hp-up/sprite.png',
    'berry': '/assets/items/oran-berry/sprite.png',
    'held-item': '/assets/items/leftovers/sprite.png',
    'evolution': '/assets/items/dawn-stone/sprite.png',
    'trainer-gear': '/assets/items/trainers-license/sprite.png',
    'key-item': '/assets/items/key-stone/sprite.png',
    'tm': '/assets/items/key-stone/sprite.png',
  };
}
