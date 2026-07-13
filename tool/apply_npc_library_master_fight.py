from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def write(path: str, source: str) -> None:
    (ROOT / path).write_text(source, encoding='utf-8')


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected one match, found {count}')
    return source.replace(old, new, 1)


# Hive boxes.
path = 'lib/database/hive_boxes.dart'
source = read(path)
source = replace_once(
    source,
    "  static const savedEncounters = 'saved_encounters';\n",
    "  static const savedEncounters = 'saved_encounters';\n"
    "  static const savedNpcTrainers = 'saved_npc_trainers';\n"
    "  static const masterBattleSessions = 'master_battle_sessions';\n",
    'hive boxes',
)
write(path, source)

# Tools navigation.
path = 'lib/screens/tools/tools_screen.dart'
source = read(path)
source = replace_once(
    source,
    "import 'npc_trainer_generator_screen.dart';\n",
    "import 'npc_trainer_generator_screen.dart';\n"
    "import 'npc_trainer_library_screen.dart';\n",
    'tools import',
)
source = replace_once(
    source,
    "                  builder: (_) => const NpcTrainerGeneratorScreen(),\n"
    "                ),\n"
    "              );\n"
    "            },\n"
    "          ),\n"
    "        ],\n",
    "                  builder: (_) => const NpcTrainerGeneratorScreen(),\n"
    "                ),\n"
    "              );\n"
    "            },\n"
    "          ),\n"
    "          const SizedBox(height: 10),\n"
    "          _ToolCard(\n"
    "            icon: Icons.people_alt_outlined,\n"
    "            title: 'Libreria Allenatori PNG',\n"
    "            subtitle:\n"
    "                'Salva, seleziona e controlla uno o più allenatori nello stesso fight.',\n"
    "            actionLabel: 'APRI',\n"
    "            onTap: () {\n"
    "              Navigator.of(context).push(\n"
    "                MaterialPageRoute(\n"
    "                  builder: (_) => const NpcTrainerLibraryScreen(),\n"
    "                ),\n"
    "              );\n"
    "            },\n"
    "          ),\n"
    "        ],\n",
    'tools library card',
)
write(path, source)

