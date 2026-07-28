from __future__ import annotations

import argparse
import zipfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

EXCLUDED_PREFIXES = (
    "assets/textures/pokemons/",
    "assets/textures/sprites/",
    "assets/textures/textures_webapp/pokemon/",
    "assets/textures/textures_webapp/pokemon_transforms/",
)

LEGAL_ASSETS = {
    "assets/data/GPL-3.0.txt",
    "assets/data/NOTICE.txt",
}


@dataclass(frozen=True)
class ArchiveResult:
    label: str
    path: Path
    archive_bytes: int
    entry_count: int
    asset_files: int
    asset_compressed_bytes: int
    asset_uncompressed_bytes: int
    blocked_paths: tuple[str, ...]
    legal_assets: tuple[str, ...]
    family_rows: tuple[tuple[str, int, int, int], ...]


def human_bytes(value: int) -> str:
    units = ("B", "KiB", "MiB", "GiB")
    amount = float(value)
    for unit in units:
        if amount < 1024 or unit == units[-1]:
            return f"{int(amount)} B" if unit == "B" else f"{amount:.1f} {unit}"
        amount /= 1024
    return f"{value} B"


def asset_key(entry_name: str) -> str | None:
    normalized = entry_name.replace("\\", "/")
    marker = "flutter_assets/"
    if marker not in normalized:
        return None
    return normalized.split(marker, 1)[1]


def asset_family(path: str) -> str:
    parts = path.split("/")
    if len(parts) >= 4 and parts[:3] == ["assets", "textures", "textures_webapp"]:
        return "/".join(parts[:4])
    if len(parts) >= 3:
        return "/".join(parts[:3])
    if len(parts) >= 2:
        return "/".join(parts[:2])
    return path


def inspect_archive(path: Path, label: str) -> ArchiveResult:
    if not path.exists():
        raise FileNotFoundError(f"Missing {label}: {path}")

    blocked: list[str] = []
    legal: set[str] = set()
    asset_files = 0
    asset_compressed = 0
    asset_uncompressed = 0
    family_stats: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])

    with zipfile.ZipFile(path) as archive:
        entries = [entry for entry in archive.infolist() if not entry.is_dir()]
        for entry in entries:
            key = asset_key(entry.filename)
            if key is None:
                continue
            if key.startswith("assets/"):
                asset_files += 1
                asset_compressed += entry.compress_size
                asset_uncompressed += entry.file_size
                family = asset_family(key)
                stats = family_stats[family]
                stats[0] += 1
                stats[1] += entry.compress_size
                stats[2] += entry.file_size
            if any(key.startswith(prefix) for prefix in EXCLUDED_PREFIXES):
                blocked.append(key)
            if key in LEGAL_ASSETS:
                legal.add(key)

    family_rows = tuple(
        (family, values[0], values[1], values[2])
        for family, values in sorted(
            family_stats.items(),
            key=lambda item: (-item[1][2], item[0]),
        )
    )
    return ArchiveResult(
        label=label,
        path=path,
        archive_bytes=path.stat().st_size,
        entry_count=len(entries),
        asset_files=asset_files,
        asset_compressed_bytes=asset_compressed,
        asset_uncompressed_bytes=asset_uncompressed,
        blocked_paths=tuple(sorted(blocked)),
        legal_assets=tuple(sorted(legal)),
        family_rows=family_rows,
    )


def archive_section(result: ArchiveResult) -> list[str]:
    lines = [
        f"## {result.label}",
        "",
        f"- Archive size: **{human_bytes(result.archive_bytes)}** ({result.archive_bytes} bytes)",
        f"- ZIP entries: **{result.entry_count}**",
        f"- Flutter asset files: **{result.asset_files}**",
        f"- Flutter assets compressed: **{human_bytes(result.asset_compressed_bytes)}**",
        f"- Flutter assets uncompressed: **{human_bytes(result.asset_uncompressed_bytes)}**",
        f"- Blocked paths found: **{len(result.blocked_paths)}**",
        "- Embedded legal assets: "
        + (", ".join(f"`{path}`" for path in result.legal_assets) or "none"),
        "",
        "| Bundled family | Files | Compressed | Uncompressed |",
        "|---|---:|---:|---:|",
    ]
    for family, files, compressed, uncompressed in result.family_rows:
        lines.append(
            f"| `{family}` | {files} | {human_bytes(compressed)} | {human_bytes(uncompressed)} |"
        )
    lines.append("")
    return lines


def build_report(apk: ArchiveResult, aab: ArchiveResult) -> str:
    lines = [
        "# Measured public-safe release",
        "",
        "This report is generated from APK/AAB archives built with the temporary public asset profile.",
        "The report is attached to CI rather than committed because archive signatures and metadata can change a few bytes between otherwise equivalent builds.",
        "",
        "- Build define: `TRAINER_ATLAS_PUBLIC_SAFE=true`",
        "- Excluded policy class: `not-cleared`",
        "- Expected blocked archive entries: **0**",
        "",
    ]
    lines.extend(archive_section(apk))
    lines.extend(archive_section(aab))
    lines.extend(
        [
            "## Interpretation",
            "",
            "A successful verification proves that the four blocked roots are absent from the produced archives and that GPL/NOTICE remain embedded.",
            "It does not clear the remaining `mixed`, `unverified`, or `project-created-pending-proof` assets for redistribution.",
            "",
        ]
    )
    return "\n".join(lines)


def validate(result: ArchiveResult) -> list[str]:
    errors: list[str] = []
    if result.blocked_paths:
        examples = ", ".join(result.blocked_paths[:5])
        errors.append(
            f"{result.label} contains {len(result.blocked_paths)} blocked assets. Examples: {examples}"
        )
    missing_legal = LEGAL_ASSETS.difference(result.legal_assets)
    if missing_legal:
        errors.append(
            f"{result.label} is missing legal assets: {', '.join(sorted(missing_legal))}"
        )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--aab", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    apk = inspect_archive(args.apk, "Android public-safe APK")
    aab = inspect_archive(args.aab, "Android public-safe AAB")
    report = build_report(apk, aab).rstrip() + "\n"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(report, encoding="utf-8", newline="\n")

    errors = [*validate(apk), *validate(aab)]
    if errors:
        for error in errors:
            print(error)
        return 1

    print(f"Verified public-safe APK: {human_bytes(apk.archive_bytes)}")
    print(f"Verified public-safe AAB: {human_bytes(aab.archive_bytes)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
