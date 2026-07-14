import 'dart:convert';

import '../models/campaign_transfer_bundle.dart';
import '../models/saved_encounter.dart';
import '../models/saved_npc_trainer.dart';
import '../repositories/saved_encounter_repository.dart';
import '../repositories/saved_npc_trainer_repository.dart';

class CampaignTransferService {
  CampaignTransferService({
    SavedEncounterRepository? encounterRepository,
    SavedNpcTrainerRepository? trainerRepository,
    DateTime Function()? clock,
  }) : _encounterRepository = encounterRepository ?? SavedEncounterRepository(),
       _trainerRepository = trainerRepository ?? SavedNpcTrainerRepository(),
       _clock = clock ?? DateTime.now;

  final SavedEncounterRepository _encounterRepository;
  final SavedNpcTrainerRepository _trainerRepository;
  final DateTime Function() _clock;

  String encode(CampaignTransferBundle bundle) {
    bundle.validate();
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
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
    bundle.validate();
    if (bundle.kind != CampaignTransferKind.encounter) {
      throw const FormatException('Seleziona un file esportato come incontro.');
    }
    final source = bundle.encounter!;
    final missingIds = {
      for (final member in source.members)
        if (!catalogPokemonIds.contains(member.pokemonId)) member.pokemonId,
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
    bundle.validate();
    if (bundle.kind != CampaignTransferKind.npcTrainer) {
      throw const FormatException(
        'Seleziona un file esportato come Allenatore PNG.',
      );
    }
    final source = bundle.npcTrainer!;
    final missingIds = {
      for (final member in source.team)
        if (!catalogPokemonIds.contains(member.pokemonId)) member.pokemonId,
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
