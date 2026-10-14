import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key, read from `android/key.properties` — a file that is **not in
// this repository** and never will be: `android/.gitignore:12` names it, and
// the keystore it points at lives outside the project tree entirely, in
// `%USERPROFILE%\FlutterKeys`.
//
// **Read conditionally, on purpose.** A fresh clone, another machine, or CI has
// no `key.properties`, and a release build there must still produce something
// — signed with the debug key, as the Flutter template does — rather than fail
// to configure. Requiring the file would mean nobody but this machine could
// build the project at all.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasUploadKey = keystorePropertiesFile.exists()

android {
    namespace = "com.novamodest.store"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Chosen 2026-09-20 and **permanent**: an application id cannot be
        // changed after the first publish. No domain is owned, and none is
        // needed — a reversed product name is the accepted form.
        applicationId = "com.novamodest.store"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // The upload key when this machine has it; the debug key otherwise,
            // so a clone without `key.properties` still builds. A release
            // signed with the debug key cannot be published — Play refuses it —
            // which is the right failure: visible at upload, not at configure.
            signingConfig = signingConfigs.getByName(
                if (hasUploadKey) "release" else "debug",
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
