import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/battle_session.dart';
import 'package:pokedex_5e_ita/models/campaign_transfer_bundle.dart';
import 'package:pokedex_5e_ita/models/generated_encounter.dart';
import 'package:pokedex_5e_ita/models/generated_npc_trainer.dart';
import 'package:pokedex_5e_ita/models/master_battle_session.dart';
import 'package:pokedex_5e_ita/models/saved_encounter.dart';
import 'package:pokedex_5e_ita/models/saved_npc_trainer.dart';
import 'package:pokedex_5e_ita/repositories/saved_encounter_repository.dart';
import 'package:pokedex_5e_ita/repositories/saved_npc_trainer_repository.dart';
import 'package:pokedex_5e_ita/services/campaign_transfer_service.dart';
import 'package:pokedex_5e_ita/services/master_fight_summary_service.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 7, 15, 12);

  group('CampaignTransferBundle', () {
    test('serializza e rilegge un incontro', () {
      final service = CampaignTransferService(clock: () => fixedTime);
      final bundle = CampaignTransferBundle.forEncounter(
        encounter: _encounter(),
        sourceProfileName: 'Misty',
        exportedAt: fixedTime,
      );

      final decoded = service.decode(service.encode(bundle));

      expect(decoded.kind, CampaignTransferKind.encounter);
      expect(decoded.sourceProfileName, 'Misty');
      expect(decoded.encounter!.name, 'Bosco notturno');
      expect(decoded.encounter!.members.single.pokemonId, 25);
    });

    test('serializza e rilegge un Allenatore PNG', () {
      final service = CampaignTransferService(clock: () => fixedTime);
      final bundle = CampaignTransferBundle.forNpcTrainer(
        npcTrainer: _trainer(),
        sourceProfileName: 'Brock',
        exportedAt: fixedTime,
      );

      final decoded = service.decode(service.encode(bundle));

      expect(decoded.kind, CampaignTransferKind.npcTrainer);
      expect(decoded.npcTrainer!.displayName, 'Iris, la Saetta');
      expect(decoded.npcTrainer!.team.single.selectedMoves, ['Thunder Shock']);
    });
  });

  group('CampaignTransferService imports', () {
    test('importa un incontro con nuovo id e nome non distruttivo', () async {
      final repository = _FakeEncounterRepository([
        _encounter(id: 'existing', name: 'Bosco notturno'),
      ]);
      final service = CampaignTransferService(
        encounterRepository: repository,
        trainerRepository: _FakeTrainerRepository(),
        clock: () => fixedTime,
      );
      final imported = await service.importEncounter(
        profileId: 'profile',
        bundle: CampaignTransferBundle.forEncounter(
          encounter: _encounter(collectionId: 'foreign-collection'),
          sourceProfileName: 'Misty',
          exportedAt: fixedTime,
        ),
        catalogPokemonIds: {25},
      );

      expect(imported.id, fixedTime.microsecondsSinceEpoch.toString());
      expect(imported.name, 'Bosco notturno (importato)');
      expect(imported.collectionId, isNull);
      expect(repository.items.first.id, imported.id);
    });

    test('importa un Allenatore PNG e conserva la scheda', () async {
      final repository = _FakeTrainerRepository([
        _trainer(id: 'existing', name: 'Iris'),
      ]);
      final service = CampaignTransferService(
        encounterRepository: _FakeEncounterRepository(),
        trainerRepository: repository,
        clock: () => fixedTime,
      );
      final imported = await service.importNpcTrainer(
        profileId: 'profile',
        bundle: CampaignTransferBundle.forNpcTrainer(
          npcTrainer: _trainer(),
          sourceProfileName: 'Brock',
          exportedAt: fixedTime,
        ),
        catalogPokemonIds: {25},
      );

      expect(imported.name, 'Iris (importato)');
      expect(imported.team.single.maxHp, 24);
      expect(imported.tactics, 'Attacca e poi cambia posizione.');
      expect(repository.items.first.id, imported.id);
    });

    test('rifiuta specie non presenti nel catalogo', () async {
      final service = CampaignTransferService(
        encounterRepository: _FakeEncounterRepository(),
        trainerRepository: _FakeTrainerRepository(),
        clock: () => fixedTime,
      );

      expect(
        () => service.importEncounter(
          profileId: 'profile',
          bundle: CampaignTransferBundle.forEncounter(
            encounter: _encounter(),
            sourceProfileName: 'Misty',
          ),
          catalogPokemonIds: const {},
        ),
        throwsFormatException,
      );
    });
  });

  test('il riepilogo del Fight include turno, PF, status e PP', () {
    final session = MasterBattleSession(
      profileId: 'profile',
      id: 'fight',
      round: 4,
      turnIndex: 0,
      selectedTrainerId: 'trainer',
      focusedSlotIndex: 0,
      participants: [
        MasterBattleParticipant(
          trainerId: 'trainer',
          name: 'Iris',
          epithet: 'la Saetta',
          rank: 'Esperto',
          tactics: 'Attacca e poi cambia posizione.',
          personality: 'Impulsiva',
          rewardMoney: 500,
          rewards: const ['Pozione'],
          activeLimit: 1,
          activeSlotIndices: const {0},
          team: [
            MasterBattlePokemonState(
              slotIndex: 0,
              pokemon: const SavedNpcPokemon(
                pokemonId: 25,
                level: 6,
                nature: 'Brave',
                selectedMoves: ['Thunder Shock'],
                isShiny: false,
                maxHp: 24,
              ),
              currentHp: 9,
              nonVolatileStatus: 'Burned',
              volatileStatuses: const {'Confused'},
              remainingPp: const {'Thunder Shock': 2},
            ),
          ],
        ),
      ],
      initiativeEntries: const [
        BattleInitiativeEntry(
          id: 'npc:trainer:0',
          name: 'Iris + Pikachu',
          initiative: 17,
          isTrainerGroup: true,
        ),
      ],
      updatedAt: fixedTime,
    );

    final summary = const MasterFightSummaryService().build(
      session: session,
      pokemonById: const {},
      exportedAt: fixedTime,
    );

    expect(summary, contains('Round: 4'));
    expect(summary, contains('← TURNO ATTUALE'));
    expect(summary, contains('PF 9/24'));
    expect(summary, contains('Burned, Confused'));
    expect(summary, contains('Thunder Shock 2 PP'));
    expect(summary, contains('Ricompensa: ₽500'));
  });
}

