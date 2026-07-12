from pathlib import Path

replacements = {
    "lib/services/encounter_generator_service.dart": [
        ("final safeMin = min(minEnemies, maxEnemies).clamp(1, 12);", "final safeMin = min(minEnemies, maxEnemies).clamp(1, 12).toInt();"),
        ("final safeMax = max(minEnemies, maxEnemies).clamp(safeMin, 12);", "final safeMax = max(minEnemies, maxEnemies).clamp(safeMin, 12).toInt();"),
        (".clamp(safeMin, safeMax);", ".clamp(safeMin, safeMax)\n            .toInt();"),
        ("entry.value.clamp(0, 12)", "entry.value.clamp(0, 12).toInt()"),
        ("? count.clamp(1, 12)\n        : count.clamp(1, min(12, available.length));", "? count.clamp(1, 12).toInt()\n        : count.clamp(1, min(12, available.length)).toInt();"),
        ("final active = party.activePokemon.clamp(1, 12);", "final active = party.activePokemon.clamp(1, 12).toInt();"),
        ("final level = party.averageLevel.clamp(1, 20);", "final level = party.averageLevel.clamp(1, 20).toInt();"),
        ("final trainers = party.trainerCount.clamp(1, 12);", "final trainers = party.trainerCount.clamp(1, 12).toInt();"),
        ("return max(1.0, active * (0.75 + level * 0.55) + trainers * 0.25);", "return max(\n      1.0,\n      active * (0.75 + level * 0.55) + trainers * 0.25,\n    ).toDouble();"),
    ],
    "lib/screens/tools/encounter_collection_editor_screen.dart": [
        ("_weights[pokemonId] = parsed.clamp(1, 100);", "_weights[pokemonId] = parsed.clamp(1, 100).toInt();"),
        ("height: (_searchResults.length * 64.0).clamp(64.0, 260.0),", "height: (_searchResults.length * 64.0)\n                          .clamp(64.0, 260.0)\n                          .toDouble(),"),
    ],
    "lib/screens/tools/encounter_generator_screen.dart": [
        ("_manualQuantities[pokemonId] = next.clamp(1, 12);", "_manualQuantities[pokemonId] = next.clamp(1, 12).toInt();"),
        ("divisions: (_maximumSr * 2).round().clamp(1, 200),", "divisions: (_maximumSr * 2)\n                .round()\n                .clamp(1, 200)\n                .toInt(),"),
    ],
}

for file_name, file_replacements in replacements.items():
    path = Path(file_name)
    content = path.read_text(encoding="utf-8")
    for old, new in file_replacements:
        if old not in content:
            raise SystemExit(f"Expected text not found in {file_name}: {old}")
        content = content.replace(old, new)
    path.write_text(content, encoding="utf-8")
