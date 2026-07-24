import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/l10n/app_localizations_en.dart';
import 'package:pokedex_5e_ita/l10n/app_localizations_it.dart';

void main() {
  test('espone i testi principali dell onboarding in italiano e inglese', () {
    final italian = AppLocalizationsIt();
    final english = AppLocalizationsEn();

    expect(italian.onboardingProfessor, 'Professore');
    expect(english.onboardingProfessor, 'Professor');
    expect(italian.onboardingStartAdventure, 'INIZIA LA TUA AVVENTURA');
    expect(english.onboardingStartAdventure, 'START YOUR ADVENTURE');
    expect(italian.onboardingBackgroundResearcher, 'Ricercatore');
    expect(english.onboardingBackgroundResearcher, 'Researcher');
    expect(italian.onboardingOriginDmApprovedName, contains('DM'));
    expect(english.onboardingOriginDmApprovedName, contains('GM'));
    expect(italian.onboardingNoStarterResults, contains('Nessun'));
    expect(english.onboardingNoStarterResults, startsWith('No Pokémon'));
  });

  test('la schermata non conserva le principali frasi italiane hardcoded', () {
    final source = File(
      'lib/screens/onboarding/first_launch_onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains("AppLocalizations.of(context)"));
    expect(source, isNot(contains('Benvenuto nel tuo nuovo viaggio.')));
    expect(source, isNot(contains('Come ti chiami?')));
    expect(source, isNot(contains('Nessun Pokémon corrisponde alla ricerca.')));
  });
}
