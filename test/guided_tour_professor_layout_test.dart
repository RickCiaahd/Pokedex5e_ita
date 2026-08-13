import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/widgets/tour/professor_tour_panel.dart';

void main() {
  testWidgets('su telefono il fumetto non copre il Professore', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfessorTourPanel(
            icon: Icons.groups,
            title: 'Allenatore e squadra',
            description:
                'Gestisci la scheda, cattura Pokémon e organizza la squadra.',
            stepIndex: 1,
            totalSteps: 5,
            lastStep: false,
            onBack: () {},
            onNext: () {},
            onSkip: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final professor = find.byKey(ProfessorTourPanel.professorImageKey);
    final speechCard = find.byKey(ProfessorTourPanel.speechCardKey);

    expect(professor, findsOneWidget);
    expect(speechCard, findsOneWidget);
    expect(
      tester.getRect(professor).bottom,
      lessThanOrEqualTo(tester.getRect(speechCard).top),
    );
  });

  test('Home e sottomenu condividono lo stesso pannello del tour', () {
    final home = File(
      'lib/widgets/home/home_tour_overlay.dart',
    ).readAsStringSync();
    final guided = File('lib/widgets/tour/guided_tour.dart').readAsStringSync();

    expect(home, contains('ProfessorTourPanel('));
    expect(
      home,
      contains('bottom: MediaQuery.viewPaddingOf(context).bottom'),
      reason: 'Il tour Home deve restare sopra la navigazione di sistema',
    );
    expect(guided, contains('ProfessorTourPanel('));
    expect(
      guided,
      contains('bottom: MediaQuery.viewPaddingOf(context).bottom'),
      reason:
          'I tour dei sottomenu devono restare sopra la navigazione di sistema',
    );
    expect(home, isNot(contains('class _ProfessorSpeechPanel')));
    expect(guided, isNot(contains('class _ProfessorSpeechPanel')));
  });

  test('le scrollbar desktop automatiche sono disattivate', () {
    final app = File('lib/app.dart').readAsStringSync();
    expect(app, contains('MaterialScrollBehavior().copyWith('));
    expect(app, contains('scrollbars: false'));
  });
}
