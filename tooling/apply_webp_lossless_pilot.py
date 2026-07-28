from __future__ import annotations

import argparse
import csv
import hashlib
import io
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFile

ROOT = Path(__file__).resolve().parents[1]
LEGACY_RESOLVER = ROOT / "lib/widgets/pokemon/pokemon_asset_image_legacy.dart"
PREFERRED_RESOLVER = ROOT / "lib/widgets/pokemon/pokemon_asset_image.dart"
TEST_PATH = ROOT / "test/webp_lossless_pilot_test.dart"
REPORT_CSV = ROOT / "docs/performance/webp-lossless-pilot.csv"
REPORT_MD = ROOT / "docs/performance/webp-lossless-pilot.md"
CONTACT_SHEET = ROOT / "build/reports/webp-lossless-pilot/contact-sheet.png"

PILOT_PNGS = (
    "assets/textures/textures_webapp/pokemon/abomasnow/main.png",
    "assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.png",
    "assets/textures/textures_webapp/pokemon/alolan-rattata/main.png",
    "assets/textures/textures_webapp/pokemon/alolan-rattata/main-shiny.png",
    "assets/textures/textures_webapp/pokemon/dusk-mane-necrozma/main-shiny.png",
    "assets/textures/textures_webapp/pokemon/bulbasaur/sprite.png",
    "assets/textures/textures_webapp/pokemon/bulbasaur/sprite-shiny.png",
    "assets/textures/textures_webapp/pokemon/indeedee-f/sprite.png",
    "assets/textures/textures_webapp/pokemon/meowstic-m/sprite.png",
    "assets/textures/textures_webapp/pokemon/meowstic-m/sprite-shiny.png",
    "assets/textures/textures_webapp/pokemon/minior-core-blue/sprite-shiny.png",
    "assets/textures/textures_webapp/pokemon/tyrunt/sprite.png",
)


@dataclass(frozen=True)
class PilotResult:
    png_path: str
    webp_path: str
    width: int
    height: int
    png_bytes: int
    webp_bytes: int
    pixel_sha256: str

    @property
    def saved_bytes(self) -> int:
        return self.png_bytes - self.webp_bytes

    @property
    def saving_ratio(self) -> float:
        return self.saved_bytes / self.png_bytes if self.png_bytes else 0.0


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def strict_rgba(path: Path) -> Image.Image:
    previous = ImageFile.LOAD_TRUNCATED_IMAGES
    ImageFile.LOAD_TRUNCATED_IMAGES = False
    try:
        with Image.open(path) as image:
            image.load()
            rgba = image.convert("RGBA")
            rgba.load()
            return rgba.copy()
    finally:
        ImageFile.LOAD_TRUNCATED_IMAGES = previous


def encode_one(relative_png: str) -> tuple[PilotResult, Image.Image, Image.Image]:
    png_path = ROOT / relative_png
    if not png_path.is_file():
        raise RuntimeError(f"Missing pilot source: {relative_png}")

    webp_path = png_path.with_suffix(".webp")
    original = strict_rgba(png_path)
    original_pixels = original.tobytes()
    pixel_hash = sha256_bytes(original_pixels)
    png_bytes = png_path.stat().st_size

    with tempfile.NamedTemporaryFile(
        prefix=f"{png_path.stem}-",
        suffix=".webp",
        dir=png_path.parent,
        delete=False,
    ) as handle:
        temporary = Path(handle.name)

    try:
        original.save(
            temporary,
            format="WEBP",
            lossless=True,
            exact=True,
            method=6,
        )
        converted = strict_rgba(temporary)
        if converted.size != original.size:
            raise RuntimeError(
                f"Dimensions changed for {relative_png}: "
                f"{original.size} -> {converted.size}"
            )
        if converted.tobytes() != original_pixels:
            raise RuntimeError(f"Decoded RGBA pixels changed for {relative_png}")
        temporary.replace(webp_path)
    finally:
        if temporary.exists():
            temporary.unlink()

    png_path.unlink()
    relative_webp = webp_path.relative_to(ROOT).as_posix()
    return (
        PilotResult(
            png_path=relative_png,
            webp_path=relative_webp,
            width=original.width,
            height=original.height,
            png_bytes=png_bytes,
            webp_bytes=webp_path.stat().st_size,
            pixel_sha256=pixel_hash,
        ),
        original,
        converted,
    )


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one {label} patch target, found {count}")
    return text.replace(old, new, 1)


