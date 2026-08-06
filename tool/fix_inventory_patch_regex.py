from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding='utf-8')
    if old not in text:
        raise RuntimeError(f'Expected block not found in {path}: {old!r}')
    file_path.write_text(text.replace(old, new, 1), encoding='utf-8')


onboarding = 'lib/screens/onboarding/first_launch_onboarding_screen.dart'
replace_once(
    onboarding,
    """      setState(() {
        _isSaving = false;
        _step = 10;
      });
""",
    """      setState(() {
        _isSaving = false;
        _step = 11;
      });
""",
)
replace_once(
    onboarding,
    'canGoBack: _step > 0 && _step < 9,',
    'canGoBack: _step > 0 && _step < 10,',
)
replace_once(
    onboarding,
    'if (_errorMessage != null && _step >= 9) ...[',
    'if (_errorMessage != null && _step >= 10) ...[',
)
replace_once(
    onboarding,
    'if (_step != 9 || !_isSaving)',
    'if (_step != 10 || !_isSaving)',
)

bag = 'lib/screens/bag/bag_screen.dart'
replace_once(
    bag,
    """    final filteredItems = widget.items.where((item) {
      return item.matchesSearchQuery(_query, aliases: [_typeLabel(item.type)]);
    }).toList();
""",
    """    final filteredItems = widget.items.where((item) {
      if (_isBuy && (item.cost == null || item.cost! <= 0)) return false;
      return item.matchesSearchQuery(_query, aliases: [_typeLabel(item.type)]);
    }).toList();
""",
)
replace_once(
    bag,
    """                    final costLabel = item.cost == null
                        ? context.uiText('Non acquistabile', 'Not for sale')
                        : '₽ ${item.cost}';
""",
    """                    final costLabel = _isBuy
                        ? '₽ ${item.cost}'
                        : context.uiText(
                            'Gestione manuale',
                            'Manual management',
                          );
""",
)
