class PokedexFormEntry {
  PokedexFormEntry({
    required this.key,
    required this.name,
    this.seen = false,
    this.caught = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String key;
  final String name;
  final bool seen;
  final bool caught;
  final DateTime updatedAt;

  PokedexFormEntry copyWith({
    String? key,
    String? name,
    bool? seen,
    bool? caught,
    DateTime? updatedAt,
  }) {
    final nextCaught = caught ?? this.caught;
    final nextSeen = nextCaught ? true : seen ?? this.seen;

    return PokedexFormEntry(
      key: key ?? this.key,
      name: name ?? this.name,
      seen: nextSeen,
      caught: nextSeen ? nextCaught : false,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'seen': seen,
      'caught': caught,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PokedexFormEntry.fromJson(
    String fallbackKey,
    Map<String, dynamic> json,
  ) {
    final caught = json['caught'] as bool? ?? false;
    final seen = (json['seen'] as bool? ?? false) || caught;
    final updatedAt = json['updatedAt']?.toString();

    return PokedexFormEntry(
      key: PokedexEntry.normalizeFormKey(
        json['key']?.toString() ?? fallbackKey,
      ),
      name: json['name']?.toString() ?? _defaultFormName(fallbackKey),
      seen: seen,
      caught: caught,
      updatedAt: DateTime.tryParse(updatedAt ?? '') ?? DateTime.now(),
    );
  }

  static String _defaultFormName(String key) {
    if (PokedexEntry.normalizeFormKey(key) == PokedexEntry.baseFormKey) {
      return 'Base';
    }

    return key
        .trim()
        .replaceAll('_', '-')
        .split('-')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class PokedexEntry {
  PokedexEntry({
    required this.pokemonId,
    bool seen = false,
    bool caught = false,
    Map<String, PokedexFormEntry> forms = const {},
    DateTime? updatedAt,
  })  : forms = Map<String, PokedexFormEntry>.unmodifiable(
          _seedForms(forms: forms, seen: seen, caught: caught),
        ),
        updatedAt = updatedAt ?? DateTime.now();

  static const String baseFormKey = 'base';

  final int pokemonId;
  final Map<String, PokedexFormEntry> forms;
  final DateTime updatedAt;

  bool get seen => forms.values.any((form) => form.seen);
  bool get caught => forms.values.any((form) => form.caught);

  static Map<String, PokedexFormEntry> _seedForms({
    required Map<String, PokedexFormEntry> forms,
    required bool seen,
    required bool caught,
  }) {
    final result = <String, PokedexFormEntry>{};

    for (final entry in forms.entries) {
      final key = normalizeFormKey(entry.key);
      final form = entry.value;
      result[key] = form.copyWith(key: key, updatedAt: form.updatedAt);
    }

    if ((seen || caught) && !result.containsKey(baseFormKey)) {
      result[baseFormKey] = PokedexFormEntry(
        key: baseFormKey,
        name: 'Base',
        seen: true,
        caught: caught,
      );
    }

    return result;
  }

  static String normalizeFormKey(String? value) {
    final normalized = (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    switch (normalized) {
      case '':
      case 'base':
      case 'default':
      case 'regular':
      case 'normal':
      case 'kanto':
        return baseFormKey;
      case 'alola':
        return 'alolan';
      case 'galar':
        return 'galarian';
      case 'hisui':
        return 'hisuian';
      case 'paldea':
        return 'paldean';
      default:
        return normalized;
    }
  }

  PokedexFormEntry formFor(String? formKey, {String? formName}) {
    final key = normalizeFormKey(formKey);
    return forms[key] ??
        PokedexFormEntry(
          key: key,
          name: formName ?? (key == baseFormKey ? 'Base' : key),
        );
  }

  PokedexFormEntry formForAliases(
    Iterable<String> aliases, {
    String? fallbackName,
  }) {
    final normalizedAliases = aliases.map(normalizeFormKey).toSet();
    final matching = <PokedexFormEntry>[
      for (final entry in forms.entries)
        if (normalizedAliases.contains(normalizeFormKey(entry.key))) entry.value,
    ];

    if (matching.isEmpty) {
      final key = normalizedAliases.isEmpty
          ? baseFormKey
          : normalizedAliases.first;
      return PokedexFormEntry(
        key: key,
        name: fallbackName ?? (key == baseFormKey ? 'Base' : key),
      );
    }

    matching.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return PokedexFormEntry(
      key: matching.first.key,
      name: matching.first.name,
      seen: matching.any((form) => form.seen),
      caught: matching.any((form) => form.caught),
      updatedAt: matching.first.updatedAt,
    );
  }

  PokedexEntry withFormStatus({
    required String formKey,
    String? formName,
    bool? seen,
    bool? caught,
  }) {
    final key = normalizeFormKey(formKey);
    final current = formFor(key, formName: formName);
    final nextCaught = caught ?? current.caught;
    final nextSeen = nextCaught ? true : seen ?? current.seen;
    final updatedForms = Map<String, PokedexFormEntry>.from(forms);

    if (!nextSeen && !nextCaught) {
      updatedForms.remove(key);
    } else {
      updatedForms[key] = current.copyWith(
        key: key,
        name: formName ?? current.name,
        seen: nextSeen,
        caught: nextCaught,
      );
    }

    return PokedexEntry(
      pokemonId: pokemonId,
      forms: updatedForms,
      updatedAt: DateTime.now(),
    );
  }

  PokedexEntry clearAllForms() {
    return PokedexEntry(pokemonId: pokemonId, updatedAt: DateTime.now());
  }

  PokedexEntry copyWith({
    int? pokemonId,
    bool? seen,
    bool? caught,
    Map<String, PokedexFormEntry>? forms,
    DateTime? updatedAt,
  }) {
    if (seen != null || caught != null) {
      final currentBase = formFor(baseFormKey, formName: 'Base');
      final nextCaught = caught ?? currentBase.caught;
      final nextSeen = nextCaught ? true : seen ?? currentBase.seen;
      return PokedexEntry(
        pokemonId: pokemonId ?? this.pokemonId,
        forms: Map<String, PokedexFormEntry>.from(this.forms)
          ..[baseFormKey] = currentBase.copyWith(
            seen: nextSeen,
            caught: nextSeen ? nextCaught : false,
          ),
        updatedAt: updatedAt ?? DateTime.now(),
      );
    }

    return PokedexEntry(
      pokemonId: pokemonId ?? this.pokemonId,
      forms: forms ?? this.forms,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory PokedexEntry.empty(int pokemonId) {
    return PokedexEntry(pokemonId: pokemonId);
  }

  Map<String, dynamic> toJson() {
    return {
      'pokemonId': pokemonId,
      'seen': seen,
      'caught': caught,
      'forms': {
        for (final entry in forms.entries) entry.key: entry.value.toJson(),
      },
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PokedexEntry.fromJson(Map<String, dynamic> json) {
    final markMode = json['markMode'] as String?;
    final updatedAt = json['updatedAt']?.toString();
    final legacySeen =
        (json['seen'] as bool?) ?? (markMode == 'seen' || markMode == 'caught');
    final legacyCaught = (json['caught'] as bool?) ?? markMode == 'caught';
    final forms = <String, PokedexFormEntry>{};
    final formsJson = json['forms'];

    if (formsJson is Map) {
      for (final entry in formsJson.entries) {
        if (entry.value is! Map) continue;
        final key = normalizeFormKey(entry.key.toString());
        forms[key] = PokedexFormEntry.fromJson(
          key,
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    return PokedexEntry(
      pokemonId: _readInt(json['pokemonId']),
      seen: forms.isEmpty && legacySeen,
      caught: forms.isEmpty && legacyCaught,
      forms: forms,
      updatedAt: DateTime.tryParse(updatedAt ?? '') ?? DateTime.now(),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
