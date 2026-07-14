import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/widgets/forms/percentage_text_field.dart';
import 'package:pokedex_5e_ita/widgets/navigation/home_leading_button.dart';

void main() {
  testWidgets('il pulsante indietro torna di un solo livello', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _FirstScreen()),
                ),
                child: const Text('APRI PRIMO LIVELLO'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('APRI PRIMO LIVELLO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APRI SECONDO LIVELLO'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Indietro'));
    await tester.pumpAndSettle();

    expect(find.text('PRIMO LIVELLO'), findsOneWidget);
    expect(find.text('SECONDO LIVELLO'), findsNothing);
  });

  testWidgets('il pulsante Home torna direttamente alla radice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _FirstScreen()),
                ),
                child: const Text('APRI PRIMO LIVELLO'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('APRI PRIMO LIVELLO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APRI SECONDO LIVELLO'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('APRI PRIMO LIVELLO'), findsOneWidget);
    expect(find.text('PRIMO LIVELLO'), findsNothing);
    expect(find.text('SECONDO LIVELLO'), findsNothing);
  });

  testWidgets('la percentuale accetta più cifre senza perdere il focus', (
    tester,
  ) async {
    var value = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Center(
              child: PercentageTextField(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();

    var editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(value, 2);
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.enterText(find.byType(TextField), '25');
    await tester.pump();

    editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(value, 25);
    expect(editable.controller.text, '25');
    expect(editable.focusNode.hasFocus, isTrue);
  });
}

class _FirstScreen extends StatelessWidget {
  const _FirstScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('PRIMO LIVELLO'),
        actions: const [HomeAppBarAction()],
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _SecondScreen()),
          ),
          child: const Text('APRI SECONDO LIVELLO'),
        ),
      ),
    );
  }
}

class _SecondScreen extends StatelessWidget {
  const _SecondScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('SECONDO LIVELLO'),
        actions: const [HomeAppBarAction()],
      ),
    );
  }
}
