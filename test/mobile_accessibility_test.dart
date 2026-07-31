import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/app.dart';
import 'package:pokedex_5e_ita/widgets/accessibility/accessible_action_card.dart';
import 'package:pokedex_5e_ita/widgets/layout/responsive_content.dart';

void main() {
  test('il tema mantiene target tattili Android di almeno 48 dp', () {
    final mobileTheme = buildTrainerAtlasTheme(
      platform: TargetPlatform.android,
    );
    final desktopTheme = buildTrainerAtlasTheme(
      platform: TargetPlatform.windows,
    );

    expect(
      mobileTheme.materialTapTargetSize,
      MaterialTapTargetSize.padded,
    );
    expect(mobileTheme.visualDensity, VisualDensity.standard);
    expect(
      desktopTheme.materialTapTargetSize,
      MaterialTapTargetSize.shrinkWrap,
    );
  });

  testWidgets('la scala testo segue le impostazioni della piattaforma', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    const textKey = Key('platform-scaled-text');
    await tester.pumpWidget(
      MaterialApp(
        builder: buildPlatformMediaQuery,
        home: const Scaffold(
          body: Center(
            child: Text(
              'Testo accessibile',
              key: textKey,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );

    final normalHeight = tester.getSize(find.byKey(textKey)).height;
    final normalScale = MediaQuery.textScalerOf(
      tester.element(find.byKey(textKey)),
    ).scale(20);

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pump();

    final enlargedHeight = tester.getSize(find.byKey(textKey)).height;
    final enlargedScale = MediaQuery.textScalerOf(
      tester.element(find.byKey(textKey)),
    ).scale(20);

    expect(normalScale, closeTo(20, 0.01));
    expect(enlargedScale, greaterThan(normalScale));
    expect(enlargedHeight, greaterThan(normalHeight));
  });

  testWidgets('le geometrie crescono con il testo di sistema', (tester) async {
    double? normalHeight;
    double? enlargedHeight;

    Future<void> pumpScale(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Builder(
              builder: (context) {
                final value = textScaleAwareValue(
                  context,
                  normal: 68,
                  enlarged: 98,
                );
                if (scale == 1) {
                  normalHeight = value;
                } else {
                  enlargedHeight = value;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    }

    await pumpScale(1);
    await pumpScale(2);

    expect(normalHeight, 68);
    expect(enlargedHeight, 98);
  });

  testWidgets('i campi affiancati si impilano al 200%', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const firstKey = Key('first-field');
    const secondKey = Key('second-field');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ResponsiveFormFieldPair(
              first: SizedBox(key: firstKey, height: 48),
              second: SizedBox(key: secondKey, height: 48),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byKey(secondKey)).dy,
      greaterThan(tester.getBottomLeft(find.byKey(firstKey)).dy),
    );
  });

  testWidgets('pulsanti e icone rispettano i 48 dp su Android', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTrainerAtlasTheme(platform: TargetPlatform.android),
        home: Scaffold(
          body: Center(
            child: Wrap(
              children: [
                FilledButton(
                  key: const Key('filled-action'),
                  onPressed: () {},
                  child: const Text('Azione'),
                ),
                IconButton(
                  key: const Key('icon-action'),
                  tooltip: 'Impostazioni',
                  onPressed: () {},
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final filledSize = tester.getSize(
      find.byKey(const Key('filled-action')),
    );
    final iconSize = tester.getSize(find.byKey(const Key('icon-action')));
    expect(filledSize.height, greaterThanOrEqualTo(48));
    expect(iconSize.width, greaterThanOrEqualTo(48));
    expect(iconSize.height, greaterThanOrEqualTo(48));
  });

  for (final content in const [
    (
      title: 'Riprendi combattimento Allenatore',
      subtitle:
          'Continua la sessione esistente mantenendo turni, condizioni e punti ferita.',
    ),
    (
      title: 'Resume Trainer battle',
      subtitle:
          'Continue the existing session while preserving turns, conditions and hit points.',
    ),
  ]) {
    testWidgets(
      'azione Home senza overflow al 200%: ${content.title}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
        final semanticsLabel = '${content.title}. ${content.subtitle}';

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildTrainerAtlasTheme(
                platform: TargetPlatform.android,
              ),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 568),
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: AccessibleActionCard(
                      icon: Icons.flash_on,
                      title: content.title,
                      subtitle: content.subtitle,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.bySemanticsLabel(semanticsLabel), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
