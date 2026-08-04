import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../localization/ui_text.dart';
import '../../services/profile_image_service.dart';

class TrainerProfileAvatar extends StatefulWidget {
  const TrainerProfileAvatar({
    super.key,
    required this.imageBase64,
    required this.trainerName,
    this.radius = 28,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String imageBase64;
  final String trainerName;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<TrainerProfileAvatar> createState() => _TrainerProfileAvatarState();
}

class _TrainerProfileAvatarState extends State<TrainerProfileAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = ProfileImageService.tryDecode(widget.imageBase64);
  }

  @override
  void didUpdateWidget(covariant TrainerProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _bytes = ProfileImageService.tryDecode(widget.imageBase64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(
      trainerName: widget.trainerName,
      foregroundColor: widget.foregroundColor,
    );

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor:
          widget.backgroundColor ??
          Theme.of(context).colorScheme.primaryContainer,
      child: ClipOval(
        child: SizedBox.square(
          dimension: widget.radius * 2,
          child: _bytes == null
              ? fallback
              : Image.memory(
                  _bytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class TrainerProfileImagePicker extends StatefulWidget {
  const TrainerProfileImagePicker({
    super.key,
    required this.imageBase64,
    required this.trainerName,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
    this.editButtonOnly = false,
    this.imageService,
  });

  final String imageBase64;
  final String trainerName;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool compact;
  final bool editButtonOnly;
  final ProfileImageService? imageService;

  @override
  State<TrainerProfileImagePicker> createState() =>
      _TrainerProfileImagePickerState();
}

class _TrainerProfileImagePickerState
    extends State<TrainerProfileImagePicker> {
  bool _isPicking = false;

  Future<void> _pickImage() async {
    if (!widget.enabled || _isPicking) return;
    setState(() => _isPicking = true);

    try {
      final encoded = await (widget.imageService ?? ProfileImageService())
          .pickProfileImage(
            dialogTitle: context.uiText(
              'Scegli un’immagine del profilo',
              'Choose a profile image',
            ),
          );
      if (!mounted || encoded == null) return;
      widget.onChanged(encoded);
    } on ProfileImageSelectionException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        ProfileImageFailure.tooLarge => context.uiText(
          'L’immagine supera i 20 MB. Scegline una più piccola.',
          'The image is larger than 20 MB. Choose a smaller one.',
        ),
        ProfileImageFailure.missingData => context.uiText(
          'Non è stato possibile leggere l’immagine scelta.',
          'The selected image could not be read.',
        ),
        ProfileImageFailure.unsupportedFormat => context.uiText(
          'Immagine non valida. Usa PNG, JPEG o WebP.',
          'Invalid image. Use PNG, JPEG or WebP.',
        ),
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _openEditOptions() async {
    if (!widget.enabled || _isPicking) return;

    final action = await showModalBottomSheet<_ProfileImageAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const ValueKey('replace-trainer-profile-image'),
              leading: Icon(
                widget.imageBase64.isEmpty
                    ? Icons.add_a_photo_outlined
                    : Icons.edit_outlined,
              ),
              title: Text(
                widget.imageBase64.isEmpty
                    ? context.uiText('Scegli immagine', 'Choose image')
                    : context.uiText('Sostituisci immagine', 'Replace image'),
              ),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(_ProfileImageAction.choose),
            ),
            if (widget.imageBase64.isNotEmpty)
              ListTile(
                key: const ValueKey('remove-trainer-profile-image-option'),
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  context.uiText('Rimuovi immagine', 'Remove image'),
                ),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ProfileImageAction.remove),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == _ProfileImageAction.choose) {
      await _pickImage();
    } else {
      widget.onChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageBase64.isNotEmpty;
    final avatar = TrainerProfileAvatar(
      imageBase64: widget.imageBase64,
      trainerName: widget.trainerName,
      radius: widget.compact ? 34 : 46,
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widget.editButtonOnly
          ? [
              OutlinedButton.icon(
                key: const ValueKey('edit-trainer-profile-image'),
                onPressed: widget.enabled && !_isPicking
                    ? _openEditOptions
                    : null,
                icon: _isPicking
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined),
                label: Text(
                  context.uiText(
                    'Modifica immagine profilo',
                    'Edit profile image',
                  ),
                ),
              ),
            ]
          : [
              OutlinedButton.icon(
                key: const ValueKey('choose-trainer-profile-image'),
                onPressed: widget.enabled && !_isPicking ? _pickImage : null,
                icon: _isPicking
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        hasImage
                            ? Icons.edit_outlined
                            : Icons.add_a_photo_outlined,
                      ),
                label: Text(
                  hasImage
                      ? context.uiText('Cambia foto', 'Change photo')
                      : context.uiText('Scegli foto', 'Choose photo'),
                ),
              ),
              if (hasImage)
                TextButton.icon(
                  key: const ValueKey('remove-trainer-profile-image'),
                  onPressed: widget.enabled && !_isPicking
                      ? () => widget.onChanged('')
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.uiText('Rimuovi', 'Remove')),
                ),
            ],
    );

    return Semantics(
      container: true,
      label: context.uiText(
        'Immagine del profilo Allenatore',
        'Trainer profile image',
      ),
      child: widget.compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: widget.editButtonOnly
                      ? actions
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.uiText(
                                'Foto profilo (facoltativa)',
                                'Profile photo (optional)',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            actions,
                          ],
                        ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(
                  child: widget.editButtonOnly
                      ? actions
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.uiText(
                                'Immagine profilo (facoltativa)',
                                'Profile image (optional)',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            actions,
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

enum _ProfileImageAction { choose, remove }

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.trainerName,
    required this.foregroundColor,
  });

  final String trainerName;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final parts = trainerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((part) => part[0].toUpperCase()).join();
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color:
              foregroundColor ??
              Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
