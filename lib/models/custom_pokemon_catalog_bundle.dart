import 'dart:convert';

import 'custom_pokemon_definition.dart';

class CustomPokemonCatalogBundle {
  const CustomPokemonCatalogBundle({
    required this.formatVersion,
    required this.exportedAt,
    required this.definitions,
    required this.checksum,
  });

  static const String applicationId = 'pokedex-5e-ita';
  static const String kind = 'fakemon-catalog';
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final DateTime exportedAt;
  final List<CustomPokemonDefinition> definitions;
  final String checksum;

  factory CustomPokemonCatalogBundle.create(
    Iterable<CustomPokemonDefinition> definitions, {
    DateTime? exportedAt,
  }) {
    final ordered = definitions.toList(growable: false)
      ..sort((a, b) => a.pokemonId.compareTo(b.pokemonId));
    _validateDefinitions(ordered);
    final effectiveExportedAt = (exportedAt ?? DateTime.now()).toUtc();
    final payload = _payload(
      formatVersion: currentFormatVersion,
      exportedAt: effectiveExportedAt,
      definitions: ordered,
    );
    return CustomPokemonCatalogBundle(
      formatVersion: currentFormatVersion,
      exportedAt: effectiveExportedAt,
      definitions: List<CustomPokemonDefinition>.unmodifiable(ordered),
      checksum: _checksum(jsonEncode(payload)),
    );
  }

  factory CustomPokemonCatalogBundle.fromJson(Map<String, dynamic> json) {
    if (json['application']?.toString() != applicationId ||
        json['kind']?.toString() != kind) {
      throw const FormatException(
        'Il file non è un catalogo Fakemon di Pokédex 5e ITA.',
      );
    }
    final version = _readInt(json['formatVersion']);
    if (version < 1 || version > currentFormatVersion) {
      throw FormatException(
        'Versione del catalogo Fakemon non supportata: $version.',
      );
    }
    final exportedAt =
        DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final rawDefinitions = json['definitions'];
    if (rawDefinitions is! List) {
      throw const FormatException('Elenco Fakemon mancante o non valido.');
    }
    final definitions = <CustomPokemonDefinition>[
      for (final value in rawDefinitions)
        if (value is Map)
          CustomPokemonDefinition.fromJson(Map<String, dynamic>.from(value))
        else
          throw const FormatException('Definizione Fakemon non valida.'),
    ];
    _validateDefinitions(definitions);

    final checksum = json['checksum']?.toString() ?? '';
    final expected = _checksum(
      jsonEncode(
        _payload(
          formatVersion: version,
          exportedAt: exportedAt,
          definitions: definitions,
        ),
      ),
    );
    if (checksum.isEmpty || checksum != expected) {
      throw const FormatException(
        'Il catalogo Fakemon è incompleto o è stato modificato.',
      );
    }

    return CustomPokemonCatalogBundle(
      formatVersion: version,
      exportedAt: exportedAt,
      definitions: List<CustomPokemonDefinition>.unmodifiable(definitions),
      checksum: checksum,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = _payload(
      formatVersion: formatVersion,
      exportedAt: exportedAt,
      definitions: definitions,
    );
    return {...payload, 'checksum': checksum};
  }

  static Map<String, dynamic> _payload({
    required int formatVersion,
    required DateTime exportedAt,
    required Iterable<CustomPokemonDefinition> definitions,
  }) {
    return {
      'application': applicationId,
      'kind': kind,
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'definitions': definitions
          .map((definition) => definition.toJson())
          .toList(growable: false),
    };
  }

  static void _validateDefinitions(
    Iterable<CustomPokemonDefinition> definitions,
  ) {
    final stableIds = <String>{};
    final pokemonIds = <int>{};
    for (final definition in definitions) {
      definition.validate();
      if (!stableIds.add(definition.stableId)) {
        throw FormatException(
          'Il catalogo contiene più copie di ${definition.name}.',
        );
      }
      if (!pokemonIds.add(definition.pokemonId)) {
        throw FormatException(
          'Il catalogo contiene più Fakemon con ID ${definition.pokemonId}.',
        );
      }
    }
  }

  static String _checksum(String source) {
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);
    for (final byte in utf8.encode(source)) {
      hash ^= BigInt.from(byte);
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
