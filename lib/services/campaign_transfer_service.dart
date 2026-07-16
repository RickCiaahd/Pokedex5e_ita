import 'dart:convert';

import '../models/campaign_transfer_bundle.dart';
import '../models/saved_encounter.dart';
import '../models/saved_npc_trainer.dart';
import '../repositories/saved_encounter_repository.dart';
import '../repositories/saved_npc_trainer_repository.dart';
import 'embedded_custom_pokemon_transfer_service.dart';

class CampaignTransferService {
  CampaignTransferService({
    SavedEncounterRepository? encounterRepository,
    SavedNpcTrainerRepository? trainerRepository,
    EmbeddedCustomPokemonTransferService? embeddedCustomPokemonService,
    DateTime Function()? clock,
  }) : _encounterRepository = encounterRepository ?? SavedEncounterRepository(),
       _trainerRepository = trainerRepository ?? SavedNpcTrainerRepository(),
       _embeddedCustomPokemonService =
           embeddedCustomPokemonService ??
           EmbeddedCustomPokemonTransferService(),
       _clock = clock ?? DateTime.now;

  final SavedEncounterRepository _encounterRepository;
  final SavedNpcTrainerRepository _trainerRepository;
  final EmbeddedCustomPokemonTransferService _embeddedCustomPokemonService;
  final DateTime Function() _clock;

  String encode(CampaignTransferBundle bundle) {
    bundle.validate(
      requireEmbeddedDefinitions:
          bundle.formatVersion >= CampaignTransferBundle.currentFormatVersion,
    );
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }

  Future<String> encodePortable(CampaignTransferBundle bundle) async {
    final definitions = await _embeddedCustomPokemonService
        .definitionsForPokemonIds(_referencedPokemonIds(bundle));
    final portableBundle = bundle.copyWith(
      formatVersion: CampaignTransferBundle.currentFormatVersion,
      customPokemon: definitions,
    );
    return encode(portableBundle);
  }

