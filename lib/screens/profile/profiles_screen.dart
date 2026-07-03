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

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profilo attivo: ${profile.name}')),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProfile,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
              Text(
                'Scegli il profilo attivo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ogni profilo ha Pokédex, squadra e impostazioni separate.',
              ),
              const SizedBox(height: 20),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(profile.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(profile.name),
        subtitle: Text(isActive ? 'Profilo attivo' : 'Tocca per attivare'),
        trailing: isActive
            ? const Icon(Icons.check_circle)
            : IconButton(
                tooltip: 'Elimina',
                icon: const Icon(Icons.delete_outline),
                onPressed: canDelete ? onDelete : null,
              ),
        onTap: isActive ? null : onSelect,
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
        decoration: const InputDecoration(
          labelText: 'Nome allenatore',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Crea'),
        ),
      ],
    );
  }
}

class _ProfilesErrorState extends StatelessWidget {
  const _ProfilesErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Errore: $message',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}
