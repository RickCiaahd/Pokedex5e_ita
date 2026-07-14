from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: attesa 1 occorrenza, trovate {count}')
    return text.replace(old, new, 1)


def update(path_value: str, operations) -> None:
    path = Path(path_value)
    text = path.read_text(encoding='utf-8')
    for old, new, label in operations:
        text = replace_once(text, old, new, f'{path_value} / {label}')
    path.write_text(text, encoding='utf-8')


# Dependency.
update(
    'pubspec.yaml',
    [
        (
            '  file_picker: ^11.0.2\n',
            '  file_picker: ^11.0.2\n  share_plus: ^13.2.0\n',
            'share_plus dependency',
        ),
    ],
)


# Team and individual Pokémon sharing.
team_share_methods = r'''
  Future<void> _sharePokemon(TeamSlot slot) async {
    final profile = _profile;
    if (_isBusy || profile == null || !slot.isPokemon) return;
    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.single(
        slot: slot,
        sourceTrainerName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final displayName = _displayNameForSlot(slot);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForPokemon(
          bundle,
          displayName: displayName,
        ),
        mimeType: 'application/json',
        title: 'Condividi $displayName',
        subject: '$displayName · Pokédex 5e ITA',
        text: 'Pokémon esportato da Pokédex 5e ITA.',
      );
      _setStatus(
        _shareService.feedback(
          outcome,
          successMessage: '$displayName condiviso correttamente.',
        ),
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareTeam() async {
    final profile = _profile;
    if (_isBusy || profile == null) return;
    final pokemonSlots = _visibleTeam.where((slot) => slot.isPokemon).toList();
    if (pokemonSlots.isEmpty) {
      _setStatus(
        'La squadra non contiene Pokémon da condividere.',
        isError: true,
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final bundle = PokemonTransferBundle.team(
        slots: pokemonSlots,
        sourceTrainerName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForTeam(bundle),
        mimeType: 'application/json',
        title: 'Condividi la squadra di ${profile.name}',
        subject: 'Squadra di ${profile.name} · Pokédex 5e ITA',
        text: 'Squadra esportata da Pokédex 5e ITA.',
      );
      _setStatus(
        _shareService.feedback(
          outcome,
          successMessage:
              'Squadra condivisa correttamente (${pokemonSlots.length} Pokémon).',
        ),
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
'''
update(
    'lib/screens/team/team_selection_screen.dart',
    [
        (
            "import '../../services/pokemon_transfer_service.dart';\n",
            "import '../../services/native_share_service.dart';\nimport '../../services/pokemon_transfer_service.dart';\n",
            'share service import',
        ),
        (
            '  final PokemonTransferService _transferService = PokemonTransferService();\n',
            '  final PokemonTransferService _transferService = PokemonTransferService();\n  final NativeShareService _shareService = const NativeShareService();\n',
            'share service field',
        ),
        (
            '  Future<void> _importPokemonInto(TeamSlot target) async {\n',
            team_share_methods + '\n  Future<void> _importPokemonInto(TeamSlot target) async {\n',
            'share methods',
        ),
        (
            "                case _TeamTransferAction.exportTeam:\n                  _exportTeam();\n                  break;\n                case _TeamTransferAction.importTeam:\n",
            "                case _TeamTransferAction.exportTeam:\n                  _exportTeam();\n                  break;\n                case _TeamTransferAction.shareTeam:\n                  _shareTeam();\n                  break;\n                case _TeamTransferAction.importTeam:\n",
            'team menu switch',
        ),
        (
            "              PopupMenuItem(\n                value: _TeamTransferAction.importTeam,\n",
            "              PopupMenuItem(\n                value: _TeamTransferAction.shareTeam,\n                child: ListTile(\n                  leading: Icon(Icons.ios_share_outlined),\n                  title: Text('Condividi squadra'),\n                  contentPadding: EdgeInsets.zero,\n                ),\n              ),\n              PopupMenuItem(\n                value: _TeamTransferAction.importTeam,\n",
            'team share menu item',
        ),
        (
            '                  onExport: slot.isPokemon ? () => _exportPokemon(slot) : null,\n                  onImport: slot.isEgg ? null : () => _importPokemonInto(slot),\n',
            '                  onExport: slot.isPokemon ? () => _exportPokemon(slot) : null,\n                  onShare: slot.isPokemon ? () => _sharePokemon(slot) : null,\n                  onImport: slot.isEgg ? null : () => _importPokemonInto(slot),\n',
            'slot share callback',
        ),
        (
            '    required this.onExport,\n    required this.onImport,\n',
            '    required this.onExport,\n    required this.onShare,\n    required this.onImport,\n',
            'slot constructor',
        ),
        (
            '  final VoidCallback? onExport;\n  final VoidCallback? onImport;\n',
            '  final VoidCallback? onExport;\n  final VoidCallback? onShare;\n  final VoidCallback? onImport;\n',
            'slot share field',
        ),
        (
            '                          case _SlotAction.export:\n                            onExport?.call();\n                            break;\n                          case _SlotAction.import:\n',
            '                          case _SlotAction.export:\n                            onExport?.call();\n                            break;\n                          case _SlotAction.share:\n                            onShare?.call();\n                            break;\n                          case _SlotAction.import:\n',
            'slot menu switch',
        ),
        (
            "                        const PopupMenuItem(\n                          value: _SlotAction.import,\n                          child: Text('Importa Pokémon qui'),\n                        ),\n",
            "                        if (pokemon != null)\n                          const PopupMenuItem(\n                            value: _SlotAction.share,\n                            child: Text('Condividi Pokémon'),\n                          ),\n                        const PopupMenuItem(\n                          value: _SlotAction.import,\n                          child: Text('Importa Pokémon qui'),\n                        ),\n",
            'slot share menu item',
        ),
        (
            'enum _TeamTransferAction { exportTeam, importTeam }\n\nenum _SlotAction { change, export, import, remove }\n',
            'enum _TeamTransferAction { exportTeam, shareTeam, importTeam }\n\nenum _SlotAction { change, export, share, import, remove }\n',
            'share enum values',
        ),
    ],
)


