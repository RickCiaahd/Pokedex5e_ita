from __future__ import annotations

import argparse
import csv
import hashlib
import io
import zipfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PERFORMANCE_DIR = ROOT / "docs" / "performance"
REPORT_PATH = PERFORMANCE_DIR / "release-footprint.md"
DUPLICATES_PATH = PERFORMANCE_DIR / "asset-duplicates.csv"

FAMILY_PREFIXES = (
    "assets/data_webapp",
    "assets/data",
    "assets/textures/textures_webapp/pokemon_transforms",
    "assets/textures/textures_webapp/pokemon",
    "assets/textures/textures_webapp/items",
    "assets/textures/pokemons",
    "assets/textures/sprites",
    "assets/textures/trainers",
    "assets/textures/type_names",
    "assets/textures/gui",
)

LEGAL_ASSET_KEYS = {
    "assets/data/GPL-3.0.txt": "GPL-3.0.txt",
    "assets/data/NOTICE.txt": "NOTICE.txt",
}


@dataclass(frozen=True)
class ArchiveSummary:
    label: str
    file_size: int
    compressed_payload: int
    uncompressed_payload: int
    entry_count: int
    legal_files: tuple[str, ...]
    family_rows: tuple[tuple[str, int, int, int], ...]
    top_entries: tuple[tuple[str, int, int], ...]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def human_bytes(value: int) -> str:
    units = ("B", "KiB", "MiB", "GiB")
    amount = float(value)
    for unit in units:
        if amount < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(amount)} B"
            return f"{amount:.1f} {unit}"
        amount /= 1024
    return f"{value} B"


def asset_family(path: str) -> str:
    normalized = path.replace("\\", "/").lstrip("./")
    for prefix in FAMILY_PREFIXES:
        if normalized == prefix or normalized.startswith(f"{prefix}/"):
            return prefix
    if normalized.startswith("assets/"):
        parts = normalized.split("/")
        return "/".join(parts[:2]) if len(parts) >= 2 else "assets"
    return "non-asset"


def flutter_asset_key(entry_name: str) -> str | None:
    marker = "flutter_assets/"
    normalized = entry_name.replace("\\", "/")
    if marker not in normalized:
        return None
    return normalized.split(marker, 1)[1]


def analyze_archive(path: Path, label: str) -> ArchiveSummary:
    if not path.exists():
        raise FileNotFoundError(f"Missing {label} archive: {path}")

    family_stats: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    top_entries: list[tuple[str, int, int]] = []
    legal_files: set[str] = set()

    with zipfile.ZipFile(path) as archive:
        entries = [entry for entry in archive.infolist() if not entry.is_dir()]
        compressed_payload = sum(entry.compress_size for entry in entries)
        uncompressed_payload = sum(entry.file_size for entry in entries)

        for entry in entries:
            key = flutter_asset_key(entry.filename)
            if key is not None:
                legal_name = LEGAL_ASSET_KEYS.get(key)
                if legal_name is not None:
                    legal_files.add(legal_name)
                if key.startswith("assets/"):
                    family = asset_family(key)
                    row = family_stats[family]
                    row[0] += 1
                    row[1] += entry.compress_size
                    row[2] += entry.file_size
            top_entries.append((entry.filename, entry.compress_size, entry.file_size))

    family_rows = tuple(
        (family, values[0], values[1], values[2])
        for family, values in sorted(
            family_stats.items(), key=lambda item: (-item[1][2], item[0])
        )
    )
    top_entries.sort(key=lambda item: (-item[2], item[0]))

    return ArchiveSummary(
        label=label,
        file_size=path.stat().st_size,
        compressed_payload=compressed_payload,
        uncompressed_payload=uncompressed_payload,
        entry_count=len(top_entries),
        legal_files=tuple(sorted(legal_files)),
        family_rows=family_rows,
        top_entries=tuple(top_entries[:20]),
    )


def duplicate_report() -> tuple[
    str,
    dict[str, int],
    tuple[tuple[int, int, str, tuple[str, ...]], ...],
]:
    assets_root = ROOT / "assets"
    groups: dict[tuple[str, int], list[str]] = defaultdict(list)
    total_files = 0
    total_bytes = 0

    for path in sorted(item for item in assets_root.rglob("*") if item.is_file()):
        relative = path.relative_to(ROOT).as_posix()
        size = path.stat().st_size
        groups[(sha256_file(path), size)].append(relative)
        total_files += 1
        total_bytes += size

    duplicates: list[tuple[int, int, str, tuple[str, ...]]] = []
    duplicate_files = 0
    reclaimable_bytes = 0
    cross_family_groups = 0

    for (digest, size), paths in groups.items():
        if len(paths) < 2:
            continue
        ordered_paths = tuple(sorted(paths))
        reclaimable = size * (len(ordered_paths) - 1)
        duplicates.append((size, reclaimable, digest, ordered_paths))
        duplicate_files += len(ordered_paths) - 1
        reclaimable_bytes += reclaimable
        if len({asset_family(path) for path in ordered_paths}) > 1:
            cross_family_groups += 1

    duplicates.sort(key=lambda item: (-item[1], -item[0], item[2]))

    buffer = io.StringIO()
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerow(
        [
            "sha256",
            "file_size_bytes",
            "copy_count",
            "reclaimable_bytes",
            "families",
            "paths",
        ]
    )
    for size, reclaimable, digest, paths in duplicates:
        writer.writerow(
            [
                digest,
                size,
                len(paths),
                reclaimable,
                "|".join(sorted({asset_family(path) for path in paths})),
                "|".join(paths),
            ]
        )

    metrics = {
        "total_files": total_files,
        "total_bytes": total_bytes,
        "duplicate_groups": len(duplicates),
        "duplicate_files": duplicate_files,
        "reclaimable_bytes": reclaimable_bytes,
        "cross_family_groups": cross_family_groups,
    }
    return buffer.getvalue(), metrics, tuple(duplicates[:20])


