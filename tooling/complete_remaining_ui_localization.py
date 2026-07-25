from __future__ import annotations

import json
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
HELPER = LIB / "localization" / "ui_text.dart"
REPORT = ROOT / "build" / "remaining-ui-localization-report.md"

MANUAL_TRANSLATIONS: dict[str, str] = {
    "Pokémon personalizzati": "Custom Pokémon",
    "Libreria Pokémon personalizzati": "Custom Pokémon Library",
    "Libreria Pokémon": "Pokémon Library",
    "Nuovo Pokémon personalizzato": "New Custom Pokémon",
    "Modifica Pokémon personalizzato": "Edit Custom Pokémon",
    "Crea Pokémon personalizzato": "Create Custom Pokémon",
    "Duplica Pokémon": "Duplicate Pokémon",
    "Importa Pokémon": "Import Pokémon",
    "Esporta Pokémon": "Export Pokémon",
    "Nessun Pokémon personalizzato": "No custom Pokémon",
    "Nessun Pokémon personalizzato salvato": "No custom Pokémon saved",
    "Allenatori PNG": "NPC Trainers",
    "Allenatore PNG": "NPC Trainer",
    "Nuovo Allenatore PNG": "New NPC Trainer",
    "Modifica Allenatore PNG": "Edit NPC Trainer",
    "Crea Allenatore PNG": "Create NPC Trainer",
    "Nessun Allenatore PNG": "No NPC Trainers",
    "Nessun allenatore salvato": "No trainers saved",
    "Battaglia contro Allenatore": "Trainer Battle",
    "Battaglia Allenatore": "Trainer Battle",
    "Battaglie salvate": "Saved Battles",
    "Allevamento": "Breeding",
    "Centro Allevamento": "Day Care",
    "Pokémon genitore": "Parent Pokémon",
    "Primo genitore": "First Parent",
    "Secondo genitore": "Second Parent",
    "Genitore 1": "Parent 1",
    "Genitore 2": "Parent 2",
    "Genera uovo": "Generate Egg",
    "Crea uovo": "Create Egg",
    "Uovo Pokémon": "Pokémon Egg",
    "Uova Pokémon": "Pokémon Eggs",
    "Nessun uovo": "No eggs",
    "Gruppo uova": "Egg Group",
    "Gruppi uova": "Egg Groups",
    "Mossa uovo": "Egg Move",
    "Mosse uovo": "Egg Moves",
    "Generatore incontri": "Encounter Generator",
    "Generatore di incontri": "Encounter Generator",
    "Generatore Pokémon": "Pokémon Generator",
    "Generatore di Pokémon": "Pokémon Generator",
    "Generatore Allenatore": "Trainer Generator",
    "Generatore Allenatori": "Trainer Generator",
    "Generatore di Allenatori": "Trainer Generator",
    "Genera incontro": "Generate Encounter",
    "Genera Pokémon": "Generate Pokémon",
    "Genera Allenatore": "Generate Trainer",
    "Rigenera": "Regenerate",
    "Genera": "Generate",
    "Risultato": "Result",
    "Risultati": "Results",
    "Parametri": "Parameters",
    "Opzioni avanzate": "Advanced Options",
    "Difficoltà": "Difficulty",
    "Facile": "Easy",
    "Medio": "Medium",
    "Media": "Medium",
    "Difficile": "Hard",
    "Casuale": "Random",
    "Quantità": "Quantity",
    "Numero": "Number",
    "Livello": "Level",
    "Livello minimo": "Minimum Level",
    "Livello massimo": "Maximum Level",
    "Livello medio": "Average Level",
    "SR minimo": "Minimum SR",
    "SR massimo": "Maximum SR",
    "Tipo": "Type",
    "Tipi": "Types",
    "Tipo principale": "Primary Type",
    "Tipo secondario": "Secondary Type",
    "Regione": "Region",
    "Generazione": "Generation",
    "Ambiente": "Environment",
    "Terreno": "Terrain",
    "Clima": "Weather",
    "Giorno": "Day",
    "Notte": "Night",
    "Nome": "Name",
    "Descrizione": "Description",
    "Statistiche": "Stats",
    "Caratteristiche": "Abilities",
    "Abilità": "Abilities",
    "Mosse": "Moves",
    "Mossa": "Move",
    "Squadra": "Team",
    "Avversario": "Opponent",
    "Alleato": "Ally",
    "Nemico": "Enemy",
    "Incontro": "Encounter",
    "Incontri": "Encounters",
    "Iniziativa": "Initiative",
    "Round": "Round",
    "Turno": "Turn",
    "Bersaglio": "Target",
    "Danno": "Damage",
    "Cura": "Healing",
    "Oggetto": "Item",
    "Oggetti": "Items",
    "Dettagli": "Details",
    "Riepilogo": "Summary",
    "Anteprima": "Preview",
    "Impostazioni": "Settings",
    "Filtri": "Filters",
    "Ricerca": "Search",
    "Cerca": "Search",
    "Seleziona": "Select",
    "Seleziona tutto": "Select All",
    "Deseleziona tutto": "Clear Selection",
    "Aggiungi": "Add",
    "Rimuovi": "Remove",
    "Modifica": "Edit",
    "Elimina": "Delete",
    "Duplica": "Duplicate",
    "Importa": "Import",
    "Esporta": "Export",
    "Salva": "Save",
    "Annulla": "Cancel",
    "Conferma": "Confirm",
    "Chiudi": "Close",
    "Indietro": "Back",
    "Avanti": "Next",
    "Fine": "Done",
    "Riprova": "Try Again",
    "Aggiorna": "Refresh",
    "Ripristina": "Restore",
    "Sostituisci": "Replace",
    "Copia": "Copy",
    "Condividi": "Share",
    "Carica": "Load",
    "Apri": "Open",
    "Attivo": "Active",
    "Inattivo": "Inactive",
    "Disponibile": "Available",
    "Non disponibile": "Unavailable",
    "Nessuno": "None",
    "Nessuna": "None",
    "Nessun risultato": "No results",
    "Nessun dato disponibile": "No data available",
    "Nessun elemento": "No items",
    "Obbligatorio": "Required",
    "Opzionale": "Optional",
    "Valore non valido": "Invalid value",
    "Errore": "Error",
    "Operazione completata": "Operation completed",
    "Operazione annullata": "Operation cancelled",
    "Salvataggio completato": "Saved successfully",
    "Dati salvati": "Data saved",
    "Eliminazione completata": "Deleted successfully",
    "Vuoi continuare?": "Do you want to continue?",
    "Conferma eliminazione": "Confirm deletion",
    "Questa operazione non può essere annullata.": "This action cannot be undone.",
    "Tutto": "All",
    "Tutti": "All",
    "Tutte": "All",
    "Sì": "Yes",
    "No": "No",
    "Maschio": "Male",
    "Femmina": "Female",
    "Senza sesso": "Genderless",
    "Comune": "Common",
    "Non comune": "Uncommon",
    "Raro": "Rare",
    "Molto raro": "Very Rare",
    "Leggendario": "Legendary",
    "Manuale": "Manual",
    "Automatico": "Automatic",
    "Predefinito": "Default",
    "Personalizzato": "Custom",
    "Base": "Base",
    "Totale": "Total",
    "Minimo": "Minimum",
    "Massimo": "Maximum",
    "Punti ferita": "Hit Points",
    "Velocità": "Speed",
    "Classe Armatura": "Armor Class",
    "Tiri salvezza": "Saving Throws",
    "Competenze": "Proficiencies",
    "Debolezze": "Weaknesses",
    "Resistenze": "Resistances",
    "Immunità": "Immunities",
    "Natura": "Nature",
    "Lealtà": "Loyalty",
    "Sesso": "Gender",
    "Taglia": "Size",
    "Esperienza": "Experience",
    "Punti esperienza": "Experience Points",
}

