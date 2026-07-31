import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val googlePlayCompileSdk = 36
val googlePlayTargetSdk = 36
val releaseShrinkingEnabled =
    providers.gradleProperty("trainerAtlasEnableReleaseShrinking")
        .orNull
        ?.toBooleanStrictOrNull()
        ?: false

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun requiredKeystoreProperty(name: String): String {
    return keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("Proprietà Android release mancante: $name")
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseTaskRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Firma Android release non configurata. Copia android/key.properties.example in android/key.properties e inserisci i dati del keystore."
    )
}

android {
    namespace = "io.github.rickciaahd.traineratlas"
    compileSdk = googlePlayCompileSdk
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.rickciaahd.traineratlas"
        minSdk = flutter.minSdkVersion
        targetSdk = googlePlayTargetSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = requiredKeystoreProperty("keyAlias")
                keyPassword = requiredKeystoreProperty("keyPassword")
                storeFile = file(requiredKeystoreProperty("storeFile"))
                storePassword = requiredKeystoreProperty("storePassword")
            }
        }
    }

    packaging {
        jniLibs {
            // AGP 8.5.1+ packages uncompressed native libraries with 16 KiB alignment.
            useLegacyPackaging = false
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = releaseShrinkingEnabled
            isShrinkResources = releaseShrinkingEnabled
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
