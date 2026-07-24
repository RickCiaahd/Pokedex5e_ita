from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ONBOARDING = ROOT / "lib/screens/onboarding/first_launch_onboarding_screen.dart"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa una occorrenza, trovate {count}")
    return text.replace(old, new, 1)


text = ONBOARDING.read_text(encoding="utf-8")

text = replace_once(
    text,
    "import 'package:flutter/material.dart';\n\n",
    "import 'package:flutter/material.dart';\n\nimport '../../l10n/app_localizations.dart';\n",
    "import localizzazioni",
)

old_backgrounds = """  static const List<_BackgroundOption> _backgroundOptions = [
    _BackgroundOption(
      name: 'Ricercatore',
      description:
          'Osservi, cataloghi e studi ogni scoperta prima di trarre conclusioni.',
      icon: Icons.science_outlined,
    ),
    _BackgroundOption(
      name: 'Esploratore',
      description:
          'Ti senti a casa sulle strade meno battute e negli ambienti selvaggi.',
      icon: Icons.explore_outlined,
    ),
    _BackgroundOption(
      name: 'Allevatore',
      description:
          'Conosci le necessità delle creature e costruisci legami pazienti.',
      icon: Icons.pets_outlined,
    ),
    _BackgroundOption(
      name: 'Combattente',
      description:
          'Affronti le difficoltà con disciplina, coraggio e spirito competitivo.',
      icon: Icons.sports_martial_arts_outlined,
    ),
    _BackgroundOption(
      name: 'Artista',
      description:
          'Esprimi te stesso attraverso spettacolo, creatività e sensibilità.',
      icon: Icons.palette_outlined,
    ),
    _BackgroundOption(
      name: 'Studioso',
      description:
          'Hai dedicato anni a libri, tradizioni e conoscenze specialistiche.',
      icon: Icons.menu_book_outlined,
    ),
  ];
"""
new_backgrounds = """  static const List<_BackgroundOption> _backgroundOptions = [
    _BackgroundOption(name: 'Ricercatore', icon: Icons.science_outlined),
    _BackgroundOption(name: 'Esploratore', icon: Icons.explore_outlined),
    _BackgroundOption(name: 'Allevatore', icon: Icons.pets_outlined),
    _BackgroundOption(
      name: 'Combattente',
      icon: Icons.sports_martial_arts_outlined,
    ),
    _BackgroundOption(name: 'Artista', icon: Icons.palette_outlined),
    _BackgroundOption(name: 'Studioso', icon: Icons.menu_book_outlined),
  ];
"""
text = replace_once(text, old_backgrounds, new_backgrounds, "background stabili")

selected_background = """  _BackgroundOption get _selectedBackground => _backgroundOptions.firstWhere(
        (option) => option.name == _background,
        orElse: () => _backgroundOptions.first,
      );
"""
localized_helpers = selected_background + """

  String _backgroundLabel(
    _BackgroundOption option,
    AppLocalizations l10n,
  ) {
    return switch (option.name) {
      'Ricercatore' => l10n.onboardingBackgroundResearcher,
      'Esploratore' => l10n.onboardingBackgroundExplorer,
      'Allevatore' => l10n.onboardingBackgroundBreeder,
      'Combattente' => l10n.onboardingBackgroundFighter,
      'Artista' => l10n.onboardingBackgroundArtist,
      'Studioso' => l10n.onboardingBackgroundScholar,
      _ => option.name,
    };
  }

  String _backgroundDescription(
    _BackgroundOption option,
    AppLocalizations l10n,
  ) {
    return switch (option.name) {
      'Ricercatore' => l10n.onboardingBackgroundResearcherDescription,
      'Esploratore' => l10n.onboardingBackgroundExplorerDescription,
      'Allevatore' => l10n.onboardingBackgroundBreederDescription,
      'Combattente' => l10n.onboardingBackgroundFighterDescription,
      'Artista' => l10n.onboardingBackgroundArtistDescription,
      'Studioso' => l10n.onboardingBackgroundScholarDescription,
      _ => option.name,
    };
  }

  String _originDisplayName(TrainerOrigin origin, AppLocalizations l10n) {
    return origin.name == 'Origine 5e approvata dal DM'
        ? l10n.onboardingOriginDmApprovedName
        : origin.name;
  }

  String _originDescription(TrainerOrigin origin, AppLocalizations l10n) {
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
      _ => origin.description,
    };
  }
"""
text = replace_once(
    text,
    selected_background,
    localized_helpers,
    "helper contenuti onboarding",
)