SAFE_NAMED_PARAMETERS = (
    "title",
    "subtitle",
    "label",
    "tooltip",
    "hintText",
    "labelText",
    "helperText",
    "errorText",
    "message",
    "emptyMessage",
    "semanticLabel",
    "buttonText",
    "dialogTitle",
    "description",
    "header",
    "caption",
)

VARIABLE_SUFFIXES = (
    "Label",
    "Title",
    "Message",
    "Text",
    "Hint",
    "Tooltip",
    "Description",
    "Subtitle",
    "Caption",
)

ITALIAN_MARKERS = re.compile(
    r"(?:\b(?:salva|annulla|elimina|modifica|nuov[oa]|nessun[oa]?|seleziona|"
    r"genera|allenator[ei]|incontr[oi]|squadra|livello|mosse?|abilità|"
    r"allevamento|uov[oa]|genitor[ei]|cattura|ricerca|descrizione|"
    r"difficoltà|quantità|casuale|errore|impossibile|disponibile|"
    r"caratteristiche|competenz[ae]|strumenti|bersaglio|danno|cura|"
    r"oggett[oi]|profil[oi]|zaino|conferma|chiudi|indietro|avanti|"
    r"ripristina|sostituisci|aggiungi|rimuovi|nessuno|nessuna)\b|"
    r"[àèéìòù])",
    re.IGNORECASE,
)


