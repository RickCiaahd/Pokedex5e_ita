import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization/ui_text.dart';
import '../../models/bag_item.dart';
import '../../models/generated_npc_trainer.dart';
import '../../models/generated_pokemon.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/saved_npc_trainer.dart';
import '../../models/trainer_manual_content.dart';
import '../../repositories/move_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/saved_npc_trainer_repository.dart';
import '../../services/npc_trainer_generator_service.dart';
import '../../services/saved_npc_trainer_mapper_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../pokemon/pokemon_detail_screen.dart';

class NpcTrainerResultScreen extends StatefulWidget {
  const NpcTrainerResultScreen({
    super.key,
    required this.trainer,
    required this.catalog,
    required this.origins,
    required this.paths,
    required this.specializations,
    required this.items,
    this.savedTrainer,
  });

  final GeneratedNpcTrainer trainer;
  final List<Pokemon> catalog;
  final List<TrainerOrigin> origins;
  final List<TrainerPath> paths;
  final List<String> specializations;
  final List<BagItem> items;
  final SavedNpcTrainer? savedTrainer;

  @override
  State<NpcTrainerResultScreen> createState() => _NpcTrainerResultScreenState();
}

class _NpcTrainerResultScreenState extends State<NpcTrainerResultScreen> {
  final NpcTrainerGeneratorService _generatorService =
      const NpcTrainerGeneratorService();
  final MoveRepository _moveRepository = MoveRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final SavedNpcTrainerRepository _savedRepository =
      SavedNpcTrainerRepository();
  final SavedNpcTrainerMapperService _savedMapper =
      const SavedNpcTrainerMapperService();

