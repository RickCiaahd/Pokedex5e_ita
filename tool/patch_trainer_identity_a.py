from pathlib import Path

def rep(t, old, new, n=1, label='replace'):
    c=t.count(old)
    if c!=n: raise RuntimeError(f'{label}: expected {n}, found {c}')
    return t.replace(old,new,n)

p=Path('lib/screens/onboarding/first_launch_onboarding_screen.dart'); t=p.read_text(encoding='utf-8')
t=rep(t,"import 'package:flutter/material.dart';\n","import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",label='services')
t=rep(t,'  int _age = 16;\n  bool _isLoading = true;\n','  int _age = 16;\n  bool _ageInputIsValid = true;\n  bool _isLoading = true;\n',label='age state')
t=rep(t,'      case 2:\n        return _nameController.text.trim().isNotEmpty;\n      case 5:\n','      case 2:\n        return _nameController.text.trim().isNotEmpty;\n      case 4:\n        return _ageInputIsValid;\n      case 5:\n',label='age guard')
t=rep(t,"""          content: _AgeSelector(
            age: _age,
            onDecrease: _age > 6 ? () => setState(() => _age--) : null,
            onIncrease: _age < 99 ? () => setState(() => _age++) : null,
          ),
""","""          content: _AgeSelector(
            age: _age,
            isValid: _ageInputIsValid,
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              setState(() {
                _ageInputIsValid = parsed != null && parsed >= 6 && parsed <= 99;
                if (_ageInputIsValid) _age = parsed!;
              });
            },
          ),
""",label='age call')
start=t.index('class _AgeSelector extends StatelessWidget {'); end=t.index('\nclass _InfoBanner',start)
t=t[:start]+"""class _AgeSelector extends StatelessWidget {
  const _AgeSelector({required this.age, required this.isValid, required this.onChanged});
  final int age;
  final bool isValid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$age',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      decoration: InputDecoration(
        labelText: context.uiText('Età dell’Allenatore', 'Trainer age'),
        helperText: context.uiText('Scrivi un valore da 6 a 99.', 'Enter a value from 6 to 99.'),
        errorText: isValid ? null : context.uiText('Inserisci un’età valida da 6 a 99.', 'Enter a valid age from 6 to 99.'),
        prefixIcon: const Icon(Icons.cake_outlined),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
"""+t[end:]
p.write_text(t,encoding='utf-8')

