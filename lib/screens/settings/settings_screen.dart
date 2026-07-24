import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../localization/app_locale_controller.dart';
import '../../widgets/layout/responsive_content.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppLocaleScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ResponsiveContent(
        maxWidth: 760,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(
                  l10n.languageSectionTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.languageSectionSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _LocaleOption(
                  icon: Icons.phone_android_outlined,
                  title: l10n.languageSystemTitle,
                  subtitle: l10n.languageSystemSubtitle,
                  selected: controller.preference == AppLocalePreference.system,
                  onTap: () async {
                    await controller.setPreference(AppLocalePreference.system);
                  },
                ),
                _LocaleOption(
                  icon: Icons.language,
                  title: l10n.languageItalianTitle,
                  subtitle: l10n.languageItalianSubtitle,
                  selected:
                      controller.preference == AppLocalePreference.italian,
                  onTap: () async {
                    await controller.setPreference(AppLocalePreference.italian);
                  },
                ),
                _LocaleOption(
                  icon: Icons.public,
                  title: l10n.languageEnglishTitle,
                  subtitle: l10n.languageEnglishSubtitle,
                  selected:
                      controller.preference == AppLocalePreference.english,
                  onTap: () async {
                    await controller.setPreference(AppLocalePreference.english);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LocaleOption extends StatelessWidget {
  const _LocaleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colors.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? colors.onPrimaryContainer : colors.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? colors.primary : colors.outline,
        ),
        onTap: onTap,
      ),
    );
  }
}
