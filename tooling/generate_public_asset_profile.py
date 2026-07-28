from __future__ import annotations

import argparse
import csv
import io
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBSPEC_PATH = ROOT / "pubspec.yaml"
ASSET_MANIFEST_PATH = ROOT / "docs" / "compliance" / "asset-manifest.csv"
REPORT_PATH = ROOT / "docs" / "performance" / "public-asset-profile.md"
REFERENCES_PATH = ROOT / "docs" / "performance" / "pokemon-artwork-references.csv"
DEFAULT_PUBLIC_PUBSPEC = ROOT / "build" / "public" / "pubspec.yaml"

EXCLUDED_PREFIXES = (
    "assets/textures/pokemons/",
    "assets/textures/sprites/",
    "assets/textures/textures_webapp/pokemon/",
    "assets/textures/textures_webapp/pokemon_transforms/",
)

TEXT_SUFFIXES = {".dart", ".py", ".yaml", ".yml", ".md"}
REFERENCE_ROOTS = ("lib", "test", "tooling", ".github")
GENERATED_PATHS = {REPORT_PATH, REFERENCES_PATH}


def human_bytes(value: int) -> str:
    units = ("B", "KiB", "MiB", "GiB")
    amount = float(value)
    for unit in units:
        if amount < 1024 or unit == units[-1]:
            return f"{int(amount)} B" if unit == "B" else f"{amount:.1f} {unit}"
        amount /= 1024
    return f"{value} B"


def is_excluded_path(path: str) -> bool:
    normalized = path.replace("\\", "/").lstrip("./")
    return any(normalized.startswith(prefix) for prefix in EXCLUDED_PREFIXES)


def public_pubspec(source: str) -> str:
    output: list[str] = []
    removed = 0
    for line in source.splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            declared_path = stripped[2:].strip().strip("'\"")
            if is_excluded_path(declared_path):
                removed += 1
                continue
        output.append(line)

    if removed == 0:
        raise RuntimeError("No not-cleared asset declarations were removed from pubspec.yaml")

    rendered = "\n".join(output).rstrip() + "\n"
    for prefix in EXCLUDED_PREFIXES:
        if prefix in rendered:
            raise RuntimeError(f"Excluded prefix still present in public pubspec: {prefix}")
    return rendered


def asset_declarations(pubspec: str) -> tuple[str, ...]:
    declarations: list[str] = []
    in_assets = False
    for line in pubspec.splitlines():
        if line == "  assets:":
            in_assets = True
            continue
        if not in_assets:
            continue
        if line and not line.startswith("    "):
            break
        stripped = line.strip()
        if not stripped.startswith("- "):
            continue
        value = stripped[2:].strip().strip("'\"")
        if value:
            declarations.append(value)
    return tuple(declarations)


def is_declared(path: str, declarations: tuple[str, ...]) -> bool:
    for declaration in declarations:
        if declaration.endswith("/"):
            if path.startswith(declaration):
                return True
        elif path == declaration:
            return True
    return False


def read_asset_rows() -> list[dict[str, str]]:
    if not ASSET_MANIFEST_PATH.exists():
        raise FileNotFoundError(
            "Missing docs/compliance/asset-manifest.csv. "
            "Run tooling/generate_compliance_reports.py first."
        )
    with ASSET_MANIFEST_PATH.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def artwork_role(path: str) -> str:
    filename = Path(path).name.lower()
    stem = Path(filename).stem
    if "shiny" in stem:
        return "shiny"
    if re.search(r"(?:^|[-_])(m|male|f|female)(?:$|[-_])", stem):
        return "gender-variant"
    if stem in {"main", "sprite"} or stem.startswith(("main-", "sprite-")):
        return "standard-or-form"
    return "other-variant"


def reference_kind(relative_path: str, line: str) -> str:
    if relative_path.startswith("lib/"):
        return "runtime-static" if ".png" in line.lower() else "runtime-dynamic"
    if relative_path.startswith("test/"):
        return "test-contract"
    if relative_path.startswith(".github/"):
        return "build-pipeline"
    if relative_path.startswith("tooling/"):
        return "tooling"
    return "documentation"


