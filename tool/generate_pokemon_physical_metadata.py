from __future__ import annotations

import csv
import io
import json
import re
import urllib.request
from collections import defaultdict
from pathlib import Path

POKEAPI_CSV_URL = (
    "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/"
    "data/v2/csv/pokemon.csv"
)

TOKEN_ALIASES = {
    "alolan": "alola",
    "galarian": "galar",
    "hisuian": "hisui",
    "paldean": "paldea",
}
GENERIC_TOKENS = {"form", "forme", "style", "mode"}


def identifier_tokens(value: str) -> set[str]:
    tokens = re.findall(r"[a-z0-9]+", value.lower())
    return {
        TOKEN_ALIASES.get(token, token)
        for token in tokens
        if TOKEN_ALIASES.get(token, token) not in GENERIC_TOKENS
    }


def read_pokeapi_rows() -> list[dict[str, str]]:
    request = urllib.request.Request(
        POKEAPI_CSV_URL,
        headers={"User-Agent": "Pokedex5e-ITA metadata generator"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        text = response.read().decode("utf-8")
    return list(csv.DictReader(io.StringIO(text)))


def score_candidate(
    local_id: str,
    candidate: dict[str, str],
    default_identifier: str | None,
) -> tuple[int, int, int]:
    candidate_id = candidate["identifier"]
    if candidate_id == local_id:
        return (10000, 0, 0)

    local_tokens = identifier_tokens(local_id)
    candidate_tokens = identifier_tokens(candidate_id)
    default_tokens = identifier_tokens(default_identifier or "")
    local_form_tokens = local_tokens - default_tokens
    candidate_form_tokens = candidate_tokens - default_tokens

    looks_base = not local_form_tokens
    is_default = candidate.get("is_default") == "1"
    if looks_base and is_default:
        return (9000, 0, 0)
    if not looks_base and is_default:
        return (-1000, 0, 0)

    if local_tokens == candidate_tokens:
        return (8000, 0, 0)
    if local_form_tokens and local_form_tokens == candidate_form_tokens:
        return (7500, 0, 0)

    intersection = len(local_form_tokens & candidate_form_tokens)
    union = len(local_form_tokens | candidate_form_tokens)
    if intersection == 0:
        return (-500, -union, -len(candidate_form_tokens))

    coverage = intersection * 1000 // max(1, len(local_form_tokens))
    precision = intersection * 1000 // max(1, len(candidate_form_tokens))
    penalty = abs(len(local_form_tokens) - len(candidate_form_tokens))
    return (5000 + coverage + precision - penalty * 100, intersection, -penalty)


def main() -> None:
    local_data = json.loads(
        Path("assets/data_webapp/pokemon.json").read_text(encoding="utf-8-sig")
    )
    local_items = [item for item in local_data.get("items", []) if isinstance(item, dict)]
    rows = read_pokeapi_rows()

    rows_by_species: dict[int, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        try:
            rows_by_species[int(row["species_id"])].append(row)
        except (KeyError, ValueError):
            continue

    output: dict[str, dict[str, object]] = {}
    fallback_ids: list[str] = []
    unmapped_ids: list[str] = []

    for item in local_items:
        local_id = str(item.get("id") or "").strip()
        try:
            species_id = int(item.get("number"))
        except (TypeError, ValueError):
            continue
        if not local_id:
            continue

        candidates = rows_by_species.get(species_id, [])
        default = next(
            (candidate for candidate in candidates if candidate.get("is_default") == "1"),
            None,
        )
        default_identifier = default.get("identifier") if default else None
        ranked = sorted(
            candidates,
            key=lambda candidate: score_candidate(
                local_id,
                candidate,
                default_identifier,
            ),
            reverse=True,
        )
        selected = ranked[0] if ranked else None
        selected_score = (
            score_candidate(local_id, selected, default_identifier)
            if selected is not None
            else (-9999, 0, 0)
        )
        matched = selected is not None and selected_score[0] >= 5000

        if not matched:
            selected = default
            if selected is not None:
                fallback_ids.append(local_id)
            else:
                unmapped_ids.append(local_id)
                continue

        try:
            height = int(selected["height"])
            weight = int(selected["weight"])
        except (KeyError, TypeError, ValueError):
            unmapped_ids.append(local_id)
            continue

        output[local_id] = {
            "height": height,
            "weight": weight,
            "sourceIdentifier": selected["identifier"],
            "matched": matched,
        }

    payload = {
        "source": POKEAPI_CSV_URL,
        "units": {"height": "decimetres", "weight": "hectograms"},
        "generatedCount": len(output),
        "fallbackCount": len(fallback_ids),
        "unmappedCount": len(unmapped_ids),
        "fallbackIds": sorted(fallback_ids),
        "unmappedIds": sorted(unmapped_ids),
        "items": dict(sorted(output.items())),
    }
    target = Path("assets/data_webapp/pokemon_physical.json")
    target.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"Generated {len(output)} entries; "
        f"fallback={len(fallback_ids)}, unmapped={len(unmapped_ids)}"
    )


if __name__ == "__main__":
    main()
