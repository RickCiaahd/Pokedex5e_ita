import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../repositories/pokedex_repositry.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/setting_repository.dart';
import '../../repositories/team_repository.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final PokedexRepository _pokedexRepository = PokedexRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();

  UserProfile? _activeProfile;
  List<UserProfile> _profiles = [];

  bool _isLoading = true;
  String? _errorMessage;

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createProfile() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateProfileDialog(),
    );

    if (name == null || name.trim().isEmpty) return;

    final profile = await _profileRepository.createProfile(name.trim());
    await _profileRepository.setActiveProfile(profile.id);
    await _loadProfiles();
  }

  Future<void> _setActiveProfile(UserProfile profile) async {
    await _profileRepository.setActiveProfile(profile.id);
    await _loadProfiles();
  }

  Future<void> _deleteProfile(UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminare profilo?'),
        content: Text(
          'Vuoi eliminare ${profile.name}? Verranno rimossi anche Pokédex, '
          'squadra e impostazioni collegate.',
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

    await _pokedexRepository.clearProfilePokedex(profile.id);
    await _teamRepository.deleteTeam(profile.id);
    await _settingsRepository.deleteSettings(profile.id);
    await _profileRepository.deleteProfile(profile.id);
    await _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfileId = _activeProfile?.id;
    final activeProfileName = _activeProfile?.name ?? 'Allenatore';

    return Scaffold(
      appBar: AppBar(title: const Text('Profili')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(true),
        icon: const Icon(Icons.check),
        label: const Text('OK'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
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
              const SizedBox(height: 24),
              _ProfilesSectionHeader(onCreateProfile: _createProfile),
              const SizedBox(height: 4),
              Text(
                'Ogni profilo ha Pokédex, squadra e impostazioni separate.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final profile in _profiles)
                _ProfileTile(
                  profile: profile,
                  isActive: profile.id == activeProfileId,
                  canDelete: profile.id != activeProfileId,
                  onSelect: () => _setActiveProfile(profile),
                  onDelete: () => _deleteProfile(profile),
                ),
            ],
          ],
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

class _ProfilesSectionHeader extends StatelessWidget {
  const _ProfilesSectionHeader({required this.onCreateProfile});

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
          onPressed: onCreateProfile,
          icon: const Icon(Icons.add),
          label: const Text('Nuovo'),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.canDelete,
    required this.onSelect,
    required this.onDelete,
  });

  final UserProfile profile;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onSelect;
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
                ? 'Usato per Pokédex e squadra'
                : 'Creato il ${_formatDate(profile.createdAt)}',
          ),
        ),
        trailing: isActive
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: onSelect, child: const Text('Attiva')),
                  IconButton(
                    tooltip: 'Elimina',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: canDelete ? onDelete : null,
                  ),
                ],
              ),
        onTap: isActive ? null : onSelect,
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
    final year = date.year.toString();

    return '$day/$month/$year';
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
