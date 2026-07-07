import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/trainer_progression.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';

class TrainerSheetScreen extends StatefulWidget {
  const TrainerSheetScreen({super.key});

  @override
  State<TrainerSheetScreen> createState() => _TrainerSheetScreenState();
}

class _TrainerSheetScreenState extends State<TrainerSheetScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _moneyController = TextEditingController();

  UserProfile? _profile;
  int _trainerLevel = TrainerProgression.minLevel;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _moneyController.addListener(_refreshMoneySummary);
    _loadProfile();
  }

  @override
  void dispose() {
    _moneyController.removeListener(_refreshMoneySummary);
    _nameController.dispose();
    _moneyController.dispose();
    super.dispose();
  }

  void _refreshMoneySummary() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.getActiveProfile();

      if (!mounted) return;

      _nameController.text = profile.name;
      _moneyController.text = profile.money.toString();

      setState(() {
        _profile = profile;
        _trainerLevel = TrainerProgression.clampLevel(profile.trainerLevel);
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

  void _changeLevel(int delta) {
    setState(() {
      _trainerLevel = TrainerProgression.clampLevel(_trainerLevel + delta);
    });
  }

  Future<void> _saveProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final name = _nameController.text.trim();
    final money = int.tryParse(_moneyController.text.trim());

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Inserisci un nome allenatore.');
      return;
    }

    if (money == null || money < 0) {
      setState(() => _errorMessage = 'Inserisci una quantita di soldi valida.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = profile.copyWith(
        name: name,
        trainerLevel: _trainerLevel,
        money: money,
      );

      await _profileRepository.saveProfile(updated);

      if (!mounted) return;

      setState(() {
        _profile = updated;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheda allenatore aggiornata.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scheda Allenatore')),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null && _profile == null)
              _TrainerSheetErrorState(
                message: _errorMessage!,
                onRetry: _loadProfile,
              )
            else ...[
              _TrainerSummary(
                trainerLevel: _trainerLevel,
                money: int.tryParse(_moneyController.text.trim()) ?? 0,
              ),
              const SizedBox(height: 20),
              _TrainerEditForm(
                nameController: _nameController,
                moneyController: _moneyController,
                trainerLevel: _trainerLevel,
                isSaving: _isSaving,
                errorMessage: _errorMessage,
                onDecreaseLevel: () => _changeLevel(-1),
                onIncreaseLevel: () => _changeLevel(1),
                onSave: _saveProfile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainerSummary extends StatelessWidget {
  const _TrainerSummary({required this.trainerLevel, required this.money});

  final int trainerLevel;
  final int money;

  @override
  Widget build(BuildContext context) {
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progressione campagna',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TrainerStat(label: 'Livello', value: '$trainerLevel'),
                ),
                Expanded(child: _TrainerStat(label: 'Soldi', value: '₽ $money')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TrainerStat(label: 'Pokéslot', value: '$pokeslots'),
                ),
                Expanded(child: _TrainerStat(label: 'SR max', value: '$maxSr')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerStat extends StatelessWidget {
  const _TrainerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TrainerEditForm extends StatelessWidget {
  const _TrainerEditForm({
    required this.nameController,
    required this.moneyController,
    required this.trainerLevel,
    required this.isSaving,
    required this.errorMessage,
    required this.onDecreaseLevel,
    required this.onIncreaseLevel,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController moneyController;
  final int trainerLevel;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onDecreaseLevel;
  final VoidCallback onIncreaseLevel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final pokeslots = TrainerProgression.pokeslotsForLevel(trainerLevel);
    final maxSr = TrainerProgression.maxControlledSrForLevel(trainerLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dati allenatore',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome allenatore'),
            ),
            const SizedBox(height: 20),
            Text(
              'Livello allenatore',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Diminuisci livello',
                  onPressed: trainerLevel <= TrainerProgression.minLevel
                      ? null
                      : onDecreaseLevel,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Lv. $trainerLevel',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('Pokéslot $pokeslots | SR max $maxSr'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Aumenta livello',
                  onPressed: trainerLevel >= TrainerProgression.maxLevel
                      ? null
                      : onIncreaseLevel,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: moneyController,
              decoration: const InputDecoration(
                labelText: 'Soldi',
                prefixText: '₽ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Salvataggio...' : 'Salva scheda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerSheetErrorState extends StatelessWidget {
  const _TrainerSheetErrorState({required this.message, required this.onRetry});

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
