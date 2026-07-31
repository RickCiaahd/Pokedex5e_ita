import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la configurazione Android usa identità e API Google Play definitive', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final strings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/io/github/rickciaahd/traineratlas/MainActivity.kt',
    );
    final legacyActivity = File(
      'android/app/src/main/kotlin/com/example/pokedex_5e_ita/MainActivity.kt',
    );

    expect(gradle, contains('namespace = "io.github.rickciaahd.traineratlas"'));
    expect(
      gradle,
      contains('applicationId = "io.github.rickciaahd.traineratlas"'),
    );
    expect(gradle, contains('val googlePlayCompileSdk = 36'));
    expect(gradle, contains('val googlePlayTargetSdk = 36'));
    expect(gradle, contains('compileSdk = googlePlayCompileSdk'));
    expect(gradle, contains('targetSdk = googlePlayTargetSdk'));
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(
      gradle,
      isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
    );
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher"'));
    expect(
      strings,
      contains('<string name="app_name">Trainer Atlas 5e</string>'),
    );
    expect(activity.existsSync(), isTrue);
    expect(
      activity.readAsStringSync(),
      contains('package io.github.rickciaahd.traineratlas'),
    );
    expect(legacyActivity.existsSync(), isFalse);
  });

  test('minificazione e resource shrinking sono testabili ma opt-in', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final proguard = File('android/app/proguard-rules.pro');

    expect(
      gradle,
      contains('gradleProperty("trainerAtlasEnableReleaseShrinking")'),
    );
    expect(gradle, contains('isMinifyEnabled = releaseShrinkingEnabled'));
    expect(gradle, contains('isShrinkResources = releaseShrinkingEnabled'));
    expect(gradle, contains('proguard-android-optimize.txt'));
    expect(gradle, contains('useLegacyPackaging = false'));
    expect(proguard.existsSync(), isTrue);
    expect(
      proguard.readAsStringSync(),
      isNot(contains('-keep class ** { *; }')),
    );
  });

  test('icona, splash Android 12+ e segreti di firma sono controllati', () {
    final adaptiveIcon = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    final foreground = File(
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
    ).readAsStringSync();
    final foregroundBitmap = File(
      'android/app/src/main/res/drawable-xxxhdpi/'
      'trainer_atlas_launcher_foreground.png',
    );
    final splash = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    final androidGitignore = File('android/.gitignore').readAsStringSync();

    expect(adaptiveIcon, contains('<adaptive-icon'));
    expect(adaptiveIcon, contains('@drawable/ic_launcher_foreground'));
    expect(foreground, contains('<bitmap'));
    expect(
      foreground,
      contains('@drawable/trainer_atlas_launcher_foreground'),
    );
    expect(foregroundBitmap.existsSync(), isTrue);
    expect(splash, contains('android:windowSplashScreenBackground'));
    expect(splash, contains('android:windowSplashScreenAnimatedIcon'));
    expect(splash, contains('@drawable/ic_launcher_foreground'));
    expect(androidGitignore, contains('key.properties'));
    expect(androidGitignore, contains('**/*.jks'));
    expect(File('android/key.properties.example').existsSync(), isTrue);
  });

  test('pipeline e documentazione coprono bundletool e aggiornamenti', () {
    final signedWorkflow = File(
      '.github/workflows/android-release.yml',
    ).readAsStringSync();
    final readinessWorkflow = File(
      '.github/workflows/release-footprint-audit.yml',
    ).readAsStringSync();
    final documentation = File('docs/android-release.md').readAsStringSync();

    expect(signedWorkflow, contains('flutter build apk --release'));
    expect(signedWorkflow, contains('flutter build appbundle --release'));
    expect(signedWorkflow, contains('ANDROID_KEYSTORE_BASE64'));
    expect(
      readinessWorkflow,
      contains(r'bundletool-all-${BUNDLETOOL_VERSION}.jar'),
    );
    expect(readinessWorkflow, contains('PAGE_ALIGNMENT_16K'));
    expect(readinessWorkflow, contains('zipalign'));
    expect(
      readinessWorkflow,
      contains('ORG_GRADLE_PROJECT_trainerAtlasEnableReleaseShrinking'),
    );
    expect(
      readinessWorkflow,
      contains('test/profile_upgrade_compatibility_test.dart'),
    );
    expect(documentation, contains('io.github.rickciaahd.traineratlas'));
    expect(documentation, contains('Android 16 (API 36)'));
    expect(documentation, contains('bundletool'));
    expect(documentation, contains('flutter build appbundle --release'));
  });
}