old_button = """  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'INIZIA LA TUA AVVENTURA';
      case 7:
        return 'CONFERMA';
      case 8:
        return _errorMessage == null ? 'CREAZIONE IN CORSO...' : 'RIPROVA';
      case 9:
        return 'INIZIA!';
      default:
        return 'AVANTI';
    }
  }
"""
new_button = """  String get _buttonLabel {
    final l10n = AppLocalizations.of(context);
    switch (_step) {
      case 0:
        return l10n.onboardingStartAdventure;
      case 7:
        return l10n.onboardingConfirm;
      case 8:
        return _errorMessage == null
            ? l10n.onboardingCreatingProfile
            : l10n.retryAction.toUpperCase();
      case 9:
        return l10n.onboardingBegin;
      default:
        return l10n.nextAction;
    }
  }
"""
text = replace_once(text, old_button, new_button, "testo pulsante")

old_origin_bonuses = """  String _originBonuses(TrainerOrigin origin) {
    if (origin.abilityBonuses.isEmpty) return 'Nessun bonus automatico';
    return origin.abilityBonuses.entries
        .map((entry) => '${entry.key.toUpperCase()} +${entry.value}')
        .join(', ');
  }
"""
new_origin_bonuses = """  String _originBonuses(TrainerOrigin origin) {
    if (origin.abilityBonuses.isEmpty) {
      return AppLocalizations.of(context).onboardingNoAutomaticBonuses;
    }
    return origin.abilityBonuses.entries
        .map((entry) => '${entry.key.toUpperCase()} +${entry.value}')
        .join(', ');
  }
"""
text = replace_once(
    text,
    old_origin_bonuses,
    new_origin_bonuses,
    "bonus origine",
)

