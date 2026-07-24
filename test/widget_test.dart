import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:pokedex_5e_ita/l10n/app_localizations.dart';
import 'package:pokedex_5e_ita/screens/onboarding/first_launch_onboarding_screen.dart';
import 'package:pokedex_5e_ita/services/app_launch_service.dart';
import 'package:pokedex_5e_ita/services/home_tour_service.dart';

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

  test('an empty installation requests first-launch onboarding', () async {
    expect(await AppLaunchService().shouldShowOnboarding(), isTrue);
  });

  test('the global Home tour is requested once and can be completed', () async {
    final service = HomeTourService();

    expect(await service.shouldShowTour(), isTrue);
    await service.markTourCompleted();
    expect(await service.shouldShowTour(), isFalse);
  });

  testWidgets('first-launch onboarding can be mounted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: FirstLaunchOnboardingScreen(onCompleted: () {}),
      ),
    );
    await tester.pump();

    expect(find.byType(FirstLaunchOnboardingScreen), findsOneWidget);
  });
}
