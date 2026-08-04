import 'item_driven_pokemon_form.dart';
import 'pokemon.dart';

class PokedexFormEntry {
  final String key;
  final String? formName;
  final bool seen;
  final bool caught;
  final DateTime updatedAt;

  const PokedexFormEntry({
    required this.key,
    required this.formName,
    required this.seen,
    required this.caught,
    required this.updatedAt,
  });

  factory PokedexFormEntry.empty({
    required String key,
    required String? formName,
  }) {
    return PokedexFormEntry(
      key: key,
      formName: formName,
      seen: false,
      caught: false,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'formName': formName,
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
    final updatedAt = json['updatedAt']?.toString();
    final key = json['key']?.toString().trim();

    return PokedexFormEntry(
      key: key == null || key.isEmpty ? fallbackKey : key,
      formName: json['formName']?.toString(),
      seen: (json['seen'] as bool? ?? false) || caught,
      caught: caught,
      updatedAt: DateTime.tryParse(updatedAt ?? '') ?? DateTime.now(),
    );
  }
}

class PokedexOwnedForm {
  const PokedexOwnedForm({required this.pokemonId, this.formName});

  final int pokemonId;
  final String? formName;
}

class PokedexEntry {
  final int pokemonId;
  final Map<String, PokedexFormEntry> forms;
  final DateTime updatedAt;

  PokedexEntry({
    required this.pokemonId,
    bool seen = false,
    bool caught = false,
    Map<String, PokedexFormEntry> forms = const {},
    DateTime? updatedAt,
  }) : forms = _initialForms(
         forms: forms,
         seen: seen,
         caught: caught,
         updatedAt: updatedAt,
       ),
       updatedAt = updatedAt ?? DateTime.now();

  bool get seen => forms.values.any((entry) => entry.seen);

  bool get caught => forms.values.any((entry) => entry.caught);

  static Map<String, PokedexFormEntry> _initialForms({
    required Map<String, PokedexFormEntry> forms,
    required bool seen,
    required bool caught,
    required DateTime? updatedAt,
  }) {
    if (forms.isNotEmpty) return Map.unmodifiable(Map.of(forms));
    if (!seen && !caught) return const {};

    final timestamp = updatedAt ?? DateTime.now();
    return Map.unmodifiable({
      'base': PokedexFormEntry(
        key: 'base',
        formName: null,
        seen: seen || caught,
        caught: caught,
        updatedAt: timestamp,
      ),
    });
  }

  static String formKey(String? formName, {String speciesName = ''}) {
    return Pokemon.formReferenceKey(formName ?? '', speciesName);
  }

