from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Expected block not found in {path}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


asset = Path("lib/widgets/pokemon/pokemon_asset_image.dart")
text = asset.read_text(encoding="utf-8")
bad = "\x08(form|forme|style|mode)\x08"
if bad not in text:
    raise RuntimeError("Control-character form regex was not found")
asset.write_text(
    text.replace(bad, r"\b(form|forme|style|mode)\b", 1),
    encoding="utf-8",
)

battle = Path("lib/screens/battle/battle_screen.dart")

replace_once(
    battle,
    """                PokemonAssetImage(
                  pokemon: pokemon,
                  size: 52,
                  formName: slot.formName,
                ),
""",
    """                PokemonAssetImage(
                  pokemon: pokemon,
                  size: 52,
                  formName: slot.formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                ),
""",
)

replace_once(
    battle,
    """                PokemonAssetImage(
                  pokemon: pokemon,
                  useLargeArtwork: true,
                  size: 96,
                  formName: slot.formName,
                ),
""",
    """                PokemonAssetImage(
                  pokemon: pokemon,
                  useLargeArtwork: true,
                  size: 96,
                  formName: slot.formName,
                  gender: slot.gender,
                  isShiny: slot.isShiny,
                ),
""",
)

print("Repaired form regex and battle Pokemon previews.")
