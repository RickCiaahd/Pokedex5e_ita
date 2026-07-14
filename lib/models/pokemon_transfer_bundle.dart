import 'team_slot.dart';

enum PokemonTransferKind { pokemon, team }

class PokemonTransferBundle {
  const PokemonTransferBundle({
    required this.formatVersion,
    required this.kind,
    required this.exportedAt,
    required this.sourceTrainerName,
    required this.pokemon,
  });

  static const String applicationId = 'pokedex-5e-ita';
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final PokemonTransferKind kind;
  final DateTime exportedAt;
  final String sourceTrainerName;
  final List<TeamSlot> pokemon;

  factory PokemonTransferBundle.single({
    required TeamSlot slot,
    required String sourceTrainerName,
    DateTime? exportedAt,
  }) {
    final bundle = PokemonTransferBundle(
      formatVersion: currentFormatVersion,
      kind: PokemonTransferKind.pokemon,
      exportedAt: exportedAt ?? DateTime.now(),
      sourceTrainerName: sourceTrainerName.trim(),
      pokemon: [_normalizeSlot(slot, 0)],
    );
    bundle.validate();
    return bundle;
  }

  factory PokemonTransferBundle.team({
    required Iterable<TeamSlot> slots,
    required String sourceTrainerName,
    DateTime? exportedAt,
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
    );
    bundle.validate();
    return bundle;
  }

  factory PokemonTransferBundle.fromJson(Map<String, dynamic> json) {
    if (json['application']?.toString() != applicationId) {
      throw const FormatException(
        'Il file non appartiene a Pokédex 5e ITA.',
      );
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
              TeamSlot.fromJson(
                Map<String, dynamic>.from(entry.$2 as Map),
              ),
              entry.$1,
            )
          else
            throw const FormatException('Scheda Pokémon non valida.'),
      ],
    );
    bundle.validate();
    return bundle;
  }

  void validate() {
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
    validate();
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
