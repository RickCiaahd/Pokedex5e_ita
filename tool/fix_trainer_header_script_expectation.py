from pathlib import Path

path = Path("tool/apply_trainer_identity_header.py")
text = path.read_text(encoding="utf-8")

old_avatar_block = '''avatar_occurrences = picker.count("                avatar,\\n")
if avatar_occurrences != 2:
    raise RuntimeError(
        f"picker layout avatars: expected 2 matches, found {avatar_occurrences}"
    )
picker = picker.replace(
    "                avatar,\\n",
    "                interactiveAvatar,\\n",
)
'''

new_avatar_block = '''layout_marker = "    return Semantics(\\n"
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

if text.count(old_avatar_block) != 1:
    raise RuntimeError("Could not patch the avatar layout replacement safely")
text = text.replace(old_avatar_block, new_avatar_block, 1)

write_marker = 'mobile_path.write_text(mobile, encoding="utf-8")\n'
remove_unused_widget = '''compact_choice_line = """class _CompactChoiceLine extends StatelessWidget {
  const _CompactChoiceLine({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 17),
          ],
        ),
      ),
    );
  }
}

"""
mobile = replace_once(
    mobile,
    compact_choice_line,
    "",
    "remove unused compact level line",
)

mobile_path.write_text(mobile, encoding="utf-8")
'''

if text.count(write_marker) != 1:
    raise RuntimeError("Could not insert removal of the unused level widget safely")
text = text.replace(write_marker, remove_unused_widget, 1)

path.write_text(text, encoding="utf-8")
print("Patched trainer header update script safely.")
