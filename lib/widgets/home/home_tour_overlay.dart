import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeTourStepData {
  const HomeTourStepData({
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.description,
  });

  final GlobalKey targetKey;
  final IconData icon;
  final String title;
  final String description;
}

class HomeTourOverlay extends StatefulWidget {
  const HomeTourOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.targetRect,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  static const _professorAsset =
      'assets/textures/trainers/onboarding_professor.png';

  final HomeTourStepData step;
  final int stepIndex;
  final int totalSteps;
  final Rect? targetRect;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<HomeTourOverlay> createState() => _HomeTourOverlayState();
}

class _HomeTourOverlayState extends State<HomeTourOverlay> {
  Rect? _resolvedTargetRect;
  int _resolutionToken = 0;

  @override
  void initState() {
    super.initState();
    _resolvedTargetRect = widget.targetRect;
    _scheduleTargetResolution();
  }

  @override
  void didUpdateWidget(covariant HomeTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepIndex != widget.stepIndex) {
      _resolvedTargetRect = null;
      _scheduleTargetResolution();
    } else if (oldWidget.targetRect != widget.targetRect &&
        widget.targetRect != null) {
      _resolvedTargetRect = widget.targetRect;
    }
  }

  void _scheduleTargetResolution() {
    final token = ++_resolutionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveTarget(token);
    });
  }

  Future<void> _resolveTarget(int token) async {
    if (!mounted || token != _resolutionToken) return;

    BuildContext? targetContext = widget.step.targetKey.currentContext;
    if (targetContext == null) {
      final scrollable = _findHomeScrollable();
      if (scrollable != null && scrollable.position.hasContentDimensions) {
        const fallbackFractions = <double>[0, .18, .64, .82, 1];
        final fallbackIndex = widget.stepIndex < fallbackFractions.length
            ? widget.stepIndex
            : fallbackFractions.length - 1;
        final destination = scrollable.position.maxScrollExtent *
            fallbackFractions[fallbackIndex];
        await scrollable.position.animateTo(
          destination,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted || token != _resolutionToken) return;
        targetContext = widget.step.targetKey.currentContext;
      }
    }

    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.12,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 340));
    }

    if (!mounted || token != _resolutionToken) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final targetBox = widget.step.targetKey.currentContext?.findRenderObject()
        as RenderBox?;
    if (overlayBox == null || targetBox == null || !targetBox.hasSize) return;

    final targetOrigin = overlayBox.globalToLocal(
      targetBox.localToGlobal(Offset.zero),
    );
    setState(() {
      _resolvedTargetRect = (targetOrigin & targetBox.size).inflate(8);
    });
  }

  ScrollableState? _findHomeScrollable() {
    ScrollableState? result;

    void visit(Element element) {
      if (result != null) return;
      if (element is StatefulElement) {
        final state = element.state;
        if (state is ScrollableState && state.position.axis == Axis.vertical) {
          result = state;
          return;
        }
      }
      element.visitChildren(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root != null) visit(root);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;
    final lastStep = widget.stepIndex == widget.totalSteps - 1;

    return Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Colors.transparent,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: _resolvedTargetRect ?? widget.targetRect,
              ),
            ),
          ),
        ),
        Positioned(
          left: compact ? 8 : 24,
          right: compact ? 8 : null,
          bottom: 8,
          width: compact ? null : math.min(650.0, size.width - 48),
          child: SafeArea(
            top: false,
            child: _ProfessorSpeechPanel(
              step: widget.step,
              stepIndex: widget.stepIndex,
              totalSteps: widget.totalSteps,
              lastStep: lastStep,
              onBack: widget.onBack,
              onNext: widget.onNext,
              onSkip: widget.onSkip,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfessorSpeechPanel extends StatelessWidget {
  const _ProfessorSpeechPanel({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.lastStep,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final HomeTourStepData step;
  final int stepIndex;
  final int totalSteps;
  final bool lastStep;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 430;
    final professorWidth = compact ? 82.0 : 116.0;

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: professorWidth,
            height: compact ? 176 : 214,
            child: Image.asset(
              HomeTourOverlay._professorAsset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => const Align(
                alignment: Alignment.bottomCenter,
                child: Icon(Icons.person, size: 78, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(-10, 0),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  16,
                  compact ? 14 : 18,
                  14,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: .45),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, color: colors.primary, size: 21),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '${stepIndex + 1}/$totalSteps',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: onSkip,
                          child: const Text('SALTA TOUR'),
                        ),
                        if (onBack != null)
                          OutlinedButton(
                            onPressed: onBack,
                            child: const Text('INDIETRO'),
                          ),
                        FilledButton(
                          onPressed: onNext,
                          child: Text(lastStep ? 'HO CAPITO' : 'AVANTI'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final fullScreen = Path()..addRect(Offset.zero & size);
    final target = targetRect;

    if (target == null) {
      canvas.drawPath(
        fullScreen,
        Paint()..color = const Color(0xB8000000),
      );
      return;
    }

    final visibleBounds = Rect.fromLTWH(
      8,
      8,
      math.max(0.0, size.width - 16),
      math.max(0.0, size.height - 16),
    );
    final safeRect = target.intersect(visibleBounds);
    if (safeRect.isEmpty) {
      canvas.drawPath(
        fullScreen,
        Paint()..color = const Color(0xB8000000),
      );
      return;
    }

    final spotlight = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          safeRect,
          const Radius.circular(18),
        ),
      );
    final shadedArea = Path.combine(
      PathOperation.difference,
      fullScreen,
      spotlight,
    );

    canvas.drawPath(
      shadedArea,
      Paint()..color = const Color(0xB8000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(safeRect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFF6B17),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
