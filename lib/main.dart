import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'localization/app_locale_controller.dart';
import 'repositories/custom_pokemon_repository.dart';
import 'services/performance_trace.dart';

Future<void> main() async {
  final coldStartTrace = PerformanceTrace.start('app.cold_start');
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  CustomPokemonRepository.markStorageReady();

  final localeController = AppLocaleController();
  await localeController.load();

  runApp(Pokedex5EApp(localeController: localeController));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    coldStartTrace.finish(arguments: {'phase': 'first_frame'});
  });
}
