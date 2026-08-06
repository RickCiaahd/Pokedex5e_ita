from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


picker_path = Path("lib/widgets/profile/trainer_profile_image_picker.dart")
picker = picker_path.read_text(encoding="utf-8")

picker = replace_once(
    picker,
    """    this.compact = false,
    this.editButtonOnly = false,
    this.imageService,
""",
    """    this.compact = false,
    this.editButtonOnly = false,
    this.avatarOnly = false,
    this.tapAvatarToEdit = false,
    this.avatarRadius,
    this.imageService,
""",
    "picker constructor options",
)

picker = replace_once(
    picker,
    """  final bool compact;
  final bool editButtonOnly;
  final ProfileImageService? imageService;
""",
    """  final bool compact;
  final bool editButtonOnly;
  final bool avatarOnly;
  final bool tapAvatarToEdit;
  final double? avatarRadius;
  final ProfileImageService? imageService;
""",
    "picker fields",
)

picker = replace_once(
    picker,
    """    final avatar = TrainerProfileAvatar(
      imageBase64: widget.imageBase64,
      trainerName: widget.trainerName,
      radius: widget.compact ? 34 : 46,
    );
    final actions = Wrap(
""",
    """    final resolvedAvatarRadius =
        widget.avatarRadius ?? (widget.compact ? 34.0 : 46.0);
    final avatar = TrainerProfileAvatar(
      imageBase64: widget.imageBase64,
      trainerName: widget.trainerName,
      radius: resolvedAvatarRadius,
    );
    final interactiveAvatar = widget.tapAvatarToEdit
        ? Tooltip(
            message: context.uiText(
              'Tocca per modificare l’immagine del profilo',
              'Tap to edit the profile image',
            ),
            child: InkResponse(
              key: const ValueKey('edit-trainer-profile-image-avatar'),
              onTap: widget.enabled && !_isPicking ? _openEditOptions : null,
              customBorder: const CircleBorder(),
              radius: resolvedAvatarRadius + 10,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  avatar,
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: _isPicking
                            ? SizedBox.square(
                                dimension: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : avatar;
    final actions = Wrap(
""",
    "interactive avatar",
)

picker = replace_once(
    picker,
    """    return Semantics(
      container: true,
""",
    """    if (widget.avatarOnly) {
      return Semantics(
        container: true,
        button: widget.tapAvatarToEdit,
        enabled: widget.enabled,
        label: context.uiText(
          'Immagine del profilo Allenatore',
          'Trainer profile image',
        ),
        hint: widget.tapAvatarToEdit
            ? context.uiText(
                'Tocca per modificarla',
                'Tap to edit it',
              )
            : null,
        child: interactiveAvatar,
      );
    }

    return Semantics(
      container: true,
""",
    "avatar-only semantics",
)

avatar_occurrences = picker.count("                avatar,\n")
if avatar_occurrences != 2:
    raise RuntimeError(
        f"picker layout avatars: expected 2 matches, found {avatar_occurrences}"
    )
picker = picker.replace(
    "                avatar,\n",
    "                interactiveAvatar,\n",
)

picker_path.write_text(picker, encoding="utf-8")

mobile_path = Path("lib/screens/trainer/trainer_sheet_mobile.dart")
mobile = mobile_path.read_text(encoding="utf-8")

old_header = """        TrainerProfileImagePicker(
          imageBase64: profileImageBase64,
          trainerName: nameController.text,
          compact: true,
          editButtonOnly: true,
          enabled: !isSaving,
          onChanged: onProfileImageChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: nameController,
          enabled: !isSaving,
          decoration: InputDecoration(
            labelText: context.uiText('Nome', 'Name'),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        _CompactChoiceLine(
          label: context.uiText('LIVELLO', 'LEVEL'),
          value: '$trainerLevel',
          onTap: () => _showCounterSheet(
            context: context,
            title: context.uiText('Livello allenatore', 'Trainer level'),
            initialValue: trainerLevel,
            minValue: TrainerProgression.minLevel,
            maxValue: TrainerProgression.maxLevel,
            onDecrease: onDecreaseLevel,
            onIncrease: onIncreaseLevel,
          ),
        ),
"""

new_header = """        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TrainerProfileImagePicker(
              imageBase64: profileImageBase64,
              trainerName: nameController.text,
              compact: true,
              avatarOnly: true,
              tapAvatarToEdit: true,
              avatarRadius: 46,
              enabled: !isSaving,
              onChanged: onProfileImageChanged,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !isSaving,
                    decoration: InputDecoration(
                      labelText: context.uiText('Nome', 'Name'),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ProminentLevelCard(
                    level: trainerLevel,
                    onTap: () => _showCounterSheet(
                      context: context,
                      title: context.uiText(
                        'Livello allenatore',
                        'Trainer level',
                      ),
                      initialValue: trainerLevel,
                      minValue: TrainerProgression.minLevel,
                      maxValue: TrainerProgression.maxLevel,
                      onDecrease: onDecreaseLevel,
                      onIncrease: onIncreaseLevel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
"""

mobile = replace_once(mobile, old_header, new_header, "mobile identity header")

level_card = """
class _ProminentLevelCard extends StatelessWidget {
  const _ProminentLevelCard({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      child: InkWell(
        key: const ValueKey('edit-trainer-level-mobile'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.military_tech_outlined, color: colors.onPrimaryContainer),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.uiText(
                        'LIVELLO ALLENATORE',
                        'TRAINER LEVEL',
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                    Text(
                      'LV $level',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: colors.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

"""

mobile = replace_once(
    mobile,
    "class _CompactChoiceLine extends StatelessWidget {\n",
    level_card + "class _CompactChoiceLine extends StatelessWidget {\n",
    "prominent level card insertion",
)

mobile_path.write_text(mobile, encoding="utf-8")

print("Trainer identity header update applied successfully.")
