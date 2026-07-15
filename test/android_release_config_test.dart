import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la configurazione Android usa l’identità release definitiva', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final strings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/io/github/rickciaahd/pokedex5eita/MainActivity.kt',
    );
    final legacyActivity = File(
      'android/app/src/main/kotlin/com/example/pokedex_5e_ita/MainActivity.kt',
    );

    expect(
      gradle,
      contains('namespace = "io.github.rickciaahd.pokedex5eita"'),
    );
    expect(
      gradle,
      contains('applicationId = "io.github.rickciaahd.pokedex5eita"'),
    );
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(
      gradle,
      isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
    );
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(strings, contains('<string name="app_name">Pokédex 5e ITA</string>'));
    expect(activity.existsSync(), isTrue);
    expect(
      activity.readAsStringSync(),
      contains('package io.github.rickciaahd.pokedex5eita'),
    );
    expect(legacyActivity.existsSync(), isFalse);
  });

  test('la pipeline Android e la documentazione release sono presenti', () {
    final workflow = File(
      '.github/workflows/android-release.yml',
    ).readAsStringSync();
    final documentation = File(
      'docs/android-release.md',
    ).readAsStringSync();

    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('flutter build appbundle --release'));
    expect(workflow, contains('ANDROID_KEYSTORE_BASE64'));
    expect(documentation, contains('io.github.rickciaahd.pokedex5eita'));
    expect(documentation, contains('flutter build appbundle --release'));
  });
}
