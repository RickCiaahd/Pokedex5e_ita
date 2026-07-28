from __future__ import annotations

import argparse
import csv
import hashlib
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageFile

DEFAULT_ROOT = Path("assets/textures/textures_webapp/pokemon")
DEFAULT_TARGETS = Path("docs/performance/unreadable-pokemon-images.csv")
DEFAULT_REPORT = Path("docs/performance/repaired-pokemon-images.csv")
SUPPORTED_SUFFIXES = {".png", ".webp", ".jpg", ".jpeg"}


@dataclass(frozen=True)
class RepairResult:
    path: str
    width: int
    height: int
    original_bytes: int
    repaired_bytes: int
    original_sha256: str
    repaired_sha256: str
    pixel_sha256: str
    status: str


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strict_load(path: Path) -> tuple[int, int, str]:
    previous = ImageFile.LOAD_TRUNCATED_IMAGES
    ImageFile.LOAD_TRUNCATED_IMAGES = False
    try:
        with Image.open(path) as image:
            image.load()
            rgba = image.convert("RGBA")
            width, height = rgba.size
            pixel_hash = sha256_bytes(rgba.tobytes())
    finally:
        ImageFile.LOAD_TRUNCATED_IMAGES = previous
    return width, height, pixel_hash


def tolerant_load(path: Path) -> Image.Image:
    previous = ImageFile.LOAD_TRUNCATED_IMAGES
    ImageFile.LOAD_TRUNCATED_IMAGES = True
    try:
        with Image.open(path) as image:
            image.load()
            repaired = image.convert("RGBA")
            repaired.load()
            return repaired.copy()
    finally:
        ImageFile.LOAD_TRUNCATED_IMAGES = previous


def repair_one(path: Path, repository_root: Path) -> RepairResult:
    relative = path.relative_to(repository_root).as_posix()
    original_bytes = path.stat().st_size
    original_sha = sha256_file(path)

    try:
        width, height, pixel_hash = strict_load(path)
        return RepairResult(
            path=relative,
            width=width,
            height=height,
            original_bytes=original_bytes,
            repaired_bytes=original_bytes,
            original_sha256=original_sha,
            repaired_sha256=original_sha,
            pixel_sha256=pixel_hash,
            status="already-valid",
        )
    except Exception:
        pass

    repaired_image = tolerant_load(path)
    width, height = repaired_image.size
    source_pixel_hash = sha256_bytes(repaired_image.tobytes())
    if width <= 0 or height <= 0:
        raise RuntimeError(f"Invalid dimensions recovered from {relative}: {width}x{height}")
    if repaired_image.getbbox() is None:
        raise RuntimeError(f"Recovered image is fully empty: {relative}")

    with tempfile.NamedTemporaryFile(
        prefix=f"{path.stem}-",
        suffix=".png",
        dir=path.parent,
        delete=False,
    ) as handle:
        temporary = Path(handle.name)

    try:
        repaired_image.save(
            temporary,
            format="PNG",
            optimize=True,
            compress_level=9,
        )
        checked_width, checked_height, checked_pixel_hash = strict_load(temporary)
        if (checked_width, checked_height) != (width, height):
            raise RuntimeError(
                f"Dimensions changed while repairing {relative}: "
                f"{width}x{height} -> {checked_width}x{checked_height}"
            )
        if checked_pixel_hash != source_pixel_hash:
            raise RuntimeError(f"Decoded pixels changed while repairing {relative}")
        temporary.replace(path)
    finally:
        if temporary.exists():
            temporary.unlink()

    return RepairResult(
        path=relative,
        width=width,
        height=height,
        original_bytes=original_bytes,
        repaired_bytes=path.stat().st_size,
        original_sha256=original_sha,
        repaired_sha256=sha256_file(path),
        pixel_sha256=source_pixel_hash,
        status="repaired-pixel-identical",
    )


def repository_root_for(path: Path) -> Path:
    resolved = path.resolve()
    for candidate in (resolved, *resolved.parents):
        if (candidate / "pubspec.yaml").exists():
            return candidate
    raise RuntimeError(f"Unable to locate repository root from {path}")


