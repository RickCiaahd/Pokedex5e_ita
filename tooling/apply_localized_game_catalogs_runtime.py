from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: attesa una occorrenza, trovate {count}: {old[:80]!r}")
    write(path, text.replace(old, new, 1))


write(
    "lib/localization/game_catalog_locale.dart",
    """/// Lingua effettiva usata dai cataloghi di gioco.
///
/// I salvataggi continuano a usare ID e nomi tecnici indipendenti dalla lingua;
/// questa classe controlla soltanto i testi mostrati all'utente.
class GameCatalogLocale {
  GameCatalogLocale._();

  static String _languageCode = 'it';
  static int _revision = 0;

  static String get languageCode => _languageCode;
  static int get revision => _revision;
  static bool get isItalian => _languageCode == 'it';
  static bool get isEnglish => _languageCode == 'en';

  static bool setLanguageCode(String? value) {
    final normalized = value?.trim().toLowerCase() == 'it' ? 'it' : 'en';
    if (_languageCode == normalized) return false;
    _languageCode = normalized;
    _revision++;
    return true;
  }
}
""",
)

# Collega la lingua effettiva di MaterialApp ai cataloghi.
replace_once(
    "lib/app.dart",
    "import 'localization/app_locale_controller.dart';\n",
    "import 'localization/app_locale_controller.dart';\n"
    "import 'localization/game_catalog_locale.dart';\n",
)
replace_once(
    "lib/app.dart",
    "        builder: (context, _) {\n          final colorScheme = ColorScheme.fromSeed(\n",
    "        builder: (context, _) {\n"
    "          final explicitLocale = _localeController.locale;\n"
    "          if (explicitLocale != null) {\n"
    "            GameCatalogLocale.setLanguageCode(explicitLocale.languageCode);\n"
    "          }\n\n"
    "          final colorScheme = ColorScheme.fromSeed(\n",
)
replace_once(
    "lib/app.dart",
    "            localeResolutionCallback: (deviceLocale, supportedLocales) {\n"
    "              return _localeController.resolveDeviceLocale(deviceLocale);\n"
    "            },\n",
    "            localeResolutionCallback: (deviceLocale, supportedLocales) {\n"
    "              final resolvedLocale = _localeController.resolveDeviceLocale(\n"
    "                deviceLocale,\n"
    "              );\n"
    "              GameCatalogLocale.setLanguageCode(\n"
    "                resolvedLocale.languageCode,\n"
    "              );\n"
    "              return resolvedLocale;\n"
    "            },\n",
)

