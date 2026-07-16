from pathlib import Path


def replace_once(path: Path, old: str, new: str, label: str) -> None:
    source = path.read_text(encoding='utf-8')
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected one match, found {count}')
    path.write_text(source.replace(old, new, 1), encoding='utf-8')


service = Path('lib/services/profile_backup_service.dart')
replace_once(
    service,
    "              : '${targetId}${value.substring(separator)}';\n",
    "              : '$targetId${value.substring(separator)}';\n",
    'identity key interpolation',
)

library = Path('lib/screens/pokemon/custom_pokemon_library_screen.dart')
replace_once(
    library,
    "                Flexible(\n"
    "                  child: SingleChildScrollView(\n"
    "                    child: Column(\n"
    "                      children: [\n"
    "                        for (final reference in report.references)\n"
    "                          ListTile(\n"
    "                            dense: true,\n"
    "                            leading: const Icon(Icons.link),\n"
    "                            title: Text(reference.location),\n"
    "                            subtitle: Text(\n"
    "                              '${reference.profileName} · ${reference.detail}',\n"
    "                            ),\n"
    "                          ),\n"
    "                      ],\n"
    "                    ),\n"
    "                  ),\n"
    "                ),\n",
    "                ConstrainedBox(\n"
    "                  constraints: const BoxConstraints(maxHeight: 420),\n"
    "                  child: ListView.builder(\n"
    "                    shrinkWrap: true,\n"
    "                    itemCount: report.references.length,\n"
    "                    itemBuilder: (context, index) {\n"
    "                      final reference = report.references[index];\n"
    "                      return ListTile(\n"
    "                        dense: true,\n"
    "                        leading: const Icon(Icons.link),\n"
    "                        title: Text(reference.location),\n"
    "                        subtitle: Text(\n"
    "                          '${reference.profileName} · ${reference.detail}',\n"
    "                        ),\n"
    "                      );\n"
    "                    },\n"
    "                  ),\n"
    "                ),\n",
    'bounded reference list',
)

validation = Path('fakemon_backup_validation.txt')
if validation.exists():
    validation.unlink()
