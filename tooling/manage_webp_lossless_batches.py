from __future__ import annotations

import argparse
from concurrent.futures import ProcessPoolExecutor
from functools import partial
import csv
import hashlib
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageFile

ROOT = Path(__file__).resolve().parents[1]
IMAGE_ROOT = ROOT / 'assets/textures/textures_webapp/pokemon'
PILOT = ROOT / 'docs/performance/webp-lossless-pilot.csv'
CANDIDATES = ROOT / 'docs/performance/webp-lossless-candidates.csv'
CONVERSIONS = ROOT / 'docs/performance/webp-lossless-conversions.csv'
SUMMARY = ROOT / 'docs/performance/webp-lossless-migration.md'


@dataclass(frozen=True)
class Entry:
    png: str
    webp: str
    width: int
    height: int
    png_bytes: int
    webp_bytes: int
    pixel_hash: str
    batch: str = ''
    eligible: bool = True
    reason: str = 'eligible'

    @property
    def saved(self) -> int:
        return self.png_bytes - self.webp_bytes

    @property
    def percent(self) -> float:
        return self.saved * 100 / self.png_bytes if self.png_bytes else 0.0


def rgba(path: Path) -> Image.Image:
    old = ImageFile.LOAD_TRUNCATED_IMAGES
    ImageFile.LOAD_TRUNCATED_IMAGES = False
    try:
        with Image.open(path) as image:
            image.load()
            return image.convert('RGBA').copy()
    finally:
        ImageFile.LOAD_TRUNCATED_IMAGES = old


def pixel_hash(image: Image.Image) -> str:
    return hashlib.sha256(image.tobytes()).hexdigest()


def encode(source: Path, directory: Path) -> tuple[Path, Image.Image]:
    original = rgba(source)
    with tempfile.NamedTemporaryFile(
        prefix=f'{source.stem}-', suffix='.webp', dir=directory, delete=False
    ) as handle:
        temporary = Path(handle.name)
    try:
        original.save(
            temporary,
            format='WEBP',
            lossless=True,
            exact=True,
            method=6,
        )
        converted = rgba(temporary)
        if converted.size != original.size or converted.tobytes() != original.tobytes():
            raise RuntimeError(f'Lossless verification failed: {source}')
        return temporary, original
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def png_files() -> list[Path]:
    return sorted(
        (path for path in IMAGE_ROOT.rglob('*.png') if path.is_file()),
        key=lambda path: path.relative_to(ROOT).as_posix().lower(),
    )


def inspect(path: Path, min_bytes: int, min_percent: float) -> Entry:
    temporary, original = encode(path, Path(tempfile.gettempdir()))
    try:
        png_size = path.stat().st_size
        webp_size = temporary.stat().st_size
        saved = png_size - webp_size
        percent = saved * 100 / png_size if png_size else 0.0
        if saved <= 0:
            eligible, reason = False, 'webp-not-smaller'
        elif saved < min_bytes:
            eligible, reason = False, 'below-byte-threshold'
        elif percent < min_percent:
            eligible, reason = False, 'below-percent-threshold'
        else:
            eligible, reason = True, 'eligible'
        rel = path.relative_to(ROOT).as_posix()
        return Entry(
            rel,
            path.with_suffix('.webp').relative_to(ROOT).as_posix(),
            original.width,
            original.height,
            png_size,
            webp_size,
            pixel_hash(original),
            eligible=eligible,
            reason=reason,
        )
    finally:
        temporary.unlink(missing_ok=True)


def scan(min_bytes: int, min_percent: float) -> list[Entry]:
    paths = png_files()
    worker = partial(inspect, min_bytes=min_bytes, min_percent=min_percent)
    result: list[Entry] = []
    with ProcessPoolExecutor(max_workers=4) as executor:
        for index, item in enumerate(
            executor.map(worker, paths, chunksize=16),
            1,
        ):
            result.append(item)
            if index % 250 == 0:
                print(f'Inspected {index} remaining PNG files')
    return result


