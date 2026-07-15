from pathlib import Path

path = Path('tool/apply_layout_review_second_pass.py')
text = path.read_text(encoding='utf-8')
old = '''pc_text = replace_once(
    pc_text,
    """const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 88,""",
    """SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        MediaQuery.sizeOf(context).width >= 900
                                        ? 112
                                        : 92,""",
    label="pc grid extent",
)
'''
new = '''pc_text, pc_grid_count = __import__("re").subn(
    r"const SliverGridDelegateWithMaxCrossAxisExtent\\(\\n\\s+maxCrossAxisExtent: 88,",
    """SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent:
                                        MediaQuery.sizeOf(context).width >= 900
                                        ? 112
                                        : 92,""",
    pc_text,
    count=1,
)
if pc_grid_count != 1:
    raise RuntimeError(
        f"pc grid extent: expected one occurrence, found {pc_grid_count}"
    )
'''
if text.count(old) != 1:
    raise RuntimeError(f'pc patch block: expected one occurrence, found {text.count(old)}')
text = text.replace(old, new, 1)
old_marker = '    "           : SafeArea(",\n'
new_marker = '    ": SafeArea(",\n'
old_replacement = '    "           : ResponsiveContent(\\n               maxWidth: 1280,\\n               child: SafeArea(",\n'
new_replacement = '    ": ResponsiveContent(\\n               maxWidth: 1280,\\n               child: SafeArea(",\n'
if text.count(old_marker) != 1:
    raise RuntimeError(f'pc marker: expected one occurrence, found {text.count(old_marker)}')
if text.count(old_replacement) != 1:
    raise RuntimeError(
        f'pc replacement: expected one occurrence, found {text.count(old_replacement)}'
    )
text = text.replace(old_marker, new_marker, 1)
text = text.replace(old_replacement, new_replacement, 1)
path.write_text(text, encoding='utf-8')