# Encounter sharing.
encounter_share_method = r'''
  Future<void> _shareEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forEncounter(
        encounter: saved,
        sourceProfileName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForEncounter(bundle),
        mimeType: 'application/json',
        title: 'Condividi ${saved.name}',
        subject: '${saved.name} · Pokédex 5e ITA',
        text: 'Incontro esportato da Pokédex 5e ITA.',
      );
      _setMessage(
        _shareService.feedback(
          outcome,
          successMessage: '${saved.name} condiviso correttamente.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
'''
update(
    'lib/screens/tools/encounter_library_screen.dart',
    [
        (
            "import '../../services/campaign_transfer_service.dart';\n",
            "import '../../services/campaign_transfer_service.dart';\nimport '../../services/native_share_service.dart';\n",
            'share service import',
        ),
        (
            '  final CampaignTransferService _transferService = CampaignTransferService();\n',
            '  final CampaignTransferService _transferService = CampaignTransferService();\n  final NativeShareService _shareService = const NativeShareService();\n',
            'share service field',
        ),
        (
            '  Future<void> _importEncounter() async {\n',
            encounter_share_method + '\n  Future<void> _importEncounter() async {\n',
            'share method',
        ),
        (
            '                  onExport: () => _exportEncounter(saved),\n                  onDuplicate: () => _duplicateEncounter(saved),\n',
            '                  onExport: () => _exportEncounter(saved),\n                  onShare: () => _shareEncounter(saved),\n                  onDuplicate: () => _duplicateEncounter(saved),\n',
            'card share callback',
        ),
        (
            '    required this.onExport,\n    required this.onDuplicate,\n',
            '    required this.onExport,\n    required this.onShare,\n    required this.onDuplicate,\n',
            'card constructor',
        ),
        (
            '  final VoidCallback onExport;\n  final VoidCallback onDuplicate;\n',
            '  final VoidCallback onExport;\n  final VoidCallback onShare;\n  final VoidCallback onDuplicate;\n',
            'card share field',
        ),
        (
            "                        case 'duplicate':\n",
            "                        case 'share':\n                          onShare();\n                          break;\n                        case 'duplicate':\n",
            'card share switch',
        ),
        (
            "                      PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
            "                      PopupMenuItem(\n                        value: 'share',\n                        child: Text('Condividi incontro'),\n                      ),\n                      PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
            'card share menu item',
        ),
    ],
)


