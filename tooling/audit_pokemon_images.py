from __future__ import annotations

import argparse
import csv
import io
import math
import statistics
import tempfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image

DEFAULT_ROOT = Path("assets/textures/textures_webapp/pokemon")
DEFAULT_OUTPUT = Path("build/reports/image-optimization-audit")

GENDER_MARKERS = ("-f", "_f", "-m", "_m", "female", "male")
FORM_MARKERS = (
    "alola",
    "alolan",
    "galar",
    "galarian",
    "hisui",
    "hisuian",
    "paldea",
    "paldean",
    "mega",
    "primal",
    "origin",
    "therian",
    "incarnate",
    "dusk-mane",
    "dawn-wings",
    "ultra",
    "school",
    "meteor",
    "core",
    "blade",
    "shield",
    "crowned",
    "eternamax",
    "totem",
)


@dataclass(frozen=True)
class ImageRecord:
    path: str
    file_name: str
    format: str
    mode: str
    width: int
    height: int
    size_bytes: int
    has_alpha: bool
    is_animated: bool
    tags: tuple[str, ...]

    @property
    def pixels(self) -> int:
        return self.width * self.height

    @property
    def max_dimension(self) -> int:
        return max(self.width, self.height)

    @property
    def bytes_per_pixel(self) -> float:
        return self.size_bytes / self.pixels if self.pixels else 0.0

    @property
    def primary_role(self) -> str:
        for role in ("sprite", "gender", "shiny", "form", "standard"):
            if role in self.tags:
                return role
        return "other"


@dataclass(frozen=True)
class CompressionRecord:
    path: str
    role: str
    original_bytes: int
    optimized_png_bytes: int
    lossless_webp_bytes: int

    @property
    def png_saved(self) -> int:
        return self.original_bytes - self.optimized_png_bytes

    @property
    def webp_saved(self) -> int:
        return self.original_bytes - self.lossless_webp_bytes

    @property
    def png_ratio(self) -> float:
        return self.png_saved / self.original_bytes if self.original_bytes else 0.0

    @property
    def webp_ratio(self) -> float:
        return self.webp_saved / self.original_bytes if self.original_bytes else 0.0


def human_bytes(value: int) -> str:
    units = ("B", "KiB", "MiB", "GiB")
    amount = float(value)
    for unit in units:
        if amount < 1024 or unit == units[-1]:
            return f"{amount:.1f} {unit}" if unit != "B" else f"{int(amount)} B"
        amount /= 1024
    return f"{value} B"


def percent(value: float) -> str:
    return f"{value * 100:.1f}%"


def classify_tags(path: Path) -> tuple[str, ...]:
    normalized = path.as_posix().lower()
    stem = path.stem.lower()
    tags: list[str] = []

    if "sprite" in stem:
        tags.append("sprite")
    if "shiny" in stem:
        tags.append("shiny")
    if any(marker in normalized for marker in GENDER_MARKERS):
        tags.append("gender")
    if any(marker in normalized for marker in FORM_MARKERS):
        tags.append("form")

    if stem in {"main", "main-shiny", "sprite", "sprite-shiny"}:
        tags.append("standard")
    elif not tags:
        tags.append("other")

    return tuple(dict.fromkeys(tags))


def repository_root_for(root: Path) -> Path:
    for candidate in (root, *root.parents):
        if (candidate / "pubspec.yaml").exists():
            return candidate
    raise RuntimeError(f"Unable to locate repository root from {root}")


def read_image(path: Path, root: Path, repository_root: Path) -> ImageRecord:
    with Image.open(path) as image:
        image_format = image.format or path.suffix.lstrip(".").upper()
        mode = image.mode
        has_alpha = "A" in image.getbands() or "transparency" in image.info
        is_animated = bool(getattr(image, "is_animated", False))
        width, height = image.size

    return ImageRecord(
        path=path.relative_to(repository_root).as_posix(),
        file_name=path.name,
        format=image_format,
        mode=mode,
        width=width,
        height=height,
        size_bytes=path.stat().st_size,
        has_alpha=has_alpha,
        is_animated=is_animated,
        tags=classify_tags(path.relative_to(root)),
    )


