import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Pannello condiviso dai tour della Home e dei principali sottomenu.
///
/// Il Professore è disposto come in una schermata dialogo: figura ampia a
/// destra, ritagliata a tre quarti e appoggiata al bordo inferiore. Il fumetto
/// viene dipinto sopra la porzione sovrapposta del personaggio, così il volto e
/// il tablet restano ben visibili senza coprire testi o pulsanti.
class ProfessorTourPanel extends StatelessWidget {
  const ProfessorTourPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.lastStep,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  static const professorAsset =
      'assets/textures/trainers/onboarding_professor.png';

  final IconData icon;
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final bool lastStep;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : viewport.width;
        final clusterWidth = compact
            ? availableWidth
            : math.min(760.0, availableWidth);
        final panelWidth = compact
            ? math.min(math.max(clusterWidth * .66, 276.0), clusterWidth * .78)
            : math.min(460.0, clusterWidth * .66);
        final professorWidth = compact
            ? math.min(math.max(clusterWidth * .68, 238.0), 360.0)
            : math.min(390.0, clusterWidth * .56);
        final professorHeight = compact
            ? math.min(math.max(professorWidth * .98, 285.0), 360.0)
            : math.min(380.0, professorWidth * 1.02);

        return Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: clusterWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: professorHeight),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomLeft,
                children: [
                  // Il personaggio viene disegnato per primo: il fumetto
                  // opaco protegge sempre la leggibilità del testo nelle zone
                  // in cui i due elementi si sovrappongono.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: professorWidth,
                    height: professorHeight,
                    child: IgnorePointer(
                      child: ClipRect(
                        child: Image.asset(
                          professorAsset,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -1),
                          errorBuilder: (_, _, _) => const Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(
                              Icons.person,
                              size: 110,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 6 : 12,
                      bottom: compact ? 8 : 12,
                    ),
                    child: SizedBox(
                      width: panelWidth,
                      child: _TourSpeechCard(
                        icon: icon,
                        title: title,
                        description: description,
                        stepIndex: stepIndex,
                        totalSteps: totalSteps,
                        lastStep: lastStep,
                        onBack: onBack,
                        onNext: onNext,
                        onSkip: onSkip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TourSpeechCard extends StatelessWidget {
  const _TourSpeechCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.lastStep,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final IconData icon;
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final bool lastStep;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Material(
      color: colors.surface,
      elevation: 10,
      shadowColor: const Color(0x66000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.primary.withValues(alpha: .48)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 20,
          16,
          compact ? 14 : 18,
          14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
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
              description,
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
                  child: Text(l10n?.tourSkip ?? 'SALTA TOUR'),
                ),
                if (onBack != null)
                  OutlinedButton(
                    onPressed: onBack,
                    child: Text(l10n?.backAction ?? 'INDIETRO'),
                  ),
                FilledButton(
                  onPressed: onNext,
                  child: Text(
                    lastStep
                        ? l10n?.tourUnderstood ?? 'HO CAPITO'
                        : l10n?.nextAction ?? 'AVANTI',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