  late GeneratedNpcTrainer _trainer;
  SavedNpcTrainer? _savedTrainer;
  Map<String, MoveData?> _moves = const {};
  bool _isWorking = false;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _trainer = widget.trainer;
    _savedTrainer = widget.savedTrainer;
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    final referencesByPokemon = <int, Set<String>>{};
    for (final generated in _trainer.team) {
      referencesByPokemon
          .putIfAbsent(generated.basePokemon.id, () => <String>{})
          .addAll(generated.selectedMoves);
    }
    final moves = await _moveRepository.getMovesByPokemon(referencesByPokemon);
    if (!mounted) return;
    setState(() => _moves = moves);
  }

  Future<void> _regenerate() async {
    if (_isWorking) return;
    setState(() {
      _isWorking = true;
      _message = null;
    });
    try {
      final generated = _generatorService.generate(
        catalog: widget.catalog,
        options: _trainer.options,
        specializations: widget.specializations,
        origins: widget.origins,
        paths: widget.paths,
        items: widget.items,
      );
      if (generated == null) {
        setState(() {
          _message = context.uiText(
            'Non è stato possibile rigenerare una squadra completa con questi parametri.',
            'A complete team could not be regenerated with these parameters.',
          );
        });
        return;
      }
      setState(() {
        _trainer = generated;
        _message = context.uiText(
          'Allenatore e squadra rigenerati.',
          'Trainer and team regenerated.',
        );
      });
      await _loadMoves();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

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
      await _savedRepository.saveTrainer(profileId: profile.id, trainer: saved);
      if (!mounted) return;
      setState(() {
        final wasUpdate = _savedTrainer != null;
        _savedTrainer = saved;
        _message = wasUpdate
            ? context.uiText(
                'Allenatore aggiornato nella libreria.',
                'Trainer updated in the library.',
              )
            : context.uiText(
                'Allenatore salvato nella libreria.',
                'Trainer saved in the library.',
              );
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

  Future<void> _copySummary() async {
    await Clipboard.setData(ClipboardData(text: _summaryText()));
    if (!mounted) return;
    setState(
      () => _message = context.uiText(
        'Riepilogo copiato negli appunti.',
        'Summary copied to the clipboard.',
      ),
    );
  }

  Future<void> _openDetails(GeneratedPokemon generated) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          pokemon: generated.basePokemon,
          teamSlot: generated.toTeamSlot(slotIndex: 0),
          allPokemon: widget.catalog,
          team: const [],
        ),
      ),
    );
  }

  String _summaryText() {
    final buffer = StringBuffer()
      ..writeln(_trainer.displayName)
      ..writeln(
        context.uiText(
          'Allenatore Lv. ${_trainer.trainerLevel} · ${_trainer.rank.label}',
          'Trainer Lv. ${_trainer.trainerLevel} · ${_trainer.rank.englishLabel}',
        ),
      )
      ..writeln(
        context.uiText(
          'Origine: ${_trainer.origin}',
          'Origin: ${_trainer.origin}',
        ),
      )
      ..writeln(
        context.uiText('Percorso: ${_trainer.path}', 'Path: ${_trainer.path}'),
      )
      ..writeln(
        context.uiText(
          'Specializzazioni: ${_trainer.specializations.join(', ')}',
          'Specializations: ${_trainer.specializations.join(', ')}',
        ),
      )
      ..writeln(
        context.uiText(
          'Personalità: ${_trainer.personality}',
          'Personality: ${_trainer.personality}',
        ),
      )
      ..writeln(
        context.uiText(
          'Motivazione: ${_trainer.motivation}',
          'Motivation: ${_trainer.motivation}',
        ),
      )
      ..writeln(
        context.uiText(
          'Particolarità: ${_trainer.quirk}',
          'Quirk: ${_trainer.quirk}',
        ),
      )
      ..writeln(
        context.uiText(
          'Battuta: ${_trainer.openingLine}',
          'Opening line: ${_trainer.openingLine}',
        ),
      )
      ..writeln(
        context.uiText(
          'Tattiche: ${_trainer.tactics}',
          'Tactics: ${_trainer.tactics}',
        ),
      )
      ..writeln(context.uiText('Squadra:', 'Team:'));
    for (final pokemon in _trainer.team) {
      buffer.writeln(
        '- ${pokemon.basePokemon.name} (${pokemon.formLabel}) Lv. ${pokemon.level}: '
        '${pokemon.selectedMoves.join(', ')}',
      );
    }
    buffer.writeln(
      context.uiText(
        'Ricompensa: ${_formatMoney(_trainer.rewardMoney)}',
        'Reward: ${_formatMoney(_trainer.rewardMoney)}',
      ),
    );
    if (_trainer.rewards.isNotEmpty) {
      buffer.writeln('Oggetti: ${_trainer.rewards.join(', ')}');
    }
    return buffer.toString().trim();
  }

  String _formatMoney(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return '${buffer.toString()} ₽';
  }

  @override
  Widget build(BuildContext context) {
    final preferredType = PokemonTypeLocalization.italianLabel(
      _trainer.preferredType,
    );
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(
          _savedTrainer == null
              ? context.uiText('Allenatore generato', 'Generated Trainer')
              : _savedTrainer!.name,
        ),
        actions: [
          IconButton(
            onPressed: _isSaving || _isWorking ? null : _saveTrainer,
            tooltip: _savedTrainer == null
                ? context.uiText('Salva nella libreria', 'Save to library')
                : context.uiText(
                    'Aggiorna allenatore salvato',
                    'Update saved Trainer',
                  ),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _savedTrainer == null
                        ? Icons.person_add_alt_1_outlined
                        : Icons.person_pin_circle_outlined,
                  ),
          ),
          IconButton(
            onPressed: _copySummary,
            tooltip: context.uiText('Copia riepilogo', 'Copy summary'),
            icon: const Icon(Icons.content_copy_outlined),
          ),
          IconButton(
            onPressed: _isWorking ? null : _regenerate,
            tooltip: context.uiText('Rigenera tutto', 'Regenerate all'),
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32.0 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          _TrainerHeader(trainer: _trainer, preferredType: preferredType),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_message!),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _InformationCard(
            icon: Icons.psychology_alt_outlined,
            title: context.uiText(
              'Personalità e motivazione',
              'Personality and motivation',
            ),
            children: [
              _LabeledText(
                label: context.uiText('Personalità', 'Personality'),
                value: _trainer.personality,
              ),
              _LabeledText(
                label: context.uiText('Obiettivo', 'Goal'),
                value: _trainer.motivation,
              ),
              _LabeledText(
                label: context.uiText('Particolarità', 'Quirk'),
                value: _trainer.quirk,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _trainer.openingLine,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InformationCard(
            icon: Icons.route_outlined,
            title: context.uiText('Tattiche', 'Tactics'),
            children: [Text(_trainer.tactics)],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.uiText(
                    'SQUADRA · ${_trainer.team.length}',
                    'TEAM · ${_trainer.team.length}',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _trainer.options.composition.label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final pokemon in _trainer.team) ...[
            _NpcPokemonCard(
              generated: pokemon,
              moves: _moves,
              onOpenDetails: () => _openDetails(pokemon),
            ),
            const SizedBox(height: 10),
          ],
          _InformationCard(
            icon: Icons.workspace_premium_outlined,
            title: context.uiText('Ricompensa', 'Reward'),
            children: [
              Text(
                _formatMoney(_trainer.rewardMoney),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (_trainer.rewards.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reward in _trainer.rewards)
                      Chip(label: Text(reward)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  context.uiText(
                    'Nessun oggetto aggiuntivo.',
                    'No additional items.',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isWorking || _isSaving ? null : _saveTrainer,
            icon: Icon(
              _savedTrainer == null
                  ? Icons.person_add_alt_1_outlined
                  : Icons.person_pin_circle_outlined,
            ),
            label: Text(
              _savedTrainer == null
                  ? context.uiText('SALVA NELLA LIBRERIA', 'SAVE TO LIBRARY')
                  : context.uiText(
                      'AGGIORNA ALLENATORE SALVATO',
                      'UPDATE SAVED TRAINER',
                    ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isWorking || _isSaving ? null : _regenerate,
            icon: _isWorking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.casino_outlined),
            label: Text(
              _isWorking
                  ? context.uiText('RIGENERAZIONE...', 'REGENERATING...')
                  : context.uiText(
                      'RIGENERA ALLENATORE E SQUADRA',
                      'REGENERATE TRAINER AND TEAM',
                    ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.tune),
            label: Text(
              context.uiText('MODIFICA PARAMETRI', 'EDIT PARAMETERS'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _copySummary,
            icon: const Icon(Icons.content_copy_outlined),
            label: Text(context.uiText('COPIA RIEPILOGO', 'COPY SUMMARY')),
          ),
        ],
      ),
    );
  }
}

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
      setState(
        () => _error = context.uiText(
          'Inserisci un nome valido.',
          'Enter a valid name.',
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pop(_NpcSaveDetails(name: name, notes: _notesController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isUpdate
            ? context.uiText('Aggiorna Allenatore PNG', 'Update NPC Trainer')
            : context.uiText('Salva Allenatore PNG', 'Save NPC Trainer'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.uiText('Nome', 'Name'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.uiText('Note facoltative', 'Optional notes'),
              border: const OutlineInputBorder(),
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
          child: Text(context.uiText('Annulla', 'Cancel')),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(
            widget.isUpdate
                ? context.uiText('Aggiorna', 'Update')
                : context.uiText('Salva', 'Save'),
          ),
        ),
      ],
    );
  }
}

class _TrainerHeader extends StatelessWidget {
  const _TrainerHeader({required this.trainer, required this.preferredType});

  final GeneratedNpcTrainer trainer;
  final String preferredType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  child: const Icon(Icons.person, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        trainer.epithet,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderChip(label: 'Lv. ${trainer.trainerLevel}'),
                _HeaderChip(label: trainer.rank.label),
                _HeaderChip(label: preferredType),
                _HeaderChip(label: trainer.origin),
                _HeaderChip(label: trainer.path),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Specializzazioni: ${trainer.specializations.join(' · ')}',
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      backgroundColor: colors.surface.withValues(alpha: 0.82),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _NpcPokemonCard extends StatelessWidget {
  const _NpcPokemonCard({
    required this.generated,
    required this.moves,
    required this.onOpenDetails,
  });

  final GeneratedPokemon generated;
  final Map<String, MoveData?> moves;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final pokemon = generated.pokemon;
    final natureModifiers = PokemonNature.forName(generated.nature);
    final armorClass = pokemon.armorClass + (natureModifiers['AC'] ?? 0);
    final gender = switch (generated.gender) {
      'Male' => 'Maschio',
      'Female' => 'Femmina',
      'Genderless' => 'Senza sesso',
      _ => 'Non specificato',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: PokemonAssetImage(
          pokemon: generated.basePokemon,
          formName: generated.formName,
          gender: generated.gender,
          isShiny: generated.isShiny,
          size: 62,
        ),
        title: Text(
          generated.basePokemon.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          context.uiText(
            '${generated.formLabel} · Livello ${generated.level} · '
                'SR ${pokemon.sr} · PF ${generated.maxHp} · CA $armorClass',
            '${generated.formLabel} · Level ${generated.level} · '
                'SR ${pokemon.sr} · HP ${generated.maxHp} · AC $armorClass',
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$gender · ${generated.nature} · '
              '${generated.ability ?? 'Nessuna abilità'}',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reference in generated.selectedMoves)
                  Chip(
                    label: Text(
                      moves[MoveRepository.contextualKey(
                                generated.basePokemon.id,
                                reference,
                              )]
                              ?.name ??
                          reference,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenDetails,
              icon: const Icon(Icons.description_outlined),
              label: Text(context.uiText('SCHEDA', 'SHEET')),
            ),
          ),
        ],
      ),
    );
  }
}
