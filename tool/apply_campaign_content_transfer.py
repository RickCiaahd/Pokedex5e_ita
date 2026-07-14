from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 occurrence, found {count}")
    return text.replace(old, new)


# Encounter library
path = Path('lib/screens/tools/encounter_library_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import 'package:flutter/material.dart';\n",
    "import 'dart:convert';\nimport 'dart:typed_data';\n\nimport 'package:file_picker/file_picker.dart';\nimport 'package:flutter/material.dart';\n",
    'encounter imports dart',
)
text = replace_once(
    text,
    "import '../../models/generated_encounter.dart';\n",
    "import '../../models/campaign_transfer_bundle.dart';\nimport '../../models/generated_encounter.dart';\n",
    'encounter model import',
)
text = replace_once(
    text,
    "import '../../services/saved_encounter_mapper_service.dart';\n",
    "import '../../services/campaign_transfer_service.dart';\nimport '../../services/saved_encounter_mapper_service.dart';\n",
    'encounter service import',
)
text = replace_once(
    text,
    "  final SavedEncounterMapperService _mapper =\n      const SavedEncounterMapperService();\n",
    "  final SavedEncounterMapperService _mapper =\n      const SavedEncounterMapperService();\n  final CampaignTransferService _transferService = CampaignTransferService();\n",
    'encounter service field',
)
encounter_methods = r'''
  Future<CampaignTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Importa incontro Pokédex 5e',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    return _transferService.decode(
      utf8.decode(bytes, allowMalformed: false),
    );
  }

  Future<void> _exportEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forEncounter(
        encounter: saved,
        sourceProfileName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Esporta ${saved.name}',
        fileName: _transferService.fileNameForEncounter(bundle),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setMessage(
        path == null
            ? 'Esportazione annullata.'
            : '${saved.name} esportato correttamente.',
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importEncounter() async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = await _pickTransferFile();
      if (bundle == null) {
        _setMessage('Importazione annullata.');
        return;
      }
      if (bundle.kind != CampaignTransferKind.encounter) {
        throw const FormatException(
          'Seleziona un file esportato come incontro.',
        );
      }
      final source = bundle.encounter!;
      if (!mounted) return;
      final origin = bundle.sourceProfileName.isEmpty
          ? ''
          : ' dal profilo ${bundle.sourceProfileName}';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importare incontro?'),
          content: Text(
            'Vuoi importare “${source.name}”$origin con '
            '${source.enemyCount} avversari? Verrà creata una nuova copia '
            'nella libreria del profilo attivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('IMPORTA'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setMessage('Importazione annullata.');
        return;
      }
      final imported = await _transferService.importEncounter(
        profileId: profile.id,
        bundle: bundle,
        catalogPokemonIds: _catalog.map((pokemon) => pokemon.id).toSet(),
      );
      await _load();
      _setMessage('${imported.name} importato nella libreria incontri.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
'''
text = replace_once(
    text,
    "  String _copyName(String original) {\n",
    encounter_methods + "\n  String _copyName(String original) {\n",
    'encounter methods',
)
text = replace_once(
    text,
    "      appBar: AppBar(\n        leading: const HomeLeadingButton(),\n        title: const Text('Libreria incontri'),\n      ),\n",
    "      appBar: AppBar(\n        leading: const HomeLeadingButton(),\n        title: const Text('Libreria incontri'),\n        actions: [\n          IconButton(\n            onPressed: _isBusy || _isLoading ? null : _importEncounter,\n            tooltip: 'Importa incontro',\n            icon: const Icon(Icons.download_outlined),\n          ),\n        ],\n      ),\n",
    'encounter appbar',
)
text = replace_once(
    text,
    "                  onFight: () => _startFight(saved),\n                  onDuplicate: () => _duplicateEncounter(saved),\n",
    "                  onFight: () => _startFight(saved),\n                  onExport: () => _exportEncounter(saved),\n                  onDuplicate: () => _duplicateEncounter(saved),\n",
    'encounter card call',
)
text = replace_once(
    text,
    "    required this.onFight,\n    required this.onDuplicate,\n",
    "    required this.onFight,\n    required this.onExport,\n    required this.onDuplicate,\n",
    'encounter card constructor',
)
text = replace_once(
    text,
    "  final VoidCallback onFight;\n  final VoidCallback onDuplicate;\n",
    "  final VoidCallback onFight;\n  final VoidCallback onExport;\n  final VoidCallback onDuplicate;\n",
    'encounter card field',
)
text = replace_once(
    text,
    "                        case 'duplicate':\n                          onDuplicate();\n                          break;\n",
    "                        case 'export':\n                          onExport();\n                          break;\n                        case 'duplicate':\n                          onDuplicate();\n                          break;\n",
    'encounter popup switch',
)
text = replace_once(
    text,
    "                    itemBuilder: (_) => const [\n                      PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
    "                    itemBuilder: (_) => const [\n                      PopupMenuItem(\n                        value: 'export',\n                        child: Text('Esporta incontro'),\n                      ),\n                      PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
    'encounter popup item',
)
path.write_text(text, encoding='utf-8')


