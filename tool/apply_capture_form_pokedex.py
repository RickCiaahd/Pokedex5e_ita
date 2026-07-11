from pathlib import Path

path = Path('lib/screens/capture/capture_pokemon_screen.dart')
text = path.read_text(encoding='utf-8')

replacements = [
    (
        """      case _CaptureRegistrationAction.markSeen:\n        await _markSeen(pokemon);\n        break;\n""",
        """      case _CaptureRegistrationAction.markSeen:\n        await _markSeen(pokemon, result.formName);\n        break;\n""",
        'mark seen call',
    ),
    (
        """  Future<void> _markSeen(Pokemon pokemon) async {\n    final profile = _profile;\n    if (profile == null) return;\n\n    await _pokedexRepository.updateMarkMode(\n      profileId: profile.id,\n      pokemonId: pokemon.id,\n      seen: true,\n      caught: false,\n    );\n\n    if (!mounted) return;\n    setState(() => _successMessage = '${pokemon.name} registrato come visto.');\n  }\n""",
        """  Future<void> _markSeen(Pokemon pokemon, String? formName) async {\n    final profile = _profile;\n    if (profile == null) return;\n\n    await _pokedexRepository.registerSeen(\n      profileId: profile.id,\n      pokemonId: pokemon.id,\n      formName: formName,\n    );\n\n    if (!mounted) return;\n    setState(() => _successMessage = '${pokemon.name} registrato come visto.');\n  }\n""",
        'mark seen implementation',
    ),
    (
        """    await _pokedexRepository.updateMarkMode(\n      profileId: profile.id,\n      pokemonId: pokemon.id,\n      seen: true,\n      caught: true,\n    );\n""",
        """    await _pokedexRepository.registerCaught(\n      profileId: profile.id,\n      pokemonId: pokemon.id,\n      formName: result.formName,\n    );\n""",
        'caught registration',
    ),
]

for old, new, label in replacements:
    if old not in text:
        raise SystemExit(f'Expected block not found: {label}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
