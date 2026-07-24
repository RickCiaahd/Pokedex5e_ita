from __future__ import annotations

import re
from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'Frammento non trovato: {label}')
    return text.replace(old, new, 1)


def add_import(text: str, anchor: str, import_line: str) -> str:
    if import_line in text:
        return text
    return replace_once(text, anchor, anchor + import_line, import_line)


def dq(value: str) -> str:
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'") + "'"


def localize_literals(text: str, pairs: list[tuple[str, str]]) -> str:
    for italian, english in pairs:
        source = dq(italian)
        target = f'context.uiText({dq(italian)}, {dq(english)})'
        if source not in text:
            raise RuntimeError(f'Stringa UI non trovata: {italian}')
        text = text.replace(source, target)
    text = text.replace('const Text(', 'Text(')
    text = text.replace('const SnackBar(', 'SnackBar(')
    return text


# ---------------------------------------------------------------------------
# TrainerUiLocalization: i valori tecnici restano inglesi, la resa italiana
# viene applicata soltanto quando la lingua effettiva dell'app è "it".
# ---------------------------------------------------------------------------
path = 'lib/models/trainer_ui_localization.dart'
text = read(path)
text = add_import(
    text,
    "class TrainerUiLocalization {\n",
    "import '../localization/game_catalog_locale.dart';\n\n",
)
for public_name in (
    'abilityLabels',
    'skillLabels',
    'startingPackLabels',
    'natureLabels',
    'sizeLabels',
    'genderLabels',
    'specializationLabels',
    'trainerPathLabels',
    'featureLabels',
):
    text = replace_once(
        text,
        f'static const Map<String, String> {public_name} = {{',
        f'static const Map<String, String> _{public_name}It = {{',
        f'rinomina {public_name}',
    )