def scan_references() -> list[dict[str, str | int]]:
    rows: list[dict[str, str | int]] = []
    for root_name in REFERENCE_ROOTS:
        root = ROOT / root_name
        if not root.exists():
            continue
        for path in sorted(root.rglob("*"), key=lambda item: item.as_posix().lower()):
            if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            if path in GENERATED_PATHS or path.name == "generate_public_asset_profile.py":
                continue
            relative = path.relative_to(ROOT).as_posix()
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except UnicodeDecodeError:
                continue
            for line_number, line in enumerate(lines, start=1):
                matched = [prefix for prefix in EXCLUDED_PREFIXES if prefix in line]
                if not matched:
                    continue
                rows.append(
                    {
                        "source_file": relative,
                        "line": line_number,
                        "kind": reference_kind(relative, line),
                        "prefixes": ";".join(matched),
                        "expression": " ".join(line.strip().split()),
                    }
                )

    for prefix in EXCLUDED_PREFIXES:
        rows.append(
            {
                "source_file": "pubspec.yaml",
                "line": 0,
                "kind": "build-declaration",
                "prefixes": prefix,
                "expression": f"All asset declarations rooted at {prefix}",
            }
        )

    rows.sort(key=lambda row: (str(row["source_file"]), int(row["line"]), str(row["prefixes"])))
    return rows


def references_csv(rows: list[dict[str, str | int]]) -> str:
    buffer = io.StringIO()
    writer = csv.DictWriter(
        buffer,
        fieldnames=("source_file", "line", "kind", "prefixes", "expression"),
        lineterminator="\n",
    )
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue()


def build_report(
    asset_rows: list[dict[str, str]],
    declarations: tuple[str, ...],
    references: list[dict[str, str | int]],
) -> str:
    total_files = len(asset_rows)
    total_bytes = sum(int(row["size_bytes"]) for row in asset_rows)

    not_cleared = [row for row in asset_rows if row["policy_status"] == "not-cleared"]
    uncovered = [row["path"] for row in not_cleared if not is_excluded_path(row["path"])]
    if uncovered:
        examples = ", ".join(uncovered[:5])
        raise RuntimeError(
            "The public profile does not cover every not-cleared asset. "
            f"Examples: {examples}"
        )

    still_declared = [
        row["path"]
        for row in not_cleared
        if is_declared(row["path"], declarations)
    ]
    if still_declared:
        examples = ", ".join(still_declared[:5])
        raise RuntimeError(
            "Not-cleared assets are still declared by the public pubspec. "
            f"Examples: {examples}"
        )

    included = [row for row in asset_rows if is_declared(row["path"], declarations)]
    excluded_bytes = sum(int(row["size_bytes"]) for row in not_cleared)
    included_bytes = sum(int(row["size_bytes"]) for row in included)

    policy_counts = Counter(row["policy_status"] for row in included)
    role_counts: dict[str, dict[str, int]] = defaultdict(lambda: {"files": 0, "bytes": 0})
    for row in not_cleared:
        role = artwork_role(row["path"])
        role_counts[role]["files"] += 1
        role_counts[role]["bytes"] += int(row["size_bytes"])

    family_stats: dict[str, dict[str, int]] = defaultdict(
        lambda: {"excluded_files": 0, "excluded_bytes": 0, "included_files": 0, "included_bytes": 0}
    )
    included_paths = {row["path"] for row in included}
    for row in asset_rows:
        stats = family_stats[row["family"]]
        if row["path"] in included_paths:
            stats["included_files"] += 1
            stats["included_bytes"] += int(row["size_bytes"])
        if row["policy_status"] == "not-cleared":
            stats["excluded_files"] += 1
            stats["excluded_bytes"] += int(row["size_bytes"])

    reference_counts = Counter(str(row["kind"]) for row in references)

    lines = [
        "# Public-safe asset profile",
        "",
        "This report is generated from `pubspec.yaml` and the file-level compliance inventory.",
        "It defines a reproducible build profile that excludes every asset currently marked `not-cleared` without deleting the private/full asset set from the repository.",
        "",
        f"- Full source inventory: **{total_files} files**, **{human_bytes(total_bytes)}**",
        f"- Assets excluded from the public bundle: **{len(not_cleared)} files**, **{human_bytes(excluded_bytes)}**",
        f"- Assets still declared in the public profile: **{len(included)} files**, **{human_bytes(included_bytes)}**",
        f"- Source-size reduction before Flutter/native overhead: **{(excluded_bytes / total_bytes * 100):.1f}%**",
        "",
        "The generated public pubspec is written below `build/public/` and is intentionally not committed. The normal `pubspec.yaml` remains the full private profile.",
        "",
        "## Excluded roots",
        "",
    ]
    lines.extend(f"- `{prefix}`" for prefix in EXCLUDED_PREFIXES)

    lines.extend(
        [
            "",
            "## Family coverage",
            "",
            "| Family | Excluded files | Excluded size | Remaining files | Remaining size |",
            "|---|---:|---:|---:|---:|",
        ]
    )
    for family, stats in sorted(
        family_stats.items(),
        key=lambda item: (-item[1]["excluded_bytes"], -item[1]["included_bytes"], item[0]),
    ):
        lines.append(
            f"| `{family}` | {stats['excluded_files']} | {human_bytes(stats['excluded_bytes'])} | "
            f"{stats['included_files']} | {human_bytes(stats['included_bytes'])} |"
        )

    lines.extend(
        [
            "",
            "## Excluded artwork roles",
            "",
            "The role classification is filename-based and is used only to estimate migration work; it is not proof that a file is reachable at runtime.",
            "",
            "| Role | Files | Size |",
            "|---|---:|---:|",
        ]
    )
    for role, stats in sorted(role_counts.items(), key=lambda item: (-item[1]["bytes"], item[0])):
        lines.append(f"| `{role}` | {stats['files']} | {human_bytes(stats['bytes'])} |")

    lines.extend(
        [
            "",
            "## Static and dynamic reference map",
            "",
            "The complete source-level map is stored in `docs/performance/pokemon-artwork-references.csv`.",
            "",
            "| Reference kind | Occurrences |",
            "|---|---:|",
        ]
    )
    for kind, count in sorted(reference_counts.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"| `{kind}` | {count} |")

    lines.extend(
        [
            "",
            "## Residual policy status",
            "",
            "Excluding `not-cleared` files is a packaging safeguard, not a legal clearance. The remaining `mixed`, `unverified`, and `project-created-pending-proof` families still require provenance and licence work before publication.",
            "",
            "| Status | Files in public profile |",
            "|---|---:|",
        ]
    )
    for status, count in sorted(policy_counts.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"| `{status}` | {count} |")

    lines.extend(
        [
            "",
            "## Build strategy",
            "",
            "1. Generate a temporary public pubspec from the full source pubspec.",
            "2. Remove only declarations rooted at the four blocked prefixes above; do not delete source assets.",
            "3. Build APK/AAB in an isolated CI workspace so the normal private build remains unchanged.",
            "4. Verify the produced archives contain no blocked paths and still embed GPL/NOTICE.",
            "5. Exercise `PokemonAssetImage` with the filtered `AssetManifest`; missing artwork must resolve to the existing in-app fallback instead of throwing.",
            "6. Replace the fallback with original, documented artwork only after authorship and redistribution terms are archived.",
            "",
        ]
    )
    return "\n".join(lines)