def ranking(entry: Entry) -> tuple[int, float, str]:
    return (-entry.saved, -entry.percent, entry.png)


def read_history() -> list[Entry]:
    source = CONVERSIONS if CONVERSIONS.is_file() else PILOT
    if not source.is_file():
        return []
    result: list[Entry] = []
    with source.open(encoding='utf-8', newline='') as handle:
        for row in csv.DictReader(handle):
            result.append(
                Entry(
                    row['png_path'],
                    row['webp_path'],
                    int(row['width']),
                    int(row['height']),
                    int(row['png_bytes']),
                    int(row['webp_bytes']),
                    row['pixel_sha256'],
                    row.get('batch') or 'pilot-1',
                )
            )
    return result


def write_candidates(entries: list[Entry]) -> None:
    CANDIDATES.parent.mkdir(parents=True, exist_ok=True)
    with CANDIDATES.open('w', encoding='utf-8', newline='') as handle:
        writer = csv.writer(handle, lineterminator='\n')
        writer.writerow([
            'png_path', 'webp_path', 'width', 'height', 'png_bytes',
            'webp_bytes', 'saved_bytes', 'saving_percent', 'eligible',
            'reason', 'pixel_sha256',
        ])
        for item in sorted(entries, key=ranking):
            writer.writerow([
                item.png, item.webp, item.width, item.height, item.png_bytes,
                item.webp_bytes, item.saved, f'{item.percent:.4f}',
                str(item.eligible).lower(), item.reason, item.pixel_hash,
            ])


def write_history(entries: list[Entry]) -> None:
    with CONVERSIONS.open('w', encoding='utf-8', newline='') as handle:
        writer = csv.writer(handle, lineterminator='\n')
        writer.writerow([
            'png_path', 'webp_path', 'width', 'height', 'png_bytes',
            'webp_bytes', 'saved_bytes', 'saving_percent', 'pixel_sha256', 'batch',
        ])
        for item in sorted(entries, key=lambda value: value.png):
            writer.writerow([
                item.png, item.webp, item.width, item.height, item.png_bytes,
                item.webp_bytes, item.saved, f'{item.percent:.4f}',
                item.pixel_hash, item.batch,
            ])


def write_summary(
    remaining: list[Entry], history: list[Entry], label: str,
    size: int, min_bytes: int, min_percent: float,
) -> None:
    eligible = [item for item in remaining if item.eligible]
    original = sum(item.png_bytes for item in history)
    current = sum(item.webp_bytes for item in history)
    saved = original - current
    ratio = saved * 100 / original if original else 0.0
    projected = sum(item.saved for item in eligible)
    SUMMARY.write_text('\n'.join([
        '# Migrazione WebP lossless degli asset Pokémon', '',
        'La migrazione procede per blocchi reversibili. Ogni conversione mantiene ',
        'identici dimensioni e pixel RGBA e viene applicata solo quando riduce il peso.', '',
        '## Stato cumulativo', '',
        f'- File convertiti: **{len(history)}**',
        f'- PNG originale equivalente: **{original / 1048576:.2f} MiB**',
        f'- WebP lossless: **{current / 1048576:.2f} MiB**',
        f'- Risparmio: **{saved / 1048576:.2f} MiB ({ratio:.1f}%)**',
        '- Pixel RGBA modificati: **0**',
        '- Immagini o varianti eliminate: **0**', '',
        '## Scansione completa dei PNG rimanenti', '',
        f'- File controllati: **{len(remaining)}**',
        f'- Candidati oltre soglia: **{len(eligible)}**',
        f'- Risparmio teorico residuo: **{projected / 1048576:.2f} MiB**', '',
        '## Ultimo blocco', '',
        f'- Etichetta: `{label}`',
        f'- Limite: **{size}** file',
        f'- Soglia: **{min_bytes} byte** e **{min_percent:.1f}%**', '',
        'Dettagli: `webp-lossless-candidates.csv` e `webp-lossless-conversions.csv`.', '',
    ]), encoding='utf-8', newline='\n')