# NPC trainer library
path = Path('lib/screens/tools/npc_trainer_library_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import 'package:flutter/material.dart';\n",
    "import 'dart:convert';\nimport 'dart:typed_data';\n\nimport 'package:file_picker/file_picker.dart';\nimport 'package:flutter/material.dart';\n",
    'trainer imports dart',
)
text = replace_once(
    text,
    "import '../../models/bag_item.dart';\n",
    "import '../../models/bag_item.dart';\nimport '../../models/campaign_transfer_bundle.dart';\n",
    'trainer model import',
)
text = replace_once(
    text,
    "import '../../services/master_battle_service.dart';\n",
    "import '../../services/campaign_transfer_service.dart';\nimport '../../services/master_battle_service.dart';\n",
    'trainer service import',
)
text = replace_once(
    text,
    "  final SavedNpcTrainerMapperService _mapper =\n      const SavedNpcTrainerMapperService();\n",
    "  final SavedNpcTrainerMapperService _mapper =\n      const SavedNpcTrainerMapperService();\n  final CampaignTransferService _transferService = CampaignTransferService();\n",
    'trainer service field',
)
trainer_methods = r'''
  Future<CampaignTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Importa Allenatore PNG Pokédex 5e',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    return _transferService.decode(
      utf8.decode(bytes, allowMalformed: false),
    );
  }

  Future<void> _exportTrainer(SavedNpcTrainer saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forNpcTrainer(
        npcTrainer: saved,
        sourceProfileName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Esporta ${saved.displayName}',
        fileName: _transferService.fileNameForNpcTrainer(bundle),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setMessage(
        path == null
            ? 'Esportazione annullata.'
            : '${saved.displayName} esportato correttamente.',
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importTrainer() async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = await _pickTransferFile();
      if (bundle == null) {
        _setMessage('Importazione annullata.');
        return;
      }
      if (bundle.kind != CampaignTransferKind.npcTrainer) {
        throw const FormatException(
          'Seleziona un file esportato come Allenatore PNG.',
        );
      }
      final source = bundle.npcTrainer!;
      if (!mounted) return;
      final origin = bundle.sourceProfileName.isEmpty
          ? ''
          : ' dal profilo ${bundle.sourceProfileName}';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importare Allenatore PNG?'),
          content: Text(
            'Vuoi importare “${source.displayName}”$origin con una squadra '
            'di ${source.team.length} Pokémon? Verrà creata una nuova copia '
            'nella libreria del profilo attivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ANNULLA'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('IMPORTA'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setMessage('Importazione annullata.');
        return;
      }
      final imported = await _transferService.importNpcTrainer(
        profileId: profile.id,
        bundle: bundle,
        catalogPokemonIds: _catalog.map((pokemon) => pokemon.id).toSet(),
      );
      await _load();
      _setMessage('${imported.displayName} importato nella libreria PNG.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
'''
text = replace_once(
    text,
    "  Future<void> _duplicateTrainer(SavedNpcTrainer saved) async {\n",
    trainer_methods + "\n  Future<void> _duplicateTrainer(SavedNpcTrainer saved) async {\n",
    'trainer methods',
)
text = replace_once(
    text,
    "      appBar: AppBar(\n        leading: const HomeLeadingButton(),\n        title: const Text('Libreria Allenatori PNG'),\n      ),\n",
    "      appBar: AppBar(\n        leading: const HomeLeadingButton(),\n        title: const Text('Libreria Allenatori PNG'),\n        actions: [\n          IconButton(\n            onPressed: _isBusy || _isLoading ? null : _importTrainer,\n            tooltip: 'Importa Allenatore PNG',\n            icon: const Icon(Icons.download_outlined),\n          ),\n        ],\n      ),\n",
    'trainer appbar',
)
text = replace_once(
    text,
    "                   onFight: () => _startFight([trainer]),\n                   onDuplicate: () => _duplicateTrainer(trainer),\n",
    "                   onFight: () => _startFight([trainer]),\n                   onExport: () => _exportTrainer(trainer),\n                   onDuplicate: () => _duplicateTrainer(trainer),\n",
    'trainer card call',
)
text = replace_once(
    text,
    "    required this.onFight,\n    required this.onDuplicate,\n",
    "    required this.onFight,\n    required this.onExport,\n    required this.onDuplicate,\n",
    'trainer card constructor',
)
text = replace_once(
    text,
    "  final VoidCallback onFight;\n  final VoidCallback onDuplicate;\n",
    "  final VoidCallback onFight;\n  final VoidCallback onExport;\n  final VoidCallback onDuplicate;\n",
    'trainer card field',
)
text = replace_once(
    text,
    "                    if (value == 'duplicate') onDuplicate();\n                    if (value == 'delete') onDelete();\n",
    "                    if (value == 'export') onExport();\n                    if (value == 'duplicate') onDuplicate();\n                    if (value == 'delete') onDelete();\n",
    'trainer popup switch',
)
text = replace_once(
    text,
    "                  itemBuilder: (_) => const [\n                    PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
    "                  itemBuilder: (_) => const [\n                    PopupMenuItem(\n                      value: 'export',\n                      child: Text('Esporta Allenatore'),\n                    ),\n                    PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
    'trainer popup item',
)
path.write_text(text, encoding='utf-8')