# Le mosse devono mantenere il testo sorgente inglese quando richiesto.
replace_once(
    "lib/models/move_data.dart",
    "  factory MoveData.fromJson(String name, Map<String, dynamic> json) {\n",
    "  factory MoveData.fromJson(\n"
    "    String name,\n"
    "    Map<String, dynamic> json, {\n"
    "    bool localizeToItalian = true,\n"
    "  }) {\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      range: _localizeMetadata(json['Range']?.toString() ?? '-'),\n"
    "      duration: _localizeMetadata(json['Duration']?.toString() ?? '-'),\n"
    "      moveTime: _localizeMetadata(json['Move Time']?.toString() ?? '-'),\n"
    "      description: _localizeVisibleText(json['Description']?.toString() ?? ''),\n"
    "      scaling: _localizeNullableText(json['Scaling']?.toString()),\n",
    "      range: _metadataText(\n"
    "        json['Range']?.toString() ?? '-',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      duration: _metadataText(\n"
    "        json['Duration']?.toString() ?? '-',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      moveTime: _metadataText(\n"
    "        json['Move Time']?.toString() ?? '-',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      description: _visibleText(\n"
    "        json['Description']?.toString() ?? '',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      scaling: _nullableText(\n"
    "        json['Scaling']?.toString(),\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      save: _localizeSave(json['Save']?.toString()),\n",
    "      save: localizeToItalian\n"
    "          ? _localizeSave(json['Save']?.toString())\n"
    "          : _normalizedNullableText(json['Save']?.toString()),\n",
)
replace_once(
    "lib/models/move_data.dart",
    "  factory MoveData.fromWebJson(Map<String, dynamic> json) {\n",
    "  factory MoveData.fromWebJson(\n"
    "    Map<String, dynamic> json, {\n"
    "    bool localizeToItalian = true,\n"
    "  }) {\n",
)
replace_once(
    "lib/models/move_data.dart",
    "    final higherLevels = _localizeNullableText(\n"
    "      json['higherLevels']?.toString(),\n"
    "    );\n",
    "    final higherLevels = _nullableText(\n"
    "      json['higherLevels']?.toString(),\n"
    "      localizeToItalian: localizeToItalian,\n"
    "    );\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      range: _localizeMetadata(json['range']?.toString() ?? '-'),\n"
    "      duration: _localizeMetadata(json['duration']?.toString() ?? '-'),\n"
    "      moveTime: _localizeMetadata(json['time']?.toString() ?? '-'),\n"
    "      description: _readDescription(\n"
    "        json['description'],\n"
    "        higherLevels: higherLevels,\n"
    "      ),\n",
    "      range: _metadataText(\n"
    "        json['range']?.toString() ?? '-',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      duration: _metadataText(\n"
    "        json['duration']?.toString() ?? '-',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      moveTime: _metadataText(\n"
    "        json['time']?.toString() ?? '-',\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n"
    "      description: _readDescription(\n"
    "        json['description'],\n"
    "        higherLevels: higherLevels,\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      save: _readSave(saveMap),\n",
    "      save: _readSave(\n"
    "        saveMap,\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      ),\n",
)
replace_once(
    "lib/models/move_data.dart",
    "  static String _readDescription(dynamic value, {String? higherLevels}) {\n",
    "  static String _readDescription(\n"
    "    dynamic value, {\n"
    "    String? higherLevels,\n"
    "    required bool localizeToItalian,\n"
    "  }) {\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      parts.add(_localizeVisibleText(value.trim()));\n",
    "      parts.add(\n"
    "        _visibleText(\n"
    "          value.trim(),\n"
    "          localizeToItalian: localizeToItalian,\n"
    "        ),\n"
    "      );\n",
)
replace_once(
    "lib/models/move_data.dart",
    "            .map(_descriptionBlockToText)\n",
    "            .map(\n"
    "              (block) => _descriptionBlockToText(\n"
    "                block,\n"
    "                localizeToItalian: localizeToItalian,\n"
    "              ),\n"
    "            )\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      parts.add('Livelli superiori: ${higherLevels.trim()}');\n",
    "      final label = localizeToItalian ? 'Livelli superiori' : 'At Higher Levels';\n"
    "      parts.add('$label: ${higherLevels.trim()}');\n",
)
replace_once(
    "lib/models/move_data.dart",
    "  static String _descriptionBlockToText(dynamic block) {\n"
    "    if (block is String) return _localizeVisibleText(block);\n",
    "  static String _descriptionBlockToText(\n"
    "    dynamic block, {\n"
    "    required bool localizeToItalian,\n"
    "  }) {\n"
    "    if (block is String) {\n"
    "      return _visibleText(\n"
    "        block,\n"
    "        localizeToItalian: localizeToItalian,\n"
    "      );\n"
    "    }\n",
)
replace_once(
    "lib/models/move_data.dart",
    "          lines.add(headers.map(_localizeVisibleText).join(' | '));\n",
    "          lines.add(\n"
    "            headers\n"
    "                .map(\n"
    "                  (header) => _visibleText(\n"
    "                    header,\n"
    "                    localizeToItalian: localizeToItalian,\n"
    "                  ),\n"
    "                )\n"
    "                .join(' | '),\n"
    "          );\n",
)
replace_once(
    "lib/models/move_data.dart",
    "              _readStringList(row).map(_localizeVisibleText).join(' | '),\n",
    "              _readStringList(row)\n"
    "                  .map(\n"
    "                    (cell) => _visibleText(\n"
    "                      cell,\n"
    "                      localizeToItalian: localizeToItalian,\n"
    "                    ),\n"
    "                  )\n"
    "                  .join(' | '),\n",
)
replace_once(
    "lib/models/move_data.dart",
    "      return map.values\n"
    "          .map((value) => _localizeVisibleText(value.toString()))\n"
    "          .join(' ');\n",
    "      return map.values\n"
    "          .map(\n"
    "            (value) => _visibleText(\n"
    "              value.toString(),\n"
    "              localizeToItalian: localizeToItalian,\n"
    "            ),\n"
    "          )\n"
    "          .join(' ');\n",
)
replace_once(
    "lib/models/move_data.dart",
    "    return _localizeVisibleText(block?.toString() ?? '');\n",
    "    return _visibleText(\n"
    "      block?.toString() ?? '',\n"
    "      localizeToItalian: localizeToItalian,\n"
    "    );\n",
)
replace_once(
    "lib/models/move_data.dart",
    "  static String? _readSave(Map<String, dynamic>? saveMap) {\n"
    "    if (saveMap == null) return null;\n"
    "    final attributes = _readStringList(saveMap['attribute'])\n"
    "        .map((attribute) => _localizeAbilityAbbreviation(attribute.toUpperCase()))\n"
    "        .toList(growable: false);\n"
    "    if (attributes.isEmpty) return 'TIRO SALVEZZA';\n",
    "  static String? _readSave(\n"
    "    Map<String, dynamic>? saveMap, {\n"
    "    required bool localizeToItalian,\n"
    "  }) {\n"
    "    if (saveMap == null) return null;\n"
    "    final attributes = _readStringList(saveMap['attribute'])\n"
    "        .map(\n"
    "          (attribute) => localizeToItalian\n"
    "              ? _localizeAbilityAbbreviation(attribute.toUpperCase())\n"
    "              : attribute.toUpperCase(),\n"
    "        )\n"
    "        .toList(growable: false);\n"
    "    if (attributes.isEmpty) {\n"
    "      return localizeToItalian ? 'TIRO SALVEZZA' : 'SAVING THROW';\n"
    "    }\n",
)
replace_once(
    "lib/models/move_data.dart",
    "  static String? _localizeNullableText(String? value) {\n"
    "    final normalized = value?.trim();\n"
    "    if (normalized == null || normalized.isEmpty) return null;\n"
    "    return _localizeVisibleText(normalized);\n"
    "  }\n\n"
    "  static String _localizeVisibleText(String value) {\n",
    "  static String _metadataText(\n"
    "    String value, {\n"
    "    required bool localizeToItalian,\n"
    "  }) {\n"
    "    return localizeToItalian ? _localizeMetadata(value) : value.trim();\n"
    "  }\n\n"
    "  static String _visibleText(\n"
    "    String value, {\n"
    "    required bool localizeToItalian,\n"
    "  }) {\n"
    "    return localizeToItalian ? _localizeVisibleText(value) : value;\n"
    "  }\n\n"
    "  static String? _nullableText(\n"
    "    String? value, {\n"
    "    required bool localizeToItalian,\n"
    "  }) {\n"
    "    final normalized = _normalizedNullableText(value);\n"
    "    if (normalized == null) return null;\n"
    "    return localizeToItalian\n"
    "        ? _localizeVisibleText(normalized)\n"
    "        : normalized;\n"
    "  }\n\n"
    "  static String? _normalizedNullableText(String? value) {\n"
    "    final normalized = value?.trim();\n"
    "    return normalized == null || normalized.isEmpty ? null : normalized;\n"
    "  }\n\n"
    "  static String? _localizeNullableText(String? value) {\n"
    "    return _nullableText(value, localizeToItalian: true);\n"
    "  }\n\n"
    "  static String _localizeVisibleText(String value) {\n",
)

