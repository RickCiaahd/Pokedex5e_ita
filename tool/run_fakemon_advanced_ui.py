from pathlib import Path

script_path = Path('tool/apply_fakemon_advanced_ui.py')
source = script_path.read_text(encoding='utf-8')

old_block = '''    """    for (final definition in installedDefinitions) {
      final json = definition.toJson();
      final baseSpeciesId = definition.baseSpeciesId;
      if (baseSpeciesId != null) {
        json['baseSpeciesId'] = idMap[baseSpeciesId] ?? baseSpeciesId;
      }
      final advanced = Map<String, dynamic>.from(
        json['advanced'] is Map ? json['advanced'] as Map : const {},
      );
      for (final key in ['evolvesFrom', 'evolvesTo']) {
        final links = advanced[key];
        if (links is! List) continue;
        advanced[key] = [
          for (final rawLink in links)
            if (rawLink is Map)
              {
                ...Map<String, dynamic>.from(rawLink),
                'pokemon': rawLink['pokemon'] is Map
                    ? {
                        ...Map<String, dynamic>.from(rawLink['pokemon'] as Map),
                        if ((rawLink['pokemon'] as Map)['pokemonId'] != null)
                          'pokemonId': idMap[
                                int.tryParse(
                                  (rawLink['pokemon'] as Map)['pokemonId']
                                      .toString(),
                                ),
                              ] ??
                              int.tryParse(
                                (rawLink['pokemon'] as Map)['pokemonId']
                                    .toString(),
                              ),
                      }
                    : rawLink['pokemon'],
              },
        ];
      }
      if (advanced.isNotEmpty) json['advanced'] = advanced;
      json['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      await _repository.save(CustomPokemonDefinition.fromJson(json));
    }
""",
'''
new_block = '''    """    for (final definition in installedDefinitions) {
      final json = definition.toJson();
      final baseSpeciesId = definition.baseSpeciesId;
      if (baseSpeciesId != null) {
        json['baseSpeciesId'] = idMap[baseSpeciesId] ?? baseSpeciesId;
      }
      final advanced = Map<String, dynamic>.from(
        json['advanced'] is Map ? json['advanced'] as Map : const {},
      );
      for (final key in ['evolvesFrom', 'evolvesTo']) {
        final links = advanced[key];
        if (links is! List) continue;
        final remappedLinks = <Map<String, dynamic>>[];
        for (final rawLink in links) {
          if (rawLink is! Map) continue;
          final linkJson = Map<String, dynamic>.from(rawLink);
          final rawPokemon = linkJson['pokemon'];
          if (rawPokemon is Map) {
            final pokemonJson = Map<String, dynamic>.from(rawPokemon);
            final sourcePokemonId = int.tryParse(
              pokemonJson['pokemonId']?.toString() ?? '',
            );
            if (sourcePokemonId != null) {
              pokemonJson['pokemonId'] =
                  idMap[sourcePokemonId] ?? sourcePokemonId;
            }
            linkJson['pokemon'] = pokemonJson;
          }
          remappedLinks.add(linkJson);
        }
        advanced[key] = remappedLinks;
      }
      if (advanced.isNotEmpty) json['advanced'] = advanced;
      json['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      await _repository.save(CustomPokemonDefinition.fromJson(json));
    }
""",
'''
if old_block not in source:
    raise SystemExit('embedded custom evolution remap marker missing')
source = source.replace(old_block, new_block, 1)
exec(compile(source, str(script_path), 'exec'))
