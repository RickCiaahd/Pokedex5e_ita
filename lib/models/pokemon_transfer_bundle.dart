import 'custom_pokemon_definition.dart';
import 'team_slot.dart';

enum PokemonTransferKind { pokemon, team }

class PokemonTransferBundle {
  const PokemonTransferBundle({
    required this.formatVersion,
    required this.kind,
    required this.exportedAt,
    required this.sourceTrainerName,
    required this.pokemon,
    this.customPokemon = const [],
  });

  static const String applicationId = 'pokedex-5e-ita';
  static const int currentFormatVersion = 2;

  final int formatVersion;
  final PokemonTransferKind kind;
  final DateTime exportedAt;
  final String sourceTrainerName;
  final List<TeamSlot> pokemon;
  final List<CustomPokemonDefinition> customPokemon;

  factory PokemonTransferBundle.single({
    required TeamSlot slot,
    required String sourceTrainerName,
    DateTime? exportedAt,
    List<CustomPokemonDefinition> customPokemon = const [],
  }) {
    final bundle = PokemonTransferBundle(
      formatVersion: currentFormatVersion,
      kind: PokemonTransferKind.pokemon,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceTrainerName: sourceTrainerName.trim(),
      pokemon: [_normalizeSlot(slot, 0)],
      customPokemon: List<CustomPokemonDefinition>.unmodifiable(customPokemon),
    );
    bundle.validate();
    return bundle;
  }

  factory PokemonTransferBundle.team({
    required Iterable<TeamSlot> slots,
    required String sourceTrainerName,
    DateTime? exportedAt,
    List<CustomPokemonDefinition> customPokemon = const [],
  }) {
    final transferable = [
      for (final slot in slots)
        if (slot.isPokemon) slot,
    ];
    final bundle = PokemonTransferBundle(
      formatVersion: currentFormatVersion,
      kind: PokemonTransferKind.team,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceTrainerName: sourceTrainerName.trim(),
      pokemon: [
        for (final entry in transferable.indexed)
          _normalizeSlot(entry.$2, entry.$1),
      ],
      customPokemon: List<CustomPokemonDefinition>.unmodifiable(customPokemon),
    );
    bundle.validate();
    return bundle;
  }

  factory PokemonTransferBundle.fromJson(Map<String, dynamic> json) {
    if (json['application']?.toString() != applicationId) {
      throw const FormatException('Il file non appartiene a Pokédex 5e ITA.');
    }

    final kindName = json['kind']?.toString() ?? '';
    PokemonTransferKind? kind;
    for (final value in PokemonTransferKind.values) {
      if (value.name == kindName) {
        kind = value;
        break;
      }
    }
    if (kind == null) {
      throw const FormatException('Tipo di esportazione non riconosciuto.');
    }

    final rawPokemon = json['pokemon'];
    if (rawPokemon is! List) {
      throw const FormatException('Elenco Pokémon mancante o non valido.');
    }
    final rawCustomPokemon = json['customPokemon'];

    final bundle = PokemonTransferBundle(
      formatVersion: _readInt(json['formatVersion']),
      kind: kind,
      exportedAt:
          DateTime.tryParse(json['exportedAt']?.toString() ?? '') ??
          DateTime.now(),
      sourceTrainerName: json['sourceTrainerName']?.toString().trim() ?? '',
      pokemon: [
        for (final entry in rawPokemon.indexed)
          if (entry.$2 is Map)
            _normalizeSlot(
              TeamSlot.fromJson(Map<String, dynamic>.from(entry.$2 as Map)),
              entry.$1,
            )
          else
            throw const FormatException('Scheda Pokémon non valida.'),
      ],
      customPokemon: [
        for (final value
            in rawCustomPokemon is List ? rawCustomPokemon : const <dynamic>[])
          if (value is Map)
            CustomPokemonDefinition.fromJson(Map<String, dynamic>.from(value))
          else
            throw const FormatException('Definizione Fakemon non valida.'),
      ],
    );
    bundle.validate(requireEmbeddedDefinitions: bundle.formatVersion >= 2);
    return bundle;
  }

