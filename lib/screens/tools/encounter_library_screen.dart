import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
        'Il fight di ${saved.name} è stato salvato e può essere ripreso dagli Strumenti del Master.',
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
      _setMessage('${copy.name} duplicato.');
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
        title: const Text('Eliminare l’incontro?'),
        content: Text('“${saved.name}” verrà rimosso dalla libreria.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
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
      _setMessage('${saved.name} eliminato.');
    } catch (error) {
      _setMessage(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<CampaignTransferBundle?> _pickTransferFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importa incontro Pokédex 5e',
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

  String _copyName(String original) {
    final names = _encounters.map((encounter) => encounter.name).toSet();
    var candidate = '$original (copia)';
    var index = 2;
    while (names.contains(candidate)) {
      candidate = '$original (copia $index)';
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
        title: const Text('Libreria incontri'),
        actions: [
          IconButton(
            onPressed: _isBusy || _isLoading ? null : _importEncounter,
            tooltip: 'Importa incontro',
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
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.bookmarks_outlined, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Nessun incontro salvato',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Genera un incontro e premi Salva nella schermata del risultato.',
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
                    'Incontri preparati',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count incontri salvati nel profilo attivo. Aprili, modificali, rigenerali e salvali di nuovo.',
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
                    tooltip: 'Condividi incontro',
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
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'export',
                        child: Text('Esporta incontro'),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Text('Condividi incontro'),
                      ),
                      PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
                      PopupMenuItem(value: 'delete', child: Text('Elimina')),
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
                  Chip(label: Text('${saved.enemyCount} avversari')),
                  Chip(
                    label: Text(
                      'Lv medio ${_formatLevel(saved.averageEnemyLevel)}',
                    ),
                  ),
                  Chip(label: Text(saved.targetDifficulty.label)),
                  Chip(label: Text(_sourceLabel(saved.source))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                remaining > 0 ? '$summary · +$remaining specie' : summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Aggiornato ${_formatDate(saved.updatedAt)}',
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
                    label: const Text('FIGHT DEL MASTER'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('APRI'),
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

  String _sourceLabel(EncounterSource source) => switch (source) {
    EncounterSource.automatic => 'Automatico',
    EncounterSource.manual => 'Manuale',
    EncounterSource.collection => 'Raccolta',
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