# Repository mosse: overlay italiano solo in italiano e cache per lingua.
replace_once(
    "lib/repositories/move_repository.dart",
    "import '../services/custom_pokemon_runtime_registry.dart';\n",
    "import '../localization/game_catalog_locale.dart';\n"
    "import '../services/custom_pokemon_runtime_registry.dart';\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "  Map<String, MoveData>? _webMoveCache;\n",
    "  Map<String, MoveData>? _webMoveCache;\n"
    "  int _catalogLocaleRevision = -1;\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "  Future<MoveData?> getMove(String reference, {int? pokemonId}) async {\n",
    "  Future<MoveData?> getMove(String reference, {int? pokemonId}) async {\n"
    "    _ensureLocaleCache();\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "       final move = MoveData.fromJson(reference, json);\n",
    "       final move = MoveData.fromJson(\n"
    "         reference,\n"
    "         json,\n"
    "         localizeToItalian: GameCatalogLocale.isItalian,\n"
    "       );\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "  Future<Map<String, MoveData>> _getWebMoveCatalog() async {\n"
    "    if (_webMoveCache != null) return _webMoveCache!;\n",
    "  Future<Map<String, MoveData>> _getWebMoveCatalog() async {\n"
    "    _ensureLocaleCache();\n"
    "    if (_webMoveCache != null) return _webMoveCache!;\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "    final localizations = await MoveLocalizationRepository().getEntries();\n",
    "    final localizations = GameCatalogLocale.isItalian\n"
    "        ? await MoveLocalizationRepository().getEntries()\n"
    "        : const <String, MoveLocalization>{};\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "       final move = MoveData.fromWebJson(\n"
    "         _localizedMoveJson(sourceJson, localizations[moveId]),\n"
    "       );\n",
    "       final move = MoveData.fromWebJson(\n"
    "         _localizedMoveJson(sourceJson, localizations[moveId]),\n"
    "         localizeToItalian: GameCatalogLocale.isItalian,\n"
    "       );\n",
)
replace_once(
    "lib/repositories/move_repository.dart",
    "  void _registerMoveKey(\n",
    "  void _ensureLocaleCache() {\n"
    "    final revision = GameCatalogLocale.revision;\n"
    "    if (_catalogLocaleRevision == revision) return;\n"
    "    _catalogLocaleRevision = revision;\n"
    "    _cache.clear();\n"
    "    _webMoveCache = null;\n"
    "  }\n\n"
    "  void _registerMoveKey(\n",
)

# Repository abilità: nomi e descrizioni italiani soltanto con locale it.
replace_once(
    "lib/repositories/ability_repository.dart",
    "import '../models/pokemon_ability.dart';\n",
    "import '../localization/game_catalog_locale.dart';\n"
    "import '../models/pokemon_ability.dart';\n",
)
replace_once(
    "lib/repositories/ability_repository.dart",
    "  Set<String>? _deprecatedAbilityCache;\n",
    "  Set<String>? _deprecatedAbilityCache;\n"
    "  int _catalogLocaleRevision = -1;\n",
)
for signature in [
    "  Future<Map<String, String>> getAbilityDescriptions({int? pokemonId}) async {\n",
    "  Future<Map<String, String>> getAbilityDisplayNames({int? pokemonId}) async {\n",
    "  Future<List<PokemonAbility>> getWebAbilities({\n",
    "  Future<Set<String>> getDeprecatedAbilityNames() async {\n",
]:
    if signature == "  Future<List<PokemonAbility>> getWebAbilities({\n":
        continue
    replace_once(
        "lib/repositories/ability_repository.dart",
        signature,
        signature + "    _ensureLocaleCache();\n",
    )
replace_once(
    "lib/repositories/ability_repository.dart",
    "  }) async {\n    if (_webAbilityCache == null) {\n",
    "  }) async {\n"
    "    _ensureLocaleCache();\n"
    "    if (_webAbilityCache == null) {\n",
)
replace_once(
    "lib/repositories/ability_repository.dart",
    "      final localizationRepository = AbilityLocalizationRepository();\n"
    "      final localizedDescriptions = await localizationRepository\n"
    "          .getDescriptions();\n"
    "      final localizedNames = await localizationRepository.getNames();\n",
    "      var localizedDescriptions = const <String, String>{};\n"
    "      var localizedNames = const <String, String>{};\n"
    "      if (GameCatalogLocale.isItalian) {\n"
    "        final localizationRepository = AbilityLocalizationRepository();\n"
    "        localizedDescriptions = await localizationRepository.getDescriptions();\n"
    "        localizedNames = await localizationRepository.getNames();\n"
    "      }\n",
)
replace_once(
    "lib/repositories/ability_repository.dart",
    "  Future<Set<String>> getDeprecatedAbilityNames() async {\n"
    "    _ensureLocaleCache();\n",
    "  Future<Set<String>> getDeprecatedAbilityNames() async {\n"
    "    _ensureLocaleCache();\n",
)
replace_once(
    "lib/repositories/ability_repository.dart",
    "    return _deprecatedAbilityCache!;\n"
    "  }\n"
    "}\n",
    "    return _deprecatedAbilityCache!;\n"
    "  }\n\n"
    "  void _ensureLocaleCache() {\n"
    "    final revision = GameCatalogLocale.revision;\n"
    "    if (_catalogLocaleRevision == revision) return;\n"
    "    _catalogLocaleRevision = revision;\n"
    "    _descriptionCache = null;\n"
    "    _displayNameCache = null;\n"
    "    _webAbilityCache = null;\n"
    "    _deprecatedAbilityCache = null;\n"
    "  }\n"
    "}\n",
)

# Repository oggetti e MT.
replace_once(
    "lib/repositories/item_repository.dart",
    "import '../models/bag_item.dart';\n",
    "import '../localization/game_catalog_locale.dart';\n"
    "import '../models/bag_item.dart';\n",
)
replace_once(
    "lib/repositories/item_repository.dart",
    "  List<BagItem>? _webItemCache;\n",
    "  List<BagItem>? _webItemCache;\n"
    "  int _catalogLocaleRevision = -1;\n",
)
replace_once(
    "lib/repositories/item_repository.dart",
    "  Future<Map<String, String>> getItemDescriptions() async {\n",
    "  Future<Map<String, String>> getItemDescriptions() async {\n"
    "    _ensureLocaleCache();\n",
)
replace_once(
    "lib/repositories/item_repository.dart",
    "  Future<List<BagItem>> getWebItems() async {\n",
    "  Future<List<BagItem>> getWebItems() async {\n"
    "    _ensureLocaleCache();\n",
)
replace_once(
    "lib/repositories/item_repository.dart",
    "    final localizations = await ItemLocalizationRepository().getEntries();\n",
    "    final localizations = GameCatalogLocale.isItalian\n"
    "        ? await ItemLocalizationRepository().getEntries()\n"
    "        : const <String, ItemLocalization>{};\n",
)
replace_once(
    "lib/repositories/item_repository.dart",
    "    final description = <String>[\n"
    "      '${tm.label}: insegna $moveName a un Pokémon compatibile.',\n",
    "    final description = <String>[\n"
    "      GameCatalogLocale.isItalian\n"
    "          ? '${tm.label}: insegna $moveName a un Pokémon compatibile.'\n"
    "          : '${tm.label}: teaches $moveName to a compatible Pokémon.',\n",
)
replace_once(
    "lib/repositories/item_repository.dart",
    "  String _labelFromId(String id) {\n",
    "  void _ensureLocaleCache() {\n"
    "    final revision = GameCatalogLocale.revision;\n"
    "    if (_catalogLocaleRevision == revision) return;\n"
    "    _catalogLocaleRevision = revision;\n"
    "    _descriptionCache = null;\n"
    "    _webItemCache = null;\n"
    "  }\n\n"
    "  String _labelFromId(String id) {\n",
)

# Repository Pokémon: descrizioni/genere e nomi delle forme per lingua.
replace_once(
    "lib/repositories/pokemon_repository.dart",
    "import '../models/pokemon.dart';\n",
    "import '../localization/game_catalog_locale.dart';\n"
    "import '../models/pokemon.dart';\n",
)
replace_once(
    "lib/repositories/pokemon_repository.dart",
    "  static int _cachedCustomRevision = -1;\n",
    "  static int _cachedCustomRevision = -1;\n"
    "  static int _cachedLocaleRevision = -1;\n",
)
replace_once(
    "lib/repositories/pokemon_repository.dart",
    "    if (_cachedAllPokemon != null && _cachedCustomRevision == customRevision) {\n",
    "    if (_cachedAllPokemon != null &&\n"
    "        _cachedCustomRevision == customRevision &&\n"
    "        _cachedLocaleRevision == GameCatalogLocale.revision) {\n",
)
text = read("lib/repositories/pokemon_repository.dart")
old = (
    "    final localizedTexts = await PokemonLocalizationRepository()\n"
    "        .getPokemonTexts();\n"
)
new = (
    "    final localizedTexts = GameCatalogLocale.isItalian\n"
    "        ? await PokemonLocalizationRepository().getPokemonTexts()\n"
    "        : const <int, PokemonLocalizedText>{};\n"
)
if text.count(old) < 1:
    raise RuntimeError("pokemon_repository.dart: overlay principale non trovato")
write(
    "lib/repositories/pokemon_repository.dart",
    text.replace(old, new, 1),
)
replace_once(
    "lib/repositories/pokemon_repository.dart",
    "    _cachedCustomRevision = customRevision;\n",
    "    _cachedCustomRevision = customRevision;\n"
    "    _cachedLocaleRevision = GameCatalogLocale.revision;\n",
)
replace_once(
    "lib/repositories/pokemon_repository.dart",
    "    _cachedCustomRevision = -1;\n",
    "    _cachedCustomRevision = -1;\n"
    "    _cachedLocaleRevision = -1;\n",
)
replace_once(
    "lib/repositories/pokemon_repository.dart",
    "      case 'male':\n        return 'Maschio';\n"
    "      case 'f':\n      case 'female':\n        return 'Femmina';\n",
    "      case 'male':\n"
    "        return GameCatalogLocale.isItalian ? 'Maschio' : 'Male';\n"
    "      case 'f':\n"
    "      case 'female':\n"
    "        return GameCatalogLocale.isItalian ? 'Femmina' : 'Female';\n",
)
# La seconda occorrenza riguarda getPokemonFlavors.
text = read("lib/repositories/pokemon_repository.dart")
old = (
    "    final localizedTexts = await PokemonLocalizationRepository()\n"
    "        .getPokemonTexts();\n"
)
if text.count(old) != 1:
    raise RuntimeError(
        "pokemon_repository.dart: attesa una seconda occorrenza per i flavor"
    )
write(
    "lib/repositories/pokemon_repository.dart",
    text.replace(
        old,
        "    final localizedTexts = GameCatalogLocale.isItalian\n"
        "        ? await PokemonLocalizationRepository().getPokemonTexts()\n"
        "        : const <int, PokemonLocalizedText>{};\n",
        1,
    ),
)

write(
    "test/game_catalog_locale_test.dart",
    """import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';

void main() {
  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
  });

  test('normalizza le lingue supportate e usa inglese come fallback', () {
    GameCatalogLocale.setLanguageCode('it');
    expect(GameCatalogLocale.languageCode, 'it');
    expect(GameCatalogLocale.isItalian, isTrue);

    GameCatalogLocale.setLanguageCode('en-US');
    expect(GameCatalogLocale.languageCode, 'en');
    expect(GameCatalogLocale.isEnglish, isTrue);

    GameCatalogLocale.setLanguageCode('fr');
    expect(GameCatalogLocale.languageCode, 'en');
  });

  test('incrementa la revisione soltanto quando cambia lingua effettiva', () {
    GameCatalogLocale.setLanguageCode('it');
    final initialRevision = GameCatalogLocale.revision;

    expect(GameCatalogLocale.setLanguageCode('it-IT'), isFalse);
    expect(GameCatalogLocale.revision, initialRevision);

    expect(GameCatalogLocale.setLanguageCode('en'), isTrue);
    expect(GameCatalogLocale.revision, initialRevision + 1);
  });
}
""",
)

write(
    "test/localized_game_catalogs_test.dart",
    """import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/localization/game_catalog_locale.dart';
import 'package:pokedex_5e_ita/repositories/ability_repository.dart';
import 'package:pokedex_5e_ita/repositories/item_repository.dart';
import 'package:pokedex_5e_ita/repositories/move_repository.dart';
import 'package:pokedex_5e_ita/repositories/pokemon_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    GameCatalogLocale.setLanguageCode('it');
    PokemonRepository.clearCache();
  });

  test('lo stesso repository mosse cambia testi senza cambiare ID tecnico', () async {
    final repository = MoveRepository();

    GameCatalogLocale.setLanguageCode('it');
    final italian = await repository.getMove('struggle');

    GameCatalogLocale.setLanguageCode('en');
    final english = await repository.getMove('struggle');

    expect(italian, isNotNull);
    expect(english, isNotNull);
    expect(italian!.id, english!.id);
    expect(italian.technicalName, 'Struggle');
    expect(english.technicalName, 'Struggle');
    expect(italian.name, 'Scontro');
    expect(english.name, 'Struggle');
    expect(italian.description, isNot(english.description));
  });

  test('abilità e oggetti usano overlay soltanto in italiano', () async {
    final abilityRepository = AbilityRepository();
    final itemRepository = ItemRepository();

    GameCatalogLocale.setLanguageCode('it');
    final italianAbilities = await abilityRepository.getWebAbilities(
      includeDeprecated: true,
    );
    final italianItems = await itemRepository.getWebItems();

    GameCatalogLocale.setLanguageCode('en');
    final englishAbilities = await abilityRepository.getWebAbilities(
      includeDeprecated: true,
    );
    final englishItems = await itemRepository.getWebItems();

    final italianOvergrow = italianAbilities.firstWhere(
      (ability) => ability.id == 'overgrow',
    );
    final englishOvergrow = englishAbilities.firstWhere(
      (ability) => ability.id == 'overgrow',
    );
    expect(italianOvergrow.name, englishOvergrow.name);
    expect(englishOvergrow.displayName, englishOvergrow.name);
    expect(italianOvergrow.displayName, isNot(englishOvergrow.displayName));
    expect(italianOvergrow.description, isNot(englishOvergrow.description));

    final italianLeftovers = italianItems.firstWhere(
      (item) => item.id == 'leftovers',
    );
    final englishLeftovers = englishItems.firstWhere(
      (item) => item.id == 'leftovers',
    );
    expect(italianLeftovers.name, 'Avanzi');
    expect(englishLeftovers.name, 'Leftovers');
    expect(italianLeftovers.id, englishLeftovers.id);
    expect(italianLeftovers.sourceName, 'Leftovers');
  });

  test('Pokémon usa i flavor sorgente inglesi e gli overlay italiani', () async {
    final repository = PokemonRepository();

    GameCatalogLocale.setLanguageCode('it');
    final italian = (await repository.getAllPokemon()).firstWhere(
      (pokemon) => pokemon.id == 1,
    );

    GameCatalogLocale.setLanguageCode('en');
    final english = (await repository.getAllPokemon()).firstWhere(
      (pokemon) => pokemon.id == 1,
    );

    expect(italian.id, english.id);
    expect(italian.name, english.name);
    expect(italian.genus, isNotEmpty);
    expect(english.genus, isNotEmpty);
    expect(italian.genus, isNot(english.genus));
    expect(italian.description, isNot(english.description));
  });
}
""",
)
