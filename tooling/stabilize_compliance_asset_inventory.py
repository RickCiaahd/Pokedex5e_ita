from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "tooling" / "generate_compliance_reports.py"

CONSTANT_ANCHOR = 'ASSET_MD = COMPLIANCE_DIR / "asset-audit-summary.md"\n\n'
CONSTANT_REPLACEMENT = (
    'ASSET_MD = COMPLIANCE_DIR / "asset-audit-summary.md"\n\n'
    'GENERATED_RELEASE_ASSETS = {\n'
    '    Path("assets/data/GPL-3.0.txt"),\n'
    '    Path("assets/data/NOTICE.txt"),\n'
    '}\n\n'
)

OLD_EVIDENCE = (
    '                if child.is_file() and child.name.lower() in EVIDENCE_NAMES:\n'
    '                    evidence.append(child.relative_to(ROOT).as_posix())\n'
)
NEW_EVIDENCE = (
    '                relative = child.relative_to(ROOT)\n'
    '                if (\n'
    '                    child.is_file()\n'
    '                    and child.name.lower() in EVIDENCE_NAMES\n'
    '                    and relative not in GENERATED_RELEASE_ASSETS\n'
    '                ):\n'
    '                    evidence.append(relative.as_posix())\n'
)

OLD_FILES = (
    '    files = sorted((path for path in assets_root.rglob("*") '
    'if path.is_file()), key=lambda item: item.as_posix().lower())\n'
)
NEW_FILES = (
    '    files = sorted(\n'
    '        (\n'
    '            path\n'
    '            for path in assets_root.rglob("*")\n'
    '            if path.is_file()\n'
    '            and path.relative_to(ROOT) not in GENERATED_RELEASE_ASSETS\n'
    '        ),\n'
    '        key=lambda item: item.as_posix().lower(),\n'
    '    )\n'
)


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected {label} exactly once, found {count}")
    return text.replace(old, new, 1)


def apply() -> None:
    text = TARGET.read_text(encoding="utf-8")
    if "GENERATED_RELEASE_ASSETS" not in text:
        text = replace_once(
            text,
            CONSTANT_ANCHOR,
            CONSTANT_REPLACEMENT,
            "asset report constant anchor",
        )
    text = replace_once(text, OLD_EVIDENCE, NEW_EVIDENCE, "evidence block")
    text = replace_once(text, OLD_FILES, NEW_FILES, "asset scan block")
    TARGET.write_text(text, encoding="utf-8", newline="\n")


def check() -> None:
    text = TARGET.read_text(encoding="utf-8")
    for marker in (
        "GENERATED_RELEASE_ASSETS = {",
        "and relative not in GENERATED_RELEASE_ASSETS",
        "and path.relative_to(ROOT) not in GENERATED_RELEASE_ASSETS",
    ):
        if marker not in text:
            raise RuntimeError(f"Missing stabilized inventory marker: {marker}")


def main() -> int:
    apply()
    check()
    print("Compliance asset inventory excludes generated release notices")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
