import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../models/bag_item.dart';
import '../../models/campaign_transfer_bundle.dart';
import '../../models/generated_npc_trainer.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_choice.dart';
import '../../models/saved_npc_trainer.dart';
import '../../models/trainer_manual_content.dart';
import '../../models/trainer_manual_options.dart';
import '../../models/trainer_ui_localization.dart';
import '../../models/user_profile.dart';
import '../../repositories/item_repository.dart';
import '../../repositories/master_battle_session_repository.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/saved_npc_trainer_repository.dart';
import '../../repositories/trainer_manual_repository.dart';
import '../../services/campaign_transfer_service.dart';
import '../../services/master_battle_service.dart';
import '../../services/native_share_service.dart';
import '../../services/saved_npc_trainer_mapper_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../battle/npc_battle_screen.dart';
import 'npc_trainer_result_screen.dart';

class NpcTrainerLibraryScreen extends StatefulWidget {
  const NpcTrainerLibraryScreen({super.key});

  @override
  State<NpcTrainerLibraryScreen> createState() =>
      _NpcTrainerLibraryScreenState();
}

class _NpcTrainerLibraryScreenState extends State<NpcTrainerLibraryScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final SavedNpcTrainerRepository _repository = SavedNpcTrainerRepository();
  final MasterBattleSessionRepository _battleRepository =
      MasterBattleSessionRepository();
  final TrainerManualRepository _manualRepository = TrainerManualRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final MasterBattleService _battleService = const MasterBattleService();
  final SavedNpcTrainerMapperService _mapper =
      const SavedNpcTrainerMapperService();
  final CampaignTransferService _transferService = CampaignTransferService();
  final NativeShareService _shareService = const NativeShareService();

  UserProfile? _profile;
  List<Pokemon> _catalog = const [];
  List<SavedNpcTrainer> _trainers = const [];
  List<TrainerOrigin> _origins = const [];
  List<TrainerPath> _paths = const [];
  List<BagItem> _items = const [];
  bool _hasActiveFight = false;
  bool _isLoading = true;
  bool _isBusy = false;
  final Set<String> _selectedIds = <String>{};
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final profile = await _profileRepository.getActiveProfile();
      final catalog = await _pokemonRepository.getAllPokemon();
      final trainers = await _repository.getTrainers(profile.id);
      final origins = await _manualRepository.getOrigins();
      final paths = await _manualRepository.getTrainerPaths();
      List<BagItem> items = const [];
      try {
        items = await _itemRepository.getWebItems();
      } catch (_) {
        items = const [];
      }
      final hasActiveFight = await _battleRepository.hasSession(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _catalog = catalog;
        _trainers = trainers;
        _origins = origins;
        _paths = paths;
        _items = items;
        _hasActiveFight = hasActiveFight;
        _selectedIds.removeWhere(
          (id) => !trainers.any((trainer) => trainer.id == id),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyError(error);
        _messageIsError = true;
        _isLoading = false;
      });
    }
  }

  void _setMessage(String value, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = value;
      _messageIsError = isError;
    });
  }

  Future<void> _openTrainer(SavedNpcTrainer saved) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final trainer = _mapper.toGenerated(saved: saved, catalog: _catalog);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NpcTrainerResultScreen(
            trainer: trainer,
            catalog: _catalog,
            origins: _origins,
            paths: _paths,
            specializations: [...TrainerManualOptions.specializations]..sort(),
            items: _items,
            savedTrainer: saved,
          ),
        ),
      );
      await _load();
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<CampaignTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: uiTextForLanguage(
        'Importa Allenatore PNG Trainer Atlas 5e',
        'Import NPC Trainer · Trainer Atlas 5e',
      ),
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
    return _transferService.decode(utf8.decode(bytes, allowMalformed: false));
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
      final json = await _transferService.encodePortable(bundle);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: uiTextForLanguage(
          'Esporta ${saved.displayName}',
          'Export ${saved.displayName}',
        ),
        fileName: _transferService.fileNameForNpcTrainer(bundle),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setMessage(
        path == null
            ? uiTextForLanguage('Esportazione annullata.', 'Export cancelled.')
            : uiTextForLanguage(
                '${saved.displayName} esportato correttamente.',
                '${saved.displayName} exported successfully.',
              ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareTrainer(SavedNpcTrainer saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forNpcTrainer(
        npcTrainer: saved,
        sourceProfileName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      if (!mounted) return;
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForNpcTrainer(bundle),
        mimeType: 'application/json',
        title: uiTextForLanguage(
          'Condividi ${saved.displayName}',
          'Share ${saved.displayName}',
        ),
        subject: '${saved.displayName} · Trainer Atlas 5e',
        text: uiTextForLanguage(
          'Allenatore PNG esportato da Trainer Atlas 5e.',
          'NPC Trainer exported from Trainer Atlas 5e.',
        ),
      );
      _setMessage(
        _shareService.feedback(
          outcome,
          successMessage: uiTextForLanguage(
            '${saved.displayName} condiviso correttamente.',
            '${saved.displayName} shared successfully.',
          ),
        ),
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
        _setMessage(
          uiTextForLanguage('Importazione annullata.', 'Import cancelled.'),
        );
        return;
      }
      if (bundle.kind != CampaignTransferKind.npcTrainer) {
        throw FormatException(
          uiTextForLanguage(
            'Seleziona un file esportato come Allenatore PNG.',
            'Select a file exported as an NPC Trainer.',
          ),
        );
      }
      final source = bundle.npcTrainer!;
      if (!mounted) return;
      final origin = bundle.sourceProfileName.isEmpty
          ? ''
          : uiTextForLanguage(
              ' dal profilo ${bundle.sourceProfileName}',
              ' from profile ${bundle.sourceProfileName}',
            );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            uiTextForLanguage(
              'Importare Allenatore PNG?',
              'Import NPC Trainer?',
            ),
          ),
          content: Text(
            uiTextForLanguage(
              'Vuoi importare “${source.displayName}”$origin con una squadra '
                  'di ${source.team.length} Pokémon? Verrà creata una nuova copia '
                  'nella libreria del profilo attivo.',
              'Import “${source.displayName}”$origin with a team of '
                  '${source.team.length} Pokémon? A new copy will be created in '
                  'the active profile library.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(uiTextForLanguage('ANNULLA', 'CANCEL')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(uiTextForLanguage('IMPORTA', 'IMPORT')),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _setMessage(
          uiTextForLanguage('Importazione annullata.', 'Import cancelled.'),
        );
        return;
      }
      final imported = await _transferService.importNpcTrainer(
        profileId: profile.id,
        bundle: bundle,
        catalogPokemonIds: _catalog.map((pokemon) => pokemon.id).toSet(),
      );
      await _load();
      _setMessage(
        uiTextForLanguage(
          '${imported.displayName} importato nella libreria PNG.',
          '${imported.displayName} imported into the NPC library.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _duplicateTrainer(SavedNpcTrainer saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final now = DateTime.now();
      final copy = saved.copyWith(
        id: now.microsecondsSinceEpoch.toString(),
        name: _copyName(saved.name),
        createdAt: now,
        updatedAt: now,
      );
      await _repository.saveTrainer(profileId: profile.id, trainer: copy);
      await _load();
      _setMessage(
        uiTextForLanguage(
          '${copy.displayName} duplicato.',
          '${copy.displayName} duplicated.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteTrainer(SavedNpcTrainer saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          uiTextForLanguage('Eliminare l’allenatore?', 'Delete trainer?'),
        ),
        content: Text(
          uiTextForLanguage(
            '“${saved.displayName}” verrà rimosso dalla libreria. Le sessioni di fight già avviate non verranno modificate.',
            '“${saved.displayName}” will be removed from the library. Existing battle sessions will not be changed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(uiTextForLanguage('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(uiTextForLanguage('Elimina', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await _repository.deleteTrainer(
        profileId: profile.id,
        trainerId: saved.id,
      );
      _selectedIds.remove(saved.id);
      await _load();
      _setMessage(
        uiTextForLanguage(
          '${saved.displayName} eliminato.',
          '${saved.displayName} deleted.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _resumeFight() async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    final session = await _battleRepository.getSession(profile.id);
    if (!mounted) return;
    if (session == null) {
      _setMessage(
        uiTextForLanguage(
          'Non c’è nessun fight del Master da riprendere.',
          'There is no Game Master battle to resume.',
        ),
        isError: true,
      );
      await _load();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NpcBattleScreen(
          profileId: profile.id,
          catalog: _catalog,
          initialSession: session,
        ),
      ),
    );
    await _load();
  }

  Future<void> _startFightWithSelected() async {
    final selected = [
      for (final trainer in _trainers)
        if (_selectedIds.contains(trainer.id)) trainer,
    ];
    await _startFight(selected);
  }

  Future<void> _startFight(List<SavedNpcTrainer> trainers) async {
    final profile = _profile;
    if (profile == null || trainers.isEmpty || _isBusy) return;
    if (_hasActiveFight) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            uiTextForLanguage(
              'Sostituire il fight attivo?',
              'Replace the active battle?',
            ),
          ),
          content: Text(
            uiTextForLanguage(
              'È già presente una sessione del Master. Avviandone una nuova perderai PF, PP, status, round e iniziativa della sessione corrente.',
              'A Game Master session is already active. Starting a new one will discard HP, PP, conditions, round and initiative from the current session.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(uiTextForLanguage('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(uiTextForLanguage('Nuovo fight', 'New battle')),
            ),
          ],
        ),
      );
      if (replace != true) return;
      if (!mounted) return;
    }

    final activeCounts = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => _FightSetupDialog(trainers: trainers),
    );
    if (activeCounts == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final session = _battleService.createSession(
        profileId: profile.id,
        trainers: trainers,
        activeCounts: activeCounts,
        catalog: _catalog,
      );
      await _battleRepository.saveSession(session);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NpcBattleScreen(
            profileId: profile.id,
            catalog: _catalog,
            initialSession: session,
          ),
        ),
      );
      await _load();
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _copyName(String original) {
    final names = _trainers.map((trainer) => trainer.name).toSet();
    var candidate = context.uiText('$original (copia)', '$original (copy)');
    var index = 2;
    while (names.contains(candidate)) {
      candidate = context.uiText(
        '$original (copia $index)',
        '$original (copy $index)',
      );
      index++;
    }
    return candidate;
  }

  Pokemon? _pokemonById(int id) {
    for (final pokemon in _catalog) {
      if (pokemon.id == id) return pokemon;
    }
    return null;
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(
          context.uiText('Libreria Allenatori PNG', 'NPC Trainer Library'),
        ),
        actions: [
          IconButton(
            onPressed: _isBusy || _isLoading ? null : _importTrainer,
            tooltip: context.uiText(
              'Importa Allenatore PNG',
              'Import NPC Trainer',
            ),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1180,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _LibraryHeader(
                count: _trainers.length,
                hasActiveFight: _hasActiveFight,
                onResumeFight: _isBusy ? null : _resumeFight,
              ),
              if (_isBusy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_message != null) ...[
                const SizedBox(height: 10),
                Card(
                  color: _messageIsError
                      ? Theme.of(context).colorScheme.errorContainer
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_message!),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_trainers.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.groups_2_outlined, size: 48),
                        SizedBox(height: 12),
                        Text(
                          context.uiText(
                            'Nessun Allenatore PNG salvato',
                            'No saved NPC Trainers',
                          ),
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 6),
                        Text(
                          context.uiText(
                            'Genera un Allenatore PNG e salvalo dalla schermata del risultato.',
                            'Generate an NPC Trainer and save it from the result screen.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  context.uiText(
                    'Seleziona più allenatori per controllarli nello stesso fight.',
                    'Select multiple trainers to control them in the same battle.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                for (final trainer in _trainers) ...[
                  _NpcTrainerCard(
                    trainer: trainer,
                    pokemonById: _pokemonById,
                    selected: _selectedIds.contains(trainer.id),
                    disabled: _isBusy,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIds.add(trainer.id);
                        } else {
                          _selectedIds.remove(trainer.id);
                        }
                      });
                    },
                    onOpen: () => _openTrainer(trainer),
                    onFight: () => _startFight([trainer]),
                    onExport: () => _exportTrainer(trainer),
                    onShare: () => _shareTrainer(trainer),
                    onDuplicate: () => _duplicateTrainer(trainer),
                    onDelete: () => _deleteTrainer(trainer),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedIds.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _isBusy ? null : _startFightWithSelected,
                icon: const Icon(Icons.flash_on),
                label: Text(
                  _selectedIds.length == 1
                      ? context.uiText(
                          'ENTRA IN FIGHT CON 1 ALLENATORE',
                          'START BATTLE WITH 1 TRAINER',
                        )
                      : context.uiText(
                          'ENTRA IN FIGHT CON ${_selectedIds.length} ALLENATORI',
                          'START BATTLE WITH ${_selectedIds.length} TRAINERS',
                        ),
                ),
              ),
            ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.count,
    required this.hasActiveFight,
    required this.onResumeFight,
  });

  final int count;
  final bool hasActiveFight;
  final VoidCallback? onResumeFight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_2_outlined,
                  size: 38,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.uiText(
                          'Allenatori del Master',
                          'Game Master Trainers',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.uiText(
                          '$count allenatori salvati nel profilo attivo.',
                          '$count trainers saved in the active profile.',
                        ),
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasActiveFight) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onResumeFight,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  context.uiText(
                    'RIPRENDI FIGHT DEL MASTER',
                    'RESUME GAME MASTER BATTLE',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NpcTrainerCard extends StatelessWidget {
  const _NpcTrainerCard({
    required this.trainer,
    required this.pokemonById,
    required this.selected,
    required this.disabled,
    required this.onSelected,
    required this.onOpen,
    required this.onFight,
    required this.onExport,
    required this.onShare,
    required this.onDuplicate,
    required this.onDelete,
  });

  final SavedNpcTrainer trainer;
  final Pokemon? Function(int) pokemonById;
  final bool selected;
  final bool disabled;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  final VoidCallback onFight;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final specializationLabels = trainer.specializations
        .map(TrainerUiLocalization.specializationName)
        .join(', ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: disabled
                      ? null
                      : (value) => onSelected(value == true),
                ),
                Expanded(
                  child: InkWell(
                    onTap: disabled ? null : onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trainer.displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${context.usesItalianUi ? trainer.rank.label : trainer.rank.englishLabel} · Lv. ${trainer.trainerLevel} · $specializationLabels',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: disabled ? null : onShare,
                  tooltip: context.uiText(
                    'Condividi Allenatore',
                    'Share Trainer',
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                ),
                PopupMenuButton<String>(
                  enabled: !disabled,
                  onSelected: (value) {
                    if (value == 'export') onExport();
                    if (value == 'share') onShare();
                    if (value == 'duplicate') onDuplicate();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Text(
                        context.uiText('Esporta Allenatore', 'Export Trainer'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Text(
                        context.uiText('Condividi Allenatore', 'Share Trainer'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(context.uiText('Duplica', 'Duplicate')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(context.uiText('Elimina', 'Delete')),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trainer.team.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final member = trainer.team[index];
                  final pokemon = pokemonById(member.pokemonId);
                  if (pokemon == null) {
                    return const SizedBox(width: 54);
                  }
                  return Tooltip(
                    message: pokemonFormDisplayName(
                      pokemon.name,
                      member.formName,
                    ),
                    child: PokemonAssetImage(
                      pokemon: pokemon,
                      formName: member.formName,
                      isShiny: member.isShiny,
                      size: 56,
                    ),
                  );
                },
              ),
            ),
            if (trainer.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(trainer.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: disabled ? null : onOpen,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(context.uiText('APRI', 'OPEN')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: disabled ? null : onFight,
                    icon: const Icon(Icons.flash_on),
                    label: Text(
                      context.uiText('ENTRA IN FIGHT', 'START BATTLE'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FightSetupDialog extends StatefulWidget {
  const _FightSetupDialog({required this.trainers});

  final List<SavedNpcTrainer> trainers;

  @override
  State<_FightSetupDialog> createState() => _FightSetupDialogState();
}

class _FightSetupDialogState extends State<_FightSetupDialog> {
  late final Map<String, int> _activeCounts = {
    for (final trainer in widget.trainers) trainer.id: 1,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.uiText('Configura il fight', 'Configure battle')),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.uiText(
                  'Scegli quanti Pokémon può tenere attivi contemporaneamente ciascun allenatore.',
                  'Choose how many Pokémon each trainer can keep active at the same time.',
                ),
              ),
              const SizedBox(height: 12),
              for (final trainer in widget.trainers)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                context.uiText(
                                  '${trainer.team.length} Pokémon in squadra',
                                  '${trainer.team.length} Pokémon on the team',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: (_activeCounts[trainer.id] ?? 1) <= 1
                              ? null
                              : () => setState(() {
                                  _activeCounts[trainer.id] =
                                      (_activeCounts[trainer.id] ?? 1) - 1;
                                }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${_activeCounts[trainer.id]}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          onPressed:
                              (_activeCounts[trainer.id] ?? 1) >=
                                  trainer.team.length
                              ? null
                              : () => setState(() {
                                  _activeCounts[trainer.id] =
                                      (_activeCounts[trainer.id] ?? 1) + 1;
                                }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.uiText('Annulla', 'Cancel')),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_activeCounts),
          icon: const Icon(Icons.flash_on),
          label: Text(context.uiText('ENTRA IN FIGHT', 'START BATTLE')),
        ),
      ],
    );
  }
}