# Master fight summary export
path = Path('lib/screens/battle/npc_battle_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import 'dart:math';\n\nimport 'package:flutter/material.dart';\n",
    "import 'dart:convert';\nimport 'dart:math';\nimport 'dart:typed_data';\n\nimport 'package:file_picker/file_picker.dart';\nimport 'package:flutter/material.dart';\n",
    'fight imports dart',
)
text = replace_once(
    text,
    "import '../../services/master_battle_service.dart';\n",
    "import '../../services/master_battle_service.dart';\nimport '../../services/master_fight_summary_service.dart';\n",
    'fight service import',
)
text = replace_once(
    text,
    "  final MasterBattleService _battleService = const MasterBattleService();\n",
    "  final MasterBattleService _battleService = const MasterBattleService();\n  final MasterFightSummaryService _summaryService =\n      const MasterFightSummaryService();\n",
    'fight service field',
)
summary_method = r'''
  Future<void> _exportSummary() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final exportedAt = DateTime.now();
      final summary = _summaryService.build(
        session: _session,
        pokemonById: _pokemonById,
        exportedAt: exportedAt,
      );
      final path = await FilePicker.saveFile(
        dialogTitle: 'Esporta riepilogo del Fight del Master',
        fileName: _summaryService.fileName(
          _session,
          exportedAt: exportedAt,
        ),
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        bytes: Uint8List.fromList(utf8.encode(summary)),
      );
      if (!mounted) return;
      setState(() {
        _message = path == null
            ? 'Esportazione annullata.'
            : 'Riepilogo del fight esportato correttamente.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error
            .toString()
            .replaceFirst('FormatException: ', '')
            .replaceFirst('Bad state: ', '')
            .trim();
      });
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }
'''
text = replace_once(
    text,
    "  Future<void> _endFight() async {\n",
    summary_method + "\n  Future<void> _endFight() async {\n",
    'fight export method',
)
text = replace_once(
    text,
    "        actions: [\n          IconButton(\n            onPressed: _isWorking ? null : _resetFight,\n",
    "        actions: [\n          IconButton(\n            onPressed: _isWorking ? null : _exportSummary,\n            tooltip: 'Esporta riepilogo',\n            icon: const Icon(Icons.file_download_outlined),\n          ),\n          IconButton(\n            onPressed: _isWorking ? null : _resetFight,\n",
    'fight appbar action',
)
path.write_text(text, encoding='utf-8')


# Documentation
path = Path('README.md')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "- backup e ripristino dei dati del profilo.\n",
    "- backup e ripristino dei dati del profilo;\n- esportazione e importazione mirata di Pokémon, squadre, incontri e Allenatori PNG, oltre al riepilogo testuale del Fight del Master.\n",
    'readme feature list',
)
text = replace_once(
    text,
    "Dalla schermata Squadra è inoltre possibile esportare e importare singoli Pokémon o una formazione completa senza sostituire l'intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC.\n",
    "Dalla schermata Squadra è inoltre possibile esportare e importare singoli Pokémon o una formazione completa senza sostituire l'intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC. Le librerie del Master supportano file portabili per incontri e Allenatori PNG, mentre il Fight del Master può produrre un riepilogo testuale con round, iniziativa, PF, status e PP.\n",
    'readme data',
)
path.write_text(text, encoding='utf-8')

path = Path('CHANGELOG.md')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "- durante l'importazione i Pokémon sostituiti e gli esuberi vengono trasferiti automaticamente nel PC, mentre le uova restano nei propri Pokéslot.\n",
    "- durante l'importazione i Pokémon sostituiti e gli esuberi vengono trasferiti automaticamente nel PC, mentre le uova restano nei propri Pokéslot;\n- incontri salvati e Allenatori PNG possono essere esportati e importati singolarmente senza sostituire il profilo, con nuovi identificativi e nomi non distruttivi in caso di duplicati;\n- il Fight del Master può esportare un riepilogo testuale con round, ordine d'iniziativa, PF, status, PP, ricompense e Pokémon attivi.\n",
    'changelog additions',
)
text = replace_once(
    text,
    "- condivisione tramite menu nativo ed esportazioni mirate di Allenatori, incontri e riepiloghi del Fight del Master.\n",
    "- condivisione diretta tramite menu nativo di Android, Windows e Web.\n",
    'changelog planned',
)
path.write_text(text, encoding='utf-8')