def read_targets(path: Path, repository_root: Path) -> list[Path]:
    targets: list[Path] = []
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or "path" not in reader.fieldnames:
            raise RuntimeError(f"Missing 'path' column in {path}")
        for row in reader:
            value = (row.get("path") or "").strip()
            if not value:
                continue
            candidate = (repository_root / value).resolve()
            try:
                candidate.relative_to(repository_root)
            except ValueError as error:
                raise RuntimeError(f"Target escapes repository root: {value}") from error
            if candidate.suffix.lower() != ".png":
                raise RuntimeError(f"Repair target is not a PNG: {value}")
            if not candidate.is_file():
                raise RuntimeError(f"Repair target does not exist: {value}")
            targets.append(candidate)
    if not targets:
        raise RuntimeError(f"No repair targets found in {path}")
    return targets


def write_report(path: Path, results: list[RepairResult]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            [
                "path",
                "status",
                "width",
                "height",
                "original_bytes",
                "repaired_bytes",
                "saved_bytes",
                "original_sha256",
                "repaired_sha256",
                "pixel_sha256",
            ]
        )
        for result in results:
            writer.writerow(
                [
                    result.path,
                    result.status,
                    result.width,
                    result.height,
                    result.original_bytes,
                    result.repaired_bytes,
                    result.original_bytes - result.repaired_bytes,
                    result.original_sha256,
                    result.repaired_sha256,
                    result.pixel_sha256,
                ]
            )


def clear_unreadable_list(path: Path) -> None:
    path.write_text("path,size_bytes\n", encoding="utf-8", newline="\n")


def find_unreadable(root: Path) -> list[tuple[str, str]]:
    repository_root = repository_root_for(root)
    failures: list[tuple[str, str]] = []
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix().lower()):
        if not path.is_file() or path.suffix.lower() not in SUPPORTED_SUFFIXES:
            continue
        try:
            strict_load(path)
        except Exception as error:
            failures.append((path.relative_to(repository_root).as_posix(), str(error)))
    return failures


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        repository_root = Path(directory)
        (repository_root / "pubspec.yaml").write_text(
            "name: repair_test\n",
            encoding="utf-8",
        )
        root = repository_root / DEFAULT_ROOT
        root.mkdir(parents=True)
        valid = root / "valid.png"
        Image.new("RGBA", (16, 12), (20, 40, 60, 128)).save(valid, format="PNG")
        result = repair_one(valid, repository_root)
        assert result.status == "already-valid"
        assert result.width == 16 and result.height == 12
        assert not find_unreadable(root)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--targets", type=Path, default=DEFAULT_TARGETS)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--repair-listed", action="store_true")
    parser.add_argument("--check-all", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        self_test()

    if not args.repair_listed and not args.check_all:
        if args.self_test:
            return 0
        raise RuntimeError("Choose --repair-listed and/or --check-all")

    root = args.root.resolve()
    repository_root = repository_root_for(root)

    if args.repair_listed:
        targets_path = (repository_root / args.targets).resolve()
        report_path = (repository_root / args.report).resolve()
        targets = read_targets(targets_path, repository_root)
        results = [repair_one(path, repository_root) for path in targets]
        write_report(report_path, results)
        failures = find_unreadable(root)
        if failures:
            formatted = "\n".join(f"- {path}: {error}" for path, error in failures)
            raise RuntimeError(f"Unreadable images remain after repair:\n{formatted}")
        clear_unreadable_list(targets_path)
        repaired = sum(result.status == "repaired-pixel-identical" for result in results)
        saved = sum(result.original_bytes - result.repaired_bytes for result in results)
        print(f"Repaired {repaired} images; lossless byte saving: {saved} bytes")

    if args.check_all:
        failures = find_unreadable(root)
        if failures:
            formatted = "\n".join(f"- {path}: {error}" for path, error in failures)
            raise RuntimeError(f"Unreadable image assets detected:\n{formatted}")
        print(f"All image assets below {root} are readable")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
