import 'package:flutter/material.dart';

/// Mantiene i contenuti leggibili sulle finestre ampie senza modificare il
/// comportamento delle schermate su smartphone.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

/// Returns the effective scale for ordinary body text.
double accessibleTextScaleRatio(
  BuildContext context, {
  double fontSize = 14,
}) {
  if (fontSize <= 0) return 1;
  final scaledSize = MediaQuery.textScalerOf(context).scale(fontSize);
  return (scaledSize / fontSize).clamp(1.0, 2.0).toDouble();
}

/// Interpolates a layout measurement between normal and enlarged text.
double textScaleAwareValue(
  BuildContext context, {
  required double normal,
  required double enlarged,
}) {
  final progress = (accessibleTextScaleRatio(context) - 1).clamp(0.0, 1.0);
  return normal + ((enlarged - normal) * progress);
}

/// Keeps two form fields side by side when there is room and stacks them when
/// large system text would make either field unreadable.
class ResponsiveFormFieldPair extends StatelessWidget {
  const ResponsiveFormFieldPair({
    super.key,
    required this.first,
    required this.second,
    this.spacing = 10,
    this.minimumTwoColumnWidth = 420,
  });

  final Widget first;
  final Widget second;
  final double spacing;
  final double minimumTwoColumnWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackFields =
            constraints.maxWidth < minimumTwoColumnWidth ||
            accessibleTextScaleRatio(context) > 1.3;
        if (stackFields) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: spacing),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            SizedBox(width: spacing),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
