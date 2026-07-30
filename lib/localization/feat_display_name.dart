import '../models/battle_environment.dart';
import '../services/battle_environment_service.dart';
import 'game_catalog_locale.dart';

String localizedFeatDisplayName(
  String value,
  Map<String, String> displayNames,
) {
  final baseName = BattleEnvironmentService.featBaseName(value);
  final displayName = displayNames[baseName] ?? baseName;
  final terrain = BattleEnvironmentService.terrainFromFeat(value);
  if (terrain == null) return displayName;
  final terrainName = GameCatalogLocale.isItalian
      ? terrain.label
      : terrain.englishLabel;
  return '$displayName ($terrainName)';
}

String? localizedFeatDescription(
  String value,
  Map<String, String> descriptions,
) => descriptions[BattleEnvironmentService.featBaseName(value)];
