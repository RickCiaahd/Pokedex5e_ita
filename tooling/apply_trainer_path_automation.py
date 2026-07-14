from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: attesa 1 occorrenza, trovate {count}")
    return text.replace(old, new, 1)


screen_path = Path('lib/screens/trainer/trainer_sheet_screen.dart')
screen = screen_path.read_text(encoding='utf-8')

screen = replace_once(
    screen,
    "import '../../repositories/trainer_manual_repository.dart';\nimport '../../widgets/navigation/home_leading_button.dart';",
    "import '../../repositories/trainer_manual_repository.dart';\nimport '../../services/trainer_path_automation_service.dart';\nimport '../../widgets/navigation/home_leading_button.dart';\nimport '../../widgets/trainer/trainer_path_automation_panel.dart';",
    'import trainer path automation',
)

screen = replace_once(
    screen,
    "  List<Pokemon> _starterCandidates = [];\n  List<TrainerOrigin> _trainerOrigins = [];",
    "  List<Pokemon> _starterCandidates = [];\n  Map<int, Pokemon> _pokemonById = {};\n  List<TrainerOrigin> _trainerOrigins = [];",
    'pokemon catalog state',
)

screen = replace_once(
    screen,
    "  List<String> _specializations = [];\n  bool _isLoading = true;",
    "  List<String> _specializations = [];\n  Map<String, String> _trainerPathChoices = {};\n  Map<String, int> _trainerPathResources = {};\n  bool _isLoading = true;",
    'trainer path state',
)

screen = replace_once(
    screen,
    "        _starterCandidates = starterCandidates;\n        _trainerOrigins = trainerOrigins;",
    "        _starterCandidates = starterCandidates;\n        _pokemonById = {for (final item in pokemon) item.id: item};\n        _trainerOrigins = trainerOrigins;",
    'load pokemon catalog',
)

screen = replace_once(
    screen,
    "        _specializations = [...profile.specializations];\n        _isLoading = false;",
    "        _specializations = [...profile.specializations];\n        _trainerPathChoices = {...profile.trainerPathChoices};\n        _trainerPathResources = {...profile.trainerPathResources};\n        _reconcileTrainerPathAutomation();\n        _isLoading = false;",
    'load path state',
)

screen = replace_once(
    screen,
    "  void _changeLevel(int delta) {\n    setState(() {\n      _trainerLevel = TrainerProgression.clampLevel(_trainerLevel + delta);\n    });\n  }",
    "  void _changeLevel(int delta) {\n    setState(() {\n      _trainerLevel = TrainerProgression.clampLevel(_trainerLevel + delta);\n      _reconcileTrainerPathAutomation();\n    });\n  }",
    'reconcile level',
)

screen = replace_once(
    screen,
    "      _abilityScores = {\n        ..._abilityScores,\n        ability: (current + delta).clamp(1, 30).toInt(),\n      };\n    });",
    "      _abilityScores = {\n        ..._abilityScores,\n        ability: (current + delta).clamp(1, 30).toInt(),\n      };\n      _reconcileTrainerPathAutomation();\n    });",
    'reconcile ability score',
)

screen = replace_once(
    screen,
    "  void _changeTrainerPath(String? path) {\n    setState(() => _trainerPath = path ?? '');\n  }",
    "  void _changeTrainerPath(String? path) {\n    final nextPath = path ?? '';\n    if (nextPath == _trainerPath) return;\n    setState(() {\n      _trainerPath = nextPath;\n      _trainerPathChoices = {};\n      _trainerPathResources = {};\n      _reconcileTrainerPathAutomation(resetResources: true);\n    });\n  }",
    'change trainer path',
)

screen = replace_once(
    screen,
    "    setState(() => _specializations = next);",
    "    setState(() {\n      _specializations = next;\n      _reconcileTrainerPathAutomation();\n    });",
    'reconcile specialization',
)

