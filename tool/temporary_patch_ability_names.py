from pathlib import Path

path = Path('lib/screens/pokemon/pokemon_detail_screen_legacy.dart')
text = path.read_text(encoding='utf-8')

replacements = [
    (
        '  Map<String, String> _abilities = {};\n  Map<String, String> _featDescriptions = {};',
        '  Map<String, String> _abilities = {};\n  Map<String, String> _abilityDisplayNames = {};\n  Map<String, String> _featDescriptions = {};',
    ),
    (
        '      _abilityRepository.getAbilityDescriptions(pokemonId: _pokemon.id),\n      _evolutionRepository.getEvolutionData(),',
        '      _abilityRepository.getAbilityDescriptions(pokemonId: _pokemon.id),\n      _abilityRepository.getAbilityDisplayNames(pokemonId: _pokemon.id),\n      _evolutionRepository.getEvolutionData(),',
    ),
    (
        '    final evolutions = results[2] as Map<String, EvolutionData>;\n    final items = results[4] as List<BagItem>;',
        '    final evolutions = results[3] as Map<String, EvolutionData>;\n    final items = results[5] as List<BagItem>;',
    ),
    (
        '      _abilities = results[1] as Map<String, String>;\n      _evolutions = evolutions;\n      _featDescriptions = results[3] as Map<String, String>;\n      _itemCatalog = {for (final item in items) item.id: item};\n      _profile = results[5] as UserProfile;',
        '      _abilities = results[1] as Map<String, String>;\n      _abilityDisplayNames = results[2] as Map<String, String>;\n      _evolutions = evolutions;\n      _featDescriptions = results[4] as Map<String, String>;\n      _itemCatalog = {for (final item in items) item.id: item};\n      _profile = results[6] as UserProfile;',
    ),
    (
        '                            abilityDescriptions: _abilities,\n                            featDescriptions: _featDescriptions,',
        '                            abilityDescriptions: _abilities,\n                            abilityDisplayNames: _abilityDisplayNames,\n                            featDescriptions: _featDescriptions,',
    ),
    (
        '    required this.abilityDescriptions,\n    required this.featDescriptions,',
        '    required this.abilityDescriptions,\n    required this.abilityDisplayNames,\n    required this.featDescriptions,',
    ),
    (
        '  final Map<String, String> abilityDescriptions;\n  final Map<String, String> featDescriptions;',
        '  final Map<String, String> abilityDescriptions;\n  final Map<String, String> abilityDisplayNames;\n  final Map<String, String> featDescriptions;',
    ),
    (
        '            title: ability,\n            child: Text(',
        '            title: abilityDisplayNames[ability] ?? ability,\n            child: Text(',
    ),
]

for old, new in replacements:
    if new in text:
        continue
    if old not in text:
        raise SystemExit(f'Blocco non trovato: {old}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
