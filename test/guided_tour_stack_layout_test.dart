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
  testWidgets(
    'chiudendo il tour lo Stack mantiene le dimensioni della schermata',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final contentKey = GlobalKey();
      final targetKey = GlobalKey();
      final scrollController = ScrollController();
      final tourController = GuidedTourController(
        tourId: 'stack_test',
        service: _FakeGuidedTourService(),
      );
      addTearDown(scrollController.dispose);
      addTearDown(tourController.dispose);

      tourController.start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView(
                      key: contentKey,
                      controller: scrollController,
                      children: [
                        Container(
                          key: targetKey,
                          height: 120,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  GuidedTourLayer(
                    controller: tourController,
                    steps: [
                      GuidedTourStepData(
                        targetKey: targetKey,
                        icon: Icons.info_outline,
                        title: 'Tour',
                        description: 'Descrizione.',
                      ),
                    ],
                    scrollController: scrollController,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(contentKey)).height, greaterThan(0));

      await tourController.finish();
      await tester.pumpAndSettle();

      expect(tourController.isVisible, isFalse);
      expect(tester.getSize(find.byKey(contentKey)).height, greaterThan(0));
    },
  );
}
