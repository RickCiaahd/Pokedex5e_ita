import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_5e_ita/services/profile_image_service.dart';
import 'package:pokedex_5e_ita/widgets/profile/trainer_profile_image_picker.dart';

void main() {
  test('profile image data can be decoded safely', () {
    final encoded = base64Encode(const [1, 2, 3, 4]);

    expect(ProfileImageService.tryDecode(encoded), [1, 2, 3, 4]);
    expect(ProfileImageService.tryDecode('not base64'), isNull);
    expect(ProfileImageService.tryDecode(''), isNull);
  });

  test('Home shows the saved image and keeps the person placeholder', () {
    final homeSource = File(
      'lib/screens/home/home_screen.dart',
    ).readAsStringSync();

    expect(homeSource, contains('TrainerProfileAvatar('));
    expect(homeSource, contains("profile?.profileImageBase64 ?? ''"));
    expect(homeSource, contains('fallback: Icon('));
  });

  testWidgets('avatar accepts a custom placeholder without an image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrainerProfileAvatar(
            imageBase64: '',
            trainerName: 'Riccardo Forte',
            fallback: Icon(Icons.person),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('RF'), findsNothing);
  });

  testWidgets('avatar falls back to Trainer initials without an image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrainerProfileAvatar(
            imageBase64: '',
            trainerName: 'Riccardo Forte',
          ),
        ),
      ),
    );

    expect(find.text('RF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a selected image can be removed from the picker', (
    tester,
  ) async {
    var value = 'encoded-image';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerProfileImagePicker(
            imageBase64: value,
            trainerName: 'Misty',
            onChanged: (updated) => value = updated,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('remove-trainer-profile-image')));
    expect(value, '');
  });

  testWidgets('trainer sheet mode uses one edit button to remove an image', (
    tester,
  ) async {
    var value = 'encoded-image';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerProfileImagePicker(
            imageBase64: value,
            trainerName: 'Misty',
            editButtonOnly: true,
            onChanged: (updated) => value = updated,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('edit-trainer-profile-image')),
      findsOneWidget,
    );
    expect(find.text('Foto profilo (facoltativa)'), findsNothing);
    expect(find.text('Profile photo (optional)'), findsNothing);
    expect(
      find.byKey(const ValueKey('choose-trainer-profile-image')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('remove-trainer-profile-image')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('edit-trainer-profile-image')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('remove-trainer-profile-image-option')),
    );
    await tester.pumpAndSettle();

    expect(value, '');
  });
}
