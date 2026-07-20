#!/usr/bin/env python3
"""Audit the web move catalog against Italian Pokémon move names.

The script is intentionally diagnostic: it never edits application data. It
compares the catalog with Pokémon Central (primary source) and PokéAPI
(secondary source), then writes JSON/CSV reports suitable for review.
"""

from __future__ import annotations

import csv
import io
import json
import re
import shutil
import unicodedata
from pathlib import Path
from typing import Any

import requests
from bs4 import BeautifulSoup, Tag

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "assets/data_webapp/moves.json"
OUTPUT_DIR = ROOT / "build/move_localization_audit"

POKEMON_CENTRAL_URL = (
    "https://wiki.pokemoncentral.it/Elenco_delle_mosse_in_altre_lingue"
)
POKEAPI_MOVES_URL = (
    "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/"
    "data/v2/csv/moves.csv"
)
POKEAPI_NAMES_URL = (
    "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/"
    "data/v2/csv/move_names.csv"
)
ITALIAN_LANGUAGE_ID = "8"


def _normalize(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    value = value.casefold().replace("’", "'")
    return re.sub(r"[^a-z0-9]+", "", value)


def _clean_cell(cell: Tag) -> str:
    """Read the current name from a multilingual table cell.

    Pokémon Central may show the current name followed by historical variants
    and generation annotations. The current form is the first meaningful text
    fragment after references and annotations are removed.
    """

    clone = BeautifulSoup(str(cell), "html.parser")
    for node in clone.select("sup, small, .reference, .mw-editsection"):
        node.decompose()
    text = clone.get_text("\n", strip=True)
    parts = [part.strip() for part in text.splitlines() if part.strip()]
    for part in parts:
        cleaned = re.sub(r"\s+", " ", part)
        if re.fullmatch(r"[IVX]+|[+\-–—]+", cleaned):
            continue
        if cleaned.casefold() in {"italiano", "inglese", "#"}:
            continue
        return cleaned
    return ""


def _pokemon_central_names() -> dict[str, str]:
    response = requests.get(
        POKEMON_CENTRAL_URL,
        timeout=60,
        headers={"User-Agent": "Pokedex5e-ITA translation audit"},
    )
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")
    result: dict[str, str] = {}

    # The multilingual tables consistently use: number, Italian, English, ...
    # Header markup varies between table sections, so positional parsing is
    # more reliable than deriving column indexes from the first row.
    for table in soup.select("table.wikitable"):
        for row in table.select("tr"):
            cells = row.find_all(["th", "td"], recursive=False)
            if len(cells) < 3:
                continue
            italian = _clean_cell(cells[1])
            english = _clean_cell(cells[2])
            if not italian or not english:
                continue
            if italian.casefold() == "italiano" or english.casefold() == "inglese":
                continue
            result.setdefault(_normalize(english), italian)

    return result


def _download_csv(url: str) -> list[dict[str, str]]:
    response = requests.get(
        url,
        timeout=60,
        headers={"User-Agent": "Pokedex5e-ITA translation audit"},
    )
    response.raise_for_status()
    return list(csv.DictReader(io.StringIO(response.text)))


def _pokeapi_names() -> tuple[dict[str, str], dict[str, str]]:
    moves = _download_csv(POKEAPI_MOVES_URL)
    names = _download_csv(POKEAPI_NAMES_URL)

    identifier_by_id = {row["id"]: row["identifier"] for row in moves}
    italian_by_id = {
        row["move_id"]: row["name"]
        for row in names
        if row.get("local_language_id") == ITALIAN_LANGUAGE_ID
    }

    by_identifier: dict[str, str] = {}
    by_english_name: dict[str, str] = {}
    english_by_id = {
        row["move_id"]: row["name"]
        for row in names
        if row.get("local_language_id") == "9"
    }
    for move_id, italian in italian_by_id.items():
        identifier = identifier_by_id.get(move_id)
        if identifier:
            by_identifier[_normalize(identifier)] = italian
        english = english_by_id.get(move_id)
        if english:
            by_english_name[_normalize(english)] = italian

    return by_identifier, by_english_name


def main() -> None:
    document = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    moves: list[dict[str, Any]] = list(document.get("moves", []))

    pcw = _pokemon_central_names()
    poke_by_id, poke_by_name = _pokeapi_names()

    rows: list[dict[str, Any]] = []
    for index, move in enumerate(moves, start=1):
        move_id = str(move.get("id", "")).strip()
        source_name = str(move.get("name", "")).strip()
        normalized_name = _normalize(source_name)
        normalized_id = _normalize(move_id)

        pcw_name = pcw.get(normalized_name)
        poke_name = poke_by_id.get(normalized_id) or poke_by_name.get(normalized_name)
        chosen = pcw_name or poke_name or source_name
        if pcw_name:
            source = "pokemon-central"
        elif poke_name:
            source = "pokeapi"
        else:
            source = "fallback"

        rows.append(
            {
                "index": index,
                "id": move_id,
                "sourceName": source_name,
                "pokemonCentralName": pcw_name,
                "pokeApiName": poke_name,
                "name": chosen,
                "nameSource": source,
                "hasDescription": bool(move.get("description")),
                "hasHigherLevels": bool(move.get("higherLevels")),
            }
        )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(CATALOG_PATH, OUTPUT_DIR / "move-catalog-source.json")
    (OUTPUT_DIR / "move-name-audit.json").write_text(
        json.dumps(
            {
                "catalogCount": len(rows),
                "pokemonCentralCatalogCount": len(pcw),
                "pokemonCentralMatches": sum(
                    row["nameSource"] == "pokemon-central" for row in rows
                ),
                "pokeApiFallbackMatches": sum(
                    row["nameSource"] == "pokeapi" for row in rows
                ),
                "unmatchedCount": sum(row["nameSource"] == "fallback" for row in rows),
                "items": rows,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    with (OUTPUT_DIR / "move-name-audit.csv").open(
        "w", encoding="utf-8", newline=""
    ) as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)

    unmatched = [row for row in rows if row["nameSource"] == "fallback"]
    print(f"catalogCount={len(rows)}")
    print(f"pokemonCentralCatalogCount={len(pcw)}")
    print(
        "pokemonCentralMatches="
        f"{sum(row['nameSource'] == 'pokemon-central' for row in rows)}"
    )
    print(
        "pokeApiFallbackMatches="
        f"{sum(row['nameSource'] == 'pokeapi' for row in rows)}"
    )
    print(f"unmatchedCount={len(unmatched)}")
    for row in unmatched:
        print(f"UNMATCHED {row['index']:04d} {row['id']} :: {row['sourceName']}")


if __name__ == "__main__":
    main()