# Save generated NPC trainers from the result screen.
path = 'lib/screens/tools/npc_trainer_result_screen.dart'
source = read(path)
source = replace_once(
    source,
    "import '../../models/pokemon_type_localization.dart';\n",
    "import '../../models/pokemon_type_localization.dart';\n"
    "import '../../models/saved_npc_trainer.dart';\n",
    'result saved model import',
)
source = replace_once(
    source,
    "import '../../repositories/move_repository.dart';\n",
    "import '../../repositories/move_repository.dart';\n"
    "import '../../repositories/profile_repository.dart';\n"
    "import '../../repositories/saved_npc_trainer_repository.dart';\n",
    'result repositories import',
)
source = replace_once(
    source,
    "import '../../services/npc_trainer_generator_service.dart';\n",
    "import '../../services/npc_trainer_generator_service.dart';\n"
    "import '../../services/saved_npc_trainer_mapper_service.dart';\n",
    'result mapper import',
)
source = replace_once(
    source,
    "    required this.items,\n"
    "  });\n",
    "    required this.items,\n"
    "    this.savedTrainer,\n"
    "  });\n",
    'result constructor',
)
source = replace_once(
    source,
    "  final List<BagItem> items;\n",
    "  final List<BagItem> items;\n"
    "  final SavedNpcTrainer? savedTrainer;\n",
    'result saved field',
)
source = replace_once(
    source,
    "  final MoveRepository _moveRepository = MoveRepository();\n",
    "  final MoveRepository _moveRepository = MoveRepository();\n"
    "  final ProfileRepository _profileRepository = ProfileRepository();\n"
    "  final SavedNpcTrainerRepository _savedRepository =\n"
    "      SavedNpcTrainerRepository();\n"
    "  final SavedNpcTrainerMapperService _savedMapper =\n"
    "      const SavedNpcTrainerMapperService();\n",
    'result repository fields',
)
source = replace_once(
    source,
    "  late GeneratedNpcTrainer _trainer;\n"
    "  Map<String, MoveData?> _moves = const {};\n"
    "  bool _isWorking = false;\n",
    "  late GeneratedNpcTrainer _trainer;\n"
    "  SavedNpcTrainer? _savedTrainer;\n"
    "  Map<String, MoveData?> _moves = const {};\n"
    "  bool _isWorking = false;\n"
    "  bool _isSaving = false;\n",
    'result state fields',
)
source = replace_once(
    source,
    "    _trainer = widget.trainer;\n"
    "    _loadMoves();\n",
    "    _trainer = widget.trainer;\n"
    "    _savedTrainer = widget.savedTrainer;\n"
    "    _loadMoves();\n",
    'result init',
)
save_method = r'''
  Future<void> _saveTrainer() async {
    if (_isSaving || _trainer.team.isEmpty) return;
    final details = await showDialog<_NpcSaveDetails>(
      context: context,
      builder: (_) => _NpcSaveDialog(
        initialName: _savedTrainer?.name ?? _trainer.name,
        initialNotes: _savedTrainer?.notes ?? '',
        isUpdate: _savedTrainer != null,
      ),
    );
    if (details == null) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      final profile = await _profileRepository.getActiveProfile();
      final saved = _savedMapper.fromGenerated(
        _trainer,
        existing: _savedTrainer,
        name: details.name,
        notes: details.notes,
      );
      await _savedRepository.saveTrainer(
        profileId: profile.id,
        trainer: saved,
      );
      if (!mounted) return;
      setState(() {
        final wasUpdate = _savedTrainer != null;
        _savedTrainer = saved;
        _message = wasUpdate
            ? 'Allenatore aggiornato nella libreria.'
            : 'Allenatore salvato nella libreria.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error
            .toString()
            .replaceFirst('FormatException: ', '')
            .replaceFirst('Bad state: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

'''
source = replace_once(
    source,
    "  Future<void> _copySummary() async {\n",
    save_method + "  Future<void> _copySummary() async {\n",
    'result save method',
)
source = replace_once(
    source,
    "        title: const Text('Allenatore generato'),\n"
    "        actions: [\n",
    "        title: Text(\n"
    "          _savedTrainer == null ? 'Allenatore generato' : _savedTrainer!.name,\n"
    "        ),\n"
    "        actions: [\n"
    "          IconButton(\n"
    "            onPressed: _isSaving || _isWorking ? null : _saveTrainer,\n"
    "            tooltip: _savedTrainer == null\n"
    "                ? 'Salva nella libreria'\n"
    "                : 'Aggiorna allenatore salvato',\n"
    "            icon: _isSaving\n"
    "                ? const SizedBox(\n"
    "                    width: 20,\n"
    "                    height: 20,\n"
    "                    child: CircularProgressIndicator(strokeWidth: 2),\n"
    "                  )\n"
    "                : Icon(\n"
    "                    _savedTrainer == null\n"
    "                        ? Icons.person_add_alt_1_outlined\n"
    "                        : Icons.person_pin_circle_outlined,\n"
    "                  ),\n"
    "          ),\n",
    'result appbar save',
)
source = replace_once(
    source,
    "          const SizedBox(height: 14),\n"
    "          FilledButton.icon(\n"
    "            onPressed: _isWorking ? null : _regenerate,\n",
    "          const SizedBox(height: 14),\n"
    "          FilledButton.icon(\n"
    "            onPressed: _isWorking || _isSaving ? null : _saveTrainer,\n"
    "            icon: Icon(\n"
    "              _savedTrainer == null\n"
    "                  ? Icons.person_add_alt_1_outlined\n"
    "                  : Icons.person_pin_circle_outlined,\n"
    "            ),\n"
    "            label: Text(\n"
    "              _savedTrainer == null\n"
    "                  ? 'SALVA NELLA LIBRERIA'\n"
    "                  : 'AGGIORNA ALLENATORE SALVATO',\n"
    "            ),\n"
    "          ),\n"
    "          const SizedBox(height: 8),\n"
    "          FilledButton.icon(\n"
    "            onPressed: _isWorking || _isSaving ? null : _regenerate,\n",
    'result save button',
)
dialog_classes = r'''
class _NpcSaveDetails {
  const _NpcSaveDetails({required this.name, required this.notes});

  final String name;
  final String notes;
}

class _NpcSaveDialog extends StatefulWidget {
  const _NpcSaveDialog({
    required this.initialName,
    required this.initialNotes,
    required this.isUpdate,
  });

  final String initialName;
  final String initialNotes;
  final bool isUpdate;

  @override
  State<_NpcSaveDialog> createState() => _NpcSaveDialogState();
}

class _NpcSaveDialogState extends State<_NpcSaveDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName,
  );
  late final TextEditingController _notesController = TextEditingController(
    text: widget.initialNotes,
  );
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Inserisci un nome valido.');
      return;
    }
    Navigator.of(context).pop(
      _NpcSaveDetails(name: name, notes: _notesController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isUpdate ? 'Aggiorna Allenatore PNG' : 'Salva Allenatore PNG',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note facoltative',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(widget.isUpdate ? 'Aggiorna' : 'Salva'),
        ),
      ],
    );
  }
}

'''
source = replace_once(
    source,
    "class _TrainerHeader extends StatelessWidget {\n",
    dialog_classes + "class _TrainerHeader extends StatelessWidget {\n",
    'result save dialog',
)
write(path, source)