def _decode_simple(value: str) -> str:
    return (
        value.replace(r"\'", "'")
        .replace(r'\"', '"')
        .replace(r"\n", "\n")
        .replace(r"\\", "\\")
    )


def _dart_quote(value: str) -> str:
    escaped = value.replace("\\", r"\\").replace("'", r"\'").replace("\n", r"\n")
    return f"'{escaped}'"


def _normalise_variants(mapping: dict[str, str]) -> dict[str, str]:
    expanded = dict(mapping)
    for italian, english in list(mapping.items()):
        if italian and italian.upper() == italian:
            expanded.setdefault(italian, english.upper())
        else:
            expanded.setdefault(italian.upper(), english.upper())
        expanded.setdefault(f"{italian}:", f"{english}:")
        expanded.setdefault(f"{italian}…", f"{english}…")
        expanded.setdefault(f"{italian}...", f"{english}...")
    return expanded


def _extract_existing_pairs() -> dict[str, str]:
    result: dict[str, str] = {}
    pair_pattern = re.compile(
        r"(?:context\.)?(?:uiText|uiTextForLanguage)\(\s*"
        r"(?P<q1>['\"])(?P<it>(?:\\.|(?!\1).)*?)(?P=q1)\s*,\s*"
        r"(?P<q2>['\"])(?P<en>(?:\\.|(?!\3).)*?)(?P=q2)",
        re.DOTALL,
    )
    for path in LIB.rglob("*.dart"):
        if "l10n" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        for match in pair_pattern.finditer(text):
            italian = _decode_simple(match.group("it"))
            english = _decode_simple(match.group("en"))
            if italian and english and italian != english:
                result.setdefault(italian, english)
    return result


def _extract_arb_pairs() -> dict[str, str]:
    result: dict[str, str] = {}
    candidates = [
        (LIB / "l10n" / "app_it.arb", LIB / "l10n" / "app_en.arb"),
        (LIB / "l10n" / "app_localizations_it.arb", LIB / "l10n" / "app_localizations_en.arb"),
    ]
    for italian_path, english_path in candidates:
        if not italian_path.exists() or not english_path.exists():
            continue
        italian = json.loads(italian_path.read_text(encoding="utf-8"))
        english = json.loads(english_path.read_text(encoding="utf-8"))
        for key, italian_value in italian.items():
            if key.startswith("@") or not isinstance(italian_value, str):
                continue
            english_value = english.get(key)
            if isinstance(english_value, str) and italian_value != english_value:
                result.setdefault(italian_value, english_value)
    return result


def _translation_map() -> dict[str, str]:
    mapping: dict[str, str] = {}
    mapping.update(_extract_existing_pairs())
    mapping.update(_extract_arb_pairs())
    mapping.update(MANUAL_TRANSLATIONS)
    return _normalise_variants(mapping)


def _relative_helper_import(path: Path) -> str:
    relative = os.path.relpath(HELPER, path.parent).replace(os.sep, "/")
    if not relative.startswith("."):
        relative = f"./{relative}"
    return f"import '{relative}';"


