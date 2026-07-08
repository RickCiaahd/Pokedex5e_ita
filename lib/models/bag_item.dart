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

  factory BagItem.fromWebJson(
    Map<String, dynamic> json, {
    Set<String>? availableSpriteAssets,
  }) {
    return BagItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Oggetto sconosciuto',
      type: _normalizeType(json['type']?.toString() ?? 'other'),
      description: _readDescription(json['description']),
      cost: _readCost(json['cost']),
      spriteAssetPath: _readSpritePath(
        json['media'],
        availableSpriteAssets: availableSpriteAssets,
      ),
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

  static String? _readSpritePath(
    dynamic media, {
    Set<String>? availableSpriteAssets,
  }) {
    if (media is! Map) return null;

    final rawPath = media['sprite']?.toString();
    if (rawPath == null || rawPath.isEmpty) return null;

    const webPrefix = '/assets/items/';
    final assetPath = rawPath.startsWith(webPrefix)
        ? 'assets/textures/textures_webapp/items/${rawPath.substring(webPrefix.length)}'
        : rawPath;

    if (availableSpriteAssets != null &&
        !availableSpriteAssets.contains(assetPath)) {
      return null;
    }

    return assetPath;
  }
}
