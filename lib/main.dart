import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'repositories/custom_pokemon_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  CustomPokemonRepository.markStorageReady();

  runApp(const Pokedex5EApp());
}
