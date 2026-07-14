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
    "      _originAbilityBonusSource = nextBonusSource;\n    });",
    "      _originAbilityBonusSource = nextBonusSource;\n      _reconcileTrainerPathAutomation();\n    });",
    'reconcile race ability bonus',
)
screen = replace_once(
    screen,
    "    final definition = _trainerPathResourceDefinitions\n        .where((item) => item.id == resourceId)\n        .firstOrNull;\n    if (definition == null) return;",
    "    TrainerPathResourceDefinition? definition;\n    for (final item in _trainerPathResourceDefinitions) {\n      if (item.id == resourceId) {\n        definition = item;\n        break;\n      }\n    }\n    if (definition == null) return;",
    'remove firstOrNull dependency',
)
screen_path.write_text(screen, encoding='utf-8')

service_path = Path('lib/services/trainer_path_automation_service.dart')
service = service_path.read_text(encoding='utf-8')
service = replace_once(
    service,
    "      required String description,\n    bool isRequired = true,\n    }) {",
    "      required String description,\n      bool isRequired = true,\n    }) {",
    'format choice helper',
)
service = replace_once(
    service,
    "          options: names,\n          description:\n              'Puoi lasciare vuota la scelta se vuoi mantenere un solo legame.',",
    "          options: ['Nessun secondo legame', ...names],\n          description:\n              'Scegli Nessun secondo legame per mantenere un solo Pokémon legato.',",
    'clearable second ranger bond',
)
service_path.write_text(service, encoding='utf-8')

widget_path = Path('lib/widgets/trainer/trainer_path_automation_panel.dart')
widget = widget_path.read_text(encoding='utf-8')
widget = replace_once(
    widget,
    "                '$current/${definition.maxUses}',",
    "                '$current/${definition.maxUses} ${definition.unitLabel}',",
    'show resource unit',
)
widget_path.write_text(widget, encoding='utf-8')
