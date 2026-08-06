from pathlib import Path

path = Path("tool/apply_trainer_identity_header.py")
text = path.read_text(encoding="utf-8")

old_block = '''layout_marker = "    return Semantics(\\n"
if picker.count(layout_marker) != 1:
    raise RuntimeError("picker semantics layout marker was not found exactly once")
picker_prefix, picker_layout = picker.split(layout_marker, 1)
avatar_occurrences = picker_layout.count("                avatar,\\n")
if avatar_occurrences != 2:
    raise RuntimeError(
        f"picker layout avatars: expected 2 matches, found {avatar_occurrences}"
    )
picker_layout = picker_layout.replace(
    "                avatar,\\n",
    "                interactiveAvatar,\\n",
)
picker = picker_prefix + layout_marker + picker_layout
'''

new_block = '''avatar_occurrences = picker.count("                avatar,\\n")
if avatar_occurrences != 3:
    raise RuntimeError(
        f"picker avatars: expected 3 matches after adding the interactive avatar, found {avatar_occurrences}"
    )
picker = picker.replace(
    "                avatar,\\n",
    "                interactiveAvatar,\\n",
)
interactive_stack = """                children: [
                  interactiveAvatar,
                  Positioned(
"""
original_stack = """                children: [
                  avatar,
                  Positioned(
"""
picker = replace_once(
    picker,
    interactive_stack,
    original_stack,
    "interactive avatar stack child",
)
'''

if text.count(old_block) != 1:
    raise RuntimeError("Could not replace the broken avatar layout patch safely")

text = text.replace(old_block, new_block, 1)
path.write_text(text, encoding="utf-8")
print("Fixed interactive avatar layout transformation.")