  static String? displayNameFor(String? formName, {String speciesName = ''}) {
    final key = formKey(formName, speciesName: speciesName);
    switch (key) {
      case 'base':
        return null;
      case 'alolan':
        return 'Alolan';
      case 'galarian':
        return 'Galarian';
      case 'hisuian':
        return 'Hisuian';
      case 'paldean':
        return 'Paldean';
      default:
        return key
            .split('-')
            .where((word) => word.isNotEmpty)
            .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }

  static bool isTrackableForm(String? formName, {String speciesName = ''}) {
    final key = formKey(formName, speciesName: speciesName);
    if (key != 'base' &&
        ItemDrivenPokemonForm.usesHeldItemFormForSpecies(speciesName)) {
      return false;
    }
    const temporaryTokens = {
      'mega',
      'gigantamax',
      'gmax',
      'dynamax',
      'terastal',
      'primal',
    };
    final parts = key.split('-').toSet();
    return !parts.any(temporaryTokens.contains);
  }

  PokedexFormEntry formFor(String? formName, {String speciesName = ''}) {
    final key = formKey(formName, speciesName: speciesName);
    final direct = forms[key];
    if (direct != null) return direct;

    for (final entry in forms.values) {
      if (formKey(entry.formName, speciesName: speciesName) == key) {
        return entry;
      }
    }

    return PokedexFormEntry.empty(
      key: key,
      formName: displayNameFor(formName, speciesName: speciesName),
    );
  }

  PokedexEntry setFormState({
    required String? formName,
    required bool seen,
    required bool caught,
    String speciesName = '',
    DateTime? updatedAt,
  }) {
    final key = formKey(formName, speciesName: speciesName);
    final timestamp = updatedAt ?? DateTime.now();
    final normalizedCaught = caught;
    final normalizedSeen = seen || normalizedCaught;
    final nextForms = Map<String, PokedexFormEntry>.of(forms);
    nextForms.removeWhere((existingKey, entry) {
      if (existingKey == key) return false;
      return formKey(entry.formName, speciesName: speciesName) == key;
    });

    if (!normalizedSeen && !normalizedCaught) {
      nextForms.remove(key);
    } else {
      nextForms[key] = PokedexFormEntry(
        key: key,
        formName: displayNameFor(formName, speciesName: speciesName),
        seen: normalizedSeen,
        caught: normalizedCaught,
        updatedAt: timestamp,
      );
    }

    return PokedexEntry(
      pokemonId: pokemonId,
      forms: nextForms,
      updatedAt: timestamp,
    );
  }

  PokedexEntry clearAllForms() {
    return PokedexEntry(pokemonId: pokemonId, forms: const {});
  }

  PokedexEntry copyWith({
    int? pokemonId,
    bool? seen,
    bool? caught,
    Map<String, PokedexFormEntry>? forms,
    DateTime? updatedAt,
  }) {
    if (forms != null) {
      return PokedexEntry(
        pokemonId: pokemonId ?? this.pokemonId,
        forms: forms,
        updatedAt: updatedAt,
      );
    }

    final target = PokedexEntry(
      pokemonId: pokemonId ?? this.pokemonId,
      forms: this.forms,
      updatedAt: updatedAt ?? this.updatedAt,
    );
    if (seen == null && caught == null) return target;

    final base = target.formFor(null);
    return target.setFormState(
      formName: null,
      seen: seen ?? base.seen,
      caught: caught ?? base.caught,
      updatedAt: updatedAt,
    );
  }

  String? get preferredFormName {
    PokedexFormEntry? preferred(Iterable<PokedexFormEntry> entries) {
      final list = entries.toList(growable: false);
      if (list.isEmpty) return null;
      for (final entry in list) {
        if (entry.key == 'base') return entry;
      }
      list.sort((a, b) {
        final updated = b.updatedAt.compareTo(a.updatedAt);
        return updated != 0 ? updated : a.key.compareTo(b.key);
      });
      return list.first;
    }

    final caughtEntry = preferred(forms.values.where((entry) => entry.caught));
    if (caughtEntry != null) return caughtEntry.formName;

    final seenEntry = preferred(forms.values.where((entry) => entry.seen));
    return seenEntry?.formName;
  }

  PokedexEntry viewForForm(String? formName, {String speciesName = ''}) {
    final selected = formFor(formName, speciesName: speciesName);
    if (!selected.seen && !selected.caught) {
      return PokedexEntry.empty(pokemonId);
    }
    return PokedexEntry(
      pokemonId: pokemonId,
      forms: {selected.key: selected},
      updatedAt: selected.updatedAt,
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
    final updatedAtValue = json['updatedAt']?.toString();
    final updatedAt = DateTime.tryParse(updatedAtValue ?? '') ?? DateTime.now();
    final rawForms = json['forms'];
    final parsedForms = <String, PokedexFormEntry>{};

    if (rawForms is Map) {
      for (final entry in rawForms.entries) {
        if (entry.value is! Map) continue;
        final key = entry.key.toString();
        parsedForms[key] = PokedexFormEntry.fromJson(
          key,
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    final legacySeen =
        (json['seen'] as bool?) ?? (markMode == 'seen' || markMode == 'caught');
    final legacyCaught = (json['caught'] as bool?) ?? markMode == 'caught';

    return PokedexEntry(
      pokemonId: json['pokemonId'] as int,
      seen: parsedForms.isEmpty && legacySeen,
      caught: parsedForms.isEmpty && legacyCaught,
      forms: parsedForms,
      updatedAt: updatedAt,
    );
  }
}
