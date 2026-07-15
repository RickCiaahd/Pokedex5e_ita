import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/profile_backup.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../services/profile_backup_service.dart';
import '../../widgets/layout/responsive_content.dart';
import '../../widgets/navigation/home_leading_button.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ProfileBackupService _backupService = ProfileBackupService();

  UserProfile? _activeProfile;
  List<UserProfile> _profiles = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activeProfile = await _profileRepository.getActiveProfile();
      final profiles = await _profileRepository.getProfiles();

      profiles.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      setState(() {
        _activeProfile = activeProfile;
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _setStatus(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  Future<void> _createProfile() async {
    if (_isBusy) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateProfileDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final profile = await _profileRepository.createProfile(name.trim());
      await _profileRepository.setActiveProfile(profile.id);
      await _loadProfiles();
      _setStatus('Profilo ${profile.name} creato e attivato.');
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _setActiveProfile(UserProfile profile) async {
    if (_isBusy || profile.id == _activeProfile?.id) return;
    setState(() => _isBusy = true);
    try {
      await _profileRepository.setActiveProfile(profile.id);
      await _loadProfiles();
      _setStatus('${profile.name} è ora il profilo attivo.');
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportProfile(UserProfile profile) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final backup = await _backupService.createBackup(profile.id);
      final json = _backupService.encodeBackup(backup);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta il profilo ${profile.name}',
        fileName: _backupService.fileNameFor(backup),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (path == null) {
        _setStatus('Esportazione annullata.');
      } else {
        _setStatus('Backup di ${profile.name} esportato correttamente.');
      }
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importProfile() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Importa un backup Pokédex 5e',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _setStatus('Importazione annullata.');
        return;
      }

      final picked = result.files.single;
      final bytes = picked.bytes ?? await picked.xFile.readAsBytes();
      final backup = _backupService.decodeBackup(
        utf8.decode(bytes, allowMalformed: false),
      );
      if (!mounted) return;

      final choice = await showDialog<_ProfileImportChoice>(
        context: context,
        builder: (_) => _ProfileImportDialog(
          backup: backup,
          profiles: _profiles,
          activeProfileId: _activeProfile?.id,
        ),
      );
      if (choice == null) {
        _setStatus('Importazione annullata.');
        return;
      }

      final imported = await _backupService.importBackup(
        backup,
        targetProfileId: choice.targetProfileId,
        profileName: choice.profileName,
      );
      await _loadProfiles();
      _setStatus(
        choice.targetProfileId == null
            ? 'Profilo ${imported.name} importato e attivato.'
            : 'Profilo ${imported.name} sostituito con il backup e attivato.',
      );
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _duplicateProfile(UserProfile profile) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final duplicate = await _backupService.duplicateProfile(profile.id);
      await _loadProfiles();
      _setStatus('${duplicate.name} creato e attivato.');
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteProfile(UserProfile profile) async {
    if (_isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminare profilo?'),
        content: Text(
          'Vuoi eliminare ${profile.name}? Verranno rimossi scheda allenatore, '
          'Pokédex, squadra, PC, zaino, impostazioni, incontri, Allenatori PNG e battaglie salvate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await _backupService.deleteProfileCompletely(profile.id);
      await _loadProfiles();
      _setStatus('Profilo ${profile.name} eliminato completamente.');
    } catch (error) {
      _setStatus(_friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text
        .replaceFirst('FormatException: ', '')
        .replaceFirst('Bad state: ', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfileId = _activeProfile?.id;
    final activeProfileName = _activeProfile?.name ?? 'Allenatore';

    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Profili'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBusy ? null : () => Navigator.of(context).pop(true),
        icon: const Icon(Icons.check),
        label: const Text('OK'),
      ),
      body: ResponsiveContent(
        maxWidth: 1040,
        child: RefreshIndicator(
          onRefresh: _loadProfiles,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (_isBusy) const LinearProgressIndicator(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _ProfilesErrorState(
                  message: _errorMessage!,
                  onRetry: _loadProfiles,
                )
              else ...[
                _ProfilesHeader(
                  activeProfileName: activeProfileName,
                  profileCount: _profiles.length,
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 12),
                  _ProfileStatusBanner(
                    message: _statusMessage!,
                    isError: _statusIsError,
                    onDismiss: () => setState(() => _statusMessage = null),
                  ),
                ],
                const SizedBox(height: 24),
                _ProfilesSectionHeader(
                  isBusy: _isBusy,
                  onImportProfile: _importProfile,
                  onCreateProfile: _createProfile,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ogni profilo conserva separatamente scheda, Pokédex, squadra, '
                  'PC, zaino, impostazioni, raccolte e incontri salvati.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final profile in _profiles)
                  _ProfileTile(
                    profile: profile,
                    isActive: profile.id == activeProfileId,
                    isBusy: _isBusy,
                    canDelete: profile.id != activeProfileId,
                    onSelect: () => _setActiveProfile(profile),
                    onExport: () => _exportProfile(profile),
                    onDuplicate: () => _duplicateProfile(profile),
                    onDelete: () => _deleteProfile(profile),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilesHeader extends StatelessWidget {
  const _ProfilesHeader({
    required this.activeProfileName,
    required this.profileCount,
  });

  final String activeProfileName;
  final int profileCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            child: const Icon(Icons.person, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profilo attivo',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeProfileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$profileCount profili salvati',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusBanner extends StatelessWidget {
  const _ProfileStatusBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
            IconButton(
              tooltip: 'Chiudi messaggio',
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilesSectionHeader extends StatelessWidget {
  const _ProfilesSectionHeader({
    required this.isBusy,
    required this.onImportProfile,
    required this.onCreateProfile,
  });

  final bool isBusy;
  final VoidCallback onImportProfile;
  final VoidCallback onCreateProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Profili allenatore',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        TextButton.icon(
          onPressed: isBusy ? null : onImportProfile,
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('Importa'),
        ),
        TextButton.icon(
          onPressed: isBusy ? null : onCreateProfile,
          icon: const Icon(Icons.add),
          label: const Text('Nuovo'),
        ),
      ],
    );
  }
}

enum _ProfileAction { export, duplicate, delete }

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.isBusy,
    required this.canDelete,
    required this.onSelect,
    required this.onExport,
    required this.onDuplicate,
    required this.onDelete,
  });

  final UserProfile profile;
  final bool isActive;
  final bool isBusy;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onExport;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          foregroundColor: isActive
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          child: Text(_initialsFor(profile.name)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              _ActiveBadge(colorScheme: colorScheme),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            isActive
                ? 'Lv. ${profile.trainerLevel} | Profilo attivo'
                : 'Lv. ${profile.trainerLevel} | Creato il ${_formatDate(profile.createdAt)}',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              TextButton(
                onPressed: isBusy ? null : onSelect,
                child: const Text('Attiva'),
              )
            else
              Icon(Icons.check_circle, color: colorScheme.primary),
            PopupMenuButton<_ProfileAction>(
              tooltip: 'Azioni profilo',
              enabled: !isBusy,
              onSelected: (action) {
                switch (action) {
                  case _ProfileAction.export:
                    onExport();
                    break;
                  case _ProfileAction.duplicate:
                    onDuplicate();
                    break;
                  case _ProfileAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _ProfileAction.export,
                  child: ListTile(
                    leading: Icon(Icons.file_download_outlined),
                    title: Text('Esporta backup'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: _ProfileAction.duplicate,
                  child: ListTile(
                    leading: Icon(Icons.copy_outlined),
                    title: Text('Duplica'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (canDelete)
                  const PopupMenuItem(
                    value: _ProfileAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Elimina'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: isActive || isBusy ? null : onSelect,
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'Attivo',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CreateProfileDialog extends StatefulWidget {
  const _CreateProfileDialog();

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo profilo'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome allenatore'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Crea')),
      ],
    );
  }
}

enum _ProfileImportMode { createNew, replaceExisting }

class _ProfileImportChoice {
  const _ProfileImportChoice({
    required this.profileName,
    required this.targetProfileId,
  });

  final String profileName;
  final String? targetProfileId;
}

class _ProfileImportDialog extends StatefulWidget {
  const _ProfileImportDialog({
    required this.backup,
    required this.profiles,
    required this.activeProfileId,
  });

  final ProfileBackup backup;
  final List<UserProfile> profiles;
  final String? activeProfileId;

  @override
  State<_ProfileImportDialog> createState() => _ProfileImportDialogState();
}

class _ProfileImportDialogState extends State<_ProfileImportDialog> {
  late final TextEditingController _nameController;
  _ProfileImportMode _mode = _ProfileImportMode.createNew;
  String? _targetProfileId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.backup.profile.name);
    _targetProfileId =
        widget.activeProfileId ??
        (widget.profiles.isEmpty ? null : widget.profiles.first.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_mode == _ProfileImportMode.replaceExisting &&
        _targetProfileId == null) {
      return;
    }

    Navigator.of(context).pop(
      _ProfileImportChoice(
        profileName: name,
        targetProfileId: _mode == _ProfileImportMode.replaceExisting
            ? _targetProfileId
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backup = widget.backup;
    final exportedDate = _formatDateTime(backup.exportedAt);

    return AlertDialog(
      title: const Text('Importa backup profilo'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                backup.profile.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                'Formato ${backup.formatVersion} · Esportato il $exportedDate',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    icon: Icons.badge_outlined,
                    label: 'Lv. ${backup.profile.trainerLevel}',
                  ),
                  _SummaryChip(
                    icon: Icons.visibility_outlined,
                    label: '${backup.seenSpecies} visti',
                  ),
                  _SummaryChip(
                    icon: Icons.catching_pokemon,
                    label: '${backup.caughtSpecies} catturati',
                  ),
                  _SummaryChip(
                    icon: Icons.groups_outlined,
                    label: '${backup.occupiedTeamSlots}/6 in squadra',
                  ),
                  _SummaryChip(
                    icon: Icons.computer_outlined,
                    label: '${backup.pc.length} nel PC',
                  ),
                  _SummaryChip(
                    icon: Icons.backpack_outlined,
                    label: '${backup.bagItemQuantity} oggetti',
                  ),
                  _SummaryChip(
                    icon: Icons.bookmarks_outlined,
                    label: '${backup.savedEncounters.length} incontri',
                  ),
                  _SummaryChip(
                    icon: Icons.flash_on_outlined,
                    label: backup.battleSession == null
                        ? 'Nessuna battaglia'
                        : 'Battaglia salvata',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome del profilo importato',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<_ProfileImportMode>(
                segments: const [
                  ButtonSegment(
                    value: _ProfileImportMode.createNew,
                    icon: Icon(Icons.person_add_alt_1),
                    label: Text('Nuovo profilo'),
                  ),
                  ButtonSegment(
                    value: _ProfileImportMode.replaceExisting,
                    icon: Icon(Icons.sync_alt),
                    label: Text('Sostituisci'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
              if (_mode == _ProfileImportMode.replaceExisting) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _targetProfileId,
                  decoration: const InputDecoration(
                    labelText: 'Profilo da sostituire',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final profile in widget.profiles)
                      DropdownMenuItem(
                        value: profile.id,
                        child: Text(profile.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _targetProfileId = value);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tutti i dati del profilo scelto verranno sostituiti dal '
                  'backup. L’operazione viene annullata automaticamente se il '
                  'ripristino non riesce.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.file_download_done_outlined),
          label: const Text('Importa'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProfilesErrorState extends StatelessWidget {
  const _ProfilesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Errore: $message', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}