def archive_section(summary: ArchiveSummary) -> list[str]:
    legal = ", ".join(f"`{name}`" for name in summary.legal_files) or "none"
    lines = [
        f"## {summary.label}",
        "",
        f"- Archive size: **{human_bytes(summary.file_size)}** ({summary.file_size} bytes)",
        f"- ZIP entries: **{summary.entry_count}**",
        f"- Compressed payload: **{human_bytes(summary.compressed_payload)}**",
        f"- Uncompressed payload: **{human_bytes(summary.uncompressed_payload)}**",
        f"- Embedded legal files: **{legal}**",
        "",
        "### Bundled Flutter asset families",
        "",
        "| Family | Files | Compressed | Uncompressed |",
        "|---|---:|---:|---:|",
    ]
    for family, count, compressed, uncompressed in summary.family_rows:
        lines.append(
            f"| `{family}` | {count} | {human_bytes(compressed)} | "
            f"{human_bytes(uncompressed)} |"
        )

    lines.extend(
        [
            "",
            "### Largest archive entries",
            "",
            "| Entry | Compressed | Uncompressed |",
            "|---|---:|---:|",
        ]
    )
    for name, compressed, uncompressed in summary.top_entries:
        lines.append(
            f"| `{name}` | {human_bytes(compressed)} | "
            f"{human_bytes(uncompressed)} |"
        )
    lines.append("")
    return lines


def build_markdown(
    apk: ArchiveSummary,
    aab: ArchiveSummary,
    duplicate_metrics: dict[str, int],
    top_duplicates: tuple[tuple[int, int, str, tuple[str, ...]], ...],
) -> str:
    flutter_revision = "ad70ec4617166f1c38e5d2bfd388af71fda14f06"
    lines = [
        "# Release footprint audit",
        "",
        "This report is generated from release APK/AAB archives and an exact "
        "SHA-256 scan of every file below `assets/`.",
        "It measures size and byte-identical duplication; it does not by itself "
        "prove that an asset is unused or safe to remove.",
        "",
        "- Pinned Flutter version: **3.44.4**",
        f"- Flutter revision: `{flutter_revision}`",
        f"- Asset files scanned: **{duplicate_metrics['total_files']}**",
        f"- Source asset size: **{human_bytes(duplicate_metrics['total_bytes'])}**",
        f"- Exact duplicate groups: **{duplicate_metrics['duplicate_groups']}**",
        f"- Redundant copies: **{duplicate_metrics['duplicate_files']}**",
        "- Theoretical maximum reclaimable bytes: "
        f"**{human_bytes(duplicate_metrics['reclaimable_bytes'])}**",
        "- Duplicate groups spanning multiple policy families: "
        f"**{duplicate_metrics['cross_family_groups']}**",
        "",
        "The theoretical saving assumes one copy per identical hash and ignores "
        "path compatibility, runtime lookup rules and compression effects.",
        "",
    ]
    lines.extend(archive_section(apk))
    lines.extend(archive_section(aab))
    lines.extend(
        [
            "## Largest exact duplicate groups",
            "",
            "| Reclaimable | Copies | Single file | Families | Example paths |",
            "|---:|---:|---:|---|---|",
        ]
    )
    for size, reclaimable, _digest, paths in top_duplicates:
        families = ", ".join(sorted({asset_family(path) for path in paths}))
        examples = "<br>".join(f"`{path}`" for path in paths[:4])
        if len(paths) > 4:
            examples += f"<br>… and {len(paths) - 4} more"
        lines.append(
            f"| {human_bytes(reclaimable)} | {len(paths)} | "
            f"{human_bytes(size)} | {families} | {examples} |"
        )

    lines.extend(
        [
            "",
            "## Interpretation and next safe actions",
            "",
            "1. Prioritise duplicate groups that cross legacy and web-app "
            "families, because they offer measurable savings without inventing "
            "new artwork.",
            "2. Do not delete a path until all static and dynamically constructed "
            "references have been mapped and tested.",
            "3. Measure a second release after each removal batch; ZIP compression "
            "means source-byte savings and AAB savings will differ.",
            "4. Keep the generated GPL and NOTICE assets embedded in Flutter "
            "archives and the source documents beside downloadable releases.",
            "5. Treat rights clearance separately from size optimisation: "
            "identical files can still have unverified redistribution terms.",
            "",
            "The complete duplicate inventory is stored in "
            "`docs/performance/asset-duplicates.csv`.",
            "",
        ]
    )
    return "\n".join(lines)


def write_or_check(path: Path, content: str, check: bool) -> bool:
    if check:
        return path.exists() and path.read_text(encoding="utf-8") == content
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--aab", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    apk = analyze_archive(args.apk, "Android release APK")
    aab = analyze_archive(args.aab, "Android release AAB")
    duplicates_csv, metrics, top_duplicates = duplicate_report()
    markdown = build_markdown(apk, aab, metrics, top_duplicates)

    results = [
        write_or_check(REPORT_PATH, markdown, args.check),
        write_or_check(DUPLICATES_PATH, duplicates_csv, args.check),
    ]
    if not all(results):
        print(
            "Release footprint reports are stale. Regenerate them with the "
            "pinned toolchain."
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
