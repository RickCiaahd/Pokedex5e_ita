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

  String? get sourceSpriteUrl {
    final originalPath = _originalWebappSpritePath;
    if (originalPath == null) return null;

    return Uri.https('poke5e.app', originalPath).toString();
  }

  String? get githubSpriteUrl {
    final path = spriteAssetPath;
    if (path == null) return null;

    return Uri.https(
      'raw.githubusercontent.com',
      '/RickCiaahd/Pokedex5e_ita/main/$path',
    ).toString();
  }

  String? get remoteSpriteUrl => sourceSpriteUrl;

  String? get _originalWebappSpritePath {
    final path = spriteAssetPath;
    if (path == null || path.isEmpty) return null;

    const localPrefix = 'assets/textures/textures_webapp/items/';
    if (path.startsWith(localPrefix)) {
      return '/assets/items/${path.substring(localPrefix.length)}';
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
}
