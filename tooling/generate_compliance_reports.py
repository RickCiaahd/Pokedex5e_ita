from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPLIANCE_DIR = ROOT / "docs" / "compliance"

DEPENDENCY_CSV = COMPLIANCE_DIR / "dependency-licenses.csv"
DEPENDENCY_MD = COMPLIANCE_DIR / "dependency-licenses.md"
ASSET_CSV = COMPLIANCE_DIR / "asset-manifest.csv"
ASSET_MD = COMPLIANCE_DIR / "asset-audit-summary.md"

GENERATED_RELEASE_ASSETS = {
    Path("assets/data/GPL-3.0.txt"),
    Path("assets/data/NOTICE.txt"),
}

EVIDENCE_NAMES = {
    "attribution.txt",
    "attributions.txt",
    "license",
    "license.txt",
    "license.md",
    "licence",
    "licence.txt",
    "licence.md",
    "copying",
    "copying.txt",
    "notice",
    "notice.txt",
    "notice.md",
    "source.txt",
    "sources.txt",
}

ASSET_POLICY = {
    "assets/data": ("mixed", "Source and redistribution terms must be linked file by file."),
    "assets/data_webapp": ("unverified", "Source and licence from the web catalogue must be archived."),
    "assets/textures/gui": ("unverified", "Confirm whether each file is covered by upstream code licensing or separate terms."),
    "assets/textures/pokemons": ("not-cleared", "Replace, exclude, or obtain explicit redistribution permission."),
    "assets/textures/sprites": ("not-cleared", "Replace, exclude, or obtain explicit redistribution permission."),
    "assets/textures/trainers": ("project-created-pending-proof", "Archive author, consent, and reuse terms."),
    "assets/textures/type_names": ("project-created-pending-proof", "Archive source artwork and author declaration."),
    "assets/textures/textures_webapp/items": ("unverified", "Complete attribution and verify redistribution terms."),
    "assets/textures/textures_webapp/pokemon": ("not-cleared", "Verify each visual set or exclude it from the public build."),
    "assets/textures/textures_webapp/pokemon_transforms": ("not-cleared", "Verify each transformation set or exclude it from the public build."),
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def human_bytes(value: int) -> str:
    units = ["B", "KiB", "MiB", "GiB"]
    amount = float(value)
    for unit in units:
        if amount < 1024 or unit == units[-1]:
            return f"{amount:.1f} {unit}" if unit != "B" else f"{int(amount)} B"
        amount /= 1024
    return f"{value} B"


def parse_pubspec_lock(path: Path) -> dict[str, dict[str, str]]:
    packages: dict[str, dict[str, str]] = {}
    current: str | None = None
    in_packages = False

    package_re = re.compile(r"^  ([A-Za-z0-9_.+-]+):\s*$")
    field_re = re.compile(r"^    (dependency|source|version):\s*(.+?)\s*$")

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if raw_line == "packages:":
            in_packages = True
            continue
        if not in_packages:
            continue
        if raw_line and not raw_line.startswith(" "):
            break

        package_match = package_re.match(raw_line)
        if package_match:
            current = package_match.group(1)
            packages[current] = {}
            continue

        field_match = field_re.match(raw_line)
        if current and field_match:
            value = field_match.group(2).strip().strip('"')
            packages[current][field_match.group(1)] = value

    if not packages:
        raise RuntimeError("No packages parsed from pubspec.lock")
    return packages


def resolve_root_uri(root_uri: str, config_path: Path) -> Path:
    parsed = urlparse(root_uri)
    if parsed.scheme == "file":
        return Path(unquote(parsed.path))
    if parsed.scheme:
        raise ValueError(f"Unsupported package root URI: {root_uri}")
    return (config_path.parent / unquote(root_uri)).resolve()


def package_roots(config_path: Path) -> dict[str, Path]:
    payload = json.loads(config_path.read_text(encoding="utf-8"))
    roots: dict[str, Path] = {}
    for package in payload.get("packages", []):
        name = package.get("name")
        root_uri = package.get("rootUri")
        if not name or not root_uri:
            continue
        try:
            roots[name] = resolve_root_uri(root_uri, config_path)
        except ValueError:
            continue
    return roots


def license_candidates(package_root: Path) -> list[Path]:
    if not package_root.exists():
        return []
    candidates: list[Path] = []
    for child in package_root.iterdir():
        if not child.is_file():
            continue
        lowered = child.name.lower()
        if (
            lowered.startswith("license")
            or lowered.startswith("licence")
            or lowered.startswith("copying")
            or lowered.startswith("notice")
        ):
            candidates.append(child)
    return sorted(candidates, key=lambda item: item.name.lower())


def detect_license_family(text: str) -> str:
    normalized = " ".join(text.lower().split())
    if "apache license" in normalized and "version 2.0" in normalized:
        return "Apache-2.0"
    if "mozilla public license" in normalized and "version 2.0" in normalized:
        return "MPL-2.0"
    if "permission is hereby granted, free of charge" in normalized:
        return "MIT"
    if "redistribution and use in source and binary forms" in normalized:
        if "neither the name" in normalized:
            return "BSD-3-Clause"
        return "BSD-2-Clause"
    if "permission to use, copy, modify, and/or distribute this software" in normalized:
        return "ISC"
    if "gnu lesser general public license" in normalized and "version 3" in normalized:
        return "LGPL-3.0"
    if "gnu general public license" in normalized and "version 3" in normalized:
        return "GPL-3.0"
    if "unicode license agreement" in normalized:
        return "Unicode"
    if "zlib license" in normalized or "this software is provided 'as-is'" in normalized:
        return "Zlib-like"
    return "Unclassified"


def dependency_reports() -> tuple[str, str]:
    lock_path = ROOT / "pubspec.lock"
    config_path = ROOT / ".dart_tool" / "package_config.json"
    if not config_path.exists():
        raise RuntimeError("Run flutter pub get before generating dependency reports")

    packages = parse_pubspec_lock(lock_path)
    roots = package_roots(config_path)
    rows: list[dict[str, str]] = []

    for name in sorted(packages, key=str.lower):
        metadata = packages[name]
        root = roots.get(name)
        candidates = license_candidates(root) if root else []
        evidence_parts: list[str] = []
        families: list[str] = []
        hashes: list[str] = []

        for candidate in candidates:
            data = candidate.read_bytes()
            text = data.decode("utf-8", errors="replace")
            evidence_parts.append(candidate.name)
            families.append(detect_license_family(text))
            hashes.append(sha256_bytes(data))

        unique_families = sorted(set(families))
        family = " + ".join(unique_families) if unique_families else "Missing evidence"
        rows.append(
            {
                "package": name,
                "version": metadata.get("version", ""),
                "dependency": metadata.get("dependency", ""),
                "source": metadata.get("source", ""),
                "detected_license": family,
                "license_files": ";".join(evidence_parts),
                "license_sha256": ";".join(hashes),
                "package_url": f"https://pub.dev/packages/{name}"
                if metadata.get("source") == "hosted"
                else "",
            }
        )

    csv_buffer = io.StringIO()
    writer = csv.DictWriter(csv_buffer, fieldnames=list(rows[0].keys()), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)

    family_counts = Counter(row["detected_license"] for row in rows)
    direct_main = sum(row["dependency"] == "direct main" for row in rows)
    direct_dev = sum(row["dependency"] == "direct dev" for row in rows)
    missing = sum(row["detected_license"] == "Missing evidence" for row in rows)
    lock_hash = sha256_file(lock_path)

    lines = [
        "# Dependency licence report",
        "",
        "This report is generated from `pubspec.lock` and the licence files installed by `flutter pub get`.",
        "Detection is heuristic and is not a substitute for legal review. The original licence files remain authoritative.",
        "",
        f"- Packages in lockfile: **{len(rows)}**",
        f"- Direct runtime dependencies: **{direct_main}**",
        f"- Direct development dependencies: **{direct_dev}**",
        f"- Packages without a root-level licence/notice file: **{missing}**",
        f"- `pubspec.lock` SHA-256: `{lock_hash}`",
        "",
        "## Detected licence families",
        "",
        "| Detected family | Packages |",
        "|---|---:|",
    ]
    for family, count in sorted(family_counts.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"| {family} | {count} |")
    lines.extend(
        [
            "",
            "## Detailed inventory",
            "",
            "The machine-readable inventory is stored in `docs/compliance/dependency-licenses.csv`.",
            "It records package name, locked version, dependency class, source, detected family, licence filenames, hashes, and the pub.dev reference when applicable.",
            "",
            "## Release rule",
            "",
            "Before a public release, every `Missing evidence` or `Unclassified` entry must be reviewed manually and the licence text supplied by Flutter's runtime `LicenseRegistry` must be compared with this report.",
            "",
        ]
    )
    return csv_buffer.getvalue(), "\n".join(lines)


def asset_family(relative: Path) -> str:
    parts = relative.parts
    if len(parts) < 2:
        return relative.as_posix()

    candidates = [
        "/".join(parts[:4]),
        "/".join(parts[:3]),
        "/".join(parts[:2]),
    ]
    for candidate in candidates:
        if candidate in ASSET_POLICY:
            return candidate
    return "/".join(parts[:2])


def evidence_for(path: Path) -> list[str]:
    evidence: list[str] = []
    current = path.parent
    assets_root = ROOT / "assets"
    while True:
        if current.exists():
            for child in current.iterdir():
                if child.is_file() and child.name.lower() in EVIDENCE_NAMES:
                    relative = child.relative_to(ROOT)
                    if relative not in GENERATED_RELEASE_ASSETS:
                        evidence.append(relative.as_posix())
        if current == assets_root or assets_root not in current.parents:
            break
        current = current.parent
    return sorted(set(evidence))


def asset_reports() -> tuple[str, str]:
    assets_root = ROOT / "assets"
    files = sorted(
        (
            path
            for path in assets_root.rglob("*")
            if path.is_file()
            and path.relative_to(ROOT) not in GENERATED_RELEASE_ASSETS
        ),
        key=lambda item: item.as_posix().lower(),
    )
    if not files:
        raise RuntimeError("No assets found")

    rows: list[dict[str, str | int]] = []
    family_stats: dict[str, dict[str, int]] = defaultdict(lambda: {"files": 0, "bytes": 0, "with_evidence": 0})
    policy_counts = Counter()

    for path in files:
        relative = path.relative_to(ROOT)
        family = asset_family(relative)
        policy_status, action = ASSET_POLICY.get(
            family,
            ("unclassified", "Add a provenance and licence record before public redistribution."),
        )
        evidence = evidence_for(path)
        size = path.stat().st_size
        digest = sha256_file(path)
        extension = path.suffix.lower() or "[none]"
        is_evidence_file = path.name.lower() in EVIDENCE_NAMES

        rows.append(
            {
                "path": relative.as_posix(),
                "family": family,
                "extension": extension,
                "size_bytes": size,
                "sha256": digest,
                "policy_status": policy_status,
                "evidence_files": ";".join(evidence),
                "is_evidence_file": str(is_evidence_file).lower(),
                "required_action": action,
            }
        )
        family_stats[family]["files"] += 1
        family_stats[family]["bytes"] += size
        if evidence:
            family_stats[family]["with_evidence"] += 1
        policy_counts[policy_status] += 1

    csv_buffer = io.StringIO()
    writer = csv.DictWriter(csv_buffer, fieldnames=list(rows[0].keys()), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)

    total_bytes = sum(int(row["size_bytes"]) for row in rows)
    with_evidence = sum(bool(row["evidence_files"]) for row in rows)
    lines = [
        "# Asset audit summary",
        "",
        "This report scans every file below `assets/` and records path, size, SHA-256, policy family, and nearby attribution/licence evidence.",
        "The presence of an attribution file does not prove that redistribution is authorised.",
        "",
        f"- Asset files: **{len(rows)}**",
        f"- Total asset size: **{human_bytes(total_bytes)}**",
        f"- Files with nearby attribution/licence evidence: **{with_evidence}**",
        f"- Files without nearby evidence: **{len(rows) - with_evidence}**",
        "",
        "## Policy status",
        "",
        "| Status | Files |",
        "|---|---:|",
    ]
    for status, count in sorted(policy_counts.items(), key=lambda item: (-item[1], item[0])):
        lines.append(f"| {status} | {count} |")

    lines.extend(
        [
            "",
            "## Families",
            "",
            "| Family | Files | Size | With evidence |",
            "|---|---:|---:|---:|",
        ]
    )
    for family, stats in sorted(family_stats.items()):
        lines.append(
            f"| `{family}` | {stats['files']} | {human_bytes(stats['bytes'])} | {stats['with_evidence']} |"
        )

    lines.extend(
        [
            "",
            "## Machine-readable inventory",
            "",
            "The complete file-level report is stored in `docs/compliance/asset-manifest.csv`.",
            "A public build must not treat `unverified`, `not-cleared`, `mixed`, or `unclassified` as permission to redistribute.",
            "",
        ]
    )
    return csv_buffer.getvalue(), "\n".join(lines)


def validate_full_gpl() -> None:
    license_path = ROOT / "LICENSE"
    if not license_path.exists():
        raise RuntimeError("LICENSE is missing")
    text = license_path.read_text(encoding="utf-8")
    required = [
        "GNU GENERAL PUBLIC LICENSE",
        "Version 3, 29 June 2007",
        "TERMS AND CONDITIONS",
        "17. Interpretation of Sections 15 and 16.",
        "END OF TERMS AND CONDITIONS",
        "How to Apply These Terms to Your New Programs",
    ]
    missing = [marker for marker in required if marker not in text]
    if missing:
        raise RuntimeError(f"LICENSE is not the complete GPLv3 text; missing: {missing}")


def write_or_check(path: Path, content: str, check: bool) -> None:
    normalized = content.rstrip() + "\n"
    if check:
        if not path.exists():
            raise RuntimeError(f"Generated file is missing: {path.relative_to(ROOT)}")
        current = path.read_text(encoding="utf-8")
        if current != normalized:
            raise RuntimeError(f"Generated file is stale: {path.relative_to(ROOT)}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(normalized, encoding="utf-8", newline="\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate deterministic compliance inventories")
    parser.add_argument("--check", action="store_true", help="Fail when committed reports are missing or stale")
    args = parser.parse_args()

    validate_full_gpl()
    dependency_csv, dependency_md = dependency_reports()
    asset_csv, asset_md = asset_reports()

    write_or_check(DEPENDENCY_CSV, dependency_csv, args.check)
    write_or_check(DEPENDENCY_MD, dependency_md, args.check)
    write_or_check(ASSET_CSV, asset_csv, args.check)
    write_or_check(ASSET_MD, asset_md, args.check)

    mode = "verified" if args.check else "generated"
    print(f"Compliance reports {mode} successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
