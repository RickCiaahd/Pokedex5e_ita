import 'dart:convert';

import 'custom_pokemon_definition.dart';

class CustomPokemonTransferBundle {
  const CustomPokemonTransferBundle({
    required this.formatVersion,
    required this.exportedAt,
    required this.definition,
    required this.checksum,
  });

  static const String applicationId = 'pokedex-5e-ita';
  static const String kind = 'fakemon';
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final DateTime exportedAt;
  final CustomPokemonDefinition definition;
  final String checksum;

  factory CustomPokemonTransferBundle.create(
    CustomPokemonDefinition definition, {
    DateTime? exportedAt,
  }) {
    definition.validate();
    final effectiveExportedAt = exportedAt ?? DateTime.now().toUtc();
    final payload = _payload(
      formatVersion: currentFormatVersion,
      exportedAt: effectiveExportedAt,
      definition: definition,
    );
    return CustomPokemonTransferBundle(
      formatVersion: currentFormatVersion,
      exportedAt: effectiveExportedAt,
      definition: definition,
      checksum: _checksum(jsonEncode(payload)),
    );
  }

  factory CustomPokemonTransferBundle.fromJson(Map<String, dynamic> json) {
    if (json['application']?.toString() != applicationId ||
        json['kind']?.toString() != kind) {
      throw const FormatException(
        'Il file non è un Fakemon di Pokédex 5e ITA.',
      );
    }
    final version = _readInt(json['formatVersion']);
    if (version < 1 || version > currentFormatVersion) {
      throw FormatException(
        'Versione del file Fakemon non supportata: $version.',
      );
    }
    final rawDefinition = json['definition'];
    if (rawDefinition is! Map) {
      throw const FormatException('Scheda Fakemon mancante o non valida.');
    }
    final exportedAt =
        DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final definition = CustomPokemonDefinition.fromJson(
      Map<String, dynamic>.from(rawDefinition),
    );
    final checksum = json['checksum']?.toString() ?? '';
    final expected = _checksum(
      jsonEncode(
        _payload(
          formatVersion: version,
          exportedAt: exportedAt,
          definition: definition,
        ),
      ),
    );
    if (checksum.isEmpty || checksum != expected) {
      throw const FormatException(
        'Il file Fakemon è incompleto o è stato modificato.',
      );
    }

    return CustomPokemonTransferBundle(
      formatVersion: version,
      exportedAt: exportedAt,
      definition: definition,
      checksum: checksum,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = _payload(
      formatVersion: formatVersion,
      exportedAt: exportedAt,
      definition: definition,
    );
    return {...payload, 'checksum': checksum};
  }

  static Map<String, dynamic> _payload({
    required int formatVersion,
    required DateTime exportedAt,
    required CustomPokemonDefinition definition,
  }) {
    return {
      'application': applicationId,
      'kind': kind,
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'definition': definition.toJson(),
    };
  }

  static String _checksum(String source) {
    // FNV-1a a 64 bit. BigInt mantiene esattamente gli stessi 64 bit anche
    // quando il codice viene compilato per JavaScript, dove gli int ordinari
    // non possono rappresentare con precisione valori oltre 53 bit.
    final offsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);

    var hash = offsetBasis;
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