# Profile backup model version 4.
path = 'lib/models/profile_backup.dart'
source = read(path)
source = replace_once(
    source,
    "import 'encounter_collection.dart';\n",
    "import 'encounter_collection.dart';\n"
    "import 'master_battle_session.dart';\n",
    'backup master import',
)
source = replace_once(
    source,
    "import 'saved_encounter.dart';\n",
    "import 'saved_encounter.dart';\n"
    "import 'saved_npc_trainer.dart';\n",
    'backup trainer import',
)
source = source.replace('static const int currentFormatVersion = 3;', 'static const int currentFormatVersion = 4;')
source = replace_once(
    source,
    "    this.savedEncounters = const [],\n"
    "  });\n",
    "    this.savedEncounters = const [],\n"
    "    this.savedNpcTrainers = const [],\n"
    "    this.masterBattleSession,\n"
    "  });\n",
    'backup constructor',
)
source = replace_once(
    source,
    "  final List<SavedEncounter> savedEncounters;\n",
    "  final List<SavedEncounter> savedEncounters;\n"
    "  final List<SavedNpcTrainer> savedNpcTrainers;\n"
    "  final MasterBattleSession? masterBattleSession;\n",
    'backup fields',
)
source = replace_once(
    source,
    "      'savedEncounters': savedEncounters\n"
    "          .map((encounter) => encounter.toJson())\n"
    "          .toList(growable: false),\n",
    "      'savedEncounters': savedEncounters\n"
    "          .map((encounter) => encounter.toJson())\n"
    "          .toList(growable: false),\n"
    "      'savedNpcTrainers': savedNpcTrainers\n"
    "          .map((trainer) => trainer.toJson())\n"
    "          .toList(growable: false),\n"
    "      'masterBattleSession': masterBattleSession?.toJson(),\n",
    'backup json',
)
source = replace_once(
    source,
    "      savedEncounters: [\n"
    "        for (final value in _readMapList(\n"
    "          json['savedEncounters'],\n"
    "          'savedEncounters',\n"
    "        ))\n"
    "          SavedEncounter.fromJson(value),\n"
    "      ],\n"
    "    );\n",
    "      savedEncounters: [\n"
    "        for (final value in _readMapList(\n"
    "          json['savedEncounters'],\n"
    "          'savedEncounters',\n"
    "        ))\n"
    "          SavedEncounter.fromJson(value),\n"
    "      ],\n"
    "      savedNpcTrainers: [\n"
    "        for (final value in _readMapList(\n"
    "          json['savedNpcTrainers'],\n"
    "          'savedNpcTrainers',\n"
    "        ))\n"
    "          SavedNpcTrainer.fromJson(value),\n"
    "      ],\n"
    "      masterBattleSession: json['masterBattleSession'] is Map\n"
    "          ? MasterBattleSession.fromJson(\n"
    "              Map<String, dynamic>.from(json['masterBattleSession'] as Map),\n"
    "            )\n"
    "          : null,\n"
    "    );\n",
    'backup parse',
)
source = replace_once(
    source,
    "    final savedEncounterIds = <String>{};\n",
    "    final trainerIds = <String>{};\n"
    "    for (final trainer in savedNpcTrainers) {\n"
    "      if (!trainer.isValid) {\n"
    "        throw const FormatException(\n"
    "          'Il backup contiene un Allenatore PNG non valido.',\n"
    "        );\n"
    "      }\n"
    "      if (!trainerIds.add(trainer.id)) {\n"
    "        throw FormatException(\n"
    "          'L’Allenatore PNG ${trainer.name} è presente più volte.',\n"
    "        );\n"
    "      }\n"
    "    }\n"
    "    if (masterBattleSession != null && !masterBattleSession!.isValid) {\n"
    "      throw const FormatException(\n"
    "        'Il backup contiene una sessione del Master non valida.',\n"
    "      );\n"
    "    }\n\n"
    "    final savedEncounterIds = <String>{};\n",
    'backup validation',
)
write(path, source)