def _ensure_import(text: str, path: Path) -> str:
    if "ui_text.dart" in text:
        return text
    import_line = _relative_helper_import(path)
    imports = list(re.finditer(r"^import\s+['\"].+?['\"];\s*$", text, re.MULTILINE))
    if imports:
        position = imports[-1].end()
        return text[:position] + "\n" + import_line + text[position:]
    return import_line + "\n\n" + text


def _lookup(mapping: dict[str, str], raw: str) -> str | None:
    value = _decode_simple(raw)
    english = mapping.get(value)
    if english is not None and english != value:
        return english
    stripped = value.strip()
    english = mapping.get(stripped)
    if english is None or english == stripped:
        return None
    prefix = value[: len(value) - len(value.lstrip())]
    suffix = value[len(value.rstrip()) :]
    return prefix + english + suffix


def _localised_expression(raw: str, english: str) -> str:
    return f"uiTextForLanguage({_dart_quote(_decode_simple(raw))}, {_dart_quote(english)})"


def _replace_text_widgets(text: str, mapping: dict[str, str]) -> tuple[str, int]:
    count = 0
    pattern = re.compile(
        r"(?P<const>\bconst\s+)?Text\(\s*(?P<quote>['\"])(?P<value>(?:\\.|(?!\2).)*?)(?P=quote)",
        re.DOTALL,
    )

    def repl(match: re.Match[str]) -> str:
        nonlocal count
        english = _lookup(mapping, match.group("value"))
        if english is None:
            return match.group(0)
        count += 1
        return "Text(" + _localised_expression(match.group("value"), english)

    return pattern.sub(repl, text), count


def _replace_named_parameters(text: str, mapping: dict[str, str]) -> tuple[str, int]:
    count = 0
    names = "|".join(re.escape(name) for name in SAFE_NAMED_PARAMETERS)
    pattern = re.compile(
        rf"(?P<name>\b(?:{names})\b\s*:\s*)(?P<quote>['\"])(?P<value>(?:\\.|(?!\2).)*?)(?P=quote)",
        re.DOTALL,
    )

    def repl(match: re.Match[str]) -> str:
        nonlocal count
        english = _lookup(mapping, match.group("value"))
        if english is None:
            return match.group(0)
        count += 1
        return match.group("name") + _localised_expression(match.group("value"), english)

    return pattern.sub(repl, text), count


def _replace_return_values(text: str, mapping: dict[str, str]) -> tuple[str, int]:
    count = 0
    pattern = re.compile(
        r"(?P<prefix>\breturn\s+|=>\s*)(?P<quote>['\"])(?P<value>(?:\\.|(?!\2).)*?)(?P=quote)(?P<suffix>\s*;)",
        re.DOTALL,
    )

    def repl(match: re.Match[str]) -> str:
        nonlocal count
        english = _lookup(mapping, match.group("value"))
        if english is None:
            return match.group(0)
        count += 1
        return match.group("prefix") + _localised_expression(match.group("value"), english) + match.group("suffix")

    return pattern.sub(repl, text), count


def _replace_ui_variables(text: str, mapping: dict[str, str]) -> tuple[str, int]:
    count = 0
    suffixes = "|".join(re.escape(value) for value in VARIABLE_SUFFIXES)
    pattern = re.compile(
        rf"(?P<prefix>\b(?:final|var|String)\s+[A-Za-z_]\w*(?:{suffixes})\s*=\s*)"
        r"(?P<quote>['\"])(?P<value>(?:\\.|(?!\2).)*?)(?P=quote)",
        re.DOTALL,
    )

    def repl(match: re.Match[str]) -> str:
        nonlocal count
        english = _lookup(mapping, match.group("value"))
        if english is None:
            return match.group(0)
        count += 1
        return match.group("prefix") + _localised_expression(match.group("value"), english)

    return pattern.sub(repl, text), count


