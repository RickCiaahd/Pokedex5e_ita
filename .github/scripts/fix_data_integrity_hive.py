from pathlib import Path

path = Path('test/data_integrity_test.dart')
source = path.read_text(encoding='utf-8')

source = source.replace(
    "import 'dart:convert';\n",
    "import 'dart:convert';\nimport 'dart:io';\n",
    1,
)
source = source.replace(
    "import 'package:flutter_test/flutter_test.dart';\n",
    "import 'package:flutter_test/flutter_test.dart';\n"
    "import 'package:hive/hive.dart';\n",
    1,
)
source = source.replace(
    "  late Set<String> bundledAssets;\n  late List<Pokemon> catalog;\n\n  setUpAll(() async {\n",
    "  late Set<String> bundledAssets;\n"
    "  late List<Pokemon> catalog;\n"
    "  late Directory hiveDirectory;\n\n"
    "  setUpAll(() async {\n"
    "    hiveDirectory = await Directory.systemTemp.createTemp(\n"
    "      'pokedex_data_integrity_',\n"
    "    );\n"
    "    Hive.init(hiveDirectory.path);\n",
    1,
)
source = source.replace(
    "  group('File sorgente', () {\n",
    "  tearDownAll(() async {\n"
    "    await Hive.close();\n"
    "    await hiveDirectory.delete(recursive: true);\n"
    "  });\n\n"
    "  group('File sorgente', () {\n",
    1,
)

path.write_text(source, encoding='utf-8')