def scan_images(root: Path) -> tuple[Path, list[ImageRecord]]:
    repository_root = repository_root_for(root)
    paths = sorted(
        (
            path
            for path in root.rglob("*")
            if path.is_file()
            and path.suffix.lower() in {".png", ".webp", ".jpg", ".jpeg"}
        ),
        key=lambda value: value.as_posix().lower(),
    )
    if not paths:
        raise RuntimeError(f"No supported images found below {root}")

    records: list[ImageRecord] = []
    failures: list[str] = []
    for path in paths:
        try:
            records.append(read_image(path, root, repository_root))
        except Exception as error:  # pragma: no cover - printed by the CI audit
            failures.append(f"{path}: {error}")

    if failures:
        preview = "\n".join(failures[:20])
        raise RuntimeError(
            f"Unable to inspect {len(failures)} image(s). First failures:\n{preview}"
        )
    return repository_root, records


def deterministic_sample(records: list[ImageRecord], limit: int) -> list[ImageRecord]:
    if limit <= 0 or limit >= len(records):
        return list(records)

    selected: dict[str, ImageRecord] = {}

    def add(items: Iterable[ImageRecord], count: int) -> None:
        for record in items:
            if len(selected) >= limit or count <= 0:
                return
            if record.path in selected:
                continue
            selected[record.path] = record
            count -= 1

    add(
        sorted(records, key=lambda item: (-item.size_bytes, item.path)),
        max(1, limit // 3),
    )

    roles = ("standard", "shiny", "sprite", "gender", "form", "other")
    remaining = limit - len(selected)
    per_role = max(1, math.ceil(remaining / len(roles)))
    for role in roles:
        role_records = [
            record
            for record in records
            if role in record.tags or record.primary_role == role
        ]
        add(
            sorted(
                role_records,
                key=lambda item: (-item.size_bytes, -item.max_dimension, item.path),
            ),
            per_role,
        )

    if len(selected) < limit:
        add(sorted(records, key=lambda item: item.path), limit - len(selected))
    return list(selected.values())


def encode_size(path: Path, output_format: str) -> int:
    with Image.open(path) as image:
        if getattr(image, "is_animated", False):
            raise ValueError("Animated images are not part of the conversion pilot")
        image.load()
        with io.BytesIO() as buffer:
            if output_format == "PNG":
                image.save(buffer, format="PNG", optimize=True, compress_level=9)
            elif output_format == "WEBP":
                image.save(
                    buffer,
                    format="WEBP",
                    lossless=True,
                    quality=100,
                    method=6,
                    exact=True,
                )
            else:
                raise ValueError(f"Unsupported output format: {output_format}")
            return len(buffer.getvalue())


def compression_pilot(
    repository_root: Path,
    records: list[ImageRecord],
    sample_limit: int,
) -> list[CompressionRecord]:
    sample = deterministic_sample(records, sample_limit)
    results: list[CompressionRecord] = []
    for record in sample:
        source = repository_root / record.path
        results.append(
            CompressionRecord(
                path=record.path,
                role=record.primary_role,
                original_bytes=record.size_bytes,
                optimized_png_bytes=encode_size(source, "PNG"),
                lossless_webp_bytes=encode_size(source, "WEBP"),
            )
        )
    return results


def write_inventory(path: Path, records: list[ImageRecord]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            [
                "path",
                "file_name",
                "format",
                "mode",
                "width",
                "height",
                "pixels",
                "max_dimension",
                "size_bytes",
                "bytes_per_pixel",
                "has_alpha",
                "is_animated",
                "primary_role",
                "tags",
                "candidate_over_512",
                "candidate_over_768",
                "candidate_over_1024",
            ]
        )
        for record in records:
            writer.writerow(
                [
                    record.path,
                    record.file_name,
                    record.format,
                    record.mode,
                    record.width,
                    record.height,
                    record.pixels,
                    record.max_dimension,
                    record.size_bytes,
                    f"{record.bytes_per_pixel:.6f}",
                    str(record.has_alpha).lower(),
                    str(record.is_animated).lower(),
                    record.primary_role,
                    ";".join(record.tags),
                    str(record.max_dimension > 512).lower(),
                    str(record.max_dimension > 768).lower(),
                    str(record.max_dimension > 1024).lower(),
                ]
            )


def write_compression_csv(path: Path, records: list[CompressionRecord]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            [
                "path",
                "role",
                "original_bytes",
                "optimized_png_bytes",
                "lossless_webp_bytes",
                "optimized_png_saved_bytes",
                "lossless_webp_saved_bytes",
                "optimized_png_saved_percent",
                "lossless_webp_saved_percent",
            ]
        )
        for record in records:
            writer.writerow(
                [
                    record.path,
                    record.role,
                    record.original_bytes,
                    record.optimized_png_bytes,
                    record.lossless_webp_bytes,
                    record.png_saved,
                    record.webp_saved,
                    f"{record.png_ratio * 100:.4f}",
                    f"{record.webp_ratio * 100:.4f}",
                ]
            )


def role_rows(records: list[ImageRecord]) -> list[tuple[str, int, int, int, int]]:
    grouped: dict[str, list[ImageRecord]] = defaultdict(list)
    for record in records:
        grouped[record.primary_role].append(record)

    rows: list[tuple[str, int, int, int, int]] = []
    for role, items in grouped.items():
        rows.append(
            (
                role,
                len(items),
                sum(item.size_bytes for item in items),
                sum(item.max_dimension > 512 for item in items),
                sum(item.max_dimension > 1024 for item in items),
            )
        )
    return sorted(rows, key=lambda row: (-row[2], row[0]))


def compression_summary(
    pilot: list[CompressionRecord],
) -> tuple[int, int, int, float, float]:
    original = sum(item.original_bytes for item in pilot)
    png = sum(item.optimized_png_bytes for item in pilot)
    webp = sum(item.lossless_webp_bytes for item in pilot)
    png_ratio = (original - png) / original if original else 0.0
    webp_ratio = (original - webp) / original if original else 0.0
    return original, png, webp, png_ratio, webp_ratio


def build_markdown(
    records: list[ImageRecord],
    pilot: list[CompressionRecord],
    root: Path,
) -> str:
    total_size = sum(item.size_bytes for item in records)
    alpha_count = sum(item.has_alpha for item in records)
    animated_count = sum(item.is_animated for item in records)
    dimensions = [item.max_dimension for item in records]
    original, png, webp, png_ratio, webp_ratio = compression_summary(pilot)

    lines = [
        "# Pokémon image optimisation audit",
        "",
        "This report is generated without modifying or deleting any image.",
        "It inventories the complete bundled Pokémon artwork family and runs a deterministic lossless compression pilot.",
        "",
        "## Guardrails",
        "",
        "- Every artwork, sprite, shiny, gender difference, form and transformation remains in the project.",
        "- Dimension thresholds identify review candidates only; they are not automatic resize instructions.",
        "- PNG optimisation and lossless WebP results are measured on a representative deterministic sample.",
        "- A format or resolution change must not be applied globally before visual regression checks on Android, Windows and web.",
        "",
        "## Inventory",
        "",
        f"- Root: `{root.as_posix()}`",
        f"- Images scanned: **{len(records)}**",
        f"- Source size: **{human_bytes(total_size)}** ({total_size} bytes)",
        f"- Images with alpha/transparency: **{alpha_count}**",
        f"- Animated images: **{animated_count}**",
        f"- Median maximum dimension: **{statistics.median(dimensions):.0f}px**",
        f"- Maximum dimension found: **{max(dimensions)}px**",
        f"- Candidates above 512px: **{sum(item.max_dimension > 512 for item in records)}**",
        f"- Candidates above 768px: **{sum(item.max_dimension > 768 for item in records)}**",
        f"- Candidates above 1024px: **{sum(item.max_dimension > 1024 for item in records)}**",
        "",
        "### Primary roles",
        "",
        "| Role | Files | Size | Above 512px | Above 1024px |",
        "|---|---:|---:|---:|---:|",
    ]
    for role, count, size, large, very_large in role_rows(records):
        lines.append(
            f"| `{role}` | {count} | {human_bytes(size)} | {large} | {very_large} |"
        )

    lines.extend(
        [
            "",
            "### Largest source images",
            "",
            "| Path | Dimensions | Size | Role | Alpha |",
            "|---|---:|---:|---|---|",
        ]
    )
    for record in sorted(records, key=lambda item: (-item.size_bytes, item.path))[:30]:
        lines.append(
            f"| `{record.path}` | {record.width}×{record.height} | "
            f"{human_bytes(record.size_bytes)} | `{record.primary_role}` | "
            f"{'yes' if record.has_alpha else 'no'} |"
        )

    lines.extend(
        [
            "",
            "## Deterministic lossless pilot",
            "",
            f"- Sample files: **{len(pilot)}**",
            f"- Original sample size: **{human_bytes(original)}**",
            f"- Re-encoded optimized PNG size: **{human_bytes(png)}** ({percent(png_ratio)} smaller)",
            f"- Re-encoded lossless WebP size: **{human_bytes(webp)}** ({percent(webp_ratio)} smaller)",
            "",
            "These percentages describe only the measured sample and must not be blindly extrapolated to every asset. The detailed per-file results are stored in `compression-pilot.csv`.",
            "",
            "### Best lossless WebP candidates in the sample",
            "",
            "| Path | Original | Lossless WebP | Saving |",
            "|---|---:|---:|---:|",
        ]
    )
    for item in sorted(pilot, key=lambda value: (-value.webp_saved, value.path))[:25]:
        lines.append(
            f"| `{item.path}` | {human_bytes(item.original_bytes)} | "
            f"{human_bytes(item.lossless_webp_bytes)} | "
            f"{human_bytes(item.webp_saved)} ({percent(item.webp_ratio)}) |"
        )

    lines.extend(
        [
            "",
            "## Safe next step",
            "",
            "1. Keep the current complete PNG bundle as the reference baseline.",
            "2. Select a small pilot batch covering standard, shiny, sprite, gender and form assets.",
            "3. Compare optimized PNG and lossless WebP visually at native size and at the largest in-app render size.",
            "4. Apply only a reversible batch with path compatibility tests and full Android/Windows/web builds.",
            "5. Measure the complete APK/AAB again before expanding the conversion.",
            "",
        ]
    )
    return "\n".join(lines)


def self_test() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        repository_root = Path(temp_dir)
        (repository_root / "pubspec.yaml").write_text("name: audit_test\n", encoding="utf-8")
        root = repository_root / DEFAULT_ROOT
        image_path = root / "sample-form" / "main-f-shiny.png"
        image_path.parent.mkdir(parents=True)
        Image.new("RGBA", (64, 32), (255, 0, 0, 128)).save(image_path, format="PNG")

        detected_root, records = scan_images(root)
        assert detected_root == repository_root
        assert len(records) == 1
        record = records[0]
        assert record.width == 64 and record.height == 32
        assert record.has_alpha
        assert "shiny" in record.tags
        assert "gender" in record.tags
        pilot = compression_pilot(repository_root, records, 1)
        assert len(pilot) == 1
        assert pilot[0].optimized_png_bytes > 0
        assert pilot[0].lossless_webp_bytes > 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--sample-limit", type=int, default=120)
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        self_test()

    root = args.root.resolve()
    output_dir = args.output_dir.resolve()
    repository_root, records = scan_images(root)
    pilot = compression_pilot(repository_root, records, args.sample_limit)

    write_inventory(output_dir / "image-inventory.csv", records)
    write_compression_csv(output_dir / "compression-pilot.csv", pilot)
    report = build_markdown(records, pilot, root.relative_to(repository_root))
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "image-optimization-audit.md").write_text(
        report,
        encoding="utf-8",
        newline="\n",
    )
    print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
