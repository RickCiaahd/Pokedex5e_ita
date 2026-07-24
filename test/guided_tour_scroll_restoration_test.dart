import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_5e_ita/services/guided_tour_service.dart';
import 'package:pokedex_5e_ita/widgets/tour/guided_tour.dart';

class _FakeGuidedTourService extends GuidedTourService {
  @override
  Future<bool> shouldShowTour(String tourId) async => false;

  @override
  Future<void> markTourCompleted(String tourId) async {}
}

void main() {
  testWidgets('chiudendo l’ultima tappa il contenuto torna all’inizio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final targetKey = GlobalKey();
    final scrollController = ScrollController();
    final tourController = GuidedTourController(
      tourId: 'test_tour',
      service: _FakeGuidedTourService(),
    );
    addTearDown(scrollController.dispose);
    addTearDown(tourController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 1100),
                    Container(
                      key: targetKey,
                      height: 120,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 300),
                  ],
                ),
              ),
              GuidedTourLayer(
                controller: tourController,
                steps: [
                  GuidedTourStepData(
                    targetKey: targetKey,
                    icon: Icons.info_outline,
                    title: 'Ultima tappa',
                    description: 'Descrizione conclusiva del tour.',
                    fallbackScrollFraction: 1,
                  ),
                ],
                scrollController: scrollController,
              ),
            ],
          ),
        ),
      ),
    );

    tourController.start();
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(0));
    expect(find.text('HO CAPITO'), findsOneWidget);

    await tester.tap(find.text('HO CAPITO'));
    await tester.pump();

    expect(tourController.isVisible, isFalse);
    expect(
      scrollController.offset,
      closeTo(scrollController.position.minScrollExtent, .1),
    );
  });
}
