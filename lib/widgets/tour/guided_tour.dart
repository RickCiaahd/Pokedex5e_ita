import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/guided_tour_service.dart';

class GuidedTourStepData {
  const GuidedTourStepData({
    required this.targetKey,
    required this.icon,
    required this.title,
    required this.description,
    this.fallbackScrollFraction = 0,
    this.scrollAlignment = 0.12,
  });

  final GlobalKey targetKey;
  final IconData icon;
  final String title;
  final String description;
  final double fallbackScrollFraction;
  final double scrollAlignment;
}

class GuidedTourController extends ChangeNotifier {
  GuidedTourController({required this.tourId, GuidedTourService? service})
    : _service = service ?? GuidedTourService();

  final String tourId;
  final GuidedTourService _service;

  bool _automaticCheckDone = false;
  bool _isVisible = false;
  bool _isFinishing = false;
  bool _disposed = false;
  int _stepIndex = 0;

  bool get isVisible => _isVisible;
  int get stepIndex => _stepIndex;

  Future<void> showAutomaticallyIfNeeded({required bool ready}) async {
    if (!ready || _automaticCheckDone || _disposed) return;
    _automaticCheckDone = true;

    try {
      final shouldShow = await _service.shouldShowTour(tourId);
      if (_disposed || !shouldShow) return;
      start();
    } catch (error) {
      debugPrint('Impossibile verificare il tour $tourId: $error');
    }
  }

  void start() {
    if (_disposed) return;
    _automaticCheckDone = true;
    _stepIndex = 0;
    _isVisible = true;
    notifyListeners();
  }

  void previous() {
    if (_disposed || !_isVisible || _stepIndex <= 0) return;
    _stepIndex -= 1;
    notifyListeners();
  }

  Future<void> next(int totalSteps) async {
    if (_disposed || !_isVisible || totalSteps <= 0) return;
    if (_stepIndex >= totalSteps - 1) {
      await finish();
      return;
    }

    _stepIndex += 1;
    notifyListeners();
  }

  Future<void> finish() async {
    if (_disposed || _isFinishing) return;
    _isFinishing = true;
    _isVisible = false;
    notifyListeners();

    try {
      await _service.markTourCompleted(tourId);
    } catch (error) {
      debugPrint('Impossibile salvare il tour $tourId: $error');
    } finally {
      _isFinishing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class GuidedTourInfoAction extends StatelessWidget {
  const GuidedTourInfoAction({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final GuidedTourController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final canStart = enabled && !controller.isVisible;
        final wide = MediaQuery.sizeOf(context).width >= 600;

        if (wide) {
          return TextButton.icon(
            onPressed: canStart ? controller.start : null,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            icon: const Icon(Icons.info_outline),
            label: const Text('INFO'),
          );
        }

        return IconButton(
          onPressed: canStart ? controller.start : null,
          tooltip: 'INFO · Rivedi il tour',
          icon: const Icon(Icons.info_outline),
        );
      },
    );
  }
}

class GuidedTourLayer extends StatelessWidget {
  const GuidedTourLayer({
    super.key,
    required this.controller,
    required this.steps,
    required this.scrollController,
  });

  final GuidedTourController controller;
  final List<GuidedTourStepData> steps;
  final ScrollController scrollController;

  void _finishTour() {
    if (scrollController.hasClients) {
      final position = scrollController.position;
      if (position.hasContentDimensions) {
        final target = position.minScrollExtent;
        if ((position.pixels - target).abs() > .5) {
          try {
            position.jumpTo(target);
          } catch (error) {
            debugPrint(
              'Impossibile ripristinare lo scorrimento del tour: $error',
            );
          }
        }
      }
    }

    controller.finish();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isVisible || steps.isEmpty) {
          return const SizedBox.shrink();
        }

        final safeIndex = controller.stepIndex.clamp(0, steps.length - 1);
        return Positioned.fill(
          child: GuidedTourOverlay(
            step: steps[safeIndex],
            stepIndex: safeIndex,
            totalSteps: steps.length,
            scrollController: scrollController,
            onBack: safeIndex == 0 ? null : controller.previous,
            onNext: () {
              if (safeIndex == steps.length - 1) {
                _finishTour();
                return;
              }
              controller.next(steps.length);
            },
            onSkip: _finishTour,
          ),
        );
      },
    );
  }
}

class GuidedTourOverlay extends StatefulWidget {
  const GuidedTourOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.scrollController,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  static const professorAsset =
      'assets/textures/trainers/onboarding_professor.png';

  final GuidedTourStepData step;
  final int stepIndex;
  final int totalSteps;
  final ScrollController scrollController;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay> {
  Rect? _targetRect;
  int _resolutionToken = 0;

  @override
  void initState() {
    super.initState();
    _scheduleTargetResolution();
  }

  @override
  void didUpdateWidget(covariant GuidedTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepIndex != widget.stepIndex ||
        oldWidget.step.targetKey != widget.step.targetKey) {
      _targetRect = null;
      _scheduleTargetResolution();
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
    if (targetContext == null && widget.scrollController.hasClients) {
      final position = widget.scrollController.position;
      if (position.hasContentDimensions) {
        final fraction = widget.step.fallbackScrollFraction.clamp(0.0, 1.0);
        await position.animateTo(
          position.maxScrollExtent * fraction,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
        await Future<void>.delayed(const Duration(milliseconds: 140));
        if (!mounted || token != _resolutionToken) return;
        targetContext = widget.step.targetKey.currentContext;
      }
    }

    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: widget.step.scrollAlignment,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 360));
    }

    if (!mounted || token != _resolutionToken) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final targetBox =
        widget.step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlayBox == null || targetBox == null || !targetBox.hasSize) return;

    final targetOrigin = overlayBox.globalToLocal(
      targetBox.localToGlobal(Offset.zero),
    );
    setState(() {
      _targetRect = (targetOrigin & targetBox.size).inflate(8);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;
    final lastStep = widget.stepIndex == widget.totalSteps - 1;

    return Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(dismissible: false, color: Colors.transparent),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(targetRect: _targetRect),
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

  final GuidedTourStepData step;
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
              GuidedTourOverlay.professorAsset,
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '${stepIndex + 1}/$totalSteps',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.35),
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
      canvas.drawPath(fullScreen, Paint()..color = const Color(0xB8000000));
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
      canvas.drawPath(fullScreen, Paint()..color = const Color(0xB8000000));
      return;
    }

    final spotlight = Path()
      ..addRRect(RRect.fromRectAndRadius(safeRect, const Radius.circular(18)));
    final shadedArea = Path.combine(
      PathOperation.difference,
      fullScreen,
      spotlight,
    );

    canvas.drawPath(shadedArea, Paint()..color = const Color(0xB8000000));
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
