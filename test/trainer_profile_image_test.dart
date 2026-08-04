import 'dart:convert';

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
}
