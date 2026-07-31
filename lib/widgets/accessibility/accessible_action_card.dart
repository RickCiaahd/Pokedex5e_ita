import 'package:flutter/material.dart';

/// A primary navigation action with one concise screen-reader announcement.
class AccessibleActionCard extends StatelessWidget {
  const AccessibleActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          color: emphasized ? colors.primaryContainer : null,
          child: ListTile(
            leading: Icon(
              icon,
              color: emphasized ? colors.onPrimaryContainer : colors.primary,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