helper_marker = "  void _changeStarter(Pokemon pokemon) {"
helper_block = """  List<String> get _teamPokemonNames {
    final names = <String>[];
    for (final slot in _team) {
      final pokemonId = slot.pokemonId;
      if (pokemonId == null) continue;
      final pokemon = _pokemonById[pokemonId];
      if (pokemon == null) continue;
      final nickname = slot.nickname?.trim() ?? '';
      final displayName = nickname.isEmpty
          ? pokemon.name
          : '$nickname (${pokemon.name})';
      names.add('Slot ${slot.slotIndex + 1} · $displayName');
    }
    return names;
  }

  List<TrainerPathChoiceDefinition> get _trainerPathChoiceDefinitions {
    return TrainerPathAutomationService.choicesFor(
      trainerPath: _trainerPath,
      trainerLevel: _trainerLevel,
      trainerPaths: _trainerPaths,
      specializations: _specializations,
      teamPokemonNames: _teamPokemonNames,
    );
  }

  List<TrainerPathResourceDefinition> get _trainerPathResourceDefinitions {
    return TrainerPathAutomationService.resourcesFor(
      trainerPath: _trainerPath,
      trainerLevel: _trainerLevel,
      abilityScores: _abilityScores,
      choices: _trainerPathChoices,
    );
  }

  void _reconcileTrainerPathAutomation({bool resetResources = false}) {
    final choiceDefinitions = _trainerPathChoiceDefinitions;
    _trainerPathChoices = TrainerPathAutomationService.reconcileChoices(
      current: _trainerPathChoices,
      definitions: choiceDefinitions,
    );
    final resourceDefinitions = _trainerPathResourceDefinitions;
    _trainerPathResources = TrainerPathAutomationService.reconcileResources(
      current: resetResources ? const {} : _trainerPathResources,
      definitions: resourceDefinitions,
    );
  }

  void _changeTrainerPathResource(String resourceId, int value) {
    final definition = _trainerPathResourceDefinitions
        .where((item) => item.id == resourceId)
        .firstOrNull;
    if (definition == null) return;
    setState(() {
      _trainerPathResources = {
        ..._trainerPathResources,
        resourceId: value.clamp(0, definition.maxUses).toInt(),
      };
    });
  }

  void _changeTrainerPathChoice(String choiceId, String value) {
    setState(() {
      final next = {..._trainerPathChoices, choiceId: value};
      if (choiceId == 'rangerStrongBond1' &&
          next['rangerStrongBond2'] == value) {
        next.remove('rangerStrongBond2');
      }
      if (choiceId == 'rangerStrongBond2' &&
          next['rangerStrongBond1'] == value) {
        next.remove('rangerStrongBond1');
      }
      _trainerPathChoices = next;
      _reconcileTrainerPathAutomation();
    });
  }

  void _restoreTrainerPathResources(TrainerPathResourceReset rest) {
    setState(() {
      _trainerPathResources = TrainerPathAutomationService.restoreForRest(
        current: _trainerPathResources,
        definitions: _trainerPathResourceDefinitions,
        rest: rest,
      );
    });
  }

"""
if screen.count(helper_marker) != 1:
    raise RuntimeError('helper marker trainer path non univoco')
screen = screen.replace(helper_marker, helper_block + helper_marker, 1)

screen = replace_once(
    screen,
    "    _changeTrainerPath(selected);\n  }\n\n  Future<void> _openSpecializationPicker",
    "    if (selected == null || selected == _trainerPath) return;\n\n    final savedPath = _profile?.trainerPath.trim() ?? '';\n    if (savedPath.isNotEmpty && selected != savedPath) {\n      final confirmed = await showDialog<bool>(\n        context: context,\n        builder: (_) => AlertDialog(\n          title: const Text('Cambiare Trainer Path?'),\n          content: Text(\n            'Passerai da $savedPath a $selected. Le risorse consumate e le scelte specifiche del vecchio path verranno azzerate.',\n          ),\n          actions: [\n            TextButton(\n              onPressed: () => Navigator.of(context).pop(false),\n              child: const Text('ANNULLA'),\n            ),\n            FilledButton(\n              onPressed: () => Navigator.of(context).pop(true),\n              child: const Text('CAMBIA TRAINER PATH'),\n            ),\n          ],\n        ),\n      );\n      if (!mounted || confirmed != true) return;\n    }\n\n    _changeTrainerPath(selected);\n  }\n\n  Future<void> _openSpecializationPicker",
    'confirm path change',
)

screen = replace_once(
    screen,
    "        trainerPath: _trainerPath,\n      );",
    "        trainerPath: _trainerPath,\n        trainerPathChoices: {..._trainerPathChoices},\n        trainerPathResources: {..._trainerPathResources},\n      );",
    'save path automation',
)