SavedEncounter _encounter({
  String id = 'encounter',
  String name = 'Bosco notturno',
  String? collectionId,
}) {
  final time = DateTime.utc(2026, 7, 1);
  return SavedEncounter(
    id: id,
    name: name,
    source: EncounterSource.automatic,
    party: const EncounterPartyProfile(
      trainerCount: 2,
      activePokemon: 2,
      averageLevel: 6,
    ),
    filters: const EncounterGeneratorFilters(habitat: 'Forest', level: 6),
    targetDifficulty: EncounterDifficulty.medium,
    members: const [
      SavedEncounterMember(
        pokemonId: 25,
        level: 6,
        nature: 'Brave',
        selectedMoves: ['Thunder Shock'],
        isShiny: false,
        maxHp: 24,
      ),
    ],
    createdAt: time,
    updatedAt: time,
    notes: 'Incontro di prova',
    collectionId: collectionId,
    collectionName: 'Foresta',
  );
}

SavedNpcTrainer _trainer({String id = 'trainer', String name = 'Iris'}) {
  final time = DateTime.utc(2026, 7, 1);
  return SavedNpcTrainer(
    id: id,
    name: name,
    epithet: 'la Saetta',
    trainerLevel: 6,
    rank: NpcTrainerRank.expert,
    origin: 'Kanto',
    path: 'Ace Trainer',
    specializations: const ['Electric'],
    preferredType: 'Electric',
    personality: 'Impulsiva',
    motivation: 'Vincere il torneo',
    quirk: 'Conta i secondi',
    openingLine: 'Non riuscirai a seguirmi!',
    tactics: 'Attacca e poi cambia posizione.',
    rewardMoney: 500,
    rewards: const ['Pozione'],
    team: const [
      SavedNpcPokemon(
        pokemonId: 25,
        level: 6,
        nature: 'Brave',
        selectedMoves: ['Thunder Shock'],
        isShiny: false,
        maxHp: 24,
      ),
    ],
    options: const NpcTrainerGeneratorOptions(
      trainerLevel: 6,
      pokemonLevel: 6,
      teamSize: 1,
      rank: NpcTrainerRank.expert,
      specialization: 'Electric',
    ),
    createdAt: time,
    updatedAt: time,
    notes: 'Rivale ricorrente',
  );
}

class _FakeEncounterRepository extends SavedEncounterRepository {
  _FakeEncounterRepository([List<SavedEncounter> initial = const []])
    : items = [...initial];

  List<SavedEncounter> items;

  @override
  Future<List<SavedEncounter>> getEncounters(String profileId) async => [
    ...items,
  ];

  @override
  Future<void> saveEncounter({
    required String profileId,
    required SavedEncounter encounter,
  }) async {
    items = [
      encounter,
      for (final existing in items)
        if (existing.id != encounter.id) existing,
    ];
  }
}

class _FakeTrainerRepository extends SavedNpcTrainerRepository {
  _FakeTrainerRepository([List<SavedNpcTrainer> initial = const []])
    : items = [...initial];

  List<SavedNpcTrainer> items;

  @override
  Future<List<SavedNpcTrainer>> getTrainers(String profileId) async => [
    ...items,
  ];

  @override
  Future<void> saveTrainer({
    required String profileId,
    required SavedNpcTrainer trainer,
  }) async {
    items = [
      trainer,
      for (final existing in items)
        if (existing.id != trainer.id) existing,
    ];
  }
}
