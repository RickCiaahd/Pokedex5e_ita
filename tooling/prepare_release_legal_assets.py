from __future__ import annotations

import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATED = {
    ROOT / "assets" / "data" / "GPL-3.0.txt": ROOT / "LICENSE",
    ROOT / "assets" / "data" / "NOTICE.txt": ROOT / "NOTICE.md",
}


def validate_sources() -> None:
    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    required = (
        "GNU GENERAL PUBLIC LICENSE",
        "Version 3, 29 June 2007",
        "END OF TERMS AND CONDITIONS",
    )
    missing = [marker for marker in required if marker not in license_text]
    if missing:
        raise RuntimeError(f"LICENSE is incomplete; missing markers: {missing}")

    notice_text = (ROOT / "NOTICE.md").read_text(encoding="utf-8")
    if "RickCiaahd/Pokedex5e_ita" not in notice_text:
        raise RuntimeError("NOTICE.md does not identify the corresponding source repository")


def prepare(check: bool) -> None:
    validate_sources()
    for destination, source in GENERATED.items():
        if check:
            if not destination.exists():
                raise RuntimeError(f"Missing generated legal asset: {destination.relative_to(ROOT)}")
            if destination.read_bytes() != source.read_bytes():
                raise RuntimeError(f"Stale generated legal asset: {destination.relative_to(ROOT)}")
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare GPL and NOTICE files for release bundles")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    prepare(args.check)
    print("Release legal assets verified." if args.check else "Release legal assets prepared.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
