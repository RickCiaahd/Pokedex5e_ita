import 'package:flutter/material.dart';

import '../../models/battle_environment.dart';
import '../../models/pokemon.dart';
import '../../models/pokemon_type_localization.dart';
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
    required this.onRollWeather,
    this.onApplyWeatherDamage,
  });

  final BattleEnvironment environment;
  final Pokemon pokemon;
  final TeamSlot slot;
  final int level;
  final int proficiency;
  final int baseSpeed;
  final VoidCallback onEdit;
  final VoidCallback onRollWeather;
  final VoidCallback? onApplyWeatherDamage;

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
    final hazard = BattleEnvironmentService.startTurnWeatherDamage(
      pokemon: pokemon,
      slot: slot,
      environment: environment,
    );
    final favored = BattleEnvironmentService.favoredMoveTypes(
      environment,
    ).map(PokemonTypeLocalization.italianLabel).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.public_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AMBIENTE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Modifica ambiente',
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _EnvironmentChip(
                  icon: Icons.cloud_outlined,
                  label: environment.weather.label,
                ),
                _EnvironmentChip(
                  icon: Icons.landscape_outlined,
                  label: environment.naturalTerrain.label,
                ),
                if (environment.hasFieldTerrain)
                  _EnvironmentChip(
                    icon: Icons.blur_circular,
                    label:
                        '${environment.fieldTerrain.label} · ${environment.fieldTerrainRoundsRemaining}R',
                  ),
                _EnvironmentChip(
                  icon: Icons.shield_outlined,
                  label: acBonus == 0
                      ? 'CA $baseAc'
                      : 'CA $baseAc → ${baseAc + acBonus}',
                ),
                _EnvironmentChip(
                  icon: Icons.speed_outlined,
                  label: speed == baseSpeed
                      ? 'Velocità $baseSpeed ft'
                      : 'Velocità $baseSpeed → $speed ft',
                ),
              ],
            ),
            if (environment.optionalWeatherDamageAdvantage &&
                favored.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Regola opzionale del manuale: vantaggio ai danni per ${favored.join(', ')}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final note in notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $note'),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRollWeather,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text('TIRA METEO · ${environment.season.label}'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('MODIFICA'),
                ),
                if (hazard != null &&
                    hazard > 0 &&
                    onApplyWeatherDamage != null)
                  FilledButton.tonalIcon(
                    onPressed: onApplyWeatherDamage,
                    icon: const Icon(Icons.heart_broken_outlined),
                    label: Text('APPLICA $hazard DANNI'),
                  ),
              ],
            ),
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
  late BattleSeason _season;
  late BattleWeather _weather;
  late bool _timedWeather;
  late int _weatherRounds;
  late final TextEditingController _sourceLevelController;
  late BattleNaturalTerrain _naturalTerrain;
  late BattleFieldTerrain _fieldTerrain;
  late int _fieldRounds;
  late bool _optionalWeatherDamageAdvantage;
  late bool _suppressWeatherAbilities;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _season = value.season;
    _weather = value.weather;
    _timedWeather = value.weatherRoundsRemaining > 0;
    _weatherRounds = value.weatherRoundsRemaining > 0
        ? value.weatherRoundsRemaining
        : 5;
    _sourceLevelController = TextEditingController(
      text: value.weatherSourceLevel > 0
          ? value.weatherSourceLevel.toString()
          : '',
    );
    _naturalTerrain = value.naturalTerrain;
    _fieldTerrain = value.fieldTerrain;
    _fieldRounds = value.fieldTerrainRoundsRemaining > 0
        ? value.fieldTerrainRoundsRemaining
        : 3;
    _optionalWeatherDamageAdvantage = value.optionalWeatherDamageAdvantage;
    _suppressWeatherAbilities = value.suppressWeatherAbilities;
  }

  @override
  void dispose() {
    _sourceLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialDamageWeather =
        _weather == BattleWeather.hail || _weather == BattleWeather.sandstorm;

    return AlertDialog(
      title: const Text('Meteo e terreno'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<BattleSeason>(
                initialValue: _season,
                decoration: const InputDecoration(labelText: 'Stagione'),
                items: [
                  for (final value in BattleSeason.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _season = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<BattleWeather>(
                initialValue: _weather,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Meteo'),
                items: [
                  for (final value in BattleWeather.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
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
                title: const Text('Meteo creato da mossa o abilità'),
                subtitle: const Text(
                  'Attiva una durata in round. Il meteo naturale resta senza scadenza.',
                ),
                value: _timedWeather && _weather != BattleWeather.clear,
                onChanged: _weather == BattleWeather.clear
                    ? null
                    : (value) => setState(() => _timedWeather = value),
              ),
              if (_timedWeather && _weather != BattleWeather.clear)
                Row(
                  children: [
                    const Expanded(child: Text('Round rimanenti')),
                    IconButton(
                      onPressed: _weatherRounds > 1
                          ? () => setState(() => _weatherRounds -= 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_weatherRounds',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: _weatherRounds < 20
                          ? () => setState(() => _weatherRounds += 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              if (_timedWeather && specialDamageWeather) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _sourceLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Livello della creatura che ha creato il meteo',
                    helperText:
                        'Serve per i danni di Grandine o Tempesta di sabbia. Lascia 0 per un fenomeno naturale.',
                  ),
                ),
              ],
              const Divider(height: 24),
              DropdownButtonFormField<BattleNaturalTerrain>(
                initialValue: _naturalTerrain,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Terreno naturale',
                ),
                items: [
                  for (final value in BattleNaturalTerrain.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _naturalTerrain = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<BattleFieldTerrain>(
                initialValue: _fieldTerrain,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Terreno creato da una mossa',
                ),
                items: [
                  for (final value in BattleFieldTerrain.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _fieldTerrain = value);
                },
              ),
              if (_fieldTerrain != BattleFieldTerrain.none)
                Row(
                  children: [
                    const Expanded(child: Text('Round terreno rimanenti')),
                    IconButton(
                      onPressed: _fieldRounds > 1
                          ? () => setState(() => _fieldRounds -= 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_fieldRounds',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: _fieldRounds < 20
                          ? () => setState(() => _fieldRounds += 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vantaggio ai danni per i tipi favoriti'),
                subtitle: const Text(
                  'Regola opzionale del manuale: tira due volte i danni e usa il risultato migliore.',
                ),
                value: _optionalWeatherDamageAdvantage,
                onChanged: (value) =>
                    setState(() => _optionalWeatherDamageAdvantage = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Air Lock / Cloud Nine attivo'),
                subtitle: const Text(
                  'Sopprime i bonus e malus delle abilità legate al meteo, non il meteo stesso.',
                ),
                value: _suppressWeatherAbilities,
                onChanged: (value) =>
                    setState(() => _suppressWeatherAbilities = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULLA'),
        ),
        FilledButton(
          onPressed: () {
            final sourceLevel =
                int.tryParse(_sourceLevelController.text.trim()) ?? 0;
            Navigator.of(context).pop(
              BattleEnvironment(
                season: _season,
                weather: _weather,
                weatherRoundsRemaining:
                    _weather == BattleWeather.clear || !_timedWeather
                    ? 0
                    : _weatherRounds,
                weatherSourceLevel:
                    _weather == BattleWeather.clear || !_timedWeather
                    ? 0
                    : sourceLevel.clamp(0, 20).toInt(),
                naturalTerrain: _naturalTerrain,
                fieldTerrain: _fieldTerrain,
                fieldTerrainRoundsRemaining:
                    _fieldTerrain == BattleFieldTerrain.none ? 0 : _fieldRounds,
                optionalWeatherDamageAdvantage: _optionalWeatherDamageAdvantage,
                suppressWeatherAbilities: _suppressWeatherAbilities,
              ),
            );
          },
          child: const Text('SALVA'),
        ),
      ],
    );
  }
}
