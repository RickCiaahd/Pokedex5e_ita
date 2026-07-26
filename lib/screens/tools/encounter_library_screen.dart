import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';

import '../../models/campaign_transfer_bundle.dart';
import '../../models/generated_encounter.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_form_choice.dart';
import '../../models/saved_encounter.dart';
import '../../models/user_profile.dart';
import '../../repositories/pokemon_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/saved_encounter_repository.dart';
import '../../services/campaign_transfer_service.dart';
import '../../services/native_share_service.dart';
import '../../services/saved_encounter_mapper_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/battle/wild_master_fight_launcher.dart';
import '../../widgets/navigation/home_leading_button.dart';
import 'encounter_result_screen.dart';

class EncounterLibraryScreen extends StatefulWidget {
  const EncounterLibraryScreen({super.key});

  @override
  State<EncounterLibraryScreen> createState() => _EncounterLibraryScreenState();
}

class _EncounterLibraryScreenState extends State<EncounterLibraryScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokemonRepository _pokemonRepository = PokemonRepository();
  final SavedEncounterRepository _repository = SavedEncounterRepository();
  final SavedEncounterMapperService _mapper =
      const SavedEncounterMapperService();
  final CampaignTransferService _transferService = CampaignTransferService();
  final NativeShareService _shareService = const NativeShareService();

  UserProfile? _profile;
  List<Pokemon> _catalog = const [];
  List<SavedEncounter> _encounters = const [];
  bool _isLoading = true;
  bool _isBusy = false;
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
      final encounters = await _repository.getEncounters(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _catalog = catalog;
        _encounters = encounters;
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

  void _setMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  Future<void> _openEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final encounter = _mapper.toGenerated(saved: saved, catalog: _catalog);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EncounterResultScreen(
            encounter: encounter,
            catalog: _catalog,
            profileId: profile.id,
            savedEncounter: saved,
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

  Future<void> _startFight(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final encounter = _mapper.toGenerated(saved: saved, catalog: _catalog);
      final launched = await launchWildMasterFight(
        context: context,
        profileId: profile.id,
        encounter: encounter,
        catalog: _catalog,
      );
      if (!mounted || !launched) return;
      _setMessage(
        uiTextForLanguage(
          'Il fight di ${saved.name} è stato salvato e può essere ripreso dagli Strumenti del Master.',
          'The fight for ${saved.name} was saved and can be resumed from Master Tools.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _duplicateEncounter(SavedEncounter saved) async {
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
      await _repository.saveEncounter(profileId: profile.id, encounter: copy);
      await _load();
      _setMessage(
        uiTextForLanguage(
          '${copy.name} duplicato.',
          '${copy.name} duplicated.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          uiTextForLanguage('Eliminare l’incontro?', 'Delete encounter?'),
        ),
        content: Text(
          uiTextForLanguage(
            '“${saved.name}” verrà rimosso dalla libreria.',
            '“${saved.name}” will be removed from the library.',
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
      await _repository.deleteEncounter(
        profileId: profile.id,
        encounterId: saved.id,
      );
      await _load();
      _setMessage(
        uiTextForLanguage('${saved.name} eliminato.', '${saved.name} deleted.'),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<CampaignTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: uiTextForLanguage(
        'Importa incontro Trainer Atlas 5e',
        'Import Trainer Atlas 5e encounter',
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

  Future<void> _exportEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forEncounter(
        encounter: saved,
        sourceProfileName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: uiTextForLanguage(
          'Esporta ${saved.name}',
          'Export ${saved.name}',
        ),
        fileName: _transferService.fileNameForEncounter(bundle),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      _setMessage(
        path == null
            ? uiTextForLanguage('Esportazione annullata.', 'Export cancelled.')
            : uiTextForLanguage(
                '${saved.name} esportato correttamente.',
                '${saved.name} exported successfully.',
              ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _shareEncounter(SavedEncounter saved) async {
    final profile = _profile;
    if (profile == null || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bundle = CampaignTransferBundle.forEncounter(
        encounter: saved,
        sourceProfileName: profile.name,
      );
      final json = await _transferService.encodePortable(bundle);
      if (!mounted) return;
      final outcome = await _shareService.shareTextFile(
        context: context,
        content: json,
        fileName: _transferService.fileNameForEncounter(bundle),
        mimeType: 'application/json',
        title: uiTextForLanguage(
          'Condividi ${saved.name}',
          'Share ${saved.name}',
        ),
        subject: '${saved.name} · Trainer Atlas 5e',
        text: uiTextForLanguage(
          'Incontro esportato da Trainer Atlas 5e.',
          'Encounter exported from Trainer Atlas 5e.',
        ),
      );
      _setMessage(
        _shareService.feedback(
          outcome,
          successMessage: uiTextForLanguage(
            '${saved.name} condiviso correttamente.',
            '${saved.name} shared successfully.',
          ),
        ),
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
        _setMessage(
          uiTextForLanguage('Importazione annullata.', 'Import cancelled.'),
        );
        return;
      }
      if (bundle.kind != CampaignTransferKind.encounter) {
        throw FormatException(
          uiTextForLanguage(
            'Seleziona un file esportato come incontro.',
            'Select a file exported as an encounter.',
          ),
        );
      }
      final source = bundle.encounter!;
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
            uiTextForLanguage('Importare incontro?', 'Import encounter?'),
          ),
          content: Text(
            uiTextForLanguage(
              'Vuoi importare “${source.name}”$origin con ${source.enemyCount} avversari? Verrà creata una nuova copia nella libreria del profilo attivo.',
              'Import “${source.name}”$origin with ${source.enemyCount} opponents? A new copy will be created in the active profile library.',
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
      final imported = await _transferService.importEncounter(
        profileId: profile.id,
        bundle: bundle,
        catalogPokemonIds: _catalog.map((pokemon) => pokemon.id).toSet(),
      );
      await _load();
      _setMessage(
        uiTextForLanguage(
          '${imported.name} importato nella libreria incontri.',
          '${imported.name} imported into the encounter library.',
        ),
      );
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _copyName(String original) {
    final names = _encounters.map((encounter) => encounter.name).toSet();
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
        title: Text(context.uiText('Libreria incontri', 'Encounter Library')),
        actions: [
          IconButton(
            onPressed: _isBusy || _isLoading ? null : _importEncounter,
            tooltip: context.uiText('Importa incontro', 'Import encounter'),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 1100,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              32.0 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              _LibraryIntroCard(count: _encounters.length),
              if (_isBusy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              if (_message != null) ...[
                const SizedBox(height: 10),
                _LibraryMessage(message: _message!, isError: _messageIsError),
              ],
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_encounters.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.bookmarks_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          context.uiText(
                            'Nessun incontro salvato',
                            'No saved encounters',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.uiText(
                            'Genera un incontro e premi Salva nella schermata del risultato.',
                            'Generate an encounter and press Save on the result screen.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final saved in _encounters) ...[
                  _SavedEncounterCard(
                    saved: saved,
                    pokemonById: _pokemonById,
                    isBusy: _isBusy,
                    onOpen: () => _openEncounter(saved),
                    onFight: () => _startFight(saved),
                    onExport: () => _exportEncounter(saved),
                    onShare: () => _shareEncounter(saved),
                    onDuplicate: () => _duplicateEncounter(saved),
                    onDelete: () => _deleteEncounter(saved),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryIntroCard extends StatelessWidget {
  const _LibraryIntroCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.bookmarks_outlined,
              size: 38,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.uiText('Incontri preparati', 'Prepared encounters'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.uiText(
                      '$count incontri salvati nel profilo attivo. Aprili, modificali, rigenerali e salvali di nuovo.',
                      '$count encounters saved in the active profile. Open, edit, regenerate and save them again.',
                    ),
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedEncounterCard extends StatelessWidget {
  const _SavedEncounterCard({
    required this.saved,
    required this.pokemonById,
    required this.isBusy,
    required this.onOpen,
    required this.onFight,
    required this.onExport,
    required this.onShare,
    required this.onDuplicate,
    required this.onDelete,
  });

  final SavedEncounter saved;
  final Pokemon? Function(int) pokemonById;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onFight;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final composition = <String, int>{};
    for (final member in saved.members) {
      final pokemon = pokemonById(member.pokemonId);
      final label = pokemon == null
          ? '#${member.pokemonId}'
          : pokemonFormDisplayName(pokemon.name, member.formName);
      composition[label] = (composition[label] ?? 0) + 1;
    }
    final labels = composition.entries
        .map(
          (entry) =>
              entry.value == 1 ? entry.key : '${entry.value}× ${entry.key}',
        )
        .toList(growable: false);
    final summary = labels.take(4).join(' · ');
    final remaining = labels.length - 4;

    return Card(
      child: InkWell(
        onTap: isBusy ? null : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      saved.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isBusy ? null : onShare,
                    tooltip: context.uiText(
                      'Condividi incontro',
                      'Share encounter',
                    ),
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                  PopupMenuButton<String>(
                    enabled: !isBusy,
                    onSelected: (value) {
                      switch (value) {
                        case 'export':
                          onExport();
                          break;
                        case 'share':
                          onShare();
                          break;
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Text(
                          context.uiText(
                            'Esporta incontro',
                            'Export encounter',
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Text(
                          context.uiText(
                            'Condividi incontro',
                            'Share encounter',
                          ),
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
              if (saved.notes.isNotEmpty) ...[
                Text(saved.notes),
                const SizedBox(height: 7),
              ],
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  Chip(
                    label: Text(
                      context.uiText(
                        '${saved.enemyCount} avversari',
                        '${saved.enemyCount} opponents',
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      context.uiText(
                        'Lv medio ${_formatLevel(saved.averageEnemyLevel)}',
                        'Average Lv ${_formatLevel(saved.averageEnemyLevel)}',
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      context.uiText(
                        saved.targetDifficulty.label,
                        saved.targetDifficulty.englishLabel,
                      ),
                    ),
                  ),
                  Chip(label: Text(_sourceLabel(context, saved.source))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                remaining > 0
                    ? context.uiText(
                        '$summary · +$remaining specie',
                        '$summary · +$remaining species',
                      )
                    : summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.uiText(
                        'Aggiornato ${_formatDate(saved.updatedAt)}',
                        'Updated ${_formatDate(saved.updatedAt)}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onFight,
                    icon: const Icon(Icons.sports_mma_outlined),
                    label: Text(
                      context.uiText('FIGHT DEL MASTER', 'MASTER FIGHT'),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.uiText('APRI', 'OPEN')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLevel(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _sourceLabel(BuildContext context, EncounterSource source) =>
      switch (source) {
        EncounterSource.automatic => context.uiText('Automatico', 'Automatic'),
        EncounterSource.manual => context.uiText('Manuale', 'Manual'),
        EncounterSource.collection => context.uiText('Raccolta', 'Collection'),
      };
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: isError ? colors.errorContainer : colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: isError
                ? colors.onErrorContainer
                : colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
