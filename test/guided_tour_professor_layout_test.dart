import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i tour condividono il montaggio del Professore a tre quarti', () {
    final panel = File(
      'lib/widgets/tour/professor_tour_panel.dart',
    ).readAsStringSync();
    final home = File(
      'lib/widgets/home/home_tour_overlay.dart',
    ).readAsStringSync();
    final guided = File('lib/widgets/tour/guided_tour.dart').readAsStringSync();

    expect(panel, contains('alignment: Alignment.bottomRight'));
    expect(panel, contains('right: 0'));
    expect(panel, contains('bottom: 0'));
    expect(panel, contains('fit: BoxFit.cover'));
    expect(panel, contains("alignment: const Alignment(0, -1)"));
    expect(panel, contains('clusterWidth * .68'));
    expect(home, contains('ProfessorTourPanel('));
    expect(guided, contains('ProfessorTourPanel('));
    expect(home, isNot(contains('class _ProfessorSpeechPanel')));
    expect(guided, isNot(contains('class _ProfessorSpeechPanel')));
  });

  test('il fumetto viene dipinto sopra il Professore', () {
    final panel = File(
      'lib/widgets/tour/professor_tour_panel.dart',
    ).readAsStringSync();

    final professorPosition = panel.indexOf('child: Image.asset(');
    final speechCardPosition = panel.indexOf('child: _TourSpeechCard(');

    expect(professorPosition, greaterThanOrEqualTo(0));
    expect(speechCardPosition, greaterThan(professorPosition));
    expect(panel, contains('opaco protegge sempre la leggibilità'));
  });

  test('le scrollbar desktop automatiche sono disattivate', () {
    final app = File('lib/app.dart').readAsStringSync();
    expect(app, contains('MaterialScrollBehavior().copyWith('));
    expect(app, contains('scrollbars: false'));
  });
}
