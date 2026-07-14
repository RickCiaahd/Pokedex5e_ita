import 'dart:convert';

import '../models/pc_pokemon.dart';
import '../models/pokemon_transfer_bundle.dart';
import '../models/team_slot.dart';
import '../repositories/pokemon_pc_repository.dart';
import '../repositories/team_repository.dart';

class PokemonTransferPlan {
  const PokemonTransferPlan({
    required this.updatedTeam,
    required this.toPc,
    required this.importedToTeam,
    required this.replacedPokemon,
    required this.overflowToPc,
  });

  final List<TeamSlot> updatedTeam;
  final List<TeamSlot> toPc;
  final int importedToTeam;
  final int replacedPokemon;
  final int overflowToPc;
}

class PokemonTransferImportResult {
  const PokemonTransferImportResult({
    required this.importedToTeam,
    required this.movedToPc,
    required this.replacedPokemon,
    required this.overflowToPc,
  });

  final int importedToTeam;
  final int movedToPc;
  final int replacedPokemon;
  final int overflowToPc;
}

class PokemonTransferService {
  PokemonTransferService({
    TeamRepository? teamRepository,
    PokemonPcRepository? pokemonPcRepository,
  }) : _teamRepository = teamRepository ?? TeamRepository(),
       _pokemonPcRepository = pokemonPcRepository ?? PokemonPcRepository();

  final TeamRepository _teamRepository;
  final PokemonPcRepository _pokemonPcRepository;

  String encode(PokemonTransferBundle bundle) {
    bundle.validate();
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }

  PokemonTransferBundle decode(String source) {
    final normalized = source.startsWith('\uFEFF') ? source.substring(1) : source;
    final decoded = jsonDecode(normalized);
    if (decoded is! Map) {
      throw const FormatException(
        'Il file selezionato non è un trasferimento valido.',
      );
    }
    return PokemonTransferBundle.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  String fileNameForPokemon(
    PokemonTransferBundle bundle, {
    required String displayName,
  }) {
    final safeName = _safeFilePart(displayName, fallback: 'pokemon');
    final date = bundle.exportedAt.toIso8601String().split('T').first;
    return 'pokedex-5e-pokemon-$safeName-$date.json';
  }

  String fileNameForTeam(PokemonTransferBundle bundle) {
    final trainer = _safeFilePart(
      bundle.sourceTrainerName,
      fallback: 'allenatore',
    );
    final date = bundle.exportedAt.toIso8601String().split('T').first;
    return 'pokedex-5e-squadra-$trainer-$date.json';
  }

  Future<PokemonTransferImportResult> importPokemon({
    required String profileId,
    required PokemonTransferBundle bundle,
    required int targetSlotIndex,
  }) async {
    final currentTeam = await _teamRepository.getTeam(profileId);
    final plan = planPokemonImport(
      currentTeam: currentTeam,
      bundle: bundle,
      targetSlotIndex: targetSlotIndex,
    );
    await _applyPlan(profileId: profileId, plan: plan);
    return _resultFor(plan);
  }

  Future<PokemonTransferImportResult> importTeam({
    required String profileId,
    required PokemonTransferBundle bundle,
    required int unlockedPokeslots,
  }) async {
    final currentTeam = await _teamRepository.getTeam(profileId);
    final plan = planTeamImport(
      currentTeam: currentTeam,
      bundle: bundle,
      unlockedPokeslots: unlockedPokeslots,
    );
    await _applyPlan(profileId: profileId, plan: plan);
    return _resultFor(plan);
  }

  static PokemonTransferPlan planPokemonImport({
    required List<TeamSlot> currentTeam,
    required PokemonTransferBundle bundle,
    required int targetSlotIndex,
  }) {
    bundle.validate();
    if (bundle.kind != PokemonTransferKind.pokemon) {
      throw const FormatException(
        'Seleziona un file esportato come singolo Pokémon.',
      );
    }
    if (targetSlotIndex < 0 || targetSlotIndex >= 6) {
      throw RangeError.range(targetSlotIndex, 0, 5, 'targetSlotIndex');
    }

    final team = _normalizeTeam(currentTeam);
    final target = team[targetSlotIndex];
    if (target.isEgg) {
      throw StateError(
        'Non puoi sostituire un uovo con un Pokémon importato.',
      );
    }

    final imported = _slotForIndex(bundle.pokemon.single, targetSlotIndex);
    final updatedTeam = [
      for (final slot in team)
        if (slot.slotIndex == targetSlotIndex) imported else slot,
    ];
    final toPc = target.isPokemon ? [target] : const <TeamSlot>[];

    return PokemonTransferPlan(
      updatedTeam: updatedTeam,
      toPc: toPc,
      importedToTeam: 1,
      replacedPokemon: target.isPokemon ? 1 : 0,
      overflowToPc: 0,
    );
  }

  static PokemonTransferPlan planTeamImport({
    required List<TeamSlot> currentTeam,
    required PokemonTransferBundle bundle,
    required int unlockedPokeslots,
  }) {
    bundle.validate();
    if (bundle.kind != PokemonTransferKind.team) {
      throw const FormatException(
        'Seleziona un file esportato come squadra.',
      );
    }

    final team = _normalizeTeam(currentTeam);
    final unlocked = unlockedPokeslots.clamp(1, 6).toInt();
    final targetIndices = [
      for (final slot in team)
        if (slot.slotIndex < unlocked && !slot.isEgg) slot.slotIndex,
    ];
    if (targetIndices.isEmpty) {
      throw StateError(
        'Non ci sono Pokéslot disponibili: gli slot sbloccati contengono uova.',
      );
    }

    final imported = bundle.pokemon;
    final importedToTeam = imported.length.clamp(0, targetIndices.length).toInt();
    final targetIndexSet = targetIndices.toSet();
    final replaced = [
      for (final slot in team)
        if (targetIndexSet.contains(slot.slotIndex) && slot.isPokemon) slot,
    ];

    final importedByTarget = <int, TeamSlot>{};
    for (var index = 0; index < importedToTeam; index++) {
      final targetIndex = targetIndices[index];
      importedByTarget[targetIndex] = _slotForIndex(
        imported[index],
        targetIndex,
      );
    }

    final updatedTeam = [
      for (final slot in team)
        if (!targetIndexSet.contains(slot.slotIndex))
          slot
        else
          importedByTarget[slot.slotIndex] ??
              TeamSlot(slotIndex: slot.slotIndex, pokemonId: null),
    ];
    final overflow = [
      for (var index = importedToTeam; index < imported.length; index++)
        _slotForIndex(imported[index], 0),
    ];

    return PokemonTransferPlan(
      updatedTeam: updatedTeam,
      toPc: [...replaced, ...overflow],
      importedToTeam: importedToTeam,
      replacedPokemon: replaced.length,
      overflowToPc: overflow.length,
    );
  }

  Future<void> _applyPlan({
    required String profileId,
    required PokemonTransferPlan plan,
  }) async {
    if (plan.toPc.isNotEmpty) {
      final stored = await _pokemonPcRepository.getPokemon(profileId);
      final seed = DateTime.now().microsecondsSinceEpoch;
      final additions = [
        for (final entry in plan.toPc.indexed)
          _pcFromSlot(entry.$2, id: 'transfer-${seed + entry.$1}'),
      ];
      await _pokemonPcRepository.savePokemon(
        profileId,
        [...additions, ...stored],
      );
    }
    await _teamRepository.saveTeam(profileId, plan.updatedTeam);
  }

  static PokemonTransferImportResult _resultFor(PokemonTransferPlan plan) {
    return PokemonTransferImportResult(
      importedToTeam: plan.importedToTeam,
      movedToPc: plan.toPc.length,
      replacedPokemon: plan.replacedPokemon,
      overflowToPc: plan.overflowToPc,
    );
  }

  static List<TeamSlot> _normalizeTeam(List<TeamSlot> source) {
    final byIndex = {
      for (final slot in source)
        if (slot.slotIndex >= 0 && slot.slotIndex < 6) slot.slotIndex: slot,
    };
    return List<TeamSlot>.generate(
      6,
      (index) => byIndex[index] ?? TeamSlot(slotIndex: index, pokemonId: null),
      growable: false,
    );
  }

  static TeamSlot _slotForIndex(TeamSlot source, int slotIndex) {
    final pokemonId = source.pokemonId;
    if (pokemonId == null) {
      throw const FormatException('Scheda Pokémon non valida.');
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

  static PcPokemon _pcFromSlot(TeamSlot slot, {required String id}) {
    final pokemonId = slot.pokemonId;
    if (pokemonId == null) {
      throw ArgumentError('Cannot move an empty slot to the PC.');
    }
    return PcPokemon(
      id: id,
      pokemonId: pokemonId,
      experience: slot.experience,
      currentHp: slot.currentHp,
      nickname: slot.nickname,
      selectedMoves: List<String>.from(slot.selectedMoves),
      isShiny: slot.isShiny,
      gender: slot.gender,
      formName: slot.formName,
      nature: slot.nature,
      heldItem: slot.heldItem,
      abilities: List<String>.from(slot.abilities),
      feats: List<String>.from(slot.feats),
      extraSkills: List<String>.from(slot.extraSkills),
      statusEffects: List<String>.from(slot.statusEffects),
      customAbilityScores: Map<String, int>.from(slot.customAbilityScores),
      loyalty: slot.loyalty,
      notes: 'Spostato automaticamente durante un’importazione.',
    );
  }

  static String _safeFilePart(String value, {required String fallback}) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? fallback : normalized;
  }
}