screen = replace_once(
    screen,
    "                onSpeedChanged: _changeSpeed,\n                onSave: _saveProfile,\n              ),\n            ],",
    "                onSpeedChanged: _changeSpeed,\n                onSave: _saveProfile,\n              ),\n              const SizedBox(height: 16),\n              TrainerPathAutomationPanel(\n                trainerPath: _trainerPath,\n                resources: _trainerPathResourceDefinitions,\n                resourceValues: _trainerPathResources,\n                choices: _trainerPathChoiceDefinitions,\n                choiceValues: _trainerPathChoices,\n                onResourceChanged: _changeTrainerPathResource,\n                onChoiceChanged: _changeTrainerPathChoice,\n                onShortRest: () => _restoreTrainerPathResources(\n                  TrainerPathResourceReset.shortRest,\n                ),\n                onLongRest: () => _restoreTrainerPathResources(\n                  TrainerPathResourceReset.longRest,\n                ),\n              ),\n            ],",
    'insert automation panel',
)

screen = replace_once(
    screen,
    "            title: 'Trainer Path',\n            level: level,",
    "            title: 'Privilegio del Path',\n            level: level,",
    'rename later path features',
)

screen_path.write_text(screen, encoding='utf-8')

service_path = Path('lib/services/trainer_path_automation_service.dart')
service = service_path.read_text(encoding='utf-8')
service = replace_once(
    service,
    "    required this.description,\n  });\n\n  final String id;",
    "    required this.description,\n    this.isRequired = true,\n  });\n\n  final String id;",
    'choice required constructor',
)
service = replace_once(
    service,
    "  final List<String> options;\n  final String description;\n}",
    "  final List<String> options;\n  final String description;\n  final bool isRequired;\n}",
    'choice required field',
)
service = replace_once(
    service,
    "    required String description,\n    }) {",
    "    required String description,\n    bool isRequired = true,\n    }) {",
    'choice add optional parameter',
)
service = replace_once(
    service,
    "          description: description,\n        ),",
    "          description: description,\n          isRequired: isRequired,\n        ),",
    'choice add required value',
)
service = replace_once(
    service,
    "          description:\n              'Puoi lasciare vuota la scelta se vuoi mantenere un solo legame.',\n        );",
    "          description:\n              'Puoi lasciare vuota la scelta se vuoi mantenere un solo legame.',\n          isRequired: false,\n        );",
    'optional second ranger bond',
)
service = replace_once(
    service,
    "    return {\n      for (final definition in definitions)\n        definition.id: current.containsKey(definition.id)\n            ? (current[definition.id] ?? 0)\n                .clamp(0, definition.maxUses)\n                .toInt()\n            : refillNewResources\n                ? definition.maxUses\n                : 0,\n    };",
    "    final next = {...current};\n    for (final definition in definitions) {\n      next[definition.id] = current.containsKey(definition.id)\n          ? (current[definition.id] ?? 0)\n              .clamp(0, definition.maxUses)\n              .toInt()\n          : refillNewResources\n              ? definition.maxUses\n              : 0;\n    }\n    return next;",
    'preserve locked resources',
)
service = replace_once(
    service,
    "    return {\n      for (final definition in definitions)\n        definition.id: rest == TrainerPathResourceReset.longRest ||\n                definition.reset == TrainerPathResourceReset.shortRest\n            ? definition.maxUses\n            : (current[definition.id] ?? definition.maxUses)\n                .clamp(0, definition.maxUses)\n                .toInt(),\n    };",
    "    final next = {...current};\n    for (final definition in definitions) {\n      next[definition.id] = rest == TrainerPathResourceReset.longRest ||\n              definition.reset == TrainerPathResourceReset.shortRest\n          ? definition.maxUses\n          : (current[definition.id] ?? definition.maxUses)\n              .clamp(0, definition.maxUses)\n              .toInt();\n    }\n    return next;",
    'preserve locked resources on rest',
)
service = replace_once(
    service,
    "    return {\n      for (final definition in definitions)\n        if (current[definition.id] != null &&\n            definition.options.contains(current[definition.id]))\n          definition.id: current[definition.id]!,\n    };",
    "    final next = {...current};\n    for (final definition in definitions) {\n      final selected = current[definition.id];\n      if (selected == null || !definition.options.contains(selected)) {\n        next.remove(definition.id);\n      }\n    }\n    return next;",
    'preserve locked choices',
)
service = replace_once(
    service,
    "      if (definition.options.isEmpty) return false;",
    "      if (!definition.isRequired || definition.options.isEmpty) return false;",
    'optional choice missing check',
)
service_path.write_text(service, encoding='utf-8')