# NPC trainer sharing.
trainer_share_method = r'''
  Future<void> _shareTrainer(SavedNpcTrainer saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forNpcTrainer(
        npcTrainer: saved,
        sourceProfileName: profile.name,
      );
      final json = _transferService.encode(bundle);
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForNpcTrainer(bundle),
        mimeType: 'application/json',
        title: 'Condividi ${saved.displayName}',
        subject: '${saved.displayName} · Pokédex 5e ITA',
        text: 'Allenatore PNG esportato da Pokédex 5e ITA.',
      );
      _setMessage(
        _shareService.feedback(
          outcome,
          successMessage: '${saved.displayName} condiviso correttamente.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
'''
update(
    'lib/screens/tools/npc_trainer_library_screen.dart',
    [
        (
            "import '../../services/master_battle_service.dart';\n",
            "import '../../services/master_battle_service.dart';\nimport '../../services/native_share_service.dart';\n",
            'share service import',
        ),
        (
            '  final CampaignTransferService _transferService = CampaignTransferService();\n',
            '  final CampaignTransferService _transferService = CampaignTransferService();\n  final NativeShareService _shareService = const NativeShareService();\n',
            'share service field',
        ),
        (
            '  Future<void> _importTrainer() async {\n',
            trainer_share_method + '\n  Future<void> _importTrainer() async {\n',
            'share method',
        ),
        (
            '                  onExport: () => _exportTrainer(trainer),\n                  onDuplicate: () => _duplicateTrainer(trainer),\n',
            '                  onExport: () => _exportTrainer(trainer),\n                  onShare: () => _shareTrainer(trainer),\n                  onDuplicate: () => _duplicateTrainer(trainer),\n',
            'card share callback',
        ),
        (
            '    required this.onExport,\n    required this.onDuplicate,\n',
            '    required this.onExport,\n    required this.onShare,\n    required this.onDuplicate,\n',
            'card constructor',
        ),
        (
            '  final VoidCallback onExport;\n  final VoidCallback onDuplicate;\n',
            '  final VoidCallback onExport;\n  final VoidCallback onShare;\n  final VoidCallback onDuplicate;\n',
            'card share field',
        ),
        (
            "                    if (value == 'export') onExport();\n                    if (value == 'duplicate') onDuplicate();\n",
            "                    if (value == 'export') onExport();\n                    if (value == 'share') onShare();\n                    if (value == 'duplicate') onDuplicate();\n",
            'card share switch',
        ),
        (
            "                    PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
            "                    PopupMenuItem(\n                      value: 'share',\n                      child: Text('Condividi Allenatore'),\n                    ),\n                    PopupMenuItem(value: 'duplicate', child: Text('Duplica')),\n",
            'card share menu item',
        ),
    ],
)


