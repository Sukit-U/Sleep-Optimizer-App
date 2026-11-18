import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (gitignored).
// Falls back to debug signing so fresh checkouts still build a runnable APK.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
// Passwords come from the environment first, so no build needs a secret in a
// file. key.properties only fills the gaps for a local build.
fun signingValue(envName: String, propertyName: String): String? =
    System.getenv(envName)?.takeIf { it.isNotBlank() }
        ?: (keystoreProperties[propertyName] as String?)?.takeIf { it.isNotBlank() }

val storePasswordValue = signingValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val keyPasswordValue = signingValue("ANDROID_KEY_PASSWORD", "keyPassword") ?: storePasswordValue
val hasKeystore = keystoreProperties["storeFile"] != null && storePasswordValue != null
if (keystoreProperties["storeFile"] == null) {
    logger.warn("android/key.properties not found — release builds will be UNSIGNED. See docs/RELEASE_SIGNING.md")
} else if (storePasswordValue == null) {
    logger.warn("No keystore password: set ANDROID_KEYSTORE_PASSWORD — release builds will be UNSIGNED. See docs/RELEASE_SIGNING.md")
}

android {
    namespace = "com.snoozefriend.snoozemate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent once published: must match the Android app registered in
        // Firebase and the app id in Play Console.
        applicationId = "com.snoozefriend.snoozemate"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                // Paths are resolved from android/, the dir holding key.properties.
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = storePasswordValue
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            // No fallback to the debug key: an unsigned artifact is obvious,
            // a debug-signed release silently cannot be published.
            signingConfig = if (hasKeystore) signingConfigs.getByName("release") else null
        }
    }
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
        }
        create("prod") {
            dimension = "environment"
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