def patch_resolvers() -> None:
    legacy = LEGACY_RESOLVER.read_text(encoding="utf-8")
    legacy = replace_once(
        legacy,
        "      if (!assetPath.endsWith('.png')) continue;",
        "      if (!_isSupportedImagePath(assetPath)) continue;",
        "form-choice extension",
    )
    legacy = replace_once(
        legacy,
        "    return candidates;\n  }\n\n  static List<String> imageCandidatePrefixes({",
        "    return _preferModernImageFormats(candidates);\n"
        "  }\n\n"
        "  static List<String> _preferModernImageFormats(\n"
        "    Iterable<String> candidates,\n"
        "  ) {\n"
        "    final resolved = <String>[];\n"
        "    for (final candidate in candidates) {\n"
        "      final isConvertible =\n"
        "          candidate.endsWith('.png') &&\n"
        "          (candidate.startsWith(_webPokemonRoot) ||\n"
        "              candidate.startsWith(_webTransformRoot));\n"
        "      if (isConvertible) {\n"
        "        final webp =\n"
        "            '${candidate.substring(0, candidate.length - 4)}.webp';\n"
        "        if (!resolved.contains(webp)) resolved.add(webp);\n"
        "      }\n"
        "      if (!resolved.contains(candidate)) resolved.add(candidate);\n"
        "    }\n"
        "    return resolved;\n"
        "  }\n\n"
        "  static bool _isSupportedImagePath(String path) {\n"
        "    final lower = path.toLowerCase();\n"
        "    return lower.endsWith('.png') || lower.endsWith('.webp');\n"
        "  }\n\n"
        "  static List<String> imageCandidatePrefixes({",
        "candidate format preference",
    )
    legacy = legacy.replace(
        ".replaceFirst(RegExp(r'\\.png$'), '')",
        ".replaceFirst(RegExp(r'\\.(?:png|webp)$'), '')",
    )
    legacy = replace_once(
        legacy,
        "    if (!assetPath.endsWith('.png')) return false;",
        "    if (!PokemonAssetPaths._isSupportedImagePath(assetPath)) return false;",
        "prefix extension",
    )
    LEGACY_RESOLVER.write_text(legacy, encoding="utf-8", newline="\n")

    preferred = PREFERRED_RESOLVER.read_text(encoding="utf-8")
    preferred = replace_once(
        preferred,
        "    for (final candidate in candidates) {\n"
        "      if (paths.contains(candidate)) return candidate;\n"
        "    }",
        "    for (final candidate in candidates) {\n"
        "      if (candidate.endsWith('.png')) {\n"
        "        final webp =\n"
        "            '${candidate.substring(0, candidate.length - 4)}.webp';\n"
        "        if (paths.contains(webp)) return webp;\n"
        "      }\n"
        "      if (paths.contains(candidate)) return candidate;\n"
        "    }",
        "preferred resolver format",
    )
    PREFERRED_RESOLVER.write_text(preferred, encoding="utf-8", newline="\n")