text = replace_once(
    text,
    "  Widget build(BuildContext context) {\n    if (_isLoading) {",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    if (_isLoading) {",
    "l10n build principale",
)
text = replace_once(
    text,
    "                      'Non è stato possibile creare il profilo. Riprova.',",
    "                      l10n.onboardingProfileCreationError,",
    "errore creazione profilo",
)

new_dialogue = r"""  Widget _buildDialogue() {
    final l10n = AppLocalizations.of(context);
    switch (_step) {
      case 1:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingWelcomeTitle,
          body: l10n.onboardingWelcomeBody,
          content: _InfoBanner(
            icon: Icons.auto_stories_outlined,
            text: l10n.onboardingWelcomeNote,
          ),
        );
      case 2:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingNameTitle,
          body: l10n.onboardingNameBody,
          content: TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.onboardingTrainerNameLabel,
              hintText: l10n.onboardingTrainerNameHint,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            onChanged: (_) => setState(() {}),
          ),
        );
      case 3:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingAgeTitle,
          body: l10n.onboardingAgeBody,
          content: _AgeSelector(
            age: _age,
            onDecrease: _age > 6 ? () => setState(() => _age--) : null,
            onIncrease: _age < 99 ? () => setState(() => _age++) : null,
          ),
        );
      case 4:
        final origin = _origin;
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingOriginTitle,
          body: l10n.onboardingOriginBody,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<TrainerOrigin>(
                initialValue: origin,
                isExpanded: true,
                items: [
                  for (final item in _origins)
                    DropdownMenuItem(
                      value: item,
                      child: Text(_originDisplayName(item, l10n)),
                    ),
                ],
                onChanged: (value) => setState(() => _origin = value),
                decoration: InputDecoration(
                  labelText: l10n.onboardingOriginLabel,
                  prefixIcon: const Icon(Icons.public),
                ),
              ),
              if (origin != null) ...[
                const SizedBox(height: 16),
                _DetailLine(
                  label: l10n.onboardingOriginBonusLabel,
                  value: _originBonuses(origin),
                ),
                _DetailLine(
                  label: l10n.onboardingProficienciesLabel,
                  value: origin.skillProficiencies.isEmpty
                      ? l10n.onboardingNoAdditionalProficiencies
                      : origin.skillProficiencies.join(', '),
                ),
                const SizedBox(height: 8),
                Text(
                  _originDescription(origin, l10n),
                  style: const TextStyle(height: 1.35),
                ),
              ],
            ],
          ),
        );
      case 5:
        final selected = _selectedBackground;
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingBackgroundTitle,
          body: l10n.onboardingBackgroundBody,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _background,
                isExpanded: true,
                items: [
                  for (final option in _backgroundOptions)
                    DropdownMenuItem(
                      value: option.name,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 20),
                          const SizedBox(width: 10),
                          Text(_backgroundLabel(option, l10n)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _background = value);
                },
                decoration: InputDecoration(
                  labelText: l10n.onboardingBackgroundLabel,
                ),
              ),
              const SizedBox(height: 16),
              _InfoBanner(
                icon: selected.icon,
                text: _backgroundDescription(selected, l10n),
              ),
            ],
          ),
        );
      case 6:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingStarterTitle,
          body: l10n.onboardingStarterBody,
          content: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.onboardingStarterSearchLabel,
                  hintText: l10n.onboardingStarterSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              _StarterGrid(
                pokemon: _filteredStarters,
                selectedId: _starter?.id,
                onSelected: (pokemon) => setState(() => _starter = pokemon),
              ),
            ],
          ),
        );
      case 7:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingSummaryTitle,
          body: l10n.onboardingSummaryBody,
          content: Column(
            children: [
              _SummaryRow(
                icon: Icons.person_outline,
                label: l10n.onboardingNameLabel,
                value: _nameController.text.trim(),
              ),
              _SummaryRow(
                icon: Icons.cake_outlined,
                label: l10n.onboardingAgeLabel,
                value: '$_age',
              ),
              _SummaryRow(
                icon: Icons.public,
                label: l10n.onboardingOriginLabel,
                value: _origin == null
                    ? '—'
                    : _originDisplayName(_origin!, l10n),
              ),
              _SummaryRow(
                icon: Icons.menu_book_outlined,
                label: l10n.onboardingBackgroundLabel,
                value: _backgroundLabel(_selectedBackground, l10n),
              ),
              _SummaryRow(
                icon: Icons.catching_pokemon,
                label: l10n.onboardingStarterLabel,
                value: _starter?.name ?? '—',
              ),
            ],
          ),
        );
      case 8:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingSavingTitle,
          body: _errorMessage == null
              ? l10n.onboardingSavingBody
              : l10n.onboardingSavingErrorBody,
          content: _SavingView(hasError: _errorMessage != null),
        );
      default:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingDoneTitle,
          body: l10n.onboardingDoneBody,
          content: _InfoBanner(
            icon: Icons.celebration_outlined,
            text: l10n.onboardingDoneNote,
          ),
        );
    }
  }
"""
pattern = re.compile(
    r"  Widget _buildDialogue\(\) \{.*?\n  \}\n\}\n\nclass _OnboardingPalette",
    re.DOTALL,
)
match = pattern.search(text)
if match is None:
    raise RuntimeError("metodo _buildDialogue non trovato")
text = text[: match.start()] + new_dialogue + "}\n\nclass _OnboardingPalette" + text[match.end() :]

text = replace_once(
    text,
    "                  tooltip: 'Indietro',",
    "                  tooltip: AppLocalizations.of(context).backAction,",
    "tooltip indietro",
)

text = replace_once(
    text,
    "  Widget build(BuildContext context) {\n    return ClipRRect(\n      borderRadius: BorderRadius.circular(30),",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    return ClipRRect(\n      borderRadius: BorderRadius.circular(30),",
    "l10n welcome stage",
)
text = replace_once(
    text,
    "                const Text(\n                  'Il tuo compagno per le avventure da tavolo',\n                  textAlign: TextAlign.center,\n                  style: TextStyle(",
    "                Text(\n                  l10n.onboardingTagline,\n                  textAlign: TextAlign.center,\n                  style: const TextStyle(",
    "tagline onboarding",
)

old_cover_placeholder = """  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF7FB), Color(0xFFFFF4DE)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: 'SFONDO COPERTINA',
            fileName: 'onboarding_welcome_background.webp',
          ),
        ),
      ),
    );
  }
"""
new_cover_placeholder = """  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF7FB), Color(0xFFFFF4DE)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: AppLocalizations.of(context).onboardingMissingCoverBackground,
            fileName: 'onboarding_welcome_background.webp',
          ),
        ),
      ),
    );
  }
"""
text = replace_once(
    text,
    old_cover_placeholder,
    new_cover_placeholder,
    "placeholder copertina",
)

old_lab_placeholder = """  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4EFEA), Color(0xFFFFF7F1)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: 'SFONDO LABORATORIO',
            fileName: 'onboarding_lab_background.webp',
          ),
        ),
      ),
    );
  }
"""
new_lab_placeholder = """  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4EFEA), Color(0xFFFFF7F1)],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _MissingAssetLabel(
            title: AppLocalizations.of(context).onboardingMissingLabBackground,
            fileName: 'onboarding_lab_background.webp',
          ),
        ),
      ),
    );
  }
"""
text = replace_once(
    text,
    old_lab_placeholder,
    new_lab_placeholder,
    "placeholder laboratorio",
)

text = replace_once(
    text,
    "        child: const Column(\n          mainAxisAlignment: MainAxisAlignment.center,",
    "        child: Column(\n          mainAxisAlignment: MainAxisAlignment.center,",
    "colonna placeholder professore",
)
text = replace_once(
    text,
    "            Text(\n              'PROFESSORE PNG\\nTRASPARENTE',",
    "            Text(\n              AppLocalizations.of(context).onboardingMissingProfessor,",
    "placeholder professore",
)
text = replace_once(
    text,
    "              style: TextStyle(\n                color: _OnboardingPalette.rust,",
    "              style: const TextStyle(\n                color: _OnboardingPalette.rust,",
    "stile placeholder professore",
)
text = replace_once(
    text,
    "            SizedBox(height: 12),",
    "            const SizedBox(height: 12),",
    "spaziatura placeholder professore 1",
)
text = replace_once(
    text,
    "            SizedBox(height: 8),\n            Text(\n              'onboarding_professor.png',",
    "            const SizedBox(height: 8),\n            const Text(\n              'onboarding_professor.png',",
    "spaziatura placeholder professore 2",
)
text = replace_once(
    text,
    "            Icon(\n              Icons.person_add_alt_1_outlined,",
    "            const Icon(\n              Icons.person_add_alt_1_outlined,",
    "icona placeholder professore",
)

text = replace_once(
    text,
    "  Widget build(BuildContext context) {\n    if (pokemon.isEmpty) {\n      return const _InfoBanner(\n        icon: Icons.search_off,\n        text: 'Nessun Pokémon corrisponde alla ricerca.',\n      );\n    }",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    final isItalian = Localizations.localeOf(context).languageCode == 'it';\n    if (pokemon.isEmpty) {\n      return _InfoBanner(\n        icon: Icons.search_off,\n        text: l10n.onboardingNoStarterResults,\n      );\n    }",
    "griglia starter vuota",
)
text = replace_once(
    text,
    "                        entry.types\n                            .map(PokemonTypeLocalization.italianLabel)\n                            .join(' / '),",
    "                        entry.types\n                            .map(\n                              isItalian\n                                  ? PokemonTypeLocalization.italianLabel\n                                  : PokemonTypeLocalization.englishValue,\n                            )\n                            .join(' / '),",
    "tipi starter localizzati",
)

old_background_class = """class _BackgroundOption {
  const _BackgroundOption({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final IconData icon;
}
"""
new_background_class = """class _BackgroundOption {
  const _BackgroundOption({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
"""
text = replace_once(
    text,
    old_background_class,
    new_background_class,
    "modello background",
)
text = replace_once(
    text,
    "            FilledButton(onPressed: onRetry, child: const Text('RIPROVA')),
",
    "            FilledButton(\n              onPressed: onRetry,\n              child: Text(\n                AppLocalizations.of(context).retryAction.toUpperCase(),\n              ),\n            ),\n",
    "pulsante errore onboarding",
)

ONBOARDING.write_text(text, encoding="utf-8")

it_updates = {
    "onboardingStartAdventure": "INIZIA LA TUA AVVENTURA",
    "onboardingConfirm": "CONFERMA",
    "onboardingCreatingProfile": "CREAZIONE IN CORSO...",
    "onboardingBegin": "INIZIA!",
    "onboardingProfileCreationError": "Non è stato possibile creare il profilo. Riprova.",
    "onboardingProfessor": "Professore",
    "onboardingWelcomeTitle": "Benvenuto nel tuo nuovo viaggio.",
    "onboardingWelcomeBody": "Qui potrai creare il tuo Allenatore, scegliere il primo compagno e prepararti alle avventure da tavolo.",
    "onboardingWelcomeNote": "Le tue scelte potranno essere modificate in seguito dal profilo.",
    "onboardingNameTitle": "Prima di iniziare, dimmi…",
    "onboardingNameBody": "Come ti chiami?",
    "onboardingTrainerNameLabel": "Nome Allenatore",
    "onboardingTrainerNameHint": "Inserisci il tuo nome",
    "onboardingAgeTitle": "Bene! E quanti anni hai?",
    "onboardingAgeBody": "Puoi sempre modificare questa informazione in seguito.",
    "onboardingOriginTitle": "Ogni Allenatore porta con sé una storia.",
    "onboardingOriginBody": "Da dove provieni?",
    "onboardingOriginLabel": "Origine",
    "onboardingOriginBonusLabel": "Bonus caratteristiche",
    "onboardingProficienciesLabel": "Competenze",
    "onboardingNoAutomaticBonuses": "Nessun bonus automatico",
    "onboardingNoAdditionalProficiencies": "Nessuna competenza aggiuntiva",
    "onboardingBackgroundTitle": "Quale strada ti ha portato fin qui?",
    "onboardingBackgroundBody": "Scegli il background che descrive meglio il tuo Allenatore.",
    "onboardingBackgroundLabel": "Background",
    "onboardingBackgroundResearcher": "Ricercatore",
    "onboardingBackgroundResearcherDescription": "Osservi, cataloghi e studi ogni scoperta prima di trarre conclusioni.",
    "onboardingBackgroundExplorer": "Esploratore",
    "onboardingBackgroundExplorerDescription": "Ti senti a casa sulle strade meno battute e negli ambienti selvaggi.",
    "onboardingBackgroundBreeder": "Allevatore",
    "onboardingBackgroundBreederDescription": "Conosci le necessità delle creature e costruisci legami pazienti.",
    "onboardingBackgroundFighter": "Combattente",
    "onboardingBackgroundFighterDescription": "Affronti le difficoltà con disciplina, coraggio e spirito competitivo.",
    "onboardingBackgroundArtist": "Artista",
    "onboardingBackgroundArtistDescription": "Esprimi te stesso attraverso spettacolo, creatività e sensibilità.",
    "onboardingBackgroundScholar": "Studioso",
    "onboardingBackgroundScholarDescription": "Hai dedicato anni a libri, tradizioni e conoscenze specialistiche.",
    "onboardingStarterTitle": "Infine, scegli il tuo primo compagno.",
    "onboardingStarterBody": "Puoi scegliere qualunque Pokémon non evoluto con SR 1/2 o inferiore.",
    "onboardingStarterSearchLabel": "Cerca per nome o tipo",
    "onboardingStarterSearchHint": "Esempio: Bulbasaur, Erba, Fuoco…",
    "onboardingNoStarterResults": "Nessun Pokémon corrisponde alla ricerca.",
    "onboardingSummaryTitle": "Ecco il tuo profilo.",
    "onboardingSummaryBody": "Controlla le scelte e preparati a iniziare.",
    "onboardingNameLabel": "Nome",
    "onboardingAgeLabel": "Età",
    "onboardingStarterLabel": "Starter",
    "onboardingSavingTitle": "Sto creando il tuo profilo.",
    "onboardingSavingBody": "Un momento… sto preparando il tuo Allenatore e il primo Pokémon.",
    "onboardingSavingErrorBody": "Qualcosa non ha funzionato. Puoi riprovare senza perdere le tue scelte.",
    "onboardingDoneTitle": "Tutto pronto!",
    "onboardingDoneBody": "La tua avventura sta per iniziare. Ci vediamo nel mondo dei Pokémon!",
    "onboardingDoneNote": "Il profilo e il tuo starter sono stati creati correttamente.",
    "onboardingTagline": "Il tuo compagno per le avventure da tavolo",
    "onboardingMissingCoverBackground": "SFONDO COPERTINA",
    "onboardingMissingLabBackground": "SFONDO LABORATORIO",
    "onboardingMissingProfessor": "PROFESSORE PNG\nTRASPARENTE",
    "onboardingOriginDmApprovedName": "Origine 5e approvata dal DM",
    "onboardingOriginAlolanDescription": "Bonus caratteristiche: INT +2, CHA +1.\nCompetenza: Nature.\nTratto: puoi lanciare Speak with Pokémon una volta per riposo lungo. È una buona origine per trainer curiosi, sociali e molto legati alla vita naturale dei Pokémon.",
    "onboardingOriginHoennianDescription": "Bonus caratteristiche: WIS +2, INT +1.\nCompetenza: Survival.\nTratto: sei abituato a viaggiare in ambienti difficili e a cavartela tra clima, terreno e rotte selvagge. Funziona bene per esploratori, ranger e allenatori da viaggio.",
    "onboardingOriginJohtoanDescription": "Bonus caratteristiche: INT +2, STR +1.\nCompetenza: History.\nTratto: la tua formazione richiama tradizioni antiche e disciplina fisica; il tratto marziale premia i colpi critici con armi. Adatta a trainer legati a storia, templi, rovine e leggende.",
    "onboardingOriginKalosianDescription": "Bonus caratteristiche: CHA +2, INT +1.\nCompetenza: Persuasion.\nTratto: puoi ritirare un 1 secondo le regole dell’origine. È pensata per trainer eleganti, diplomatici e capaci di restare lucidi quando contano presenza e stile.",
    "onboardingOriginKantoanDescription": "Bonus caratteristiche: +1 a due caratteristiche a scelta. Questo bonus va assegnato manualmente nei box delle caratteristiche.\nCompetenza: Investigation.\nTratto: ottieni un talento approvato dal DM. È l’origine più flessibile, ottima per costruire un trainer molto personalizzato.",
    "onboardingOriginSinnoanDescription": "Bonus caratteristiche: CON +2, STR +1.\nCompetenza: Athletics.\nTratto: ottieni competenza nei tiri salvezza di Costituzione. Ideale per allenatori resistenti, abituati a montagna, neve e lunghe spedizioni.",
    "onboardingOriginUnovanDescription": "Bonus caratteristiche: DEX +2, WIS +1.\nCompetenza: Insight.\nTratto: ottieni due competenze aggiuntive a scelta. Perfetta per trainer rapidi, adattabili e capaci di leggere persone e situazioni.",
    "onboardingOriginGalarianDescription": "Bonus caratteristiche: scegli DEX +2 e STR +1 oppure STR +2 e DEX +1. Questo bonus va assegnato manualmente nei box delle caratteristiche.\nCompetenza: Intimidation.\nTratto: ottieni una reazione difensiva. Adatta a trainer competitivi, fisici e abituati a reggere la pressione dello scontro.",
    "onboardingOriginDmApprovedDescription": "Usa un’origine 5e classica o homebrew approvata dal DM. Segna manualmente bonus caratteristiche, competenze e tratti concordati al tavolo.",
}

en_updates = {
    "onboardingStartAdventure": "START YOUR ADVENTURE",
    "onboardingConfirm": "CONFIRM",
    "onboardingCreatingProfile": "CREATING PROFILE...",
    "onboardingBegin": "BEGIN!",
    "onboardingProfileCreationError": "The profile could not be created. Try again.",
    "onboardingProfessor": "Professor",
    "onboardingWelcomeTitle": "Welcome to your new journey.",
    "onboardingWelcomeBody": "Here you can create your Trainer, choose your first companion and prepare for tabletop adventures.",
    "onboardingWelcomeNote": "You can change these choices later from your profile.",
    "onboardingNameTitle": "Before we begin, tell me…",
    "onboardingNameBody": "What is your name?",
    "onboardingTrainerNameLabel": "Trainer name",
    "onboardingTrainerNameHint": "Enter your name",
    "onboardingAgeTitle": "Great! How old are you?",
    "onboardingAgeBody": "You can change this information later.",
    "onboardingOriginTitle": "Every Trainer carries a story.",
    "onboardingOriginBody": "Where do you come from?",
    "onboardingOriginLabel": "Origin",
    "onboardingOriginBonusLabel": "Ability bonuses",
    "onboardingProficienciesLabel": "Proficiencies",
    "onboardingNoAutomaticBonuses": "No automatic bonuses",
    "onboardingNoAdditionalProficiencies": "No additional proficiencies",
    "onboardingBackgroundTitle": "Which path brought you here?",
    "onboardingBackgroundBody": "Choose the background that best describes your Trainer.",
    "onboardingBackgroundLabel": "Background",
    "onboardingBackgroundResearcher": "Researcher",
    "onboardingBackgroundResearcherDescription": "You observe, catalogue and study every discovery before drawing conclusions.",
    "onboardingBackgroundExplorer": "Explorer",
    "onboardingBackgroundExplorerDescription": "You feel at home on less-travelled roads and in the wilderness.",
    "onboardingBackgroundBreeder": "Breeder",
    "onboardingBackgroundBreederDescription": "You understand the needs of creatures and build patient bonds.",
    "onboardingBackgroundFighter": "Fighter",
    "onboardingBackgroundFighterDescription": "You face challenges with discipline, courage and a competitive spirit.",
    "onboardingBackgroundArtist": "Artist",
    "onboardingBackgroundArtistDescription": "You express yourself through performance, creativity and sensitivity.",
    "onboardingBackgroundScholar": "Scholar",
    "onboardingBackgroundScholarDescription": "You have devoted years to books, traditions and specialist knowledge.",
    "onboardingStarterTitle": "Finally, choose your first companion.",
    "onboardingStarterBody": "You may choose any unevolved Pokémon with SR 1/2 or lower.",
    "onboardingStarterSearchLabel": "Search by name or type",
    "onboardingStarterSearchHint": "Example: Bulbasaur, Grass, Fire…",
    "onboardingNoStarterResults": "No Pokémon match your search.",
    "onboardingSummaryTitle": "Here is your profile.",
    "onboardingSummaryBody": "Review your choices and get ready to begin.",
    "onboardingNameLabel": "Name",
    "onboardingAgeLabel": "Age",
    "onboardingStarterLabel": "Starter",
    "onboardingSavingTitle": "I am creating your profile.",
    "onboardingSavingBody": "One moment… I am preparing your Trainer and first Pokémon.",
    "onboardingSavingErrorBody": "Something went wrong. You can try again without losing your choices.",
    "onboardingDoneTitle": "All set!",
    "onboardingDoneBody": "Your adventure is about to begin. See you in the world of Pokémon!",
    "onboardingDoneNote": "Your profile and starter were created successfully.",
    "onboardingTagline": "Your companion for tabletop adventures",
    "onboardingMissingCoverBackground": "COVER BACKGROUND",
    "onboardingMissingLabBackground": "LABORATORY BACKGROUND",
    "onboardingMissingProfessor": "TRANSPARENT\nPROFESSOR PNG",
    "onboardingOriginDmApprovedName": "GM-approved 5e Origin",
    "onboardingOriginAlolanDescription": "Ability bonuses: INT +2, CHA +1.\nProficiency: Nature.\nTrait: you can cast Speak with Pokémon once per long rest. A good origin for curious, sociable Trainers closely connected to the natural lives of Pokémon.",
    "onboardingOriginHoennianDescription": "Ability bonuses: WIS +2, INT +1.\nProficiency: Survival.\nTrait: you are accustomed to travelling through difficult environments and handling climate, terrain and wild routes. It suits explorers, rangers and travelling Trainers.",
    "onboardingOriginJohtoanDescription": "Ability bonuses: INT +2, STR +1.\nProficiency: History.\nTrait: your training draws on ancient traditions and physical discipline; the martial trait rewards critical hits with weapons. It suits Trainers connected to history, temples, ruins and legends.",
    "onboardingOriginKalosianDescription": "Ability bonuses: CHA +2, INT +1.\nProficiency: Persuasion.\nTrait: you may reroll a 1 according to the origin rules. It is designed for elegant, diplomatic Trainers who stay composed when presence and style matter.",
    "onboardingOriginKantoanDescription": "Ability bonuses: +1 to two abilities of your choice. Assign these bonuses manually in the ability boxes.\nProficiency: Investigation.\nTrait: gain a feat approved by the GM. This is the most flexible origin and is ideal for building a highly customised Trainer.",
    "onboardingOriginSinnoanDescription": "Ability bonuses: CON +2, STR +1.\nProficiency: Athletics.\nTrait: gain proficiency in Constitution saving throws. Ideal for resilient Trainers accustomed to mountains, snow and long expeditions.",
    "onboardingOriginUnovanDescription": "Ability bonuses: DEX +2, WIS +1.\nProficiency: Insight.\nTrait: gain two additional proficiencies of your choice. Perfect for quick, adaptable Trainers who can read people and situations.",
    "onboardingOriginGalarianDescription": "Ability bonuses: choose DEX +2 and STR +1, or STR +2 and DEX +1. Assign these bonuses manually in the ability boxes.\nProficiency: Intimidation.\nTrait: gain a defensive reaction. It suits competitive, physical Trainers accustomed to handling the pressure of battle.",
    "onboardingOriginDmApprovedDescription": "Use a classic or homebrew 5e origin approved by the GM. Record the agreed ability bonuses, proficiencies and traits manually.",
}

for relative_path, updates in (
    ("lib/l10n/app_it.arb", it_updates),
    ("lib/l10n/app_en.arb", en_updates),
):
    path = ROOT / relative_path
    data = json.loads(path.read_text(encoding="utf-8"))
    duplicates = sorted(set(updates).intersection(data))
    if duplicates:
        raise RuntimeError(f"{relative_path}: chiavi già presenti: {duplicates}")
    data.update(updates)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


test_path = ROOT / "test/onboarding_localization_test.dart"
test_path.write_text(
    """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/l10n/app_localizations_en.dart';
import 'package:pokedex_5e_ita/l10n/app_localizations_it.dart';

void main() {
  test('espone i testi principali dell onboarding in italiano e inglese', () {
    final italian = AppLocalizationsIt();
    final english = AppLocalizationsEn();

    expect(italian.onboardingProfessor, 'Professore');
    expect(english.onboardingProfessor, 'Professor');
    expect(italian.onboardingStartAdventure, 'INIZIA LA TUA AVVENTURA');
    expect(english.onboardingStartAdventure, 'START YOUR ADVENTURE');
    expect(italian.onboardingBackgroundResearcher, 'Ricercatore');
    expect(english.onboardingBackgroundResearcher, 'Researcher');
    expect(italian.onboardingOriginDmApprovedName, contains('DM'));
    expect(english.onboardingOriginDmApprovedName, contains('GM'));
    expect(italian.onboardingNoStarterResults, contains('Nessun'));
    expect(english.onboardingNoStarterResults, startsWith('No Pokémon'));
  });

  test('la schermata non conserva le principali frasi italiane hardcoded', () {
    final source = File(
      'lib/screens/onboarding/first_launch_onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains("AppLocalizations.of(context)"));
    expect(source, isNot(contains('Benvenuto nel tuo nuovo viaggio.')));
    expect(source, isNot(contains('Come ti chiami?')));
    expect(source, isNot(contains('Nessun Pokémon corrisponde alla ricerca.')));
  });
}
""",
    encoding="utf-8",
)