def write_or_check(path: Path, content: str, check: bool) -> bool:
    normalized = content.rstrip() + "\n"
    if check:
        return path.exists() and path.read_text(encoding="utf-8") == normalized
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(normalized, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument(
        "--pubspec-output",
        type=Path,
        default=DEFAULT_PUBLIC_PUBSPEC,
        help="Temporary pubspec used by the public-safe CI build.",
    )
    args = parser.parse_args()

    source_pubspec = PUBSPEC_PATH.read_text(encoding="utf-8")
    rendered_pubspec = public_pubspec(source_pubspec)
    declarations = asset_declarations(rendered_pubspec)
    asset_rows = read_asset_rows()
    references = scan_references()
    report = build_report(asset_rows, declarations, references)
    reference_inventory = references_csv(references)

    args.pubspec_output.parent.mkdir(parents=True, exist_ok=True)
    args.pubspec_output.write_text(rendered_pubspec, encoding="utf-8", newline="\n")

    results = [
        write_or_check(REPORT_PATH, report, args.check),
        write_or_check(REFERENCES_PATH, reference_inventory, args.check),
    ]
    if not all(results):
        print(
            "Public asset profile reports are stale. Regenerate them with "
            "python tooling/generate_public_asset_profile.py"
        )
        return 1

    print(f"Public pubspec: {args.pubspec_output.relative_to(ROOT)}")
    print(f"Declared public asset roots: {len(declarations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
