import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../models/battle_environment.dart';
import '../../models/pokemon.dart';
import '../../models/team_slot.dart';
import '../../services/battle_environment_service.dart';

class BattleEnvironmentCard extends StatelessWidget {
  const BattleEnvironmentCard({
    super.key,
    required this.environment,
    required this.pokemon,
    required this.slot,
    required this.level,
    required this.proficiency,
    required this.baseSpeed,
    required this.onEdit,
  });

  final BattleEnvironment environment;
  final Pokemon pokemon;
  final TeamSlot slot;
  final int level;
  final int proficiency;
  final int baseSpeed;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final baseAc = BattleEnvironmentService.baseArmorClass(pokemon, slot);
    final acBonus = BattleEnvironmentService.armorClassBonus(
      pokemon: pokemon,
      slot: slot,
      environment: environment,
    );
    final speed = BattleEnvironmentService.effectiveSpeed(
      baseSpeed: baseSpeed,
      pokemon: pokemon,
      slot: slot,
      environment: environment,
    );
    final notes = BattleEnvironmentService.pokemonNotes(
      pokemon: pokemon,
      slot: slot,
      level: level,
      proficiency: proficiency,
      environment: environment,
    );
    final weatherLabel = context.uiText(
      environment.weather.label,
      environment.weather.englishLabel,
    );
    final naturalTerrainLabel = context.uiText(
      environment.naturalTerrain.label,
      environment.naturalTerrain.englishLabel,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.public_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.uiText('AMBIENTE', 'ENVIRONMENT'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        context.uiText(
                          'Tracker delle condizioni comunicate dal Master',
                          'Tracker for conditions communicated by the GM',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.uiText(
                    'Aggiorna ambiente',
                    'Update environment',
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _EnvironmentChip(
                  icon: Icons.cloud_outlined,
                  label: environment.hasTimedWeather
                      ? '$weatherLabel · ${environment.weatherRoundsRemaining}R'
                      : weatherLabel,
                ),
                _EnvironmentChip(
                  icon: Icons.landscape_outlined,
                  label: naturalTerrainLabel,
                ),
                if (environment.hasFieldTerrain)
                  _EnvironmentChip(
                    icon: Icons.blur_circular,
                    label:
                        '${context.uiText(environment.fieldTerrain.label, environment.fieldTerrain.englishLabel)} · ${environment.fieldTerrainRoundsRemaining}R',
                  ),
                if (acBonus != 0)
                  _EnvironmentChip(
                    icon: Icons.shield_outlined,
                    label:
                        '${context.uiText('CA', 'AC')} $baseAc → ${baseAc + acBonus}',
                  ),
                if (speed != baseSpeed)
                  _EnvironmentChip(
                    icon: Icons.speed_outlined,
                    label:
                        '${context.uiText('Velocità', 'Speed')} $baseSpeed → $speed ft',
                  ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(
                  context.uiText(
                    'EFFETTI SUL POKÉMON (${notes.length})',
                    'EFFECTS ON POKÉMON (${notes.length})',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  for (final note in notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('• $note'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnvironmentChip extends StatelessWidget {
  const _EnvironmentChip({required this.icon, required this.label});

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

Future<BattleEnvironment?> showBattleEnvironmentDialog({
  required BuildContext context,
  required BattleEnvironment initial,
}) {
  return showDialog<BattleEnvironment>(
    context: context,
    builder: (_) => _BattleEnvironmentDialog(initial: initial),
  );
}

class _BattleEnvironmentDialog extends StatefulWidget {
  const _BattleEnvironmentDialog({required this.initial});

  final BattleEnvironment initial;

  @override
  State<_BattleEnvironmentDialog> createState() =>
      _BattleEnvironmentDialogState();
}

class _BattleEnvironmentDialogState extends State<_BattleEnvironmentDialog> {
  late BattleWeather _weather;
  late bool _timedWeather;
  late int _weatherRounds;
  late BattleNaturalTerrain _naturalTerrain;
  late BattleFieldTerrain _fieldTerrain;
  late int _fieldRounds;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _weather = value.weather;
    _timedWeather = value.hasTimedWeather;
    _weatherRounds = value.weatherRoundsRemaining > 0
        ? value.weatherRoundsRemaining
        : 5;
    _naturalTerrain = value.naturalTerrain;
    _fieldTerrain = value.fieldTerrain;
    _fieldRounds = value.fieldTerrainRoundsRemaining > 0
        ? value.fieldTerrainRoundsRemaining
        : 3;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.uiText('Aggiorna ambiente', 'Update environment')),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.uiText(
                  'Inserisci soltanto le condizioni comunicate dal Master. Il Battle Companion non genera casualmente il meteo e non decide la scena.',
                  'Enter only the conditions communicated by the GM. The Battle Companion does not generate weather or decide the scene.',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<BattleWeather>(
                initialValue: _weather,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.uiText('Meteo', 'Weather'),
                ),
                items: [
                  for (final value in BattleWeather.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        context.uiText(value.label, value.englishLabel),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _weather = value;
                    if (value == BattleWeather.clear) _timedWeather = false;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.uiText(
                    'Meteo con durata comunicata',
                    'Weather with a communicated duration',
                  ),
                ),
                subtitle: Text(
                  context.uiText(
                    'Usalo solo quando il Master indica un numero di round.',
                    'Use this only when the GM provides a number of rounds.',
                  ),
                ),
                value: _timedWeather && _weather != BattleWeather.clear,
                onChanged: _weather == BattleWeather.clear
                    ? null
                    : (value) => setState(() => _timedWeather = value),
              ),
              if (_timedWeather && _weather != BattleWeather.clear)
                _RoundCounter(
                  label: context.uiText(
                    'Round meteo rimanenti',
                    'Weather rounds remaining',
                  ),
                  value: _weatherRounds,
                  onChanged: (value) => setState(() => _weatherRounds = value),
                ),
              const Divider(height: 24),
              DropdownButtonFormField<BattleNaturalTerrain>(
                initialValue: _naturalTerrain,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.uiText(
                    'Terreno naturale',
                    'Natural terrain',
                  ),
                ),
                items: [
                  for (final value in BattleNaturalTerrain.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        context.uiText(value.label, value.englishLabel),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _naturalTerrain = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<BattleFieldTerrain>(
                initialValue: _fieldTerrain,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.uiText(
                    'Terreno creato da una mossa',
                    'Terrain created by a move',
                  ),
                ),
                items: [
                  for (final value in BattleFieldTerrain.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        context.uiText(value.label, value.englishLabel),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _fieldTerrain = value);
                },
              ),
              if (_fieldTerrain != BattleFieldTerrain.none)
                _RoundCounter(
                  label: context.uiText(
                    'Round terreno rimanenti',
                    'Terrain rounds remaining',
                  ),
                  value: _fieldRounds,
                  onChanged: (value) => setState(() => _fieldRounds = value),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.uiText('ANNULLA', 'CANCEL')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              BattleEnvironment(
                season: widget.initial.season,
                weather: _weather,
                weatherRoundsRemaining:
                    _weather == BattleWeather.clear || !_timedWeather
                    ? 0
                    : _weatherRounds,
                weatherSourceLevel: 0,
                naturalTerrain: _naturalTerrain,
                fieldTerrain: _fieldTerrain,
                fieldTerrainRoundsRemaining:
                    _fieldTerrain == BattleFieldTerrain.none ? 0 : _fieldRounds,
                optionalWeatherDamageAdvantage: false,
                suppressWeatherAbilities: false,
              ),
            );
          },
          child: Text(context.uiText('SALVA', 'SAVE')),
        ),
      ],
    );
  }
}

class _RoundCounter extends StatelessWidget {
  const _RoundCounter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        IconButton(
          onPressed: value < 20 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