def test_source() -> str:
    webp_paths = [str(Path(path).with_suffix(".webp")).replace("\\", "/") for path in PILOT_PNGS]
    path_lines = "\n".join(f"  '{path}'," for path in webp_paths)
    return f"""import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/models/pokemon.dart';
import 'package:pokedex_5e_ita/models/pokemon_attributes.dart';
import 'package:pokedex_5e_ita/models/pokemon_moves.dart';
import 'package:pokedex_5e_ita/widgets/pokemon/pokemon_asset_image.dart';

const _pilotWebpAssets = <String>[
{path_lines}
];

Pokemon _pokemon(int id, String name) {{
  return Pokemon(
    id: id,
    name: name,
    types: const [],
    armorClass: 0,
    hitPoints: 0,
    size: 'Unknown',
    speed: 0,
    attributes: const PokemonAttributes(
      strength: 0,
      dexterity: 0,
      constitution: 0,
      intelligence: 0,
      wisdom: 0,
      charisma: 0,
    ),
    abilities: const [],
    hiddenAbility: null,
    skills: const [],
    savingThrows: const [],
    moves: const PokemonMoves(startingMoves: [], levelMoves: {{}}, tmMoves: []),
    hitDice: 0,
    sr: 0,
    minLevelFound: 0,
  );
}}

void main() {{
  test('WebP is preferred before PNG for web artwork candidates', () {{
    final candidates = PokemonAssetPaths.imageCandidates(
      pokemon: _pokemon(460, 'Abomasnow'),
      useLargeArtwork: true,
      isShiny: true,
    );

    const webp =
        'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.webp';
    const png =
        'assets/textures/textures_webapp/pokemon/abomasnow/main-shiny.png';
    expect(candidates, contains(webp));
    expect(candidates, contains(png));
    expect(candidates.indexOf(webp), lessThan(candidates.indexOf(png)));
  }});

  testWidgets('pilot WebP assets replace their PNG counterparts', (tester) async {{
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    for (final webp in _pilotWebpAssets) {{
      expect(assets, contains(webp), reason: webp);
      expect(
        assets,
        isNot(contains(webp.replaceFirst(RegExp(r'\\.webp$'), '.png'))),
        reason: webp,
      );
    }}
  }});

  testWidgets('Flutter decodes every pilot WebP asset', (tester) async {{
    for (final path in _pilotWebpAssets) {{
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: path);
      expect(frame.image.height, greaterThan(0), reason: path);
      frame.image.dispose();
      codec.dispose();
    }}
  }});
}}
"""


def write_test() -> None:
    TEST_PATH.write_text(test_source(), encoding="utf-8", newline="\n")


def make_contact_sheet(images: list[tuple[PilotResult, Image.Image, Image.Image]]) -> None:
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    card_width = 720
    card_height = 300
    sheet = Image.new("RGBA", (card_width, card_height * len(images)), "white")
    draw = ImageDraw.Draw(sheet)
    for index, (result, original, converted) in enumerate(images):
        y = index * card_height
        max_side = 220
        left = original.copy()
        right = converted.copy()
        left.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
        right.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
        sheet.alpha_composite(left, (30, y + 45))
        sheet.alpha_composite(right, (360, y + 45))
        draw.text((20, y + 10), result.png_path, fill="black")
        draw.text((30, y + 265), "PNG reference", fill="black")
        draw.text((360, y + 265), "WebP lossless", fill="black")
        draw.line((0, y + card_height - 1, card_width, y + card_height - 1), fill="gray")
    sheet.convert("RGB").save(CONTACT_SHEET, format="PNG", optimize=True)


def write_reports(results: list[PilotResult]) -> None:
    REPORT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with REPORT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(
            [
                "png_path",
                "webp_path",
                "width",
                "height",
                "png_bytes",
                "webp_bytes",
                "saved_bytes",
                "saving_percent",
                "pixel_sha256",
            ]
        )
        for result in results:
            writer.writerow(
                [
                    result.png_path,
                    result.webp_path,
                    result.width,
                    result.height,
                    result.png_bytes,
                    result.webp_bytes,
                    result.saved_bytes,
                    f"{result.saving_ratio * 100:.2f}",
                    result.pixel_sha256,
                ]
            )

    original = sum(result.png_bytes for result in results)
    converted = sum(result.webp_bytes for result in results)
    saved = original - converted
    ratio = saved / original if original else 0.0
    lines = [
        "# Lotto pilota WebP lossless",
        "",
        "Il lotto converte un insieme piccolo e rappresentativo di artwork e sprite ",
        "da PNG a WebP lossless. I file PNG selezionati sono sostituiti dai relativi ",
        "WebP, mantenendo invariati percorso logico, dimensioni e pixel RGBA decodificati.",
        "",
        f"- File convertiti: **{len(results)}**",
        f"- Peso PNG di partenza: **{original / 1024 / 1024:.2f} MiB**",
        f"- Peso WebP lossless: **{converted / 1024 / 1024:.2f} MiB**",
        f"- Risparmio: **{saved / 1024 / 1024:.2f} MiB ({ratio * 100:.1f}%)**",
        "- Pixel RGBA modificati: **0**",
        "- Immagini o varianti eliminate: **0**",
        "",
        "## Copertura del campione",
        "",
        "Il campione include artwork grandi, shiny, sprite, forma regionale, forma ",
        "alternativa, differenze di genere e alcuni file riparati nel blocco precedente.",
        "",
        "## Compatibilità",
        "",
        "Il risolutore prova prima il corrispondente `.webp` e mantiene il `.png` come ",
        "fallback generale. In questo modo la migrazione può essere estesa per lotti ",
        "senza cambiare gli ID tecnici o le regole di selezione delle immagini.",
        "",
        "Il report file-per-file è disponibile in ",
        "`docs/performance/webp-lossless-pilot.csv`.",
        "",
    ]
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def read_report() -> list[PilotResult]:
    if not REPORT_CSV.is_file():
        raise RuntimeError(f"Missing pilot report: {REPORT_CSV.relative_to(ROOT)}")
    results: list[PilotResult] = []
    with REPORT_CSV.open("r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            results.append(
                PilotResult(
                    png_path=row["png_path"],
                    webp_path=row["webp_path"],
                    width=int(row["width"]),
                    height=int(row["height"]),
                    png_bytes=int(row["png_bytes"]),
                    webp_bytes=int(row["webp_bytes"]),
                    pixel_sha256=row["pixel_sha256"],
                )
            )
    return results


