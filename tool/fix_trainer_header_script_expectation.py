from pathlib import Path

path = Path("tool/apply_trainer_identity_header.py")
text = path.read_text(encoding="utf-8")
old_condition = "if avatar_occurrences != 2:"
old_message = "expected 2 matches"

if text.count(old_condition) != 1 or text.count(old_message) != 1:
    raise RuntimeError("Could not update avatar occurrence expectation safely")

text = text.replace(old_condition, "if avatar_occurrences != 3:", 1)
text = text.replace(old_message, "expected 3 matches", 1)
path.write_text(text, encoding="utf-8")
print("Updated avatar occurrence expectation from 2 to 3.")