def _replace_known_standalone_literals(text: str, mapping: dict[str, str]) -> tuple[str, int]:
    count = 0
    # Covers common menu/list entries. Restrict to a whole source line to avoid
    # touching IDs, JSON keys, routes, enum values, or persisted data.
    pattern = re.compile(
        r"^(?P<indent>\s*)(?P<quote>['\"])(?P<value>(?:\\.|(?!\2).)*?)(?P=quote)(?P<comma>,?)\s*$",
        re.MULTILINE,
    )

    def repl(match: re.Match[str]) -> str:
        nonlocal count
        english = _lookup(mapping, match.group("value"))
        if english is None:
            return match.group(0)
        count += 1
        return (
            match.group("indent")
            + _localised_expression(match.group("value"), english)
            + match.group("comma")
        )

    return pattern.sub(repl, text), count


def _drop_unsafe_widget_const(text: str) -> str:
    widget_names = (
        "Text",
        "InputDecoration",
        "DropdownMenuItem",
        "ListTile",
        "AlertDialog",
        "SimpleDialog",
        "SnackBar",
        "Tooltip",
        "PopupMenuItem",
        "ChoiceChip",
        "FilterChip",
        "ActionChip",
        "DataColumn",
        "Tab",
    )
    names = "|".join(widget_names)
    text = re.sub(rf"\bconst\s+(?=(?:{names})\s*\()", "", text)
    # Lists/maps that now contain runtime expressions cannot remain const.
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if "uiTextForLanguage(" not in line:
            continue
        for previous in range(index, max(-1, index - 8), -1):
            candidate = lines[previous]
            if re.search(r"\bconst\s+[\[\{]", candidate):
                lines[previous] = re.sub(r"\bconst\s+", "", candidate, count=1)
                break
            if ";" in candidate or "{" in candidate and previous != index:
                break
    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


def _is_candidate(path: Path) -> bool:
    if path == HELPER or "l10n" in path.parts or path.name.endswith(".g.dart"):
        return False
    return "screens" in path.parts or "widgets" in path.parts


def _remaining_candidates(text: str) -> list[str]:
    results: list[str] = []
    literal_pattern = re.compile(r"(?P<quote>['\"])(?P<value>(?:\\.|(?!\1).)*?)(?P=quote)", re.DOTALL)
    for match in literal_pattern.finditer(text):
        value = _decode_simple(match.group("value"))
        if len(value) < 3 or not ITALIAN_MARKERS.search(value):
            continue
        prefix = text[max(0, match.start() - 90) : match.start()]
        if "uiText(" in prefix or "uiTextForLanguage(" in prefix:
            continue
        results.append(value.replace("\n", " ")[:180])
    return results


def main() -> None:
    mapping = _translation_map()
    modified: list[tuple[Path, int]] = []
    residual: list[tuple[Path, str]] = []

    for path in sorted(LIB.rglob("*.dart")):
        if not _is_candidate(path):
            continue
        original = path.read_text(encoding="utf-8")
        text = original
        total = 0
        for transformer in (
            _replace_text_widgets,
            _replace_named_parameters,
            _replace_return_values,
            _replace_ui_variables,
            _replace_known_standalone_literals,
        ):
            text, replacements = transformer(text, mapping)
            total += replacements
        if total:
            text = _drop_unsafe_widget_const(text)
            text = _ensure_import(text, path)
            path.write_text(text, encoding="utf-8")
            modified.append((path, total))
        for value in _remaining_candidates(text):
            residual.append((path, value))

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Secondo passaggio localizzazione UI",
        "",
        f"- File modificati automaticamente: **{len(modified)}**",
        f"- Sostituzioni sicure applicate: **{sum(count for _, count in modified)}**",
        f"- Candidati residui da revisione manuale: **{len(residual)}**",
        "",
        "## File modificati",
        "",
    ]
    lines.extend(
        f"- `{path.relative_to(ROOT)}`: {count} sostituzioni"
        for path, count in modified
    )
    lines.extend(["", "## Candidati residui", ""])
    lines.extend(
        f"- `{path.relative_to(ROOT)}` — {value}"
        for path, value in residual[:500]
    )
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    (ROOT / "build" / "remaining-ui-modified-files.txt").write_text(
        "\n".join(str(path.relative_to(ROOT)) for path, _ in modified) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
