from __future__ import annotations

import re
from pathlib import Path

PATH = Path('lib/screens/onboarding/first_launch_onboarding_screen.dart')
text = PATH.read_text(encoding='utf-8')


def replace_once(pattern: str, replacement: str, label: str, *, flags: int = 0) -> None:
    global text
    updated, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f'Impossibile aggiornare {label}: occorrenze trovate {count}')
    text = updated


if "trainer_origin_name_localization.dart" not in text:
    replace_once(
        re.escape("import '../../models/trainer_manual_options.dart';\n"),
        "import '../../models/trainer_manual_options.dart';\n"
        "import '../../models/trainer_origin_name_localization.dart';\n",
        'import della localizzazione origini',
    )

replace_once(
    r"  String _originDisplayName\(TrainerOrigin origin, AppLocalizations l10n\) \{.*?\n  \}\n\n  String _originDescription",
    """  String _originDisplayName(TrainerOrigin origin, AppLocalizations l10n) {
    return trainerOriginDisplayName(
      origin.name,
      isItalian: Localizations.localeOf(context).languageCode == 'it',
      dmApprovedLabel: l10n.onboardingOriginDmApprovedName,
    );
  }

  String _originDescription""",
    'nome localizzato delle origini',
    flags=re.DOTALL,
)

replace_once(r"      6 => \.46,", "      6 => .30,", 'altezza della scena starter')

replace_once(
    r"      case 6:.*?\n      case 7:",
    """      case 6:
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
      case 7:""",
    'contenuto fisso della scelta starter',
    flags=re.DOTALL,
)

replace_once(
    r"class _DialogueCard extends StatelessWidget \{.*?\n\}\n\nclass _AgeSelector",
    """class _DialogueCard extends StatelessWidget {
  const _DialogueCard({
    required this.speaker,
    required this.title,
    required this.body,
    this.content,
    this.compact = false,
    this.scrollable = true,
    this.expandContent = false,
  });

  final String speaker;
  final String title;
  final String body;
  final Widget? content;
  final bool compact;
  final bool scrollable;
  final bool expandContent;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 16.0 : 22.0;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          speaker,
          style: TextStyle(
            color: _OnboardingPalette.rust,
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 5 : 8),
        Text(
          title,
          key: const ValueKey('onboarding-dialogue-title'),
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: _OnboardingPalette.text,
            fontSize: compact ? 22 : 27,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          body,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: TextStyle(
            color: _OnboardingPalette.text,
            fontSize: compact ? 14 : 16,
            height: compact ? 1.25 : 1.35,
          ),
        ),
        if (content != null) ...[
          SizedBox(height: compact ? 10 : 18),
          if (expandContent) Expanded(child: content!) else content!,
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: _OnboardingPalette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _OnboardingPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: scrollable
          ? Scrollbar(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: column,
              ),
            )
          : Padding(padding: EdgeInsets.all(padding), child: column),
    );
  }
}

class _AgeSelector""",
    'dialogue card compatta',
    flags=re.DOTALL,
)

replace_once(
    r"class _StarterGrid extends StatelessWidget \{.*?\n\}\n\nclass _SummaryRow",
    """class _StarterGrid extends StatelessWidget {
  const _StarterGrid({
    required this.pokemon,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Pokemon> pokemon;
  final int? selectedId;
  final ValueChanged<Pokemon> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isItalian = Localizations.localeOf(context).languageCode == 'it';
    if (pokemon.isEmpty) {
      return _InfoBanner(
        icon: Icons.search_off,
        text: l10n.onboardingNoStarterResults,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 4 : 2;
        return GridView.builder(
          key: const ValueKey('onboarding-starter-grid'),
          primary: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.zero,
          itemCount: pokemon.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final entry = pokemon[index];
            final selected = selectedId == entry.id;
            return InkWell(
              onTap: () => onSelected(entry),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? _OnboardingPalette.peach
                      : _OnboardingPalette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _OnboardingPalette.orange
                        : _OnboardingPalette.border,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PokemonAssetImage(
                        pokemon: entry,
                        useLargeArtwork: true,
                        size: 82,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      entry.types
                          .map(
                            isItalian
                                ? PokemonTypeLocalization.italianLabel
                                : PokemonTypeLocalization.englishValue,
                          )
                          .join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryRow""",
    'griglia starter compatta',
    flags=re.DOTALL,
)

PATH.write_text(text, encoding='utf-8')
