import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../localization/ui_text.dart';

/// Pannello condiviso dai tour della Home e dei principali sottomenu.
///
/// Sui telefoni il Professore viene disposto sopra il fumetto, così testo,
/// pulsanti e illustrazione restano completamente leggibili senza sovrapporsi.
/// Sugli schermi più larghi resta il montaggio a dialogo con la figura a destra.
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
  static const professorImageKey = ValueKey<String>('tour-professor-image');
  static const speechCardKey = ValueKey<String>('tour-speech-card');

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

        if (compact) {
          final professorWidth = math.min(
            math.max(clusterWidth * .46, 178.0),
            230.0,
          );
          final professorHeight = math.min(
            math.max(professorWidth * 1.08, 192.0),
            250.0,
          );

          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: clusterWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SizedBox(
                      key: professorImageKey,
                      width: professorWidth,
                      height: professorHeight,
                      child: const _ProfessorImage(fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: SizedBox(
                      key: speechCardKey,
                      width: clusterWidth,
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
          );
        }

        final panelWidth = math.min(460.0, clusterWidth * .66);
        final professorWidth = math.min(390.0, clusterWidth * .56);
        final professorHeight = math.min(380.0, professorWidth * 1.02);

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
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: professorWidth,
                    height: professorHeight,
                    child: const SizedBox(
                      key: professorImageKey,
                      child: _ProfessorImage(fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: SizedBox(
                      key: speechCardKey,
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

class _ProfessorImage extends StatelessWidget {
  const _ProfessorImage({required this.fit});

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Image.asset(
          ProfessorTourPanel.professorAsset,
          fit: fit,
          alignment: const Alignment(0, -1),
          errorBuilder: (_, _, _) => const Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.person, size: 110, color: Colors.white),
          ),
        ),
      ),
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
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
                    child: Text(
                      l10n?.backAction ??
                          uiTextForLanguage('INDIETRO', """BACK"""),
                    ),
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
