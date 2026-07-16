import 'dart:convert';

import '../models/custom_pokemon_definition.dart';
import '../models/custom_pokemon_transfer_bundle.dart';
import '../repositories/custom_pokemon_repository.dart';

class CustomPokemonImportResult {
  const CustomPokemonImportResult({
    required this.definition,
    required this.updatedExisting,
    required this.remappedPokemonId,
  });

  final CustomPokemonDefinition definition;
  final bool updatedExisting;
  final bool remappedPokemonId;
}

class CustomPokemonTransferService {
  CustomPokemonTransferService({CustomPokemonRepository? repository})
    : _repository = repository ?? CustomPokemonRepository();

  final CustomPokemonRepository _repository;

  String encode(CustomPokemonDefinition definition) {
    final bundle = CustomPokemonTransferBundle.create(definition);
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }

  CustomPokemonTransferBundle decode(String source) {
    final normalized = source.startsWith('\uFEFF') ? source.substring(1) : source;
    final decoded = jsonDecode(normalized);
    if (decoded is! Map) {
      throw const FormatException('Il file Fakemon non contiene un oggetto JSON.');
    }
    return CustomPokemonTransferBundle.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  String fileNameFor(CustomPokemonDefinition definition) {
    final safeName = definition.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${safeName.isEmpty ? 'fakemon' : safeName}.p5fakemon';
  }

  Future<CustomPokemonImportResult> importBundle(
    CustomPokemonTransferBundle bundle, {
    bool duplicate = false,
  }) async {
    final incoming = bundle.definition;
    final existing = await _repository.getByStableId(incoming.stableId);
    final now = DateTime.now().toUtc();

    if (existing != null && !duplicate) {
      final updated = _copyDefinition(
        incoming,
        stableId: existing.stableId,
        pokemonId: existing.pokemonId,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      await _repository.save(updated);
      return CustomPokemonImportResult(
        definition: updated,
        updatedExisting: true,
        remappedPokemonId: incoming.pokemonId != existing.pokemonId,
      );
    }

    var stableId = incoming.stableId;
    var pokemonId = incoming.pokemonId;
    var remapped = false;

    if (duplicate || await _repository.containsStableId(stableId)) {
      stableId = _repository.createStableId();
      remapped = true;
    }
    if (duplicate || await _repository.containsPokemonId(pokemonId)) {
      pokemonId = await _repository.allocatePokemonId();
      remapped = true;
    }

    final imported = _copyDefinition(
      incoming,
      stableId: stableId,
      pokemonId: pokemonId,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(imported);
    return CustomPokemonImportResult(
      definition: imported,
      updatedExisting: false,
      remappedPokemonId: remapped,
    );
  }

  CustomPokemonDefinition _copyDefinition(
    CustomPokemonDefinition source, {
    required String stableId,
    required int pokemonId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return CustomPokemonDefinition(
      formatVersion: CustomPokemonDefinition.currentFormatVersion,
      stableId: stableId,
      pokemonId: pokemonId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: source.name,
      author: source.author,
      types: List<String>.from(source.types),
      armorClass: source.armorClass,
      hitPoints: source.hitPoints,
      size: source.size,
      speed: source.speed,
      attributes: source.attributes,
      abilities: List<String>.from(source.abilities),
      hiddenAbility: source.hiddenAbility,
      skills: List<String>.from(source.skills),
      savingThrows: List<String>.from(source.savingThrows),
      startingMoves: List<String>.from(source.startingMoves),
      levelMoves: {
        for (final entry in source.levelMoves.entries)
          entry.key: List<String>.from(entry.value),
      },
      tmMoves: List<int>.from(source.tmMoves),
      eggMoves: List<String>.from(source.eggMoves),
      hitDice: source.hitDice,
      sr: source.sr,
      minLevelFound: source.minLevelFound,
      description: source.description,
      genus: source.genus,
      height: source.height,
      weight: source.weight,
      genderRatio: source.genderRatio,
      creatorNotes: source.creatorNotes,
      imageMimeType: source.imageMimeType,
      imageBase64: source.imageBase64,
      localMoves: List<CustomPokemonMoveDefinition>.from(source.localMoves),
      localAbilities: List<CustomPokemonAbilityDefinition>.from(
        source.localAbilities,
      ),
    );
  }
}