def convert(item: Entry, label: str) -> Entry:
    source = ROOT / item.png
    destination = ROOT / item.webp
    if not source.is_file() or destination.exists():
        raise RuntimeError(f'Invalid conversion paths: {item.png}')
    temporary, original = encode(source, source.parent)
    try:
        if temporary.stat().st_size != item.webp_bytes or pixel_hash(original) != item.pixel_hash:
            raise RuntimeError(f'Non-deterministic conversion: {item.png}')
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    source.unlink()
    return Entry(
        item.png, item.webp, item.width, item.height, item.png_bytes,
        destination.stat().st_size, item.pixel_hash, label,
    )


def verify() -> None:
    if not all(path.is_file() for path in (CANDIDATES, CONVERSIONS, SUMMARY)):
        raise RuntimeError('Missing WebP migration reports')
    history = read_history()
    if not history:
        raise RuntimeError('Empty WebP conversion history')
    converted_sources: set[str] = set()
    for item in history:
        if item.png in converted_sources:
            raise RuntimeError(f'Duplicate conversion: {item.png}')
        converted_sources.add(item.png)
        source, destination = ROOT / item.png, ROOT / item.webp
        if source.exists() or not destination.is_file():
            raise RuntimeError(f'Invalid committed conversion: {item.png}')
        image = rgba(destination)
        if image.size != (item.width, item.height):
            raise RuntimeError(f'Dimensions changed: {item.webp}')
        if pixel_hash(image) != item.pixel_hash:
            raise RuntimeError(f'Pixels changed: {item.webp}')
        if destination.stat().st_size != item.webp_bytes or item.saved <= 0:
            raise RuntimeError(f'Stale or ineffective conversion: {item.webp}')
    with CANDIDATES.open(encoding='utf-8', newline='') as handle:
        rows = list(csv.DictReader(handle))
    reported = {row['png_path'] for row in rows}
    actual = {path.relative_to(ROOT).as_posix() for path in png_files()}
    if reported != actual or reported.intersection(converted_sources):
        raise RuntimeError('Candidate report does not match remaining PNG files')


def run_apply(label: str, size: int, min_bytes: int, min_percent: float) -> None:
    candidates = scan(min_bytes, min_percent)
    selected = sorted(
        (item for item in candidates if item.eligible), key=ranking,
    )[:size]
    history = read_history()
    existing = {item.png for item in history}
    converted: list[Entry] = []
    for index, item in enumerate(selected, 1):
        if item.png in existing:
            raise RuntimeError(f'Already converted: {item.png}')
        converted.append(convert(item, label))
        print(f'Converted {index}/{len(selected)}: {item.png}')
    history += converted
    selected_paths = {item.png for item in selected}
    remaining = [item for item in candidates if item.png not in selected_paths]
    write_candidates(remaining)
    write_history(history)
    write_summary(remaining, history, label, size, min_bytes, min_percent)
    verify()
    print(f'Applied {len(converted)} conversions; saved {sum(i.saved for i in converted)/1048576:.2f} MiB')


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        source = Path(directory) / 'sample.png'
        Image.new('RGBA', (32, 24), (20, 40, 60, 120)).save(source)
        temporary, original = encode(source, Path(directory))
        try:
            assert rgba(temporary).tobytes() == original.tobytes()
        finally:
            temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--self-test', action='store_true')
    parser.add_argument('--batch-label', default='batch-2')
    parser.add_argument('--batch-size', type=int, default=150)
    parser.add_argument('--min-saved-bytes', type=int, default=4096)
    parser.add_argument('--min-saved-percent', type=float, default=5.0)
    args = parser.parse_args()
    if args.batch_size <= 0 or args.min_saved_bytes < 0 or args.min_saved_percent < 0:
        raise RuntimeError('Invalid WebP batch configuration')
    if args.self_test:
        self_test()
    if args.apply:
        run_apply(
            args.batch_label, args.batch_size,
            args.min_saved_bytes, args.min_saved_percent,
        )
    if args.check:
        verify()
    if not (args.apply or args.check or args.self_test):
        raise RuntimeError('Choose --apply, --check or --self-test')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