# Profile backup repositories and persistence.
path = 'lib/services/profile_backup_service.dart'
source = read(path)
source = replace_once(
    source,
    "import '../models/battle_session.dart';\n",
    "import '../models/battle_session.dart';\n"
    "import '../models/master_battle_session.dart';\n",
    'backup service master model',
)
source = replace_once(
    source,
    "import '../repositories/encounter_collection_repository.dart';\n",
    "import '../repositories/encounter_collection_repository.dart';\n"
    "import '../repositories/master_battle_session_repository.dart';\n",
    'backup service master repo import',
)
source = replace_once(
    source,
    "import '../repositories/saved_encounter_repository.dart';\n",
    "import '../repositories/saved_encounter_repository.dart';\n"
    "import '../repositories/saved_npc_trainer_repository.dart';\n",
    'backup service trainer repo import',
)
source = replace_once(
    source,
    "    SavedEncounterRepository? savedEncounterRepository,\n"
    "  }) : _profileRepository = profileRepository ?? ProfileRepository(),\n",
    "    SavedEncounterRepository? savedEncounterRepository,\n"
    "    SavedNpcTrainerRepository? savedNpcTrainerRepository,\n"
    "    MasterBattleSessionRepository? masterBattleSessionRepository,\n"
    "  }) : _profileRepository = profileRepository ?? ProfileRepository(),\n",
    'backup service constructor args',
)
source = replace_once(
    source,
    "        _savedEncounterRepository =\n"
    "            savedEncounterRepository ?? SavedEncounterRepository();\n",
    "        _savedEncounterRepository =\n"
    "            savedEncounterRepository ?? SavedEncounterRepository(),\n"
    "        _savedNpcTrainerRepository =\n"
    "            savedNpcTrainerRepository ?? SavedNpcTrainerRepository(),\n"
    "        _masterBattleSessionRepository = masterBattleSessionRepository ??\n"
    "            MasterBattleSessionRepository();\n",
    'backup service initializer',
)
source = replace_once(
    source,
    "  final SavedEncounterRepository _savedEncounterRepository;\n",
    "  final SavedEncounterRepository _savedEncounterRepository;\n"
    "  final SavedNpcTrainerRepository _savedNpcTrainerRepository;\n"
    "  final MasterBattleSessionRepository _masterBattleSessionRepository;\n",
    'backup service fields',
)
source = replace_once(
    source,
    "    final savedEncounters = await _savedEncounterRepository.getEncounters(\n"
    "      profileId,\n"
    "    );\n",
    "    final savedEncounters = await _savedEncounterRepository.getEncounters(\n"
    "      profileId,\n"
    "    );\n"
    "    final savedNpcTrainers = await _savedNpcTrainerRepository.getTrainers(\n"
    "      profileId,\n"
    "    );\n"
    "    final masterBattleSession = await _masterBattleSessionRepository\n"
    "        .getSession(profileId);\n",
    'backup service load',
)
source = replace_once(
    source,
    "      savedEncounters: savedEncounters,\n"
    "    );\n",
    "      savedEncounters: savedEncounters,\n"
    "      savedNpcTrainers: savedNpcTrainers,\n"
    "      masterBattleSession: masterBattleSession,\n"
    "    );\n",
    'backup service return',
)
source = replace_once(
    source,
    "    await _savedEncounterRepository.replaceEncounters(\n"
    "      destinationId,\n"
    "      backup.savedEncounters,\n"
    "    );\n",
    "    await _savedEncounterRepository.replaceEncounters(\n"
    "      destinationId,\n"
    "      backup.savedEncounters,\n"
    "    );\n"
    "    await _savedNpcTrainerRepository.replaceTrainers(\n"
    "      destinationId,\n"
    "      backup.savedNpcTrainers,\n"
    "    );\n"
    "    final masterSession = backup.masterBattleSession;\n"
    "    if (masterSession != null) {\n"
    "      await _masterBattleSessionRepository.saveSession(\n"
    "        MasterBattleSession(\n"
    "          profileId: destinationId,\n"
    "          id: masterSession.id,\n"
    "          round: masterSession.round,\n"
    "          turnIndex: masterSession.turnIndex,\n"
    "          selectedTrainerId: masterSession.selectedTrainerId,\n"
    "          focusedSlotIndex: masterSession.focusedSlotIndex,\n"
    "          participants: masterSession.participants,\n"
    "          initiativeEntries: masterSession.initiativeEntries,\n"
    "          updatedAt: masterSession.updatedAt,\n"
    "        ),\n"
    "      );\n"
    "    }\n",
    'backup service write',
)
source = replace_once(
    source,
    "    await _savedEncounterRepository.deleteEncounters(profileId);\n",
    "    await _savedEncounterRepository.deleteEncounters(profileId);\n"
    "    await _savedNpcTrainerRepository.deleteTrainers(profileId);\n"
    "    await _masterBattleSessionRepository.deleteSession(profileId);\n",
    'backup service clear',
)
write(path, source)

# Profile deletion copy.
path = 'lib/screens/profile/profiles_screen.dart'
source = read(path)
source = source.replace(
    'Pokédex, squadra, PC, zaino, impostazioni, incontri e battaglia salvata.',
    'Pokédex, squadra, PC, zaino, impostazioni, incontri, Allenatori PNG e battaglie salvate.',
)
write(path, source)
