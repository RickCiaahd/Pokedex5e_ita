import 'custom_pokemon_definition.dart';
import 'saved_encounter.dart';
import 'saved_npc_trainer.dart';

enum CampaignTransferKind { encounter, npcTrainer }

class CampaignTransferBundle {
  const CampaignTransferBundle({
    required this.formatVersion,
    required this.kind,
    required this.exportedAt,
    required this.sourceProfileName,
    this.encounter,
    this.npcTrainer,
    this.customPokemon = const [],
  });

  static const String applicationId = 'pokedex-5e-ita';
  static const int currentFormatVersion = 2;

  final int formatVersion;
  final CampaignTransferKind kind;
  final DateTime exportedAt;
  final String sourceProfileName;
  final SavedEncounter? encounter;
  final SavedNpcTrainer? npcTrainer;
  final List<CustomPokemonDefinition> customPokemon;

  factory CampaignTransferBundle.forEncounter({
    required SavedEncounter encounter,
    required String sourceProfileName,
    DateTime? exportedAt,
    List<CustomPokemonDefinition> customPokemon = const [],
  }) {
    return CampaignTransferBundle(
      formatVersion: currentFormatVersion,
      kind: CampaignTransferKind.encounter,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceProfileName: sourceProfileName.trim(),
      encounter: encounter,
      customPokemon: List<CustomPokemonDefinition>.unmodifiable(customPokemon),
    );
  }

  factory CampaignTransferBundle.forNpcTrainer({
    required SavedNpcTrainer npcTrainer,
    required String sourceProfileName,
    DateTime? exportedAt,
    List<CustomPokemonDefinition> customPokemon = const [],
  }) {
    return CampaignTransferBundle(
      formatVersion: currentFormatVersion,
      kind: CampaignTransferKind.npcTrainer,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceProfileName: sourceProfileName.trim(),
      npcTrainer: npcTrainer,
      customPokemon: List<CustomPokemonDefinition>.unmodifiable(customPokemon),
    );
  }

  CampaignTransferBundle copyWith({
    int? formatVersion,
    SavedEncounter? encounter,
    SavedNpcTrainer? npcTrainer,
    List<CustomPokemonDefinition>? customPokemon,
  }) {
    return CampaignTransferBundle(
      formatVersion: formatVersion ?? this.formatVersion,
      kind: kind,
      exportedAt: exportedAt,
      sourceProfileName: sourceProfileName,
      encounter: encounter ?? this.encounter,
      npcTrainer: npcTrainer ?? this.npcTrainer,
      customPokemon: customPokemon ?? this.customPokemon,
    );
  }

  void validate({bool requireEmbeddedDefinitions = false}) {
    if (formatVersion < 1 || formatVersion > currentFormatVersion) {
      throw FormatException(
        'Versione del trasferimento non supportata: $formatVersion.',
      );
    }
    switch (kind) {
      case CampaignTransferKind.encounter:
        if (encounter == null || npcTrainer != null || !encounter!.isValid) {
          throw const FormatException(
            'Il file non contiene un incontro valido.',
          );
        }
        break;
      case CampaignTransferKind.npcTrainer:
        if (npcTrainer == null || encounter != null || !npcTrainer!.isValid) {
          throw const FormatException(
            'Il file non contiene un Allenatore PNG valido.',
          );
        }
        break;
    }

    final customByPokemonId = <int, CustomPokemonDefinition>{};
    final stableIds = <String>{};
    for (final definition in customPokemon) {
      definition.validate();
      if (!stableIds.add(definition.stableId) ||
          customByPokemonId.containsKey(definition.pokemonId)) {
        throw const FormatException(
          'Il trasferimento contiene definizioni Fakemon duplicate.',
        );
      }
      customByPokemonId[definition.pokemonId] = definition;
    }

    if (requireEmbeddedDefinitions) {
      final referencedCustomIds = _referencedPokemonIds()
          .where(
            (pokemonId) =>
                pokemonId >= CustomPokemonDefinition.firstCustomPokemonId,
          )
          .toSet();
      final missing = referencedCustomIds.difference(
        customByPokemonId.keys.toSet(),
      );
      if (missing.isNotEmpty) {
        final ordered = missing.toList()..sort();
        throw FormatException(
          'Il trasferimento non include le definizioni Fakemon per '
          '${ordered.map((id) => '#$id').join(', ')}.',
        );
      }
      final unused = customByPokemonId.keys.toSet().difference(
        referencedCustomIds,
      );
      if (unused.isNotEmpty) {
        throw const FormatException(
          'Il trasferimento contiene definizioni Fakemon non utilizzate.',
        );
      }
    }
  }

  Iterable<int> _referencedPokemonIds() sync* {
    switch (kind) {
      case CampaignTransferKind.encounter:
        for (final member in encounter!.members) {
          yield member.pokemonId;
        }
        break;
      case CampaignTransferKind.npcTrainer:
        for (final member in npcTrainer!.team) {
          yield member.pokemonId;
        }
        break;
    }
  }

  Map<String, dynamic> toJson() {
    validate(requireEmbeddedDefinitions: formatVersion >= 2);
    return {
      'application': applicationId,
      'formatVersion': formatVersion,
      'kind': kind.name,
      'exportedAt': exportedAt.toIso8601String(),
      'sourceProfileName': sourceProfileName,
      'data': switch (kind) {
        CampaignTransferKind.encounter => encounter!.toJson(),
        CampaignTransferKind.npcTrainer => npcTrainer!.toJson(),
      },
      if (formatVersion >= 2)
        'customPokemon': customPokemon
            .map((definition) => definition.toJson())
            .toList(growable: false),
    };
  }

  factory CampaignTransferBundle.fromJson(Map<String, dynamic> json) {
    if (json['application']?.toString() != applicationId) {
      throw const FormatException('Il file non appartiene a Trainer Atlas 5e.');
    }
    final version = _readInt(json['formatVersion']);
    if (version < 1 || version > currentFormatVersion) {
      throw FormatException(
        'Versione del trasferimento non supportata: $version.',
      );
    }
    final kindName = json['kind']?.toString() ?? '';
    final kind = CampaignTransferKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => throw const FormatException(
        'Tipo di trasferimento non riconosciuto.',
      ),
    );
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : throw const FormatException('Il contenuto del file non è valido.');
    final rawCustomPokemon = json['customPokemon'];
    final bundle = CampaignTransferBundle(
      formatVersion: version,
      kind: kind,
      exportedAt:
          DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
          DateTime.now(),
      sourceProfileName: json['sourceProfileName']?.toString().trim() ?? '',
      encounter: kind == CampaignTransferKind.encounter
          ? SavedEncounter.fromJson(data)
          : null,
      npcTrainer: kind == CampaignTransferKind.npcTrainer
          ? SavedNpcTrainer.fromJson(data)
          : null,
      customPokemon: [
        for (final value
            in rawCustomPokemon is List ? rawCustomPokemon : const <dynamic>[])
          if (value is Map)
            CustomPokemonDefinition.fromJson(Map<String, dynamic>.from(value))
          else
            throw const FormatException('Definizione Fakemon non valida.'),
      ],
    );
    bundle.validate(requireEmbeddedDefinitions: version >= 2);
    return bundle;
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
