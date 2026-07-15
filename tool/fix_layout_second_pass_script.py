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
path.write_text(text.replace(old, new, 1), encoding='utf-8')
