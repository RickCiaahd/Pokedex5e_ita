import 'package:flutter/material.dart';

import '../../models/generated_encounter.dart';
import '../../models/generated_pokemon.dart';
import '../../models/move_data.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_nature.dart';
import '../../repositories/move_repository.dart';
import '../../services/encounter_generator_service.dart';
import '../../services/pokemon_generator_service.dart';
import '../../widgets/navigation/home_leading_button.dart';
import '../../widgets/pokemon/pokemon_asset_image.dart';
import '../pokemon/pokemon_detail_screen.dart';

class EncounterResultScreen extends StatefulWidget {
  const EncounterResultScreen({
    super.key,
    required this.encounter,
    required this.catalog,
  });

  final GeneratedEncounter encounter;
  final List<Pokemon> catalog;

  @override
  State<EncounterResultScreen> createState() => _EncounterResultScreenState();
}

class _EncounterResultScreenState extends State<EncounterResultScreen> {
  final EncounterGeneratorService _encounterService =
      const EncounterGeneratorService();
  final PokemonGeneratorService _pokemonGeneratorService =
      const PokemonGeneratorService();
  final MoveRepository _moveRepository = MoveRepository();

  late GeneratedEncounter _encounter;
  Map<String, MoveData?> _moves = const {};
  bool _isWorking = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _encounter = widget.encounter;
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    final references = <String>{
      for (final member in _encounter.members) ...member.pokemon.selectedMoves,
    };
    final moves = await _moveRepository.getMoves(references);
    if (!mounted) return;
    setState(() => _moves = moves);
  }

  PokemonGeneratorFilters get _generationFilters => PokemonGeneratorFilters(
    minSr: 0,
    maxSr: 100,
    minGeneration: 1,
    maxGeneration: 9,
    level: _encounter.filters.level,
    includeForms: _encounter.filters.includeForms,
    shinyChance: 0.01,
  );

  Future<void> _regenerateMember(int index) async {
    if (_isWorking || index < 0 || index >= _encounter.members.length) return;
    final current = _encounter.members[index];
    setState(() {
      _isWorking = true;
      _message = null;
    });
    try {
      final generated = _pokemonGeneratorService.generateForPokemonForm(
        pokemon: current.pokemon.basePokemon,
        formName: current.pokemon.formName,
        filters: _generationFilters,
      );
      if (generated == null) return;
      final members = [..._encounter.members]
        ..[index] = current.copyWith(pokemon: generated);
      _replaceMembers(members);
      await _loadMoves();
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _regenerateUnlocked() async {
    if (_isWorking) return;
    setState(() {
      _isWorking = true;
      _message = null;
    });
    try {
      final members = <EncounterMember>[];
      for (final member in _encounter.members) {
        if (member.isLocked) {
          members.add(member);
          continue;
        }
        final generated = _pokemonGeneratorService.generateForPokemonForm(
          pokemon: member.pokemon.basePokemon,
          formName: member.pokemon.formName,
          filters: _generationFilters,
        );
        members.add(
          generated == null ? member : member.copyWith(pokemon: generated),
        );
      }
      _replaceMembers(members);
      await _loadMoves();
      if (mounted) {
        setState(
          () => _message = 'Rigenerati tutti gli avversari non bloccati.',
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  void _replaceMembers(List<EncounterMember> members) {
    final estimate = _encounterService.estimate(
      party: _encounter.party,
      generated: members.map((member) => member.pokemon),
      targetDifficulty: _encounter.targetDifficulty,
    );
    setState(() {
      _encounter = _encounter.copyWith(members: members, estimate: estimate);
    });
  }

  void _toggleLock(int index) {
    final members = [..._encounter.members];
    final current = members[index];
    members[index] = current.copyWith(isLocked: !current.isLocked);
    _replaceMembers(members);
  }

  void _removeMember(int index) {
    final members = [
      for (
        var memberIndex = 0;
        memberIndex < _encounter.members.length;
        memberIndex++
      )
        if (memberIndex != index) _encounter.members[memberIndex],
    ];
    _replaceMembers(members);
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

  String _format(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final estimate = _encounter.estimate;
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: Text(_encounter.title),
        actions: [
          IconButton(
            onPressed: _encounter.members.isEmpty || _isWorking
                ? null
                : _regenerateUnlocked,
            tooltip: 'Rigenera i non bloccati',
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'DIFFICOLTÀ STIMATA: ${estimate.difficulty.label.toUpperCase()}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Obiettivo ${_encounter.targetDifficulty.label} · '
                    'budget gruppo ${_format(estimate.partyBudget)} · '
                    'costo incontro ${_format(estimate.encounterCost)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_encounter.party.activePokemon} Pokémon alleati · '
                    'livello medio ${_encounter.party.averageLevel} · '
                    '${_encounter.members.length} avversari',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (estimate.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ATTENZIONE',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    for (final warning in estimate.warnings)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $warning'),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_message!),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_encounter.members.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Non ci sono più avversari in questo incontro.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (var index = 0; index < _encounter.members.length; index++) ...[
              _EncounterMemberCard(
                member: _encounter.members[index],
                moves: _moves,
                isWorking: _isWorking,
                onToggleLock: () => _toggleLock(index),
                onRegenerate: () => _regenerateMember(index),
                onOpenDetails: () =>
                    _openDetails(_encounter.members[index].pokemon),
                onRemove: () => _removeMember(index),
              ),
              if (index != _encounter.members.length - 1)
                const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _encounter.members.isEmpty || _isWorking
                ? null
                : _regenerateUnlocked,
            icon: _isWorking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.casino_outlined),
            label: const Text('RIGENERA TUTTI I NON BLOCCATI'),
          ),
          const SizedBox(height: 8),
          const Text(
            'L’incontro è temporaneo: non modifica Squadra, PC o Pokédex.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EncounterMemberCard extends StatelessWidget {
  const _EncounterMemberCard({
    required this.member,
    required this.moves,
    required this.isWorking,
    required this.onToggleLock,
    required this.onRegenerate,
    required this.onOpenDetails,
    required this.onRemove,
  });

  final EncounterMember member;
  final Map<String, MoveData?> moves;
  final bool isWorking;
  final VoidCallback onToggleLock;
  final VoidCallback onRegenerate;
  final VoidCallback onOpenDetails;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final generated = member.pokemon;
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                generated.basePokemon.name.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: onToggleLock,
              tooltip: member.isLocked ? 'Sblocca' : 'Blocca',
              icon: Icon(
                member.isLocked ? Icons.lock : Icons.lock_open_outlined,
              ),
            ),
          ],
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isWorking || member.isLocked ? null : onRegenerate,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('Rigenera'),
              ),
              TextButton.icon(
                onPressed: onOpenDetails,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Scheda'),
              ),
              TextButton.icon(
                onPressed: isWorking ? null : onRemove,
                icon: const Icon(Icons.close),
                label: const Text('Rimuovi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
