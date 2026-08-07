import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile creation offers distinct quick and guided modes', () {
    final source = File(
      'lib/screens/profile/profiles_screen.dart',
    ).readAsStringSync();

    for (final marker in [
      "ValueKey('create-profile-quick')",
      "ValueKey('create-profile-guided')",
      "'Crea profilo'",
      "'Create profile'",
      "'Crea profilo guidato'",
      "'Create guided profile'",
      '_CreateProfileNameDialog',
      '_CreateProfileImageDialog',
      "'Salta'",
      "'Skip'",
      'nome, età, origine, background e starter',
      'name, age, origin, background and starter',
    ]) {
      expect(source, contains(marker), reason: marker);
    }
  });

  test('guided creation can be cancelled only before persistence starts', () {
    final onboardingSource = File(
      'lib/screens/onboarding/first_launch_onboarding_screen.dart',
    ).readAsStringSync();
    final profilesSource = File(
      'lib/screens/profile/profiles_screen.dart',
    ).readAsStringSync();

    expect(onboardingSource, contains('this.onCancel'));
    expect(profilesSource, contains('markOnboardingCompleted: false'));
    expect(
      onboardingSource,
      contains('_canCancelFlow ? widget.onCancel : null'),
    );
    expect(onboardingSource, contains('canPop: _canPopRoute'));
    expect(onboardingSource, contains('static const int _totalSteps = 12'));
    expect(onboardingSource, contains("'Scegli la tua immagine'"));
    expect(onboardingSource, contains("'Choose your image'"));
    expect(
      onboardingSource,
      contains('if (_errorMessage != null && _step >= 10) ...['),
    );
  });
}
