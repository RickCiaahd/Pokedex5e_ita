import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bag_item.dart';
import '../../models/generated_npc_trainer.dart';
import '../../models/generated_pokemon.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../models/pokemon_type_localization.dart';
import '../../models/trainer_manual_content.dart';
import '../../repositories/move_repository.dart';
import '../../services/npc_trainer_generator_service.dart';
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
  });

  final GeneratedNpcTrainer trainer;
  final List<Pokemon> catalog;
  final List<TrainerOrigin> origins;
  final List<TrainerPath> paths;
  final List<String> specializations;
  final List<BagItem> items;

  @override
  State<NpcTrainerResultScreen> createState() => _NpcTrainerResultScreenState();
}

class _NpcTrainerResultScreenState extends State<NpcTrainerResultScreen> {
  final NpcTrainerGeneratorService _generatorService =
      const NpcTrainerGeneratorService();
  final MoveRepository _moveRepository = MoveRepository();

  late GeneratedNpcTrainer _trainer;
  Map<String, MoveData?> _moves = const {};
  bool _isWorking = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _trainer = widget.trainer;
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    final references = <String>{
      for (final pokemon in _trainer.team) ...pokemon.selectedMoves,
    };
    final moves = await _moveRepository.getMoves(references);
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
          _message =
              'Non è stato possibile rigenerare una squadra completa con questi parametri.';
        });
        return;
      }
      setState(() {
        _trainer = generated;
        _message = 'Allenatore e squadra rigenerati.';
      });
      await _loadMoves();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _copySummary() async {
    await Clipboard.setData(ClipboardData(text: _summaryText()));
    if (!mounted) return;
    setState(() => _message = 'Riepilogo copiato negli appunti.');
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
        'Allenatore Lv. ${_trainer.trainerLevel} · ${_trainer.rank.label}',
      )
      ..writeln('Origine: ${_trainer.origin}')
      ..writeln('Path: ${_trainer.path}')
      ..writeln('Specializzazioni: ${_trainer.specializations.join(', ')}')
      ..writeln('Personalità: ${_trainer.personality}')
      ..writeln('Motivazione: ${_trainer.motivation}')
      ..writeln('Particolarità: ${_trainer.quirk}')
      ..writeln('Battuta: ${_trainer.openingLine}')
      ..writeln('Tattiche: ${_trainer.tactics}')
      ..writeln('Squadra:');
    for (final pokemon in _trainer.team) {
      buffer.writeln(
        '- ${pokemon.basePokemon.name} (${pokemon.formLabel}) Lv. ${pokemon.level}: '
        '${pokemon.selectedMoves.join(', ')}',
      );
    }
    buffer.writeln('Ricompensa: ${_formatMoney(_trainer.rewardMoney)}');
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
        title: const Text('Allenatore generato'),
        actions: [
          IconButton(
            onPressed: _copySummary,
            tooltip: 'Copia riepilogo',
            icon: const Icon(Icons.content_copy_outlined),
          ),
          IconButton(
            onPressed: _isWorking ? null : _regenerate,
            tooltip: 'Rigenera tutto',
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
            title: 'Personalità e motivazione',
            children: [
              _LabeledText(label: 'Personalità', value: _trainer.personality),
              _LabeledText(label: 'Obiettivo', value: _trainer.motivation),
              _LabeledText(label: 'Particolarità', value: _trainer.quirk),
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
            title: 'Tattiche',
            children: [Text(_trainer.tactics)],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'SQUADRA · ${_trainer.team.length}',
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
            title: 'Ricompensa',
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
                const Text('Nessun oggetto aggiuntivo.'),
              ],
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isWorking ? null : _regenerate,
            icon: _isWorking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.casino_outlined),
            label: Text(
              _isWorking ? 'RIGENERAZIONE...' : 'RIGENERA ALLENATORE E SQUADRA',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.tune),
            label: const Text('MODIFICA PARAMETRI'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _copySummary,
            icon: const Icon(Icons.content_copy_outlined),
            label: const Text('COPIA RIEPILOGO'),
          ),
        ],
      ),
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
          '${generated.formLabel} · Livello ${generated.level} · '
          'SR ${pokemon.sr} · PF ${generated.maxHp} · CA $armorClass',
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
                  Chip(label: Text(moves[reference]?.name ?? reference)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenDetails,
              icon: const Icon(Icons.description_outlined),
              label: const Text('SCHEDA'),
            ),
          ),
        ],
      ),
    );
  }
}
