from __future__ import annotations

import argparse

from analyze_release_footprint import DUPLICATES_PATH, duplicate_report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    duplicates_csv, metrics, _top_duplicates = duplicate_report()
    if args.check:
        if not DUPLICATES_PATH.exists():
            print(f"Missing duplicate inventory: {DUPLICATES_PATH}")
            return 1
        if DUPLICATES_PATH.read_text(encoding="utf-8") != duplicates_csv:
            print("Asset duplicate inventory is stale.")
            return 1
    else:
        DUPLICATES_PATH.parent.mkdir(parents=True, exist_ok=True)
        DUPLICATES_PATH.write_text(
            duplicates_csv,
            encoding="utf-8",
            newline="\n",
        )

    print(
        "Duplicate inventory: "
        f"{metrics['duplicate_groups']} groups, "
        f"{metrics['duplicate_files']} redundant copies, "
        f"{metrics['reclaimable_bytes']} reclaimable bytes"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
