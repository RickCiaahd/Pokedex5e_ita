from pathlib import Path

POKEDEX = Path('lib/screens/pokedex/pokedex_screen.dart')
TEAM = Path('lib/screens/team/team_selection_screen.dart')


def insert_before(text: str, marker: str, insertion: str) -> str:
    if marker not in text:
        raise RuntimeError(f'Marker not found: {marker!r}')
    return text.replace(marker, insertion + marker, 1)


def replace_between(text: str, start_marker: str, end_marker: str, replacement: str) -> str:
    start = text.find(start_marker)
    if start < 0:
        raise RuntimeError(f'Start marker not found: {start_marker!r}')
    end = text.find(end_marker, start)
    if end < 0:
        raise RuntimeError(f'End marker not found: {end_marker!r}')
    return text[:start] + replacement + text[end:]


pokedex = POKEDEX.read_text(encoding='utf-8')

new_mobile_helpers = r'''  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refreshSheet() => setSheetState(() {});

            return FractionallySizedBox(
              heightFactor: 0.9,
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.uiText('FILTRI POKÉDEX', 'POKÉDEX FILTERS'),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (_hasCustomOptions)
                            TextButton.icon(
                              onPressed: () {
                                _resetOptions();
                                refreshSheet();
                              },
                              icon: const Icon(Icons.restart_alt),
                              label: Text(
                                context.uiText('Ripristina', 'Reset'),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _filterSummary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FilterGroupTitle(
                              icon: Icons.sort,
                              label: context.uiText('Ordina', 'Sort'),
                            ),
                            const SizedBox(height: 6),
                            _SortModeSelector(
                              sortMode: _sortMode,
                              onChanged: (sortMode) {
                                setState(() {
                                  _sortMode = sortMode;
                                  _applyFilters();
                                });
                                refreshSheet();
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterGroupTitle(
                              icon: Icons.public,
                              label: context.uiText(
                                'Regione e tipo',
                                'Region and type',
                              ),
                            ),
                            const SizedBox(height: 6),
                            _RegionFilterSelector(
                              regions: _visibleRegions,
                              selectedRegion: _selectedRegion,
                              progressBuilder: _regionProgress,
                              onChanged: (region) {
                                setState(() {
                                  _selectedRegion = region;
                                  _applyFilters();
                                });
                                refreshSheet();
                              },
                            ),
                            const SizedBox(height: 8),
                            _TypeFilterSelector(
                              types: _availableTypes,
                              selectedTypes: _selectedTypes,
                              onChanged: (types) {
                                setState(() {
                                  _selectedTypes
                                    ..clear()
                                    ..addAll(types);
                                  _applyFilters();
                                });
                                refreshSheet();
                              },
                              onClear: () {
                                setState(() {
                                  _selectedTypes.clear();
                                  _applyFilters();
                                });
                                refreshSheet();
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterGroupTitle(
                              icon: Icons.visibility_outlined,
                              label: context.uiText('Mostra', 'Show'),
                            ),
                            const SizedBox(height: 6),
                            _ViewFilterSelector(
                              selectedFilter: _viewFilter,
                              onChanged: (filter) {
                                setState(() {
                                  _viewFilter = filter;
                                  _applyFilters();
                                });
                                refreshSheet();
                              },
                            ),
                            const SizedBox(height: 16),
                            _FilterGroupTitle(
                              icon: Icons.touch_app_outlined,
                              label: context.uiText(
                                'Quando tocchi un Pokémon',
                                'When you tap a Pokémon',
                              ),
                            ),
                            const SizedBox(height: 6),
                            _MarkModeSelector(
                              selectedMode: _markMode,
                              onChanged: (mode) {
                                setState(() => _markMode = mode);
                                refreshSheet();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(context.uiText('CHIUDI', 'CLOSE')),
                      ),
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

  Widget _buildCompactFilterButton() {
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton(
      onPressed: _openFilterSheet,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: _hasCustomOptions ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.uiText('FILTRI', 'FILTERS'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _filterSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_up, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }

'''

pokedex = insert_before(
    pokedex,
    '  Widget _buildFilterControls() {\n',
    new_mobile_helpers,
)

new_filter_panel = r'''  Widget _buildFilterPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return _buildCompactFilterButton();
        }

        final colorScheme = Theme.of(context).colorScheme;
        return Material(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const PageStorageKey<String>('pokedex-filter-panel'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: const Icon(Icons.tune),
              title: Text(
                context.uiText('Filtri e modalità', 'Filters and modes'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _filterSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                if (_hasCustomOptions)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _resetOptions,
                      icon: const Icon(Icons.restart_alt),
                      label: Text(context.uiText('Ripristina', 'Reset')),
                    ),
                  ),
                _buildFilterControls(),
                const SizedBox(height: 12),
                _FilterGroupTitle(
                  icon: Icons.visibility_outlined,
                  label: context.uiText('Mostra', 'Show'),
                ),
                const SizedBox(height: 6),
                _ViewFilterSelector(
                  selectedFilter: _viewFilter,
                  onChanged: (filter) {
                    setState(() {
                      _viewFilter = filter;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _FilterGroupTitle(
                  icon: Icons.touch_app_outlined,
                  label: context.uiText(
                    'Quando tocchi un Pokémon',
                    'When you tap a Pokémon',
                  ),
                ),
                const SizedBox(height: 6),
                _MarkModeSelector(
                  selectedMode: _markMode,
                  onChanged: (mode) => setState(() => _markMode = mode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

'''

pokedex = replace_between(
    pokedex,
    '  Widget _buildFilterPanel() {\n',
    '  @override\n  Widget build(BuildContext context) {\n',
    new_filter_panel,
)

POKEDEX.write_text(pokedex, encoding='utf-8')

team = TEAM.read_text(encoding='utf-8')
old_progress = '''                                    child: LinearProgressIndicator(\n                                      value: hpProgress,\n                                      minHeight: 6,\n                                      backgroundColor:\n                                          colorScheme.surfaceContainerHighest,\n                                    ),\n'''
new_progress = '''                                    child: LinearProgressIndicator(\n                                      value: hpProgress,\n                                      minHeight: 6,\n                                      valueColor: AlwaysStoppedAnimation<Color>(\n                                        _teamHpProgressColor(hpProgress),\n                                      ),\n                                      backgroundColor:\n                                          colorScheme.surfaceContainerHighest,\n                                    ),\n'''
if old_progress not in team:
    raise RuntimeError('Team HP progress block not found')
team = team.replace(old_progress, new_progress, 1)

helper_marker = 'enum _TeamTransferAction { exportTeam, shareTeam, importTeam }\n'
helper = '''Color _teamHpProgressColor(double value) {\n  if (value <= 0.25) return Colors.red;\n  if (value <= 0.5) return Colors.amber;\n  return Colors.green;\n}\n\n'''
if helper_marker not in team:
    raise RuntimeError('Team helper insertion marker not found')
team = team.replace(helper_marker, helper + helper_marker, 1)
TEAM.write_text(team, encoding='utf-8')