  PokemonTransferBundle copyWith({
    int? formatVersion,
    List<TeamSlot>? pokemon,
    List<CustomPokemonDefinition>? customPokemon,
  }) {
    return PokemonTransferBundle(
      formatVersion: formatVersion ?? this.formatVersion,
      kind: kind,
      exportedAt: exportedAt,
      sourceTrainerName: sourceTrainerName,
      pokemon: pokemon ?? this.pokemon,
      customPokemon: customPokemon ?? this.customPokemon,
    );
  }

  void validate({bool requireEmbeddedDefinitions = false}) {
    if (formatVersion < 1 || formatVersion > currentFormatVersion) {
      throw FormatException(
        'Versione del file non supportata: $formatVersion.',
      );
    }
    if (pokemon.isEmpty) {
      throw const FormatException('Il file non contiene Pokémon.');
    }
    if (pokemon.length > 6) {
      throw const FormatException(
        'Una squadra condivisa non può contenere più di 6 Pokémon.',
      );
    }
    if (kind == PokemonTransferKind.pokemon && pokemon.length != 1) {
      throw const FormatException(
        'Un file Pokémon deve contenere una sola creatura.',
      );
    }
    for (final slot in pokemon) {
      if (!slot.isPokemon || slot.isEgg || (slot.pokemonId ?? 0) <= 0) {
        throw const FormatException(
          'Il file contiene uno slot vuoto o un uovo non trasferibile.',
        );
      }
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
      final referencedCustomIds = {
        for (final slot in pokemon)
          if ((slot.pokemonId ?? 0) >=
              CustomPokemonDefinition.firstCustomPokemonId)
            slot.pokemonId!,
      };
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

  TeamSlot slotForIndex(int slotIndex, {int? fallbackCurrentHp}) {
    if (pokemon.isEmpty) {
      throw StateError('Il file non contiene Pokémon.');
    }
    final source = pokemon.first;
    return _normalizeSlot(
      source.copyWith(
        currentHp: source.currentHp > 0
            ? source.currentHp
            : fallbackCurrentHp ?? source.currentHp,
      ),
      slotIndex,
    );
  }

  Map<String, dynamic> toJson() {
    validate(requireEmbeddedDefinitions: formatVersion >= 2);
    return {
      'application': applicationId,
      'formatVersion': formatVersion,
      'kind': kind.name,
      'exportedAt': exportedAt.toIso8601String(),
      'sourceTrainerName': sourceTrainerName,
      'pokemon': [
        for (final entry in pokemon.indexed)
          _normalizeSlot(entry.$2, entry.$1).toJson(),
      ],
      if (formatVersion >= 2)
        'customPokemon': customPokemon
            .map((definition) => definition.toJson())
            .toList(growable: false),
    };
  }

  static TeamSlot _normalizeSlot(TeamSlot source, int slotIndex) {
    final pokemonId = source.pokemonId;
    if (pokemonId == null) {
      throw const FormatException(
        'Solo i Pokémon possono essere esportati singolarmente.',
      );
    }
    return TeamSlot(
      slotIndex: slotIndex,
      pokemonId: pokemonId,
      experience: source.experience,
      currentHp: source.currentHp,
      nickname: source.nickname,
      selectedMoves: List<String>.from(source.selectedMoves),
      isShiny: source.isShiny,
      gender: source.gender,
      formName: source.formName,
      nature: source.nature,
      heldItem: source.heldItem,
      abilities: List<String>.from(source.abilities),
      feats: List<String>.from(source.feats),
      extraSkills: List<String>.from(source.extraSkills),
      statusEffects: List<String>.from(source.statusEffects),
      customAbilityScores: Map<String, int>.from(source.customAbilityScores),
      loyalty: source.loyalty,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