  CampaignTransferBundle decode(String source) {
    final normalized = source.startsWith('\uFEFF')
        ? source.substring(1)
        : source;
    final decoded = jsonDecode(normalized);
    if (decoded is! Map) {
      throw const FormatException(
        'Il file selezionato non è un trasferimento valido.',
      );
    }
    return CampaignTransferBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  String fileNameForEncounter(CampaignTransferBundle bundle) {
    if (bundle.kind != CampaignTransferKind.encounter) {
      throw const FormatException('Il trasferimento non contiene un incontro.');
    }
    final name = _safeName(bundle.encounter!.name, fallback: 'incontro');
    final date = bundle.exportedAt.toIso8601String().split('T').first;
    return 'pokedex-5e-incontro-$name-$date.json';
  }

  String fileNameForNpcTrainer(CampaignTransferBundle bundle) {
    if (bundle.kind != CampaignTransferKind.npcTrainer) {
      throw const FormatException(
        'Il trasferimento non contiene un Allenatore PNG.',
      );
    }
    final name = _safeName(bundle.npcTrainer!.name, fallback: 'allenatore-png');
    final date = bundle.exportedAt.toIso8601String().split('T').first;
    return 'pokedex-5e-allenatore-$name-$date.json';
  }

  Future<SavedEncounter> importEncounter({
    required String profileId,
    required CampaignTransferBundle bundle,
    required Set<int> catalogPokemonIds,
  }) async {
    final resolved = await _installEmbeddedCustomPokemon(bundle);
    final resolvedBundle = resolved.bundle;
    resolvedBundle.validate();
    if (resolvedBundle.kind != CampaignTransferKind.encounter) {
      throw const FormatException('Seleziona un file esportato come incontro.');
    }
    final source = resolvedBundle.encounter!;
    final availableIds = {
      ...catalogPokemonIds,
      ...resolved.installResult.pokemonIdMap.values,
    };
    final missingIds = {
      for (final member in source.members)
        if (!availableIds.contains(member.pokemonId)) member.pokemonId,
    };
    if (missingIds.isNotEmpty) {
      final values = missingIds.toList()..sort();
      throw FormatException(
        'Il catalogo non contiene i Pokémon: ${values.map((id) => '#$id').join(', ')}.',
      );
    }

    final existing = await _encounterRepository.getEncounters(profileId);
    final now = _clock();
    final imported = SavedEncounter(
      id: _newId(existing.map((item) => item.id), now),
      name: _uniqueName(source.name, existing.map((item) => item.name)),
      source: source.source,
      party: source.party,
      filters: source.filters,
      targetDifficulty: source.targetDifficulty,
      members: source.members,
      createdAt: now,
      updatedAt: now,
      notes: source.notes,
      collectionName: source.collectionName,
    );
    await _encounterRepository.saveEncounter(
      profileId: profileId,
      encounter: imported,
    );
    return imported;
  }

  Future<SavedNpcTrainer> importNpcTrainer({
    required String profileId,
    required CampaignTransferBundle bundle,
    required Set<int> catalogPokemonIds,
  }) async {
    final resolved = await _installEmbeddedCustomPokemon(bundle);
    final resolvedBundle = resolved.bundle;
    resolvedBundle.validate();
    if (resolvedBundle.kind != CampaignTransferKind.npcTrainer) {
      throw const FormatException(
        'Seleziona un file esportato come Allenatore PNG.',
      );
    }
    final source = resolvedBundle.npcTrainer!;
    final availableIds = {
      ...catalogPokemonIds,
      ...resolved.installResult.pokemonIdMap.values,
    };
    final missingIds = {
      for (final member in source.team)
        if (!availableIds.contains(member.pokemonId)) member.pokemonId,
    };
    if (missingIds.isNotEmpty) {
      final values = missingIds.toList()..sort();
      throw FormatException(
        'Il catalogo non contiene i Pokémon: ${values.map((id) => '#$id').join(', ')}.',
      );
    }

    final existing = await _trainerRepository.getTrainers(profileId);
    final now = _clock();
    final imported = source.copyWith(
      id: _newId(existing.map((item) => item.id), now),
      name: _uniqueName(source.name, existing.map((item) => item.name)),
      createdAt: now,
      updatedAt: now,
    );
    await _trainerRepository.saveTrainer(
      profileId: profileId,
      trainer: imported,
    );
    return imported;
  }

  Future<_ResolvedCampaignTransfer> _installEmbeddedCustomPokemon(
    CampaignTransferBundle bundle,
  ) async {
    bundle.validate(
      requireEmbeddedDefinitions:
          bundle.formatVersion >= CampaignTransferBundle.currentFormatVersion,
    );
    final installResult = await _embeddedCustomPokemonService
        .installDefinitions(bundle.customPokemon);
    if (installResult.pokemonIdMap.isEmpty) {
      return _ResolvedCampaignTransfer(
        bundle: bundle,
        installResult: installResult,
      );
    }

    switch (bundle.kind) {
      case CampaignTransferKind.encounter:
        final encounter = bundle.encounter!;
        final remapped = encounter.copyWith(
          members: [
            for (final member in encounter.members)
              SavedEncounterMember(
                pokemonId: installResult.resolvePokemonId(member.pokemonId),
                level: member.level,
                nature: member.nature,
                selectedMoves: List<String>.from(member.selectedMoves),
                isShiny: member.isShiny,
                maxHp: member.maxHp,
                formName: member.formName,
                gender: member.gender,
                ability: member.ability,
                isLocked: member.isLocked,
              ),
          ],
        );
        return _ResolvedCampaignTransfer(
          bundle: bundle.copyWith(
            formatVersion: 1,
            encounter: remapped,
            customPokemon: const [],
          ),
          installResult: installResult,
        );
      case CampaignTransferKind.npcTrainer:
        final trainer = bundle.npcTrainer!;
        final remapped = trainer.copyWith(
          team: [
            for (final member in trainer.team)
              SavedNpcPokemon(
                pokemonId: installResult.resolvePokemonId(member.pokemonId),
                level: member.level,
                nature: member.nature,
                selectedMoves: List<String>.from(member.selectedMoves),
                isShiny: member.isShiny,
                maxHp: member.maxHp,
                formName: member.formName,
                gender: member.gender,
                ability: member.ability,
              ),
          ],
        );
        return _ResolvedCampaignTransfer(
          bundle: bundle.copyWith(
            formatVersion: 1,
            npcTrainer: remapped,
            customPokemon: const [],
          ),
          installResult: installResult,
        );
    }
  }

  Iterable<int> _referencedPokemonIds(CampaignTransferBundle bundle) sync* {
    switch (bundle.kind) {
      case CampaignTransferKind.encounter:
        for (final member in bundle.encounter!.members) {
          yield member.pokemonId;
        }
        break;
      case CampaignTransferKind.npcTrainer:
        for (final member in bundle.npcTrainer!.team) {
          yield member.pokemonId;
        }
        break;
    }
  }

  String _newId(Iterable<String> existingIds, DateTime now) {
    final existing = existingIds.toSet();
    var value = now.microsecondsSinceEpoch;
    var candidate = value.toString();
    while (existing.contains(candidate)) {
      value += 1;
      candidate = value.toString();
    }
    return candidate;
  }

  String _uniqueName(String source, Iterable<String> existingNames) {
    final trimmed = source.trim().isEmpty
        ? 'Contenuto importato'
        : source.trim();
    final existing = existingNames
        .map((name) => name.trim().toLowerCase())
        .toSet();
    if (!existing.contains(trimmed.toLowerCase())) return trimmed;

    final base = '$trimmed (importato)';
    if (!existing.contains(base.toLowerCase())) return base;
    var index = 2;
    while (existing.contains('$base $index'.toLowerCase())) {
      index += 1;
    }
    return '$base $index';
  }

  String _safeName(String value, {required String fallback}) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? fallback : normalized;
  }
}

class _ResolvedCampaignTransfer {
  const _ResolvedCampaignTransfer({
    required this.bundle,
    required this.installResult,
  });

  final CampaignTransferBundle bundle;
  final EmbeddedCustomPokemonInstallResult installResult;
}