p=Path('lib/models/trainer_ui_localization.dart'); t=p.read_text(encoding='utf-8')
anchor='''  static const Map<String, String> _startingPackLabelsIt = {
    "Dungeoneer's pack": 'Dotazione da Avventuriero',
    "Explorer's pack": 'Dotazione da Esploratore',
    "Filcher's pack": 'Dotazione da Borseggiatore',
  };
'''
extra=anchor+'''\n  static const Map<String, String> _startingPackDescriptionsIt = {
    "Dungeoneer's pack": 'Contiene: zaino, kit da scalatore, torcia, 5 celle energetiche, acciarino e pietra focaia, 10 razioni da campeggio, borraccia e 30 piedi di corda.',
    "Explorer's pack": 'Contiene: zaino, sacco a pelo, gavetta, acciarino e pietra focaia, torcia, 5 celle energetiche, 10 razioni da campeggio, borraccia e 30 piedi di corda.',
    "Filcher's pack": 'Contiene: zaino, arnesi da scasso, 20 piedi di filo, campanella, lanterna, 3 celle energetiche, 5 razioni da campeggio, acciarino e pietra focaia e borraccia.',
  };
  static const Map<String, String> _startingPackDescriptionsEn = {
    "Dungeoneer's pack": "Contains a backpack, climber's kit, flashlight, 5 energy cells, flint and steel, 10 camping rations, a canteen, and 30 feet of rope.",
    "Explorer's pack": 'Contains a backpack, sleeping bag, mess kit, flint and steel, flashlight, 5 energy cells, 10 camping rations, a canteen, and 30 feet of rope.',
    "Filcher's pack": "Contains a backpack, thieves' tools, 20 feet of wire, a bell, a lantern, 3 energy cells, 5 camping rations, flint and steel, and a canteen.",
  };
  static const List<String> backgroundOptions = ['Ricercatore', 'Esploratore', 'Allevatore', 'Combattente', 'Artista', 'Studioso'];
  static const Map<String, String> _backgroundLabelsIt = {
    'Ricercatore': 'Ricercatore', 'Esploratore': 'Esploratore', 'Allevatore': 'Allevatore',
    'Combattente': 'Combattente', 'Artista': 'Artista', 'Studioso': 'Studioso',
  };
  static const Map<String, String> _backgroundLabelsEn = {
    'Ricercatore': 'Researcher', 'Esploratore': 'Explorer', 'Allevatore': 'Breeder',
    'Combattente': 'Fighter', 'Artista': 'Artist', 'Studioso': 'Scholar',
  };
  static const Map<String, String> _backgroundDescriptionsIt = {
    'Ricercatore': 'Osservi, cataloghi e studi ogni scoperta prima di trarre conclusioni. Scelta narrativa: non modifica automaticamente le caratteristiche.',
    'Esploratore': 'Ti senti a casa sulle strade meno battute e negli ambienti selvaggi. Scelta narrativa: non modifica automaticamente le caratteristiche.',
    'Allevatore': 'Conosci le necessità delle creature e costruisci legami pazienti. Scelta narrativa: non modifica automaticamente le caratteristiche.',
    'Combattente': 'Affronti le difficoltà con disciplina, coraggio e spirito competitivo. Scelta narrativa: non modifica automaticamente le caratteristiche.',
    'Artista': 'Esprimi te stesso attraverso spettacolo, creatività e sensibilità. Scelta narrativa: non modifica automaticamente le caratteristiche.',
    'Studioso': 'Hai dedicato anni a libri, tradizioni e conoscenze specialistiche. Scelta narrativa: non modifica automaticamente le caratteristiche.',
  };
  static const Map<String, String> _backgroundDescriptionsEn = {
    'Ricercatore': 'You observe, catalogue and study every discovery before drawing conclusions. Narrative choice: it does not automatically change ability scores.',
    'Esploratore': 'You feel at home on less-travelled roads and in the wilderness. Narrative choice: it does not automatically change ability scores.',
    'Allevatore': 'You understand the needs of creatures and build patient bonds. Narrative choice: it does not automatically change ability scores.',
    'Combattente': 'You face challenges with discipline, courage and a competitive spirit. Narrative choice: it does not automatically change ability scores.',
    'Artista': 'You express yourself through performance, creativity and sensitivity. Narrative choice: it does not automatically change ability scores.',
    'Studioso': 'You have devoted years to books, traditions and specialist knowledge. Narrative choice: it does not automatically change ability scores.',
  };
'''
t=rep(t,anchor,extra,label='manual maps')
t=rep(t,'  static Map<String, String> get startingPackLabels =>\n      _localizedMap(_startingPackLabelsIt);\n','''  static Map<String, String> get startingPackLabels => _localizedMap(_startingPackLabelsIt);
  static Map<String, String> get startingPackDescriptions => _isItalian ? _startingPackDescriptionsIt : _startingPackDescriptionsEn;
  static Map<String, String> get backgroundLabels => _isItalian ? _backgroundLabelsIt : _backgroundLabelsEn;
  static Map<String, String> get backgroundDescriptions => _isItalian ? _backgroundDescriptionsIt : _backgroundDescriptionsEn;
''',label='manual getters')
t=rep(t,"  static String startingPackName(String value) =>\n      _isItalian ? (_startingPackLabelsIt[value] ?? value) : value;\n","""  static String startingPackName(String value) => _isItalian ? (_startingPackLabelsIt[value] ?? value) : value;
  static String startingPackDescription(String value) => startingPackDescriptions[value] ?? '';
  static String backgroundName(String value) => backgroundLabels[value] ?? value;
  static String backgroundDescription(String value) => backgroundDescriptions[value] ?? '';
""",label='manual methods')
p.write_text(t,encoding='utf-8')