def check() -> None:
    legacy = LEGACY_RESOLVER.read_text(encoding="utf-8")
    preferred = PREFERRED_RESOLVER.read_text(encoding="utf-8")
    required_legacy = (
        "return _preferModernImageFormats(candidates);",
        "lower.endsWith('.png') || lower.endsWith('.webp')",
        "PokemonAssetPaths._isSupportedImagePath(assetPath)",
        "RegExp(r'\\.(?:png|webp)$')",
    )
    for marker in required_legacy:
        if marker not in legacy:
            raise RuntimeError(f"Missing resolver marker: {marker}")
    if "if (paths.contains(webp)) return webp;" not in preferred:
        raise RuntimeError("Preferred resolver does not select WebP first")
    if TEST_PATH.read_text(encoding="utf-8") != test_source():
        raise RuntimeError("WebP pilot test is missing or stale")

    results = read_report()
    expected = set(PILOT_PNGS)
    if {result.png_path for result in results} != expected:
        raise RuntimeError("Pilot report paths do not match the configured batch")

    for result in results:
        png = ROOT / result.png_path
        webp = ROOT / result.webp_path
        if png.exists():
            raise RuntimeError(f"PNG still bundled after pilot conversion: {result.png_path}")
        if not webp.is_file():
            raise RuntimeError(f"Missing WebP replacement: {result.webp_path}")
        image = strict_rgba(webp)
        if image.size != (result.width, result.height):
            raise RuntimeError(f"Dimensions changed after commit: {result.webp_path}")
        if sha256_bytes(image.tobytes()) != result.pixel_sha256:
            raise RuntimeError(f"Pixel hash changed after commit: {result.webp_path}")
        if webp.stat().st_size != result.webp_bytes:
            raise RuntimeError(f"Recorded size is stale: {result.webp_path}")


def apply() -> None:
    patch_resolvers()
    write_test()
    rendered: list[tuple[PilotResult, Image.Image, Image.Image]] = []
    for relative in PILOT_PNGS:
        rendered.append(encode_one(relative))
    results = [result for result, _, _ in rendered]
    write_reports(results)
    make_contact_sheet(rendered)
    check()


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / "sample.png"
        Image.new("RGBA", (32, 24), (30, 60, 90, 0)).save(path, format="PNG")
        image = strict_rgba(path)
        buffer = io.BytesIO()
        image.save(buffer, format="WEBP", lossless=True, exact=True, method=6)
        buffer.seek(0)
        with Image.open(buffer) as webp:
            webp.load()
            assert webp.convert("RGBA").tobytes() == image.tobytes()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.self_test:
        self_test()
    if args.apply:
        apply()
    if args.check:
        check()
    if not args.apply and not args.check and not args.self_test:
        raise RuntimeError("Choose --apply, --check or --self-test")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