# Master fight summary sharing.
fight_share_method = r'''
  Future<void> _shareSummary() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      final exportedAt = DateTime.now();
      final summary = _summaryService.build(
        session: _session,
        pokemonById: _pokemonById,
        exportedAt: exportedAt,
      );
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: summary,
        fileName: _summaryService.fileName(_session, exportedAt: exportedAt),
        mimeType: 'text/plain',
        title: 'Condividi il riepilogo del Fight del Master',
        subject: 'Riepilogo Fight del Master · Pokédex 5e ITA',
        text: 'Riepilogo esportato da Pokédex 5e ITA.',
      );
      if (!mounted) return;
      setState(() {
        _message = _shareService.feedback(
          outcome,
          successMessage: 'Riepilogo del fight condiviso correttamente.',
        );
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
update(
    'lib/screens/battle/npc_battle_screen.dart',
    [
        (
            "import '../../services/master_fight_summary_service.dart';\n",
            "import '../../services/master_fight_summary_service.dart';\nimport '../../services/native_share_service.dart';\n",
            'share service import',
        ),
        (
            '  final MasterFightSummaryService _summaryService =\n      const MasterFightSummaryService();\n',
            '  final MasterFightSummaryService _summaryService =\n      const MasterFightSummaryService();\n  final NativeShareService _shareService = const NativeShareService();\n',
            'share service field',
        ),
        (
            '  Future<void> _endFight() async {\n',
            fight_share_method + '\n  Future<void> _endFight() async {\n',
            'share summary method',
        ),
        (
            "          IconButton(\n            onPressed: _isWorking ? null : _exportSummary,\n            tooltip: 'Esporta riepilogo',\n            icon: const Icon(Icons.file_download_outlined),\n          ),\n",
            "          PopupMenuButton<_FightSummaryAction>(\n            enabled: !_isWorking,\n            tooltip: 'Esporta o condividi riepilogo',\n            icon: const Icon(Icons.ios_share_outlined),\n            onSelected: (action) {\n              switch (action) {\n                case _FightSummaryAction.export:\n                  _exportSummary();\n                  break;\n                case _FightSummaryAction.share:\n                  _shareSummary();\n                  break;\n              }\n            },\n            itemBuilder: (_) => const [\n              PopupMenuItem(\n                value: _FightSummaryAction.export,\n                child: Text('Salva riepilogo'),\n              ),\n              PopupMenuItem(\n                value: _FightSummaryAction.share,\n                child: Text('Condividi riepilogo'),\n              ),\n            ],\n          ),\n",
            'fight summary menu',
        ),
    ],
)
fight_path = Path('lib/screens/battle/npc_battle_screen.dart')
fight_text = fight_path.read_text(encoding='utf-8')
if 'enum _FightSummaryAction' in fight_text:
    raise SystemExit('fight summary enum già presente')
fight_path.write_text(
    fight_text.rstrip() + '\n\nenum _FightSummaryAction { export, share }\n',
    encoding='utf-8',
)


# Documentation.
update(
    'README.md',
    [
        (
            '- esportazione e importazione mirata di Pokémon, squadre, incontri e Allenatori PNG, oltre al riepilogo testuale del Fight del Master.\n',
            '- esportazione, importazione e condivisione nativa di Pokémon, squadre, incontri e Allenatori PNG, oltre al riepilogo testuale del Fight del Master.\n',
            'feature list',
        ),
        (
            'Dalla schermata Squadra è inoltre possibile esportare e importare singoli Pokémon o una formazione completa senza sostituire l’intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC. Le librerie del Master supportano file portabili per incontri e Allenatori PNG, mentre il Fight del Master può produrre un riepilogo testuale con round, iniziativa, PF, status e PP.\n',
            'Dalla schermata Squadra è inoltre possibile esportare, importare e condividere singoli Pokémon o una formazione completa senza sostituire l’intero profilo; i Pokémon rimpiazzati e gli eventuali esuberi vengono conservati nel PC. Le librerie del Master supportano file portabili e condivisione diretta per incontri e Allenatori PNG, mentre il Fight del Master può salvare o condividere un riepilogo testuale con round, iniziativa, PF, status e PP.\n',
            'data sharing paragraph',
        ),
    ],
)
update(
    'CHANGELOG.md',
    [
        (
            "- il Fight del Master può esportare un riepilogo testuale con round, ordine d'iniziativa, PF, status, PP, ricompense e Pokémon attivi.\n",
            "- il Fight del Master può esportare un riepilogo testuale con round, ordine d'iniziativa, PF, status, PP, ricompense e Pokémon attivi;\n- Pokémon, squadre, incontri, Allenatori PNG e riepiloghi del Fight del Master possono essere condivisi tramite il menu nativo del dispositivo, con fallback al download sul Web.\n",
            'native sharing entry',
        ),
        (
            '- condivisione diretta tramite menu nativo di Android, Windows e Web.\n',
            '- review generale del layout e preparazione della prima release Android.\n',
            'planned work',
        ),
    ],
)

print('Condivisione nativa applicata correttamente.')
