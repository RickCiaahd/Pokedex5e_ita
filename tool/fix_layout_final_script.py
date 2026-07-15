from pathlib import Path

path = Path('tool/apply_layout_final_block.py')
text = path.read_text(encoding='utf-8')
old = '''def add_bottom_sheet_safe_area(text: str) -> str:
    pattern = re.compile(
        r"(showModalBottomSheet(?:<[^>\\n]+>)?\\(\\n(?P<indent>[ \\t]+)context: context,\\n)(?![ \\t]+useSafeArea:)"
    )

    def replacement(match: re.Match[str]) -> str:
        indent = match.group("indent")
        return f"{match.group(1)}{indent}useSafeArea: true,\\n"

    return pattern.sub(replacement, text)
'''
new = '''def add_bottom_sheet_safe_area(text: str) -> str:
    marker = "showModalBottomSheet"
    cursor = 0

    while True:
        start = text.find(marker, cursor)
        if start < 0:
            return text
        opening = text.find("(", start)
        if opening < 0:
            raise RuntimeError("bottom sheet opening parenthesis not found")
        end = find_matching_parenthesis(text, opening)
        call = text[start : end + 1]

        if "useSafeArea:" in call:
            cursor = end + 1
            continue

        context_line = re.search(
            r"(?P<indent>[ \\t]+)context: context,\\n",
            call,
        )
        if context_line is None:
            cursor = end + 1
            continue

        indent = context_line.group("indent")
        updated_call = call.replace(
            f"{indent}context: context,\\n",
            f"{indent}context: context,\\n{indent}useSafeArea: true,\\n",
            1,
        )
        text = text[:start] + updated_call + text[end + 1 :]
        cursor = start + len(updated_call)
'''
count = text.count(old)
if count != 1:
    raise RuntimeError(f'bottom sheet helper: expected one occurrence, found {count}')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
