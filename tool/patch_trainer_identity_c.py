from pathlib import Path

def rep(t, old, new, n=1, label='replace'):
    c=t.count(old)
    if c!=n: raise RuntimeError(f'{label}: expected {n}, found {c}')
    return t.replace(old,new,n)

p=Path('lib/screens/trainer/trainer_sheet_screen.dart'); t=p.read_text(encoding='utf-8')
t=rep(t,'  final TextEditingController _nameController = TextEditingController();\n  final TextEditingController _moneyController = TextEditingController();\n','  final TextEditingController _nameController = TextEditingController();\n  final TextEditingController _ageController = TextEditingController();\n  final TextEditingController _moneyController = TextEditingController();\n',label='age controller')
t=rep(t,"  String _startingPack = '';\n  String _trainerPath = '';\n","  String _startingPack = '';\n  String _background = '';\n  String _trainerPath = '';\n",label='background state')
for old,new,label in [
('    _nameController.addListener(_refreshSheetPreview);\n    _moneyController.addListener(_refreshSheetPreview);\n','    _nameController.addListener(_refreshSheetPreview);\n    _ageController.addListener(_refreshSheetPreview);\n    _moneyController.addListener(_refreshSheetPreview);\n','age listen'),
('    _nameController.removeListener(_refreshSheetPreview);\n    _moneyController.removeListener(_refreshSheetPreview);\n','    _nameController.removeListener(_refreshSheetPreview);\n    _ageController.removeListener(_refreshSheetPreview);\n    _moneyController.removeListener(_refreshSheetPreview);\n','age unlisten'),
('    _nameController.dispose();\n    _moneyController.dispose();\n','    _nameController.dispose();\n    _ageController.dispose();\n    _moneyController.dispose();\n','age dispose'),
('      _nameController.text = profile.name;\n      _moneyController.text = profile.money.toString();\n','      _nameController.text = profile.name;\n      _ageController.text = profile.trainerAge.toString();\n      _moneyController.text = profile.money.toString();\n','age load'),
("        _startingPack = profile.startingPack;\n        _trainerPath = profile.trainerPath;\n","        _startingPack = profile.startingPack;\n        _background = profile.background;\n        _trainerPath = profile.trainerPath;\n",'background load')]: t=rep(t,old,new,label=label)
t=rep(t,"  void _changeStartingPack(String? pack) {\n    setState(() => _startingPack = pack ?? '');\n  }\n\n  void _changeTrainerPath(String? path) {\n","  void _changeStartingPack(String? pack) {\n    setState(() => _startingPack = pack ?? '');\n  }\n\n  void _changeBackground(String? value) {\n    if (value != null) setState(() => _background = value);\n  }\n\n  void _changeTrainerPath(String? path) {\n",label='background change')
t=rep(t,'    final name = _nameController.text.trim();\n    final money = int.tryParse(_moneyController.text.trim());\n','    final name = _nameController.text.trim();\n    final age = int.tryParse(_ageController.text.trim());\n    final money = int.tryParse(_moneyController.text.trim());\n',label='age parse')
t=rep(t,'    if (money == null || money < 0) {\n','''    if (age == null || age < 6 || age > 99) {
      setState(
        () => _errorMessage = context.uiText(
          'Inserisci un’età valida da 6 a 99.',
          'Enter a valid age from 6 to 99.',
        ),
      );
      return;
    }

    if (money == null || money < 0) {
''',label='age validate')
t=rep(t,'        profileImageBase64: _profileImageBase64,\n        trainerLevel: _trainerLevel,\n','        profileImageBase64: _profileImageBase64,\n        trainerAge: age,\n        trainerLevel: _trainerLevel,\n',label='age save')
t=rep(t,'        originAbilityBonusSource: _originAbilityBonusSource,\n        starterPokemon: _starterPokemon.trim(),\n','        originAbilityBonusSource: _originAbilityBonusSource,\n        background: _background,\n        starterPokemon: _starterPokemon.trim(),\n',label='background save')
t=rep(t,'  Future<void> _openStartingPackPicker() async {\n','''  Future<void> _openBackgroundPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _StringPickerSheet(
        title: context.uiText('Background', 'Background'),
        options: TrainerUiLocalization.backgroundOptions,
        selected: _background,
        descriptions: TrainerUiLocalization.backgroundDescriptions,
        displayNames: TrainerUiLocalization.backgroundLabels,
      ),
    );
    _changeBackground(selected);
  }

  Future<void> _openStartingPackPicker() async {
''',label='background picker')
t=rep(t,'        selected: _startingPack,\n        displayNames: TrainerUiLocalization.startingPackLabels,\n','        selected: _startingPack,\n        descriptions: TrainerUiLocalization.startingPackDescriptions,\n        displayNames: TrainerUiLocalization.startingPackLabels,\n',label='pack picker details')
t=rep(t,'                          moneyController: _moneyController,\n                          race: selectedOrigin == null\n','                          moneyController: _moneyController,\n                          ageController: _ageController,\n                          race: selectedOrigin == null\n',label='root age arg')
t=rep(t,"""                          raceDescription: selectedOrigin == null
                              ? ''
                              : _localizedOriginDescription(selectedOrigin),
                          selectedStarter: _selectedStarter,
""","""                          raceDescription: selectedOrigin == null
                              ? ''
                              : _localizedOriginDescription(selectedOrigin),
                          background: TrainerUiLocalization.backgroundName(
                            _background,
                          ),
                          backgroundDescription:
                              TrainerUiLocalization.backgroundDescription(
                                _background,
                              ),
                          selectedStarter: _selectedStarter,
""",label='root background args')
t=rep(t,'                          onRaceTap: _openRacePicker,\n                          onStarterTap: _openStarterPicker,\n','                          onRaceTap: _openRacePicker,\n                          onBackgroundTap: _openBackgroundPicker,\n                          onStarterTap: _openStarterPicker,\n',label='root background callback')
t=rep(t,'    required this.moneyController,\n    required this.race,\n    required this.raceDescription,\n    required this.selectedStarter,\n','    required this.moneyController,\n    required this.ageController,\n    required this.race,\n    required this.raceDescription,\n    required this.background,\n    required this.backgroundDescription,\n    required this.selectedStarter,\n',2,'constructors')
t=rep(t,'    required this.onRaceTap,\n    required this.onStarterTap,\n','    required this.onRaceTap,\n    required this.onBackgroundTap,\n    required this.onStarterTap,\n',2,'callbacks')
t=rep(t,'  final TextEditingController moneyController;\n  final String race;\n  final String raceDescription;\n  final Pokemon? selectedStarter;\n','  final TextEditingController moneyController;\n  final TextEditingController ageController;\n  final String race;\n  final String raceDescription;\n  final String background;\n  final String backgroundDescription;\n  final Pokemon? selectedStarter;\n',2,'fields')
t=rep(t,'  final VoidCallback onRaceTap;\n  final VoidCallback onStarterTap;\n','  final VoidCallback onRaceTap;\n  final VoidCallback onBackgroundTap;\n  final VoidCallback onStarterTap;\n',2,'callback fields')
t=rep(t,'        moneyController: moneyController,\n        race: race,\n        raceDescription: raceDescription,\n        selectedStarter: selectedStarter,\n','        moneyController: moneyController,\n        ageController: ageController,\n        race: race,\n        raceDescription: raceDescription,\n        background: background,\n        backgroundDescription: backgroundDescription,\n        selectedStarter: selectedStarter,\n',label='mobile args')
t=rep(t,'        onRaceTap: onRaceTap,\n        onStarterTap: onStarterTap,\n','        onRaceTap: onRaceTap,\n        onBackgroundTap: onBackgroundTap,\n        onStarterTap: onStarterTap,\n',label='mobile callback')
t=rep(t,'                      moneyController: moneyController,\n                      race: race,\n                      raceDescription: raceDescription,\n                      selectedStarter: selectedStarter,\n','                      moneyController: moneyController,\n                      ageController: ageController,\n                      race: race,\n                      raceDescription: raceDescription,\n                      background: background,\n                      backgroundDescription: backgroundDescription,\n                      selectedStarter: selectedStarter,\n',2,'desktop args')
t=rep(t,'                      onRaceTap: onRaceTap,\n                      onStarterTap: onStarterTap,\n','                      onRaceTap: onRaceTap,\n                      onBackgroundTap: onBackgroundTap,\n                      onStarterTap: onStarterTap,\n',2,'desktop callbacks')
t=rep(t,"            _SheetCounterBox(\n              label: context.uiText('Livello', 'Level'),\n","""            _SheetTextBox(
              label: context.uiText('Età', 'Age'),
              controller: ageController,
              width: 96,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
            _SheetCounterBox(
              label: context.uiText('Livello', 'Level'),
""",label='desktop age')
t=rep(t,"""        _SheetChoiceBox(
          label: context.uiText('Origine', 'Origin'),
          value: race.isEmpty ? context.uiText('Scegli', 'Choose') : race,
          detail: race.isEmpty
              ? context.uiText(
                  'Tocca per scegliere dal manuale',
                  'Tap to choose from the manual',
                )
              : raceDescription,
          detailMaxLines: null,
          onTap: onRaceTap,
        ),
        const SizedBox(height: 16),
""","""        _SheetChoiceBox(
          label: context.uiText('Origine', 'Origin'),
          value: race.isEmpty ? context.uiText('Scegli', 'Choose') : race,
          detail: race.isEmpty
              ? context.uiText(
                  'Tocca per scegliere dal manuale',
                  'Tap to choose from the manual',
                )
              : raceDescription,
          detailMaxLines: null,
          onTap: onRaceTap,
        ),
        const SizedBox(height: 8),
        _SheetChoiceBox(
          label: context.uiText('Background', 'Background'),
          value: background.isEmpty
              ? context.uiText('Scegli', 'Choose')
              : background,
          detail: background.isEmpty
              ? context.uiText(
                  'Scelta narrativa, senza bonus automatici alle caratteristiche.',
                  'Narrative choice, with no automatic ability-score bonuses.',
                )
              : backgroundDescription,
          detailMaxLines: null,
          onTap: onBackgroundTap,
        ),
        const SizedBox(height: 16),
""",label='desktop background')
t=rep(t,"""                  detail: context.uiText(
                    'Equipaggiamento iniziale dell’Allenatore.',
                    'The Trainer’s starting equipment.',
                  ),
""","""                  detail: startingPack.isEmpty
                      ? context.uiText(
                          'Scegli una delle tre dotazioni del manuale.',
                          'Choose one of the three packs from the manual.',
                        )
                      : TrainerUiLocalization.startingPackDescription(
                          startingPack,
                        ),
""",label='desktop pack details')
p.write_text(t,encoding='utf-8')

Path('test/trainer_manual_identity_fields_test.dart').write_text("""import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/trainer_manual_options.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';

void main() {
  test('manual trainer fields expose descriptions', () {
    expect(TrainerManualOptions.startingPacks, hasLength(3));
    for (final value in TrainerManualOptions.startingPacks) {
      expect(TrainerUiLocalization.startingPackDescriptions[value], isNotEmpty);
    }
    expect(TrainerUiLocalization.backgroundOptions, hasLength(6));
    for (final value in TrainerUiLocalization.backgroundOptions) {
      expect(TrainerUiLocalization.backgroundLabels[value], isNotEmpty);
      expect(TrainerUiLocalization.backgroundDescriptions[value], isNotEmpty);
    }
  });
}
""",encoding='utf-8')
