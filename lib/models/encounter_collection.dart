class EncounterCollectionEntry {
  const EncounterCollectionEntry({
    required this.pokemonId,
    required this.weight,
    this.formName,
  });

  final int pokemonId;
  final int weight;
  final String? formName;

  EncounterCollectionEntry copyWith({
    int? pokemonId,
    int? weight,
    Object? formName = _unset,
  }) {
    return EncounterCollectionEntry(
      pokemonId: pokemonId ?? this.pokemonId,
      weight: weight ?? this.weight,
      formName: identical(formName, _unset) ? this.formName : formName as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'pokemonId': pokemonId,
    'weight': weight,
    'formName': formName,
  };

  factory EncounterCollectionEntry.fromJson(Map<String, dynamic> json) {
    return EncounterCollectionEntry(
      pokemonId: _readInt(json['pokemonId']),
      weight: _readInt(json['weight']),
      formName: _readNullableString(json['formName']),
    );
  }

  static const Object _unset = Object();
}

class EncounterCollection {
  const EncounterCollection({
    required this.id,
    required this.name,
    required this.entries,
    required this.updatedAt,
    this.notes = '',
  });

  final String id;
  final String name;
  final List<EncounterCollectionEntry> entries;
  final DateTime updatedAt;
  final String notes;

  int get totalWeight => entries.fold(0, (total, entry) => total + entry.weight);

  bool get isReady =>
      name.trim().isNotEmpty &&
      entries.isNotEmpty &&
      entries.every((entry) => entry.pokemonId > 0 && entry.weight > 0) &&
      totalWeight == 100;

  EncounterCollection copyWith({
    String? id,
    String? name,
    List<EncounterCollectionEntry>? entries,
    DateTime? updatedAt,
    String? notes,
  }) {
    return EncounterCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
  };

  factory EncounterCollection.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    return EncounterCollection(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      entries: rawEntries is List
          ? [
              for (final value in rawEntries)
                if (value is Map)
                  EncounterCollectionEntry.fromJson(
                    Map<String, dynamic>.from(value),
                  ),
            ]
          : const [],
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString() ?? '',
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
