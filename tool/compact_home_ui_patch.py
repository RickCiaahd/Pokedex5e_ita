from pathlib import Path

path = Path('lib/screens/home/home_screen.dart')
text = path.read_text(encoding='utf-8')

old = '''                      const SizedBox(height: 24),
                      _HomeSectionTitle(
                        key: _trainerSectionKey,
                        icon: Icons.person_outline,
                        title: l10n.homeTrainerAndTeamTitle,
                        subtitle: l10n.homeTrainerAndTeamSubtitle,
                      ),
                      if (!_hasActiveBattle)
                        _HomeActionButton(
                          icon: Icons.flash_on,
                          title: l10n.homeBattleCompanionTitle,
                          subtitle: l10n.homeBattleCompanionSubtitle,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BattleScreen(),
                              ),
                            );
                            await _loadDashboard();
                          },
                        ),
                      _HomeActionButton(
                        icon: Icons.badge_outlined,
                        title: l10n.homeTrainerSheetTitle,
                        subtitle: l10n.homeTrainerSheetSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TrainerSheetScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.add_circle_outline,
                        title: l10n.homeCaptureTitle,
                        subtitle: l10n.homeCaptureSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CapturePokemonScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.groups,
                        title: l10n.homeTeamTitle,
                        subtitle: l10n.homeTeamSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeamSelectionScreen(
                                nickname: profile?.name ?? l10n.trainerFallback,
                              ),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.computer,
                        title: l10n.homePcTitle,
                        subtitle: l10n.homePcSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PokemonPcScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.egg_alt_outlined,
                        title: l10n.homeBreedingTitle,
                        subtitle: l10n.homeBreedingSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BreedingScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      _HomeActionButton(
                        icon: Icons.backpack_outlined,
                        title: l10n.homeBagTitle,
                        subtitle: l10n.homeBagSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BagScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
                      const SizedBox(height: 24),
                      _HomeSectionTitle(
                        icon: Icons.menu_book_outlined,
                        title: l10n.homeConsultationTitle,
                        subtitle: l10n.homeConsultationSubtitle,
                      ),
                      _HomeActionButton(
                        key: _pokedexKey,
                        icon: Icons.catching_pokemon,
                        title: l10n.homeOpenPokedexTitle,
                        subtitle: l10n.homeOpenPokedexSubtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PokedexScreen(),
                            ),
                          );
                          await _loadDashboard();
                        },
                      ),
'''

new = '''                      const SizedBox(height: 20),
                      _HomeSectionTitle(
                        key: _trainerSectionKey,
                        icon: Icons.person_outline,
                        title: l10n.homeTrainerAndTeamTitle,
                        subtitle: l10n.homeTrainerAndTeamSubtitle,
                      ),
                      _HomeQuickActionsGrid(
                        children: [
                          if (!_hasActiveBattle)
                            _HomeQuickAction(
                              icon: Icons.flash_on,
                              title: l10n.homeBattleCompanionTitle,
                              subtitle: l10n.homeBattleCompanionSubtitle,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BattleScreen(),
                                  ),
                                );
                                await _loadDashboard();
                              },
                            ),
                          _HomeQuickAction(
                            icon: Icons.badge_outlined,
                            title: l10n.homeTrainerSheetTitle,
                            subtitle: l10n.homeTrainerSheetSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TrainerSheetScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                          _HomeQuickAction(
                            icon: Icons.groups,
                            title: l10n.homeTeamTitle,
                            subtitle: l10n.homeTeamSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TeamSelectionScreen(
                                    nickname:
                                        profile?.name ?? l10n.trainerFallback,
                                  ),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                          _HomeQuickAction(
                            icon: Icons.add_circle_outline,
                            title: l10n.homeCaptureTitle,
                            subtitle: l10n.homeCaptureSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CapturePokemonScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                          _HomeQuickAction(
                            icon: Icons.computer,
                            title: l10n.homePcTitle,
                            subtitle: l10n.homePcSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PokemonPcScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                          _HomeQuickAction(
                            icon: Icons.backpack_outlined,
                            title: l10n.homeBagTitle,
                            subtitle: l10n.homeBagSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BagScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                          _HomeQuickAction(
                            icon: Icons.egg_alt_outlined,
                            title: l10n.homeBreedingTitle,
                            subtitle: l10n.homeBreedingSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BreedingScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _HomeSectionTitle(
                        icon: Icons.menu_book_outlined,
                        title: l10n.homeConsultationTitle,
                        subtitle: l10n.homeConsultationSubtitle,
                      ),
                      _HomeQuickActionsGrid(
                        children: [
                          _HomeQuickAction(
                            key: _pokedexKey,
                            icon: Icons.catching_pokemon,
                            title: l10n.homeOpenPokedexTitle,
                            subtitle: l10n.homeOpenPokedexSubtitle,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PokedexScreen(),
                                ),
                              );
                              await _loadDashboard();
                            },
                          ),
                        ],
                      ),
'''

if old not in text:
    raise SystemExit('Main Home action block not found')
text = text.replace(old, new, 1)

anchor = '''class _HomeActionButton extends StatelessWidget {
'''
addition = '''class _HomeQuickActionsGrid extends StatelessWidget {
  const _HomeQuickActionsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: enlargedText ? 156 : 126),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            color: colors.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: enlargedText ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

'''
if anchor not in text:
    raise SystemExit('HomeActionButton anchor not found')
text = text.replace(anchor, addition + anchor, 1)

# Tighten the top dashboard slightly without changing the information hierarchy.
text = text.replace(
    '''                      _TrainerHeader(key: _trainerHeaderKey, profile: profile),\n                      const SizedBox(height: 20),\n''',
    '''                      _TrainerHeader(key: _trainerHeaderKey, profile: profile),\n                      const SizedBox(height: 14),\n''',
    1,
)

path.write_text(text, encoding='utf-8')
