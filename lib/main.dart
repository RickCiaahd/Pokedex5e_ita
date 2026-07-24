import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'localization/app_locale_controller.dart';
import 'repositories/custom_pokemon_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  CustomPokemonRepository.markStorageReady();

  final localeController = AppLocaleController();
  await localeController.load();

  runApp(Pokedex5EApp(localeController: localeController));
}
