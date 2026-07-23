import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:pokedex_5e_ita/app.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDirectory = await Directory.systemTemp.createTemp('pokedex_hive_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('shows first-launch onboarding when no profiles exist', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Pokedex5EApp());
    await tester.pumpAndSettle();

    expect(find.text('Benvenuto, Allenatore.'), findsOneWidget);
    expect(find.text('AVANTI'), findsOneWidget);
  });
}
