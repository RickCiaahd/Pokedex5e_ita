from pathlib import Path

def rep(t, old, new, n=1, label='replace'):
    c=t.count(old)
    if c!=n: raise RuntimeError(f'{label}: expected {n}, found {c}')
    return t.replace(old,new,n)

p=Path('lib/screens/trainer/trainer_sheet_mobile.dart'); t=p.read_text(encoding='utf-8')
old='    required this.moneyController,\n    required this.race,\n    required this.raceDescription,\n    required this.selectedStarter,\n'
new='    required this.moneyController,\n    required this.ageController,\n    required this.race,\n    required this.raceDescription,\n    required this.background,\n    required this.backgroundDescription,\n    required this.selectedStarter,\n'
t=rep(t,old,new,2,'constructors')
t=rep(t,'    required this.onRaceTap,\n    required this.onStarterTap,\n','    required this.onRaceTap,\n    required this.onBackgroundTap,\n    required this.onStarterTap,\n',2,'callbacks')
t=rep(t,'  final TextEditingController moneyController;\n  final String race;\n  final String raceDescription;\n  final Pokemon? selectedStarter;\n','  final TextEditingController moneyController;\n  final TextEditingController ageController;\n  final String race;\n  final String raceDescription;\n  final String background;\n  final String backgroundDescription;\n  final Pokemon? selectedStarter;\n',2,'fields')
t=rep(t,'  final VoidCallback onRaceTap;\n  final VoidCallback onStarterTap;\n','  final VoidCallback onRaceTap;\n  final VoidCallback onBackgroundTap;\n  final VoidCallback onStarterTap;\n',2,'callback fields')
t=rep(t,'                  moneyController: widget.moneyController,\n                  race: widget.race,\n                  raceDescription: widget.raceDescription,\n                  selectedStarter: widget.selectedStarter,\n','                  moneyController: widget.moneyController,\n                  ageController: widget.ageController,\n                  race: widget.race,\n                  raceDescription: widget.raceDescription,\n                  background: widget.background,\n                  backgroundDescription: widget.backgroundDescription,\n                  selectedStarter: widget.selectedStarter,\n',label='overview args')
t=rep(t,'                  onRaceTap: widget.onRaceTap,\n                  onStarterTap: widget.onStarterTap,\n','                  onRaceTap: widget.onRaceTap,\n                  onBackgroundTap: widget.onBackgroundTap,\n                  onStarterTap: widget.onStarterTap,\n',label='overview callback')
money='''        TextField(
          controller: moneyController,
          enabled: !isSaving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: context.uiText('Pokédollars', 'Pokédollars'),
            prefixText: '₽ ',
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
'''
age='''        Row(
          children: [
            Expanded(
              child: TextField(
                controller: moneyController,
                enabled: !isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.uiText('Pokédollars', 'Pokédollars'),
                  prefixText: '₽ ',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: TextField(
                controller: ageController,
                enabled: !isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: context.uiText('Età', 'Age'),
                  prefixIcon: const Icon(Icons.cake_outlined, size: 19),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
'''
t=rep(t,money,age,label='age row')
t=rep(t,"""              : _compactOriginDetail(raceDescription),
          onTap: onRaceTap,
        ),
        const SizedBox(height: 12),
        _MobileSectionTitle(title: context.uiText('COMBATTIMENTO', 'COMBAT')),
""","""              : _compactDetail(raceDescription),
          onTap: onRaceTap,
        ),
        const SizedBox(height: 8),
        _CompactChoiceCard(
          icon: Icons.auto_stories_outlined,
          label: context.uiText('BACKGROUND', 'BACKGROUND'),
          value: background.isEmpty
              ? context.uiText('Scegli', 'Choose')
              : background,
          detail: background.isEmpty
              ? context.uiText(
                  'Scelta narrativa, senza bonus automatici alle caratteristiche.',
                  'Narrative choice, with no automatic ability-score bonuses.',
                )
              : _compactDetail(backgroundDescription),
          onTap: onBackgroundTap,
        ),
        const SizedBox(height: 12),
        _MobileSectionTitle(title: context.uiText('COMBATTIMENTO', 'COMBAT')),
""",label='background card')
t=rep(t,"""          value: startingPack.isEmpty
              ? context.uiText('Scegli', 'Choose')
              : TrainerUiLocalization.startingPackName(startingPack),
          onTap: onStartingPackTap,
""","""          value: startingPack.isEmpty
              ? context.uiText('Scegli', 'Choose')
              : TrainerUiLocalization.startingPackName(startingPack),
          detail: startingPack.isEmpty
              ? context.uiText(
                  'Scegli una delle tre dotazioni del manuale.',
                  'Choose one of the three packs from the manual.',
                )
              : TrainerUiLocalization.startingPackDescription(startingPack),
          onTap: onStartingPackTap,
""",label='pack details')
t=rep(t,'  String _compactOriginDetail(String description) {\n','  String _compactDetail(String description) {\n',label='detail helper')
p.write_text(t,encoding='utf-8')
