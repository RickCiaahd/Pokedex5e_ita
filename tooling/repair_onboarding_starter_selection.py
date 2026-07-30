from __future__ import annotations

import re
from pathlib import Path

path = Path('lib/screens/onboarding/first_launch_onboarding_screen.dart')
text = path.read_text(encoding='utf-8')

correct_navigation = """  bool get _canContinue {
    switch (_step) {
      case 2:
        return _nameController.text.trim().isNotEmpty;
      case 4:
        return _origin != null;
      case 5:
        return _background.trim().isNotEmpty;
      case 6:
        return _starter != null;
      case 8:
        return !_isSaving && _errorMessage != null;
      default:
        return true;
    }
  }

  String get _buttonLabel {
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

  Future<void> _next()"""

text, count = re.subn(
    r"  bool get _canContinue \{.*?\n  Future<void> _next\(\)",
    correct_navigation,
    text,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise SystemExit(f'Ripristino navigazione onboarding fallito: {count}')

marker = '  Widget _buildDialogue() {'
head, separator, tail = text.partition(marker)
if not separator:
    raise SystemExit('Metodo _buildDialogue non trovato')

starter_case = """      case 6:
        return _DialogueCard(
          speaker: l10n.onboardingProfessor,
          title: l10n.onboardingStarterTitle,
          body: l10n.onboardingStarterBody,
          compact: true,
          scrollable: false,
          expandContent: true,
          content: Column(
            children: [
              TextField(
                key: const ValueKey('onboarding-starter-search'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.onboardingStarterSearchLabel,
                  hintText: l10n.onboardingStarterSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _StarterGrid(
                  pokemon: _filteredStarters,
                  selectedId: _starter?.id,
                  onSelected: (pokemon) => setState(() => _starter = pokemon),
                ),
              ),
            ],
          ),
        );
      case 7:"""

tail, count = re.subn(
    r"      case 6:.*?\n      case 7:",
    starter_case,
    tail,
    count=1,
    flags=re.DOTALL,
)
if count != 1:
    raise SystemExit(f'Aggiornamento del vero case 6 fallito: {count}')

path.write_text(head + separator + tail, encoding='utf-8')
