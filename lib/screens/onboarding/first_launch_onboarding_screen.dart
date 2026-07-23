import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'first_launch_onboarding_screen_impl.dart' as implementation;

/// Presentational shell for the first-launch flow.
///
/// The underlying onboarding keeps ownership of profile creation and
/// navigation. This shell adds the illustrated Professor layer without
/// coupling the saved-data flow to the artwork.
class FirstLaunchOnboardingScreen extends StatefulWidget {
  const FirstLaunchOnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<FirstLaunchOnboardingScreen> createState() =>
      _FirstLaunchOnboardingScreenState();
}

class _FirstLaunchOnboardingScreenState
    extends State<FirstLaunchOnboardingScreen> {
  int _estimatedStep = 0;

  void _handlePointerUp(PointerUpEvent event) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final size = renderObject.size;
    final padding = MediaQuery.paddingOf(context);
    final position = event.localPosition;

    final tappedBottomAction =
        position.dy >= size.height - padding.bottom - 104;
    final tappedBack =
        position.dx <= 104 && position.dy <= padding.top + 88;

    if (tappedBack && _estimatedStep > 0 && _estimatedStep < 8) {
      setState(() => _estimatedStep -= 1);
      return;
    }

    if (!tappedBottomAction || _estimatedStep >= 9) return;
    setState(() => _estimatedStep += 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = MediaQuery.paddingOf(context);
        final compact = constraints.maxWidth < 760;
        final boundedWidth = math.min(constraints.maxWidth, 1080.0);
        final centeredLeft = (constraints.maxWidth - boundedWidth) / 2;

        final sceneTop = padding.top + 12 + 44 + 14;
        final footerReserve = padding.bottom + 18 + 54 + 14;
        final sceneHeight = math.max(
          260.0,
          constraints.maxHeight - sceneTop - footerReserve,
        );

        final compactFactor = switch (_estimatedStep) {
          6 => .19,
          7 || 8 || 9 => .24,
          _ => .41,
        };
        final compactCardTop = math.max(142.0, sceneHeight * compactFactor);

        final portraitLeft = compact
            ? centeredLeft + 36
            : centeredLeft + 16 + 22;
        final portraitTop = compact ? sceneTop + 10 : sceneTop + 22;
        final portraitWidth = compact
            ? boundedWidth - 72
            : ((boundedWidth - 32 - 44 - 20) * .4);
        final portraitHeight = compact
            ? math.max(116.0, compactCardTop - 10)
            : math.max(220.0, sceneHeight - 44);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerUp: _handlePointerUp,
          child: Stack(
            fit: StackFit.expand,
            children: [
              implementation.FirstLaunchOnboardingScreen(
                onCompleted: widget.onCompleted,
              ),
              if (_estimatedStep > 0)
                Positioned(
                  left: portraitLeft,
                  top: portraitTop,
                  width: math.max(180.0, portraitWidth),
                  height: portraitHeight,
                  child: const IgnorePointer(
                    child: _ElegantProfessorPortrait(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ElegantProfessorPortrait extends StatelessWidget {
  const _ElegantProfessorPortrait();

  static const _assetPath =
      'assets/textures/trainers/professor_riccardo.webp';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFEA),
          border: Border.all(color: const Color(0xFFD8C7BF)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _ProfessorLaboratoryPainter()),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x24FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x2EFFF1E8),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: .98,
                heightFactor: 1,
                child: Transform.translate(
                  offset: const Offset(0, 10),
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.person,
                        size: 116,
                        color: Color(0xFF242120),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD8C7BF)),
                ),
                child: const Text(
                  'PROFESSORE',
                  style: TextStyle(
                    color: Color(0xFF974A28),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessorLaboratoryPainter extends CustomPainter {
  const _ProfessorLaboratoryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF4EFEA);
    final windowPaint = Paint()..color = const Color(0xFFDCE8E6);
    final wood = Paint()..color = const Color(0xFFC7B8A9);
    final plant = Paint()..color = const Color(0xFFB8CDA9);

    canvas.drawRect(Offset.zero & size, background);

    final window = Rect.fromLTWH(
      size.width * .05,
      size.height * .07,
      size.width * .34,
      size.height * .48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(8)),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(window.center.dx - 2, window.top, 4, window.height),
      wood,
    );
    canvas.drawRect(
      Rect.fromLTWH(window.left, window.center.dy - 2, window.width, 4),
      wood,
    );

    for (var index = 0; index < 4; index++) {
      final y = size.height * (.17 + index * .13);
      canvas.drawRect(
        Rect.fromLTWH(size.width * .70, y, size.width * .25, 4),
        wood,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * (.72 + (index.isEven ? .02 : .10)),
            y - 22,
            size.width * .06,
            22,
          ),
          const Radius.circular(3),
        ),
        plant,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .80, size.width, size.height * .20),
      Paint()..color = const Color(0xFFE0D1C3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
