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

  test('Trainer Atlas branding assets are wired into onboarding and Android', () {
    final onboardingSource = File(
      'lib/screens/onboarding/first_launch_onboarding_screen.dart',
    ).readAsStringSync();
    final adaptiveForeground = File(
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    ).readAsStringSync();

    expect(
      File('assets/textures/trainers/trainer_atlas_logo.png').existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png')
          .existsSync(),
      isTrue,
    );
    expect(
      onboardingSource,
      contains('_OnboardingAssets.trainerAtlasLogo'),
    );
    expect(onboardingSource, contains("label: 'Trainer Atlas 5e'"));
    expect(
      adaptiveForeground,
      contains('@drawable/trainer_atlas_launcher_foreground'),
    );
  });

  test('onboarding uses the compact layout when the keyboard is visible', () {
    final source = File(
      'lib/screens/onboarding/first_launch_onboarding_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('MediaQuery.viewInsetsOf(context).bottom > 0'),
      reason: 'Il layout deve rilevare la tastiera prima dello Scaffold',
    );
    expect(
      source,
      contains('_buildStage(keyboardVisible: keyboardVisible)'),
      reason: 'Lo stato della tastiera deve raggiungere la scena del professore',
    );
    expect(
      source,
      contains('keyboardCompact ? .22 : compactCardTopFactor'),
      reason: 'Il dialogo deve salire quando la tastiera riduce lo spazio',
    );
    expect(
      source,
      contains('constraints.maxHeight - (keyboardCompact ? 220 : 140)'),
      reason: 'Il dialogo deve conservare altezza sufficiente per lo scroll',
    );
  });
}