new_tail = r'''  static bool get _isItalian => GameCatalogLocale.isItalian;

  static Map<String, String> _localizedMap(
    Map<String, String> italian,
  ) {
    if (_isItalian) return italian;
    return {for (final key in italian.keys) key: key};
  }

  static Map<String, String> get abilityLabels =>
      _localizedMap(_abilityLabelsIt);
  static Map<String, String> get skillLabels => _localizedMap(_skillLabelsIt);
  static Map<String, String> get startingPackLabels =>
      _localizedMap(_startingPackLabelsIt);
  static Map<String, String> get natureLabels => _localizedMap(_natureLabelsIt);
  static Map<String, String> get sizeLabels => _localizedMap(_sizeLabelsIt);
  static Map<String, String> get genderLabels => _localizedMap(_genderLabelsIt);
  static Map<String, String> get specializationLabels =>
      _localizedMap(_specializationLabelsIt);
  static Map<String, String> get trainerPathLabels =>
      _localizedMap(_trainerPathLabelsIt);
  static Map<String, String> get featureLabels =>
      _localizedMap(_featureLabelsIt);

  static String abilityAbbreviation(String value) {
    final normalized = value.trim().toUpperCase();
    return _isItalian ? (_abilityLabelsIt[normalized] ?? value) : normalized;
  }

  static String skillName(String value) =>
      _isItalian ? (_skillLabelsIt[value] ?? value) : value;

  static String startingPackName(String value) =>
      _isItalian ? (_startingPackLabelsIt[value] ?? value) : value;

  static String natureName(String value) =>
      _isItalian ? (_natureLabelsIt[value] ?? value) : value;

  static String sizeName(String value) =>
      _isItalian ? (_sizeLabelsIt[value] ?? value) : value;

  static String genderName(String value) =>
      _isItalian ? (_genderLabelsIt[value] ?? value) : value;

  static String specializationName(String value) =>
      _isItalian ? (_specializationLabelsIt[value] ?? value) : value;

  static String trainerPathName(String value) =>
      _isItalian ? (_trainerPathLabelsIt[value] ?? value) : value;

  static String featureName(String value) {
    if (!_isItalian) return value;
    return _featureLabelsIt[value] ?? trainerPathName(value);
  }

  static String optionLabel(String value) {
    if (!_isItalian) return value;
    final parts = value.split(' · ');
    if (parts.length == 3 && parts[1].startsWith('Lv ')) {
      return '${trainerPathName(parts[0])} · Liv. ${parts[1].substring(3)} · ${featureName(parts[2])}';
    }
    final ability = _abilityLabelsIt[value.toUpperCase()];
    if (ability != null) return ability;
    final specialization = _specializationLabelsIt[value];
    if (specialization != null) return specialization;
    return visibleText(value);
  }

  static String visibleText(String value) {
    if (!_isItalian) return value;
    final exactFeature = _featureLabelsIt[value];
    if (exactFeature != null) return exactFeature;
    final exactPath = _trainerPathLabelsIt[value];
    if (exactPath != null) return exactPath;

    var result = value;
    const phraseReplacements = <String, String>{
      'Trainer Path': 'Percorso Allenatore',
      'Shadow Points': 'Punti Ombra',
      'Tactical Points': 'Punti Tattici',
      'Ability Score Improvement': 'Aumento di Caratteristica',
      'Control Upgrade': 'Aumento del Controllo',
      'Master Trainer': 'Maestro Allenatore',
      "Trainer's Resolve": "Determinazione dell'Allenatore",
      'Pokémon Tracker': 'Ricercatore Pokémon',
      'Additional Feats': 'Talenti Aggiuntivi',
      'Egg Moves': 'Mosse Uovo',
      'Egg Move': 'Mossa Uovo',
      'Speak with Animals': 'Parlare con gli Animali',
      'Copy Meowth': 'Copia Meowth',
      'livello trainer': "livello dell'Allenatore",
      'level up': 'aumento di livello',
      'stat block': 'blocco statistiche',
      'Pokecenter': 'Centro Pokémon',
      'Pokemon': 'Pokémon',
      'Loyalty': 'Lealtà',
      'Loyal': 'Leale',
      'Disloyal': 'Sleale',
      'Indifferent': 'Indifferente',
      'Feature': 'Privilegio',
      'feature': 'privilegio',
      'Path': 'Percorso',
      'path': 'percorso',
      'DM': 'Master',
      'pool': 'elenco',
      'item': 'oggetto',
      'tier': 'grado',
      'treat': 'leccornia',
    };
    for (final entry in phraseReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    for (final entry in _skillLabelsIt.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    for (final entry in _abilityLabelsIt.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b'),
        entry.value,
      );
    }
    result = result.replaceAllMapped(
      RegExp(r'\b(\d+)\s*ft\b', caseSensitive: false),
      (match) => '${match.group(1)} piedi',
    );
    return result;
  }
'''
text, count = re.subn(
    r'  static String abilityAbbreviation\(String value\) \{.*?\n  \}\n\}',
    new_tail + '}',
    text,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise RuntimeError('Coda TrainerUiLocalization non sostituita')
write(path, text)


# ---------------------------------------------------------------------------
# Badge dei tipi: in inglese usa il badge testuale, perché gli asset con il
# nome incorporato sono italiani.
# ---------------------------------------------------------------------------
path = 'lib/widgets/pokemon/pokemon_asset_image_legacy.dart'
text = read(path)
text = add_import(
    text,
    "import '../../models/pokedex_entry.dart';\n",
    "import '../../localization/game_catalog_locale.dart';\n",
)
new_type_block = r'''  static List<String> typeCandidates(String type) {
    if (!GameCatalogLocale.isItalian) return const [];
    final localized = localizedTypeLabel(type);
    final assetName = _assetName(localized);
    final lowercaseAssetName = assetName.toLowerCase();

    return [
      'assets/textures/type_names/$lowercaseAssetName.png',
      if (assetName != lowercaseAssetName)
        'assets/textures/type_names/$assetName.png',
    ];
  }

  static String localizedTypeLabel(String type) {
    final normalized = type.trim().toLowerCase();
    if (!GameCatalogLocale.isItalian) {
      switch (normalized) {
        case 'coleottero':
        case 'bug':
          return 'Bug';
        case 'buio':
        case 'dark':
          return 'Dark';
        case 'drago':
        case 'dragon':
          return 'Dragon';
        case 'elettro':
        case 'electric':
          return 'Electric';
        case 'folletto':
        case 'fairy':
          return 'Fairy';
        case 'lotta':
        case 'fighting':
          return 'Fighting';
        case 'fuoco':
        case 'fire':
          return 'Fire';
        case 'volante':
        case 'flying':
          return 'Flying';
        case 'spettro':
        case 'ghost':
          return 'Ghost';
        case 'erba':
        case 'grass':
          return 'Grass';
        case 'terra':
        case 'ground':
          return 'Ground';
        case 'ghiaccio':
        case 'ice':
          return 'Ice';
        case 'normale':
        case 'normal':
          return 'Normal';
        case 'veleno':
        case 'poison':
          return 'Poison';
        case 'psico':
        case 'psychic':
          return 'Psychic';
        case 'roccia':
        case 'rock':
          return 'Rock';
        case 'acciaio':
        case 'steel':
          return 'Steel';
        case 'acqua':
        case 'water':
          return 'Water';
        default:
          return type;
      }
    }

    switch (normalized) {
      case 'bug':
      case 'coleottero':
        return 'Coleottero';
      case 'dark':
      case 'buio':
        return 'Buio';
      case 'dragon':
      case 'drago':
        return 'Drago';
      case 'electric':
      case 'elettro':
        return 'Elettro';
      case 'fairy':
      case 'folletto':
        return 'Folletto';
      case 'fighting':
      case 'lotta':
        return 'Lotta';
      case 'fire':
      case 'fuoco':
        return 'Fuoco';
      case 'flying':
      case 'volante':
        return 'Volante';
      case 'ghost':
      case 'spettro':
        return 'Spettro';
      case 'grass':
      case 'erba':
        return 'Erba';
      case 'ground':
      case 'terra':
        return 'Terra';
      case 'ice':
      case 'ghiaccio':
        return 'Ghiaccio';
      case 'normal':
      case 'normale':
        return 'Normale';
      case 'poison':
      case 'veleno':
        return 'Veleno';
      case 'psychic':
      case 'psico':
        return 'Psico';
      case 'rock':
      case 'roccia':
        return 'Roccia';
      case 'steel':
      case 'acciaio':
        return 'Acciaio';
      case 'water':
      case 'acqua':
        return 'Acqua';
      default:
        return type;
    }
  }

'''
text, count = re.subn(
    r'  static List<String> typeCandidates\(String type\) \{.*?\n  static PokemonFormChoice\? _formChoiceFromAssetPath',
    new_type_block + '  static PokemonFormChoice? _formChoiceFromAssetPath',
    text,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise RuntimeError('Blocco tipi non sostituito')
write(path, text)


# ---------------------------------------------------------------------------
# Riepilogo Pokédex.
# ---------------------------------------------------------------------------
path = 'lib/widgets/pokedex/pokemon_summary_dialog.dart'
text = read(path)
text = add_import(
    text,
    "import '../../models/pokedex_entry.dart';\n",
    "import '../../localization/ui_text.dart';\n",
)
text = replace_once(
    text,
    "  String get _selectedLabel => _selectedFormName ?? 'Base';",
    "  String _selectedLabel(BuildContext context) =>\n      _selectedFormName ?? context.uiText('Base', 'Base');",
    'etichetta forma base',
)
text = text.replace('_selectedLabel.toUpperCase()', '_selectedLabel(context).toUpperCase()')
text = replace_once(
    text,
    "                    'Altezza: ${heightMeters.toStringAsFixed(1)} m · '\n                    'Peso: ${weightKg.toStringAsFixed(1)} kg',",
    "                    context.uiText(\n                      'Altezza: ${heightMeters.toStringAsFixed(1)} m · Peso: ${weightKg.toStringAsFixed(1)} kg',\n                      'Height: ${heightMeters.toStringAsFixed(1)} m · Weight: ${weightKg.toStringAsFixed(1)} kg',\n                    ),",
    'altezza e peso',
)
text = localize_literals(
    text,
    [
        ('Forma non ancora vista.', 'Form not seen yet.'),
        ('Non visto', 'Mark unseen'),
        ('Visto', 'Mark seen'),
        ('Non catturato', 'Mark uncaught'),
        ('Catturato', 'Mark caught'),
        ('Scheda', 'Sheet'),
        ('CA', 'AC'),
        ('PF', 'HP'),
        ('FOR', 'STR'),
        ('DES', 'DEX'),
        ('COS', 'CON'),
        ('SAG', 'WIS'),
        ('CAR', 'CHA'),
    ],
)
text = replace_once(
    text,
    "    final label = formName ?? 'Base';",
    "    final label = formName ?? context.uiText('Base', 'Base');",
    'base form card',
)
write(path, text)


# ---------------------------------------------------------------------------
# Battle Companion: tour e comandi principali.
# ---------------------------------------------------------------------------
path = 'lib/screens/battle/battle_screen.dart'
text = read(path)
text = add_import(
    text,
    "import '../../models/bag_inventory_entry.dart';\n",
    "import '../../localization/ui_text.dart';\n",
)
text = localize_literals(
    text,
    [
        ('Squadra e round', 'Team and round'),
        ('In alto controlli il round, termini la battaglia e scegli quale Pokémon della squadra è attivo. La sessione viene conservata finché non la chiudi.', 'At the top you control the round, end the battle and choose the active Pokémon. The session is preserved until you close it.'),
        ('Iniziativa e turni', 'Initiative and turns'),
        ('Aggiungi partecipanti, modifica l’ordine e usa il comando del turno successivo. Quando il giro termina, il round avanza automaticamente.', 'Add participants, change the order and use the next-turn command. When the cycle ends, the round advances automatically.'),
        ('Meteo e terreno', 'Weather and terrain'),
        ('L’ambiente applica regole e modificatori a velocità, CA, tipi e danni. Puoi impostarlo manualmente o generare il meteo con il d100.', 'The environment applies rules and modifiers to speed, AC, types and damage. Set it manually or roll weather with a d100.'),
        ('Pokémon attivo', 'Active Pokémon'),
        ('Qui gestisci PF, PF temporanei, status, forma di battaglia, oggetto tenuto e Zaino rapido del Pokémon selezionato.', 'Manage HP, temporary HP, conditions, battle form, held item and the selected Pokémon’s quick Bag.'),
        ('Mosse e PP', 'Moves and PP'),
        ('Le mosse mostrano tiro, CD, danni e PP rimanenti. Usa e ripristina i PP dai pulsanti; quando finiscono, il tracker segnala Struggle.', 'Moves show rolls, DC, damage and remaining PP. Spend or restore PP with the buttons; when all are depleted, the tracker warns you to use Struggle.'),
        ('Errore caricando il combattimento', 'Error loading battle'),
        ('Nessun Pokémon in squadra', 'No Pokémon in the team'),
        ('Aggiungi almeno un Pokémon alla squadra prima di aprire il tracker.', 'Add at least one Pokémon to the team before opening the tracker.'),
        ('MOSSE DA COMBATTIMENTO', 'BATTLE MOVES'),
        ('Termina battaglia', 'End battle'),
        ('Nessun turno impostato.', 'No turn is set.'),
        ('PROSSIMO TURNO', 'NEXT TURN'),
        ('Allenatore + Pokémon', 'Trainer + Pokémon'),
        ('Aggiungi iniziativa', 'Add initiative'),
        ('Nome partecipante', 'Participant name'),
        ('Cambia forma in battaglia', 'Change battle form'),
        ('CAMBIA FORMA', 'CHANGE FORM'),
        ('STATUS: nessuno', 'CONDITIONS: none'),
        ('STATUS IN COMBATTIMENTO', 'BATTLE CONDITIONS'),
        ('Tocca uno status per applicarlo subito. Un solo status non-volatile alla volta; gli status volatili terminano fuori dal combattimento.', 'Tap a condition to apply it immediately. Only one non-volatile condition can be active at a time; volatile conditions end outside battle.'),
        ('RIMUOVI TUTTI', 'REMOVE ALL'),
        ('Apri lo zaino rapido per usare un consumabile o lanciare una Poké Ball.', 'Open the quick Bag to use a consumable or throw a Poké Ball.'),
        ('Bacca tenuta: puoi consumarla subito in combattimento.', 'Held Berry: you can consume it immediately in battle.'),
        ('nessuno status', 'no conditions'),
        ('Zaino rapido', 'Quick Bag'),
        ('Recupera PP', 'Restore PP'),
        ('Usa mossa', 'Use move'),
        ('Dettagli mossa non disponibili.', 'Move details are unavailable.'),
        ('Modifica HP', 'Change HP'),
        ('HP o modifica', 'HP or change'),
        ('Tutti i PP delle mosse tracciabili sono a zero. Usa Struggle.', 'All tracked move PP are at zero. Use Struggle.'),
    ],
)
text = replace_once(
    text,
    "                  ? 'Nessun turno impostato.'\n                  : 'Turno: ${currentEntry.name}',",
    "                  ? context.uiText('Nessun turno impostato.', 'No turn is set.')\n                  : context.uiText(\n                      'Turno: ${currentEntry.name}',\n                      'Turn: ${currentEntry.name}',\n                    ),",
    'turno corrente',
)
text = replace_once(
    text,
    "              'Ordine e comandi (${entries.length})',",
    "              context.uiText(\n                'Ordine e comandi (${entries.length})',\n                'Order and commands (${entries.length})',\n              ),",
    'ordine iniziativa',
)
write(path, text)


# ---------------------------------------------------------------------------
# Scheda Allenatore: tour, macro-sezioni e contenuti tecnici localizzati.
# ---------------------------------------------------------------------------
path = 'lib/screens/trainer/trainer_sheet_screen.dart'
text = read(path)
text = add_import(
    text,
    "import '../../models/evolution_data.dart';\n",
    "import '../../l10n/app_localizations.dart';\nimport '../../localization/ui_text.dart';\n",
)
origin_methods = r'''  String _localizedOriginName(TrainerOrigin origin) {
    final l10n = AppLocalizations.of(context);
    return origin.name == 'Origine 5e approvata dal DM'
        ? l10n.onboardingOriginDmApprovedName
        : origin.name;
  }

  String _localizedOriginDescription(TrainerOrigin origin) {
    final l10n = AppLocalizations.of(context);
    return switch (origin.name) {
      'Alolan' => l10n.onboardingOriginAlolanDescription,
      'Hoennian' => l10n.onboardingOriginHoennianDescription,
      'Johtoan' => l10n.onboardingOriginJohtoanDescription,
      'Kalosian' => l10n.onboardingOriginKalosianDescription,
      'Kantoan' => l10n.onboardingOriginKantoanDescription,
      'Sinnoan' => l10n.onboardingOriginSinnoanDescription,
      'Unovan' => l10n.onboardingOriginUnovanDescription,
      'Galarian' => l10n.onboardingOriginGalarianDescription,
      'Origine 5e approvata dal DM' =>
        l10n.onboardingOriginDmApprovedDescription,
      _ => TrainerUiLocalization.visibleText(origin.description),
    };
  }

  Map<String, String> get _originDisplayNames => {
    for (final origin in _trainerOrigins)
      origin.name: _localizedOriginName(origin),
  };

'''
text = replace_once(
    text,
    "  Map<String, int> _originAbilityBonuses(String name) {\n",
    origin_methods + "  Map<String, int> _originAbilityBonuses(String name) {\n",
    'metodi origine localizzata',
)
text = replace_once(
    text,
    "        origin.name: TrainerUiLocalization.visibleText(origin.description),",
    "        origin.name: _localizedOriginDescription(origin),",
    'descrizioni origine',
)
text = replace_once(
    text,
    "        options: [for (final origin in _trainerOrigins) origin.name],\n        selected: _raceController.text.trim(),\n        descriptions: _originDescriptions,",
    "        options: [for (final origin in _trainerOrigins) origin.name],\n        selected: _raceController.text.trim(),\n        descriptions: _originDescriptions,\n        displayNames: _originDisplayNames,",
    'picker origine',
)
text = replace_once(
    text,
    "                              )?.description ??\n                              '',",
    "                              ) == null\n                          ? ''\n                          : _localizedOriginDescription(\n                              _originByName(_raceController.text.trim())!,\n                            ),",
    'descrizione origine scheda',
)
text = localize_literals(
    text,
    [
        ('La scheda interattiva', 'The interactive sheet'),
        ('Qui aggiorni nome, livello, denaro, origine, starter, caratteristiche, PF, CA, velocità, competenze e tiri salvezza. I riquadri modificabili reagiscono al tocco.', 'Update name, level, money, origin, starter, ability scores, HP, AC, speed, proficiencies and saving throws. Editable panels respond to taps.'),
        ('Avanzamento e percorso', 'Progression and path'),
        ('La colonna Avanzamento mostra specializzazioni, Percorso Allenatore e privilegi sbloccati ai livelli corretti. Le scelte disponibili cambiano con il livello.', 'The Progression column shows specializations, Trainer Path and features unlocked at the appropriate levels. Available choices change with level.'),
        ('Risorse del percorso', 'Path resources'),
        ('Qui gestisci soltanto le scelte e le risorse già sbloccate dal tuo Percorso Allenatore, compresi i recuperi con riposo breve o lungo.', 'Manage only choices and resources already unlocked by your Trainer Path, including short- and long-rest recovery.'),
        ('Inserisci un nome allenatore.', 'Enter a Trainer name.'),
        ('Inserisci una quantita di soldi valida.', 'Enter a valid amount of money.'),
        ('Scheda allenatore aggiornata.', 'Trainer sheet updated.'),
        ('Origine', 'Origin'),
        ('Dotazione iniziale', 'Starting pack'),
        ('Percorso Allenatore', 'Trainer Path'),
        ('Cambiare Percorso Allenatore?', 'Change Trainer Path?'),
        ('ANNULLA', 'CANCEL'),
        ('CAMBIA PERCORSO', 'CHANGE PATH'),
        ('Specializzazione', 'Specialization'),
        ('Scheda Allenatore', 'Trainer Sheet'),
        ('Pokéslot', 'Poké Slots'),
        ('Slot squadra', 'Team slots'),
        ('SR max', 'Max SR'),
        ('Pokédollars', 'Pokédollars'),
        ('PF attuali', 'Current HP'),
        ('PF max', 'Max HP'),
        ('Velocità', 'Speed'),
        ('Equipaggiamento iniziale dell’Allenatore.', 'The Trainer’s starting equipment.'),
        ('Prossimi avanzamenti', 'Next progression milestones'),
        ('Salva scheda', 'Save sheet'),
        ('ABILITÀ', 'SKILLS'),
        ('TIRI SALVEZZA', 'SAVING THROWS'),
        ('Competenze selezionate', 'Selected proficiencies'),
        ('Spunta le competenze nella sezione Abilità.', 'Select proficiencies in the Skills section.'),
        ('Privilegio del Percorso', 'Path Feature'),
        ('Scegli il percorso al livello 2 per vedere il privilegio automatico.', 'Choose a path at level 2 to see its automatic feature.'),
        ('Starter Pokémon', 'Starter Pokémon'),
        ('Starter gia presente in squadra.', 'Starter already in the team.'),
        ('Aggiungi alla squadra', 'Add to team'),
        ('Cerca per nome, numero o tipo...', 'Search by name, number or type...'),
    ],
)
text = replace_once(
    text,
    "      SnackBar(content: Text('${starter.name} aggiunto alla squadra.')),",
    "      SnackBar(\n        content: Text(\n          context.uiText(\n            '${starter.name} aggiunto alla squadra.',\n            '${starter.name} added to the team.',\n          ),\n        ),\n      ),",
    'starter aggiunto',
)
write(path, text)


# ---------------------------------------------------------------------------
# Strumenti del Master: intera schermata e tour.
# ---------------------------------------------------------------------------
path = 'lib/screens/tools/tools_screen.dart'
text = read(path)
text = add_import(
    text,
    "import '../../models/pokemon.dart';\n",
    "import '../../localization/ui_text.dart';\n",
)
text = text.replace('const _ToolSectionTitle(', '_ToolSectionTitle(')
text = localize_literals(
    text,
    [
        ('Il centro di comando', 'The command center'),
        ('Questa schermata separa la preparazione della sessione dalle librerie e dal Fight del Master. Ogni blocco raccoglie strumenti con uno scopo preciso.', 'This screen separates session preparation from libraries and the GM Fight. Each section groups tools with a specific purpose.'),
        ('Generatori', 'Generators'),
        ('Qui crei Pokémon, incontri e Allenatori PNG. I risultati possono essere usati subito oppure salvati per una sessione futura.', 'Create Pokémon, encounters and NPC Trainers. Results can be used immediately or saved for a future session.'),
        ('Librerie e Fight', 'Libraries and Fight'),
        ('Le librerie riaprono i contenuti salvati e permettono di portarli nel Fight del Master, che conserva PF, PP, status, iniziativa e round.', 'Libraries reopen saved content and send it to the GM Fight, which preserves HP, PP, conditions, initiative and rounds.'),
        ('Strumenti del Master', 'GM Tools'),
        ('Preparazione e gestione della sessione', 'Session preparation and management'),
        ('Generatori, raccolte, contenuti salvati e Fight del Master sono divisi per funzione.', 'Generators, collections, saved content and the GM Fight are organized by purpose.'),
        ('SESSIONE IN CORSO', 'ONGOING SESSION'),
        ('La sessione rimane salvata finché non viene sostituita.', 'The session remains saved until it is replaced.'),
        ('Fight del Master in corso', 'GM Fight in progress'),
        ('Riprendi PF, PP, status, round e iniziativa salvati.', 'Resume saved HP, PP, conditions, rounds and initiative.'),
        ('GENERATORI', 'GENERATORS'),
        ('Crea nuovi contenuti da usare o salvare.', 'Create new content to use or save.'),
        ('Generatore Pokémon', 'Pokémon Generator'),
        ('Estrai un Pokémon con forma, livello, natura, abilità, mosse, sesso e probabilità shiny.', 'Generate a Pokémon with form, level, nature, ability, moves, gender and shiny chance.'),
        ('Generatore incontri', 'Encounter Generator'),
        ('Composizione automatica, manuale e raccolte ponderate con stima della difficoltà.', 'Automatic or manual composition and weighted collections with difficulty estimates.'),
        ('Generatore Allenatori PNG', 'NPC Trainer Generator'),
        ('Crea identità, specializzazione, squadra, personalità, tattiche e ricompense.', 'Create identity, specialization, team, personality, tactics and rewards.'),
        ('GENERA', 'GENERATE'),
        ('LIBRERIE', 'LIBRARIES'),
        ('Riapri, modifica e usa i contenuti già preparati.', 'Reopen, edit and use prepared content.'),
        ('Libreria incontri', 'Encounter Library'),
        ('Incontri salvati, raccolte ponderate e avvio diretto nel Fight del Master.', 'Saved encounters, weighted collections and direct launch into the GM Fight.'),
        ('Libreria Allenatori PNG', 'NPC Trainer Library'),
        ('Allenatori salvati, selezione multipla e gestione delle loro squadre nel fight.', 'Saved Trainers, multiple selection and team management in the fight.'),
        ('APRI', 'OPEN'),
    ],
)
write(path, text)


# ---------------------------------------------------------------------------
# Test automatici del ponte e della localizzazione tecnica.
# ---------------------------------------------------------------------------
Path('test/secondary_ui_localization_test.dart').write_text(
    r'''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/localization/ui_text.dart';
import 'package:pokedex_5e_ita/models/trainer_ui_localization.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

void main() {
  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('trainer labels follow the effective application language', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'FOR');
    expect(TrainerUiLocalization.skillName('Animal Handling'), 'Addestrare Animali');

    GameCatalogLocale.setLanguageCode('en');
    expect(TrainerUiLocalization.abilityAbbreviation('STR'), 'STR');
    expect(TrainerUiLocalization.skillName('Animal Handling'), 'Animal Handling');
    expect(TrainerUiLocalization.trainerPathName('Ace Trainer'), 'Ace Trainer');
  });

  test('type badges use English text instead of Italian image labels', () {
    GameCatalogLocale.setLanguageCode('en');
    expect(PokemonAssetPaths.localizedTypeLabel('fire'), 'Fire');
    expect(PokemonAssetPaths.typeCandidates('fire'), isEmpty);

    GameCatalogLocale.setLanguageCode('it');
    expect(PokemonAssetPaths.localizedTypeLabel('fire'), 'Fuoco');
    expect(PokemonAssetPaths.typeCandidates('fire'), isNotEmpty);
  });

  testWidgets('secondary UI helper follows the widget locale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Text(context.uiText('Scheda', 'Sheet')),
        ),
      ),
    );

    expect(find.text('Sheet'), findsOneWidget);
    expect(find.text('Scheda'), findsNothing);
  });
}
''',
    encoding='utf-8',
)

print('Core secondary UI localization applied.')
